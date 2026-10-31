//
//  ALTApplication.m
//  AltSign
//
//  Created by Riley Testut on 6/24/19.
//  Copyright © 2019 Riley Testut. All rights reserved.
//

#import "ALTApplication.h"
#import "ALTProvisioningProfile.h"
#import "NSError+ALTErrors.h"

#include "alt_ldid.hpp"

ALTDeviceType ALTDeviceTypeFromUIDeviceFamily(NSInteger deviceFamily)
{
    switch (deviceFamily)
    {
        case 1: return ALTDeviceTypeiPhone;
        case 2: return ALTDeviceTypeiPad;
        case 3: return ALTDeviceTypeAppleTV;
        default: return ALTDeviceTypeNone;
    }
}

// Provisioning arrays can authorize a wildcard (for example associated domains).
static BOOL ALTWatchEntitlementValueIsAllowed(id required, id allowed)
{
    if (allowed == nil) { return NO; }
    if ([required isKindOfClass:NSArray.class])
    {
        if (![allowed isKindOfClass:NSArray.class]) { return NO; }
        for (id value in required)
        {
            BOOL found = NO;
            for (id permitted in allowed)
            {
                if (ALTWatchEntitlementValueIsAllowed(value, permitted)) { found = YES; break; }
            }
            if (!found) { return NO; }
        }
        return YES;
    }
    if ([required isKindOfClass:NSString.class] && [allowed isKindOfClass:NSString.class] && [allowed hasSuffix:@"*"])
    {
        return [allowed length] == 1 || [required hasPrefix:[allowed substringToIndex:[allowed length] - 1]];
    }
    return [required isEqual:allowed];
}

@interface ALTApplication ()

@property (nonatomic, copy, nullable, readonly) NSString *iconName;

@end

@implementation ALTApplication
@synthesize entitlements = _entitlements;
@synthesize entitlementsString = _entitlementsString;
@synthesize provisioningProfile = _provisioningProfile;

- (instancetype)initWithFileURL:(NSURL *)fileURL
{
    self = [super init];
    if (self)
    {
        NSBundle *bundle = [NSBundle bundleWithURL:fileURL];
        if (bundle == nil)
        {
            return nil;
        }
        
        // Load info dictionary directly from disk, since NSBundle caches values
        // that might not reflect the updated values on disk (such as bundle identifier).
        NSURL *infoPlistURL = [bundle.bundleURL URLByAppendingPathComponent:@"Info.plist"];
        NSDictionary *infoDictionary = [NSDictionary dictionaryWithContentsOfURL:infoPlistURL];
        if (infoDictionary == nil)
        {
            return nil;
        }
        
        NSString *name = infoDictionary[@"CFBundleDisplayName"] ?: infoDictionary[(NSString *)kCFBundleNameKey];
        NSString *bundleIdentifier = infoDictionary[(NSString *)kCFBundleIdentifierKey];
                
        if (name == nil || bundleIdentifier == nil)
        {
            return nil;
        }
        
        // These technically can be nil, but in practice every app should have a version and build version.
        NSString *version = infoDictionary[@"CFBundleShortVersionString"] ?: @"1.0";
        NSString *buildVersion = infoDictionary[(NSString *)kCFBundleVersionKey] ?: @"1";
        
        NSString *minimumVersionString = infoDictionary[@"MinimumOSVersion"] ?: @"1.0";
        NSArray *versionComponents = [minimumVersionString componentsSeparatedByString:@"."];
        
        NSInteger majorVersion = [versionComponents.firstObject integerValue];
        NSInteger minorVersion = (versionComponents.count > 1) ? [versionComponents[1] integerValue] : 0;
        NSInteger patchVersion = (versionComponents.count > 2) ? [versionComponents[2] integerValue] : 0;
        
        NSOperatingSystemVersion minimumVersion;
        minimumVersion.majorVersion = majorVersion;
        minimumVersion.minorVersion = minorVersion;
        minimumVersion.patchVersion = patchVersion;
        
        NSArray<NSNumber *> *deviceFamilies = infoDictionary[@"UIDeviceFamily"];
        ALTDeviceType supportedDeviceTypes = ALTDeviceTypeNone;
        
        if ([deviceFamilies isKindOfClass:[NSNumber class]])
        {
            NSInteger rawDeviceFamily = [(NSNumber *)deviceFamilies integerValue];
            supportedDeviceTypes = ALTDeviceTypeFromUIDeviceFamily(rawDeviceFamily);
        }
        else if ([deviceFamilies isKindOfClass:[NSArray class]] && deviceFamilies.count > 0)
        {
            for (NSNumber *deviceFamily in deviceFamilies)
            {
                NSInteger rawDeviceFamily = [deviceFamily integerValue];
                supportedDeviceTypes |= ALTDeviceTypeFromUIDeviceFamily(rawDeviceFamily);
            }
        }
        else
        {
            supportedDeviceTypes = ALTDeviceTypeiPhone;
        }
        
        NSDictionary *icons = infoDictionary[@"CFBundleIcons"];
        NSDictionary *primaryIcon = icons[@"CFBundlePrimaryIcon"];
        
        NSString *iconName = nil;
        
        if ([primaryIcon isKindOfClass:[NSString class]])
        {
            iconName = (NSString *)primaryIcon;
        }
        else
        {
            NSArray *iconFiles = primaryIcon[@"CFBundleIconFiles"];
            if (iconFiles == nil)
            {
                iconFiles = infoDictionary[@"CFBundleIconFiles"];
            }
            
            iconName = [iconFiles lastObject];
            if (iconName == nil)
            {
                iconName = infoDictionary[@"CFBundleIconFile"];
            }
        }
        
        _bundle = bundle;
        _fileURL = [fileURL copy];
        _name = [name copy];
        _bundleIdentifier = [bundleIdentifier copy];
        _version = [version copy];
        _buildVersion = [buildVersion copy];
        _minimumiOSVersion = minimumVersion;
        _supportedDeviceTypes = supportedDeviceTypes;
        _iconName = [iconName copy];
    }
    
    return self;
}

