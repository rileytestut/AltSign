//
//  NSError+ALTErrors.h
//  AltSign
//
//  Created by Riley Testut on 5/10/19.
//  Copyright © 2019 Riley Testut. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSErrorDomain const AltSignErrorDomain;
extern NSErrorDomain const ALTAppleAPIErrorDomain;
extern NSErrorDomain const ALTUnderlyingAppleAPIErrorDomain;

extern NSErrorUserInfoKey const ALTSourceFileErrorKey;
extern NSErrorUserInfoKey const ALTSourceLineErrorKey;
extern NSErrorUserInfoKey const ALTAppNameErrorKey;

typedef NS_ERROR_ENUM(AltSignErrorDomain, ALTError)
{
    ALTErrorUnknown,
    ALTErrorInvalidApp,
    ALTErrorMissingAppBundle,
    ALTErrorMissingInfoPlist,
    ALTErrorMissingProvisioningProfile,
};

typedef NS_ERROR_ENUM(ALTAppleAPIErrorDomain, ALTAppleAPIError)
{
    ALTAppleAPIErrorUnknown = 3000,
    ALTAppleAPIErrorInvalidParameters = 3001,
    
    ALTAppleAPIErrorIncorrectCredentials = 3002,
    ALTAppleAPIErrorAppSpecificPasswordRequired = 3003,
    
    ALTAppleAPIErrorNoTeams = 3004,
    
    ALTAppleAPIErrorInvalidDeviceID = 3005,
    ALTAppleAPIErrorDeviceAlreadyRegistered = 3006,
    
    ALTAppleAPIErrorInvalidCertificateRequest = 3007,
    ALTAppleAPIErrorCertificateDoesNotExist = 3008,
    
    ALTAppleAPIErrorInvalidAppIDName = 3009,
    ALTAppleAPIErrorInvalidBundleIdentifier = 3010,
    ALTAppleAPIErrorBundleIdentifierUnavailable = 3011,
    ALTAppleAPIErrorAppIDDoesNotExist = 3012,
    ALTAppleAPIErrorMaximumAppIDLimitReached = 3013,
    
    ALTAppleAPIErrorInvalidAppGroup = 3014,
    ALTAppleAPIErrorAppGroupDoesNotExist = 3015,
    
    ALTAppleAPIErrorInvalidProvisioningProfileIdentifier = 3016,
    ALTAppleAPIErrorProvisioningProfileDoesNotExist = 3017,
    
    ALTAppleAPIErrorRequiresTwoFactorAuthentication = 3018,
    ALTAppleAPIErrorIncorrectVerificationCode = 3019,
    ALTAppleAPIErrorAuthenticationHandshakeFailed = 3020,
    
    ALTAppleAPIErrorInvalidAnisetteData = 3021,
};

NS_ASSUME_NONNULL_BEGIN

@interface NSError (ALTError)

@end

NS_ASSUME_NONNULL_END
