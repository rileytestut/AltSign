//
//  ALTModel+Internal.h
//  AltSign
//
//  Created by Riley Testut on 5/28/19.
//  Copyright © 2019 Riley Testut. All rights reserved.
//

#import <AltSign/ALTAccount.h>
#import <AltSign/ALTTeam.h>
#import <AltSign/ALTDevice.h>
#import <AltSign/ALTCertificate.h>
#import <AltSign/ALTCertificateRequest.h>
#import <AltSign/ALTAppID.h>
#import <AltSign/ALTAppGroup.h>
#import <AltSign/ALTProvisioningProfile.h>

NS_ASSUME_NONNULL_BEGIN

@interface ALTAccount ()
- (nullable instancetype)initWithResponseDictionary:(NSDictionary *)responseDictionary;
@end

@interface ALTTeam ()
- (nullable instancetype)initWithAccount:(ALTAccount *)account responseDictionary:(NSDictionary *)responseDictionary;
@end

@interface ALTDevice ()
- (nullable instancetype)initWithResponseDictionary:(NSDictionary *)responseDictionary;
@end

@interface ALTCertificate ()
- (instancetype)initWithName:(NSString *)name serialNumber:(NSString *)serialNumber data:(nullable NSData *)data NS_DESIGNATED_INITIALIZER;
- (nullable instancetype)initWithResponseDictionary:(NSDictionary *)responseDictionary;
@end

@interface ALTAppID ()
- (nullable instancetype)initWithResponseDictionary:(NSDictionary *)responseDictionary;
@end

@interface ALTAppGroup ()
- (nullable instancetype)initWithResponseDictionary:(NSDictionary *)responseDictionary;
@end

@interface ALTProvisioningProfile ()
- (nullable instancetype)initWithResponseDictionary:(NSDictionary *)responseDictionary;
@end

NS_ASSUME_NONNULL_END