#if TARGET_OS_IPHONE
- (UIImage *)icon
{
    NSString *iconName = self.iconName;
    if (iconName == nil)
    {
        return nil;
    }
    
    UIImage *icon = [UIImage imageNamed:iconName inBundle:self.bundle compatibleWithTraitCollection:nil];
    return icon;
}
#endif

- (NSDictionary<ALTEntitlement,id> *)entitlements
{
    if (_entitlements == nil)
    {
        NSDictionary<NSString *, id> *appEntitlements = @{};
        
        if (self.entitlementsString.length != 0)
        {
            NSData *entitlementsData = [self.entitlementsString dataUsingEncoding:NSUTF8StringEncoding];
            
            NSError *error = nil;
            NSDictionary *entitlements = [NSPropertyListSerialization propertyListWithData:entitlementsData options:0 format:nil error:&error];
            
            if (entitlements != nil)
            {
                appEntitlements = entitlements;
            }
            else
            {
                NSLog(@"Error parsing entitlements: %@", error);
            }
        }
        
        _entitlements = appEntitlements;
    }
    
    return _entitlements;
}

- (NSString *)entitlementsString
{
    if (_entitlementsString == nil)
    {
        NSString *path = [self.fileURL.path.stringByStandardizingPath stringByAppendingString:@"/"];
        
        std::string rawEntitlements = ldid::Entitlements(path.fileSystemRepresentation);
        _entitlementsString = @(rawEntitlements.c_str());
    }
    
    return _entitlementsString;
}

- (ALTProvisioningProfile *)provisioningProfile
{
    if (_provisioningProfile == nil)
    {
        NSURL *provisioningProfileURL = [self.fileURL URLByAppendingPathComponent:@"embedded.mobileprovision"];
        _provisioningProfile = [[ALTProvisioningProfile alloc] initWithURL:provisioningProfileURL];
    }
    
    return _provisioningProfile;
}

- (NSSet<ALTApplication *> *)appExtensions
{
    NSMutableSet *appExtensions = [NSMutableSet set];
    
    NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtURL:self.bundle.builtInPlugInsURL includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsSubdirectoryDescendants errorHandler:nil];
    for (NSURL *fileURL in enumerator)
    {
        if (![fileURL.pathExtension.lowercaseString isEqualToString:@"appex"])
        {
            continue;
        }
        
        ALTApplication *appExtension = [[ALTApplication alloc] initWithFileURL:fileURL];
        if (appExtension == nil)
        {
            continue;
        }
        
        [appExtensions addObject:appExtension];
    }
    
    return appExtensions;
}

- (NSArray<ALTApplication *> *)nestedApplications
{
    NSMutableArray<ALTApplication *> *children = [NSMutableArray arrayWithArray:self.appExtensions.allObjects];
    NSMutableArray<NSURL *> *directories = [NSMutableArray arrayWithObject:[self.fileURL URLByAppendingPathComponent:@"Watch"]];
    if ([self.fileURL.pathExtension.lowercaseString isEqualToString:@"appex"])
    {
        // watchOS 1 packaged the Watch app inside the iOS WatchKit extension.
        [directories addObject:self.fileURL];
    }

    for (NSURL *directory in directories)
    {
        NSArray<NSURL *> *URLs = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:directory includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles error:nil];
        for (NSURL *URL in URLs)
        {
            if (![URL.pathExtension.lowercaseString isEqualToString:@"app"]) { continue; }
            ALTApplication *app = [[ALTApplication alloc] initWithFileURL:URL];
            if (app != nil) { [children addObject:app]; }
        }
    }

    [children sortUsingComparator:^NSComparisonResult(ALTApplication *a, ALTApplication *b) {
        return [a.fileURL.path compare:b.fileURL.path];
    }];
    NSMutableArray<ALTApplication *> *applications = [NSMutableArray array];
    for (ALTApplication *child in children)
    {
        [applications addObject:child];
        [applications addObjectsFromArray:child.nestedApplications];
    }
    return applications;
}

