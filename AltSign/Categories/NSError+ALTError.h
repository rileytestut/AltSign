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
    ALTErrorInvalidResponse = -23,
};

NS_ASSUME_NONNULL_BEGIN

@interface NSError (ALTError)

@end

NS_ASSUME_NONNULL_END
