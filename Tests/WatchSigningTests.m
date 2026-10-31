#import <Foundation/Foundation.h>
#import "ALTApplication.h"
#import "ALTProvisioningProfile.h"
#import "ALTCertificate.h"
#import "ALTSigner.h"
#import "ALTTeam.h"
#import "ALTCapabilities.h"

static NSURL *work;
static NSInteger assertions;
static void check(BOOL condition, NSString *message)
{
    assertions++;
    if (!condition) { NSLog(@"FAIL: %@", message); exit(1); }
}

static int command(NSString *path, NSArray<NSString *> *arguments)
{
    NSTask *task = [NSTask new];
    task.launchPath = path;
    task.arguments = arguments;
    task.standardOutput = [NSFileHandle fileHandleWithNullDevice];
    [task launch];
    [task waitUntilExit];
    return task.terminationStatus;
}

static NSDictionary *info(NSURL *URL)
{
    return [NSDictionary dictionaryWithContentsOfURL:[URL URLByAppendingPathComponent:@"Info.plist"]];
}

static ALTApplication *app(NSString *path, NSString *identifier, NSDictionary *additional)
{
    NSURL *URL = [work URLByAppendingPathComponent:path];
    [[NSFileManager defaultManager] createDirectoryAtURL:URL withIntermediateDirectories:YES attributes:nil error:nil];
    NSMutableDictionary *dictionary = [@{@"CFBundleIdentifier": identifier, @"CFBundleName": @"Test", @"CFBundleExecutable": @"Executable", @"CFBundlePackageType": @"APPL", @"CFBundleVersion": @"1"} mutableCopy];
    [dictionary addEntriesFromDictionary:additional];
    check([dictionary writeToURL:[URL URLByAppendingPathComponent:@"Info.plist"] atomically:YES], @"write fixture plist");
    [[NSFileManager defaultManager] copyItemAtURL:[work URLByAppendingPathComponent:@"Executable"] toURL:[URL URLByAppendingPathComponent:@"Executable"] error:nil];
    return [[ALTApplication alloc] initWithFileURL:URL];
}

static ALTProvisioningProfile *profile(NSString *identifier, NSArray *platforms, NSDictionary *entitlements)
{
    NSURL *plist = [work URLByAppendingPathComponent:@"profile.plist"];
    NSURL *cms = [work URLByAppendingPathComponent:[NSUUID UUID].UUIDString];
    NSMutableDictionary *values = [@{@"application-identifier": [@"Z9NVYMZ644." stringByAppendingString:identifier], @"com.apple.developer.team-identifier": @"Z9NVYMZ644", @"get-task-allow": @YES} mutableCopy];
    [values addEntriesFromDictionary:entitlements];
    NSDictionary *dictionary = @{@"Name": @"Synthetic profile", @"UUID": [NSUUID UUID].UUIDString, @"TeamIdentifier": @[@"Z9NVYMZ644"], @"TeamName": @"Tests", @"CreationDate": [NSDate date], @"ExpirationDate": [NSDate dateWithTimeIntervalSinceNow:86400], @"Entitlements": values, @"ProvisionedDevices": @[@"TEST-WATCH"], @"Platform": platforms};
    [dictionary writeToURL:plist atomically:YES];
    check(command(@"/usr/bin/openssl", @[@"smime", @"-sign", @"-binary", @"-nodetach", @"-in", plist.path, @"-signer", [work URLByAppendingPathComponent:@"cert.pem"].path, @"-inkey", [work URLByAppendingPathComponent:@"key.pem"].path, @"-outform", @"DER", @"-out", cms.path]) == 0, @"encode synthetic profile");
    ALTProvisioningProfile *result = [[ALTProvisioningProfile alloc] initWithURL:cms];
    check(result != nil, @"production profile parser accepts synthetic CMS");
    return result;
}

static void sign(ALTApplication *application, NSArray *profiles)
{
    ALTCertificate *certificate = [[ALTCertificate alloc] initWithP12Data:[NSData dataWithContentsOfURL:[work URLByAppendingPathComponent:@"test.p12"]] password:@""];
    check(certificate != nil, @"load disposable signing identity");
    ALTTeam *team = [[ALTTeam alloc] initWithName:@"Tests" identifier:@"Z9NVYMZ644" type:ALTTeamTypeIndividual account:(id)[NSNull null]];
    ALTSigner *signer = [[ALTSigner alloc] initWithTeam:team certificate:certificate];
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block NSError *failure = nil;
    [signer signAppAtURL:application.fileURL provisioningProfiles:profiles completionHandler:^(BOOL success, NSError *error) {
        failure = success ? nil : error;
        dispatch_semaphore_signal(semaphore);
    }];
    check(dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, 30 * NSEC_PER_SEC)) == 0, @"signing finishes");
    check(failure == nil, [NSString stringWithFormat:@"production signer succeeds: %@", failure]);
    check(command(@"/usr/bin/codesign", @[@"--verify", @"--deep", @"--strict", application.fileURL.path]) == 0, @"nested signatures and resource seals verify");
}

