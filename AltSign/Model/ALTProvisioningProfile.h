//
//  ALTProvisioningProfile.h
//  AltSign
//
//  Created by Riley Testut on 5/22/19.
//  Copyright © 2019 Riley Testut. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ALTAppID;
@class ALTCertificate;

NS_ASSUME_NONNULL_BEGIN

typedef NSString *ALTEntitlement NS_TYPED_EXTENSIBLE_ENUM;
extern ALTEntitlement const ALTEntitlementApplicationIdentifier;
extern ALTEntitlement const ALTEntitlementKeychainAccessGroups;
extern ALTEntitlement const ALTEntitlementGetTaskAllow;
extern ALTEntitlement const ALTEntitlementTeamIdentifier;
extern ALTEntitlement const ALTEntitlementInterAppAudio;

@interface ALTProvisioningProfile : NSObject

@property (copy, nonatomic, readonly) NSString *name;
@property (copy, nonatomic, readonly) NSString *identifier;

@property (copy, nonatomic, readonly) NSString *bundleIdentifier;
@property (copy, nonatomic, readonly) NSString *teamIdentifier;

@property (copy, nonatomic, readonly) NSDate *creationDate;
@property (copy, nonatomic, readonly) NSDate *expirationDate;

@property (copy, nonatomic, readonly) NSDictionary<ALTEntitlement, id> *entitlements;
@property (copy, nonatomic, readonly) NSArray<ALTCertificate *> *certificates;
@property (copy, nonatomic, readonly) NSArray<NSString *> *deviceIDs;

@property (copy, nonatomic, readonly) NSData *data;

- (nullable instancetype)initWithData:(NSData *)data NS_DESIGNATED_INITIALIZER;
- (nullable instancetype)initWithURL:(NSURL *)fileURL;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
