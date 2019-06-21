//
//  NSError+ALTErrors.h
//  AltSign
//
//  Created by Riley Testut on 5/10/19.
//  Copyright © 2019 Riley Testut. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSErrorDomain const AltSignErrorDomain;
typedef NS_ERROR_ENUM(AltSignErrorDomain, ALTError)
{
    ALTErrorUnknown,
    ALTErrorMissingAppBundle,
    ALTErrorMissingInfoPlist,
};

extern NSErrorDomain const ALTAppleAPIErrorDomain;
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
    
    ALTAppleAPIErrorInvalidProvisioningProfileIdentifier,
    ALTAppleAPIErrorProvisioningProfileDoesNotExist,
};

NS_ASSUME_NONNULL_BEGIN

@interface NSError (ALTError)

@end

NS_ASSUME_NONNULL_END