int main(int argc, const char *argv[])
{
    @autoreleasepool
    {
        work = [NSURL fileURLWithPath:@(argv[1]) isDirectory:YES];
        NSString *phoneID = @"com.calebmech.Race";
        NSString *watchID = @"com.calebmech.Race.watchkitapp";
        NSString *newPhoneID = @"com.calebmech.Race.Z9NVYMZ644";
        NSString *newWatchID = [newPhoneID stringByAppendingString:@".watchkitapp"];
        ALTApplication *phone = app(@"Modern.app", phoneID, @{});
        ALTApplication *watch = app(@"Modern.app/Watch/RaceWatch.app", watchID, @{@"WKApplication": @YES, @"WKCompanionAppBundleIdentifier": phoneID, @"DTPlatformName": @"watchos", @"UIDeviceFamily": @[@4], @"NSHealthShareUsageDescription": @"Read workouts"});
        check(phone.appExtensions.count == 0, @"single-target Watch app is not an iOS extension slot");
        check(phone.nestedApplications.count == 1, @"discover modern single-target companion");
        check(watch.isWatchOSApplication, @"identify watchOS");
        check([info(watch.fileURL)[@"NSHealthShareUsageDescription"] isEqual:@"Read workouts"], @"Watch-only privacy description is accessible to permission review");
        NSDictionary *mapping = @{phoneID: newPhoneID, watchID: newWatchID};
        NSError *error = nil;
        check([phone remapBundleIdentifiers:mapping error:&error], @"remap modern companion");
        check([info(watch.fileURL)[@"WKCompanionAppBundleIdentifier"] isEqual:newPhoneID], @"exact team-suffixed companion regression");
        check([info(watch.fileURL)[@"CFBundleIdentifier"] isEqual:newWatchID], @"Watch ID retains resigned parent prefix");

        // Attach an entitlement only to the Watch binary, not the iPhone.
        NSURL *entitlements = [work URLByAppendingPathComponent:@"health.plist"];
        [@{@"com.apple.developer.healthkit": @YES, @"com.apple.developer.healthkit.access": @[]} writeToURL:entitlements atomically:YES];
        check(command(@"/usr/bin/codesign", @[@"-f", @"-s", @"-", @"--entitlements", entitlements.path, watch.fileURL.path]) == 0, @"seed Watch-only HealthKit entitlement");
        watch = [[ALTApplication alloc] initWithFileURL:watch.fileURL];
        ALTProvisioningProfile *watchProfile = profile(newWatchID, @[@"iOS"], @{@"com.apple.developer.healthkit": @YES, @"com.apple.developer.healthkit.access": @[]});
        check([watch validateWatchProvisioningProfile:watchProfile error:&error], @"iOS-family profile authorizes Watch HealthKit without a watchOS Platform entry");
        check(![watch validateWatchProvisioningProfile:profile(newWatchID, @[@"tvOS"], @{}) error:&error], @"reject profile from wrong app family");
        check(![watch validateWatchProvisioningProfile:profile(newWatchID, @[@"iOS", @"watchOS"], @{}) error:&error], @"reject silently stripped HealthKit");
        check([error.localizedFailureReason containsString:@"healthkit"], @"actionable capability error");
        check([ALTFeatureForEntitlement(ALTEntitlementHealthKit) isEqual:ALTFeatureHealthKit] && !ALTFeatureIsLegacy(ALTFeatureHealthKit), @"enable HealthKit using modern capability API");
        phone = [[ALTApplication alloc] initWithFileURL:phone.fileURL];
        sign(phone, @[profile(newPhoneID, @[@"iOS"], @{}), watchProfile]);
        watch = [[ALTApplication alloc] initWithFileURL:watch.fileURL];
        check([watch.entitlements[ALTEntitlementHealthKit] boolValue], @"signer preserves Watch HealthKit");
        check([watch.provisioningProfile.bundleIdentifier isEqual:newWatchID], @"signer embeds Watch-specific profile");
        check([watch.entitlements[ALTEntitlementApplicationIdentifier] isEqual:[@"Z9NVYMZ644." stringByAppendingString:newWatchID]], @"Watch receives its own application identifier entitlement");
        check(![phone.entitlements[ALTEntitlementHealthKit] boolValue], @"Watch entitlements do not leak into phone");

        for (NSNumber *firstGeneration in @[@NO, @YES])
        {
            NSString *root = firstGeneration.boolValue ? @"Legacy1.app" : @"Legacy2.app";
            ALTApplication *parent = app(root, @"com.example.Legacy", @{});
            NSString *extensionPath = [root stringByAppendingString:firstGeneration.boolValue ? @"/PlugIns/Watch.appex" : @"/Watch/Watch.app/PlugIns/Watch.appex"];
            NSString *watchPath = [root stringByAppendingString:firstGeneration.boolValue ? @"/PlugIns/Watch.appex/Watch.app" : @"/Watch/Watch.app"];
            app(watchPath, @"com.example.Legacy.watchkitapp", @{@"WKWatchKitApp": @YES, @"WKCompanionAppBundleIdentifier": @"com.example.Legacy"});
            app(extensionPath, @"com.example.Legacy.watchkitextension", @{@"DTPlatformName": firstGeneration.boolValue ? @"iphoneos" : @"watchos", @"NSExtension": @{@"NSExtensionPointIdentifier": @"com.apple.watchkit", @"NSExtensionAttributes": @{@"WKAppBundleIdentifier": @"com.example.Legacy.watchkitapp", @"Unrelated": @"keep"}}});
            NSDictionary *IDs = @{@"com.example.Legacy": @"com.random.TEAM", @"com.example.Legacy.watchkitapp": @"com.random.TEAM.watchkitapp", @"com.example.Legacy.watchkitextension": @"com.random.TEAM.watchkitextension"};
            check(parent.nestedApplications.count == 2, @"discover legacy Watch app and extension exactly once");
            check([parent remapBundleIdentifiers:IDs error:&error], @"remap legacy and randomized IDs");
            NSDictionary *attributes = info([work URLByAppendingPathComponent:extensionPath])[@"NSExtension"][@"NSExtensionAttributes"];
            check([attributes[@"WKAppBundleIdentifier"] isEqual:IDs[@"com.example.Legacy.watchkitapp"]], @"legacy extension references exact Watch ID");
            check([attributes[@"Unrelated"] isEqual:@"keep"], @"preserve unrelated extension attributes");
            parent = [[ALTApplication alloc] initWithFileURL:parent.fileURL];
            NSMutableArray *profiles = [NSMutableArray array];
            for (ALTApplication *item in [@[parent] arrayByAddingObjectsFromArray:parent.nestedApplications])
            {
                [profiles addObject:profile(item.bundleIdentifier, @[@"iOS", @"watchOS"], @{})];
            }
            sign(parent, profiles);
            for (ALTApplication *item in parent.nestedApplications)
            {
                check([item.provisioningProfile.bundleIdentifier isEqual:item.bundleIdentifier], @"legacy bundle gets matching embedded profile");
                check([item.entitlements[ALTEntitlementApplicationIdentifier] isEqual:[@"Z9NVYMZ644." stringByAppendingString:item.bundleIdentifier]], @"legacy executable gets its own entitlements");
            }
        }

        ALTApplication *ordinary = app(@"Ordinary.app", @"com.example.Ordinary", @{});
        app(@"Ordinary.app/PlugIns/Widget.appex", @"com.example.Ordinary.Widget", @{@"NSExtension": @{@"NSExtensionPointIdentifier": @"com.apple.widgetkit-extension"}});
        check(ordinary.appExtensions.count == 1 && ordinary.nestedApplications.count == 1, @"ordinary extension discovery unchanged");
        NSDictionary *IDs = @{@"com.example.Ordinary": @"com.example.Ordinary.TEAM", @"com.example.Ordinary.Widget": @"com.example.Ordinary.TEAM.Widget"};
        check([ordinary remapBundleIdentifiers:IDs error:&error], @"ordinary app and extension remapping");
        ordinary = [[ALTApplication alloc] initWithFileURL:ordinary.fileURL];
        check([ordinary validateWatchProvisioningProfile:profile(ordinary.bundleIdentifier, @[@"iOS"], @{}) error:&error], @"ordinary app does not require watchOS profile");
        sign(ordinary, @[profile(ordinary.bundleIdentifier, @[@"iOS"], @{}), profile(ordinary.nestedApplications.firstObject.bundleIdentifier, @[@"iOS"], @{})]);
        ALTApplication *broken = app(@"Broken.app", @"com.example.Broken", @{});
        app(@"Broken.app/Watch/Watch.app", @"com.example.Broken.watch", @{@"WKApplication": @YES, @"WKCompanionAppBundleIdentifier": @"com.example.Wrong"});
        check(![broken remapBundleIdentifiers:@{@"com.example.Broken": @"new", @"com.example.Broken.watch": @"new.watch"} error:&error], @"reject unmapped companion dependency");
        check([info(broken.fileURL)[@"CFBundleIdentifier"] isEqual:@"com.example.Broken"], @"invalid mapping does not partly rewrite plists");

        ALTApplication *domains = app(@"Domains.app", @"com.example.Domains", @{@"WKApplication": @YES});
        [@{@"com.apple.developer.associated-domains": @[@"applinks:example.com"]} writeToURL:entitlements atomically:YES];
        check(command(@"/usr/bin/codesign", @[@"-f", @"-s", @"-", @"--entitlements", entitlements.path, domains.fileURL.path]) == 0, @"seed associated domains entitlement");
        check([domains validateWatchProvisioningProfile:profile(domains.bundleIdentifier, @[@"iOS"], @{@"com.apple.developer.associated-domains": @[@"*"]}) error:&error], @"profile wildcard permits associated domains");
        check(![domains validateWatchProvisioningProfile:profile(domains.bundleIdentifier, @[@"iOS"], @{@"com.apple.developer.associated-domains": @[@"applinks:other.com"]}) error:&error], @"reject unauthorized entitlement array value");
        [@{@"com.apple.developer.healthkit": @YES, @"com.apple.developer.healthkit.access": @[]} writeToURL:entitlements atomically:YES];

        ALTApplication *plain = app(@"Plain.app", @"com.example.Plain", @{});
        check(plain.nestedApplications.count == 0 && plain.appExtensions.count == 0, @"plain iPhone app has no extra profiles");
        sign(plain, @[profile(plain.bundleIdentifier, @[@"iOS"], @{})]);

        if (argc > 2)
        {
            NSURL *copy = [work URLByAppendingPathComponent:@"RealFixture.app"];
            check([[NSFileManager defaultManager] copyItemAtURL:[NSURL fileURLWithPath:@(argv[2])] toURL:copy error:&error], @"copy read-only physical-device fixture");
            ALTApplication *fixture = [[ALTApplication alloc] initWithFileURL:copy];
            NSMutableDictionary *IDs = [NSMutableDictionary dictionary];
            NSString *original = fixture.bundleIdentifier;
            NSString *resigned = [original stringByAppendingString:@".Z9NVYMZ644"];
            NSArray *applications = [@[fixture] arrayByAddingObjectsFromArray:fixture.nestedApplications];
            for (ALTApplication *item in applications)
            {
                check([item.bundleIdentifier hasPrefix:original], @"fixture bundle hierarchy");
                IDs[item.bundleIdentifier] = [resigned stringByAppendingString:[item.bundleIdentifier substringFromIndex:original.length]];
                check(command(@"/usr/bin/codesign", @[@"-f", @"-s", @"-", @"--entitlements", entitlements.path, item.fileURL.path]) == 0, @"seed HealthKit in disposable fixture copy");
            }
            check([fixture remapBundleIdentifiers:IDs error:&error], @"remap real fixture");
            fixture = [[ALTApplication alloc] initWithFileURL:copy];
            NSMutableArray *profiles = [NSMutableArray array];
            for (ALTApplication *item in [@[fixture] arrayByAddingObjectsFromArray:fixture.nestedApplications])
            {
                [profiles addObject:profile(item.bundleIdentifier, @[@"iOS", @"watchOS"], @{@"com.apple.developer.healthkit": @YES, @"com.apple.developer.healthkit.access": @[]})];
            }
            sign(fixture, profiles);
            for (ALTApplication *item in fixture.nestedApplications)
            {
                if (!item.isWatchOSApplication) { continue; }
                check([info(item.fileURL)[@"WKCompanionAppBundleIdentifier"] isEqual:resigned], @"real fixture companion ID matches suffixed phone ID");
                check([item.entitlements[ALTEntitlementHealthKit] boolValue], @"real fixture retains HealthKit");
            }
        }
        NSLog(@"PASS: %ld assertions; modern, both legacy structures, HealthKit, ordinary extension, real nested signatures.", (long)assertions);
    }
    return 0;
}
