//
//  NSError+ALTError.h
//  AltSign
//
//  Created by Riley Testut on 5/10/19.
//  Copyright © 2019 Riley Testut. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSErrorDomain const AltSignErrorDomain;

typedef NS_ERROR_ENUM(AltSignErrorDomain, ALTError)
{
    ALTErrorUnknown = -1,
    ALTErrorInvalidResponse = -23,
    ALTErrorInvalidParameters = -24,
    
    ALTErrorMissingAppBundle = -100,
    ALTErrorMissingInfoPlist = -101,
};

NS_ASSUME_NONNULL_BEGIN

@interface NSError (ALTError)

@end

NS_ASSUME_NONNULL_END
