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
    ALTAppleAPIErrorUnknown,
    ALTAppleAPIErrorInvalidParameters,
    
    ALTAppleAPIErrorIncorrectCredentials,
    ALTAppleAPIErrorAppSpecificPasswordRequired,
    
    ALTAppleAPIErrorNoTeams,
    
    ALTAppleAPIErrorInvalidDeviceID,
    ALTAppleAPIErrorDeviceAlreadyRegistered,
    
    ALTAppleAPIErrorInvalidCertificateRequest,
    ALTAppleAPIErrorCertificateDoesNotExist,
    
    ALTAppleAPIErrorInvalidAppIDName,
    ALTAppleAPIErrorInvalidBundleIdentifier,
    ALTAppleAPIErrorBundleIdentifierUnavailable,
    ALTAppleAPIErrorAppIDDoesNotExist,
    ALTAppleAPIErrorMaximumAppIDLimitReached,
    
    ALTAppleAPIErrorInvalidAppGroup,
    ALTAppleAPIErrorAppGroupDoesNotExist,
    
    ALTAppleAPIErrorInvalidProvisioningProfileIdentifier,
    ALTAppleAPIErrorProvisioningProfileDoesNotExist,
    
    ALTAppleAPIErrorRequiresTwoFactorAuthentication,
    ALTAppleAPIErrorIncorrectVerificationCode,
    ALTAppleAPIErrorAuthenticationHandshakeFailed,
    
    ALTAppleAPIErrorInvalidAnisetteData,
};

NS_ASSUME_NONNULL_BEGIN

@interface NSError (ALTError)

@end

NS_ASSUME_NONNULL_END
