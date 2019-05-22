//
//  ALTSign.h
//  AltSign
//
//  Created by Riley Testut on 5/10/19.
//  Copyright © 2019 Riley Testut. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <AltSign/ALTAccount.h>
#import <AltSign/ALTTeam.h>
#import <AltSign/ALTDevice.h>
#import <AltSign/ALTCertificate.h>
#import <AltSign/ALTAppID.h>
#import <AltSign/ALTProvisioningProfile.h>

#import <AltSign/NSError+ALTError.h>

//! Project version number for AltSign.
FOUNDATION_EXPORT double AltSignVersionNumber;

//! Project version string for AltSign.
FOUNDATION_EXPORT const unsigned char AltSignVersionString[];

NS_ASSUME_NONNULL_BEGIN

@interface ALTSign : NSObject

@property (class, nonatomic, readonly) ALTSign *shared;

/* Authentication */
- (void)authenticateWithAppleID:(NSString *)appleID password:(NSString *)password
              completionHandler:(void (^)(ALTAccount *_Nullable account, NSError *_Nullable error))completionHandler NS_SWIFT_NAME(authenticate(appleID:password:completionHandler:));

/* Teams */
- (void)fetchTeamsForAccount:(ALTAccount *)account
           completionHandler:(void (^)(NSArray<ALTTeam *> *_Nullable teams, NSError *_Nullable error))completionHandler;

/* Devices */
- (void)fetchDevicesForTeam:(ALTTeam *)team
          completionHandler:(void (^)(NSArray<ALTDevice *> *_Nullable devices, NSError *_Nullable error))completionHandler;

- (void)registerDeviceWithName:(NSString *)name identifier:(NSString *)identifier team:(ALTTeam *)team
             completionHandler:(void (^)(ALTDevice *_Nullable device, NSError *_Nullable error))completionHandler NS_SWIFT_NAME(registerDevice(name:identifier:team:completionHandler:));

/* Certificates */
- (void)fetchCertificatesForTeam:(ALTTeam *)team
               completionHandler:(void (^)(NSArray<ALTCertificate *> *_Nullable certificates, NSError *_Nullable error))completionHandler;

- (void)addCertificateWithMachineName:(NSString *)name toTeam:(ALTTeam *)team
                    completionHandler:(void (^)(ALTCertificate *_Nullable certificate, NSError *_Nullable error))completionHandler
                NS_SWIFT_NAME(addCertificate(machineName:to:completionHandler:));

- (void)revokeCertificate:(ALTCertificate *)certificate forTeam:(ALTTeam *)team
        completionHandler:(void (^)(BOOL success, NSError *_Nullable error))completionHandler
                NS_SWIFT_NAME(revoke(_:for:completionHandler:));

/* App IDs */
- (void)fetchAppIDsForTeam:(ALTTeam *)team
         completionHandler:(void (^)(NSArray<ALTAppID *> *_Nullable appIDs, NSError *_Nullable error))completionHandler;

- (void)addAppIDWithName:(NSString *)name bundleIdentifier:(NSString *)bundleIdentifier team:(ALTTeam *)team
       completionHandler:(void (^)(ALTAppID *_Nullable appID, NSError *_Nullable error))completionHandler;

- (void)deleteAppID:(ALTAppID *)appID forTeam:(ALTTeam *)team
  completionHandler:(void (^)(BOOL success, NSError *_Nullable error))completionHandler;

/* Provisioning Profiles */
- (void)fetchProvisioningProfileForAppID:(ALTAppID *)appID team:(ALTTeam *)team
                       completionHandler:(void (^)(ALTProvisioningProfile *_Nullable provisioningProfile, NSError *_Nullable error))completionHandler;

@end

NS_ASSUME_NONNULL_END
