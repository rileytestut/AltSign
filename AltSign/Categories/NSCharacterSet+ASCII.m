//
//  NSCharacterSet+ASCII.m
//  AltSign
//
//  Created by Riley Testut on 11/30/23.
//  Copyright © 2023 Riley Testut. All rights reserved.
//

#import "NSCharacterSet+ASCII.h"

@implementation NSCharacterSet (Ascii)

+ (NSCharacterSet *)asciiAlphanumericCharacterSet
{
    // alphanumericCharacterSet includes characters from non-English languages, which are not supported by Apple's servers.
    NSCharacterSet *characterSet = [NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"];
    return characterSet;
}

@end