- (BOOL)isWatchOSApplication
{
    NSDictionary *info = [NSDictionary dictionaryWithContentsOfURL:[self.fileURL URLByAppendingPathComponent:@"Info.plist"]];
    return [info[@"DTPlatformName"] isEqual:@"watchos"] ||
        [info[@"CFBundleSupportedPlatforms"] containsObject:@"WatchOS"] ||
        [info[@"WKApplication"] boolValue] || [info[@"WKWatchKitApp"] boolValue];
}

- (BOOL)remapBundleIdentifiers:(NSDictionary<NSString *,NSString *> *)identifiers error:(NSError **)error
{
    NSArray<ALTApplication *> *applications = [@[self] arrayByAddingObjectsFromArray:self.nestedApplications];
    NSMutableDictionary<NSURL *, NSDictionary *> *updates = [NSMutableDictionary dictionary];
    for (ALTApplication *app in applications)
    {
        NSURL *URL = [app.fileURL URLByAppendingPathComponent:@"Info.plist"];
        NSMutableDictionary *info = [[NSDictionary dictionaryWithContentsOfURL:URL] mutableCopy];
        NSString *identifier = identifiers[app.bundleIdentifier];
        if (info == nil || identifier == nil)
        {
            if (error) { *error = [NSError errorWithDomain:AltSignErrorDomain code:ALTErrorInvalidApp userInfo:nil]; }
            return NO;
        }
        info[@"CFBundleIdentifier"] = identifier;
        for (NSString *key in @[@"WKCompanionAppBundleIdentifier", @"WKAppBundleIdentifier"])
        {
            NSString *original = info[key];
            if (original == nil) { continue; }
            if (identifiers[original] == nil)
            {
                if (error) { *error = [NSError errorWithDomain:AltSignErrorDomain code:ALTErrorInvalidApp userInfo:@{NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:@"No bundle identifier mapping for %@ (%@).", original, key]}]; }
                return NO;
            }
            info[key] = identifiers[original];
        }
        NSMutableDictionary *extension = [info[@"NSExtension"] mutableCopy];
        NSMutableDictionary *attributes = [extension[@"NSExtensionAttributes"] mutableCopy];
        NSString *watchIdentifier = attributes[@"WKAppBundleIdentifier"];
        if (watchIdentifier != nil)
        {
            if (identifiers[watchIdentifier] == nil)
            {
                if (error) { *error = [NSError errorWithDomain:AltSignErrorDomain code:ALTErrorInvalidApp userInfo:nil]; }
                return NO;
            }
            attributes[@"WKAppBundleIdentifier"] = identifiers[watchIdentifier];
            extension[@"NSExtensionAttributes"] = attributes;
            info[@"NSExtension"] = extension;
        }
        updates[URL] = info;
    }
    // Validate the entire mapping before writing any plists.
    for (NSURL *URL in updates)
    {
        if (![updates[URL] writeToURL:URL error:error]) { return NO; }
    }
    return YES;
}

- (BOOL)validateWatchProvisioningProfile:(ALTProvisioningProfile *)profile error:(NSError **)error
{
    if (!self.isWatchOSApplication) { return YES; }
    NSString *reason = nil;
    // Embedded companions use the iOS provisioning family. Valid profiles may
    // list only iOS (plus other iOS-family platforms), without a watchOS entry.
    if (![profile.platforms containsObject:@"iOS"] && ![profile.platforms containsObject:@"watchOS"])
    {
        reason = @"The provisioning profile does not support the iOS/watchOS app family.";
    }
    else
    {
        // Do not silently remove Watch capabilities when the account/profile cannot grant them.
        // Identity and app groups are remapped separately by the signer/provisioning caller.
        for (NSString *key in self.entitlements)
        {
            if (![key hasPrefix:@"com.apple.developer."] || [key isEqual:ALTEntitlementTeamIdentifier]) { continue; }
            id required = self.entitlements[key];
            id allowed = profile.entitlements[key];
            if ([required isKindOfClass:NSNumber.class] && ![required boolValue]) { continue; }
            if ([required respondsToSelector:@selector(count)] && [required count] == 0) { continue; }
            BOOL supported = ALTWatchEntitlementValueIsAllowed(required, allowed);
            if (!supported)
            {
                reason = [NSString stringWithFormat:@"The provisioning profile does not authorize the Watch entitlement %@. Your Apple developer account must support this capability.", key];
                break;
            }
        }
    }
    if (reason == nil) { return YES; }
    if (error)
    {
        *error = [NSError errorWithDomain:AltSignErrorDomain code:ALTErrorMissingProvisioningProfile userInfo:@{NSLocalizedFailureReasonErrorKey: reason, ALTAppNameErrorKey: self.name}];
    }
    return NO;
}

@end
