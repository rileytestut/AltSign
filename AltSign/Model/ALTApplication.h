//
//  ALTApplication.h
//  AltSign
//
//  Created by Riley Testut on 6/24/19.
//  Copyright © 2019 Riley Testut. All rights reserved.
//

#import <Foundation/Foundation.h>

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif

#import "ALTCapabilities.h"
#import "ALTDevice.h"

@class ALTProvisioningProfile;

NS_ASSUME_NONNULL_BEGIN

@interface ALTApplication : NSObject

@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, copy, readonly) NSString *bundleIdentifier;
@property (nonatomic, copy, readonly) NSString *version;
@property (nonatomic, copy, readonly) NSString *buildVersion;

#if TARGET_OS_IPHONE
@property (nonatomic, readonly, nullable) UIImage *icon;
#endif

@property (nonatomic, readonly, nullable) ALTProvisioningProfile *provisioningProfile;
// Immediate PlugIns/*.appex only, retained for callers that count iOS extension slots.
@property (nonatomic, readonly) NSSet<ALTApplication *> *appExtensions;

// All embedded apps and extensions, recursively, excluding self. Includes Watch/*.app
// and the Watch app inside a first-generation WatchKit extension.
@property (nonatomic, readonly) NSArray<ALTApplication *> *nestedApplications;
@property (nonatomic, readonly) BOOL isWatchOSApplication;

// Uses exact identifiers, including WatchKit dependency keys. Does not change entitlements.
- (BOOL)remapBundleIdentifiers:(NSDictionary<NSString *, NSString *> *)identifiers error:(NSError **)error;
- (BOOL)validateWatchProvisioningProfile:(ALTProvisioningProfile *)profile error:(NSError **)error;

@property (nonatomic, readonly) NSOperatingSystemVersion minimumiOSVersion;
@property (nonatomic, readonly) ALTDeviceType supportedDeviceTypes;

@property (nonatomic, copy, readonly) NSDictionary<ALTEntitlement, id> *entitlements;
@property (nonatomic, copy, readonly) NSString *entitlementsString;

@property (nonatomic, copy, readonly) NSURL *fileURL;
@property (nonatomic, readonly) NSBundle *bundle;

@property (nonatomic, assign) BOOL hasPrivateEntitlements;

- (nullable instancetype)initWithFileURL:(NSURL *)fileURL;

@end

NS_ASSUME_NONNULL_END
