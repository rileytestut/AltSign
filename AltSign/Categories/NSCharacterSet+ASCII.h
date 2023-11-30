//
//  NSCharacterSet+ASCII.h
//  AltSign
//
//  Created by Riley Testut on 11/30/23.
//  Copyright © 2023 Riley Testut. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSCharacterSet (Ascii)

@property(readonly, class, copy) NSCharacterSet *asciiAlphanumericCharacterSet;

@end

NS_ASSUME_NONNULL_END
