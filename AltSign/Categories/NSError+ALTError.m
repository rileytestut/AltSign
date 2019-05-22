//
//  NSError+ALTError.m
//  AltSign
//
//  Created by Riley Testut on 5/10/19.
//  Copyright © 2019 Riley Testut. All rights reserved.
//

#import "NSError+ALTError.h"

NSErrorDomain const AltSignErrorDomain = @"com.rileytestut.AltSign";

@implementation NSError (ALTError)

+ (void)load
{
    [NSError setUserInfoValueProviderForDomain:AltSignErrorDomain provider:^id _Nullable(NSError * _Nonnull error, NSErrorUserInfoKey  _Nonnull userInfoKey) {
        if ([userInfoKey isEqualToString:NSLocalizedFailureReasonErrorKey])
        {
            return [error alt_localizedFailureReason];
        }
        
        return nil;
    }];
}

- (nullable NSString *)alt_localizedFailureReason
{
    switch (self.code)
    {
        case ALTErrorUnknown:
            return NSLocalizedString(@"An unknown error occured.", "");
            
        case ALTErrorInvalidResponse:
            return NSLocalizedString(@"The server returned an invalid response.", @"");
        
        case ALTErrorInvalidParameters:
            return NSLocalizedString(@"The provided parameters are invalid.", "");
    }
    
    return nil;
}

@end
