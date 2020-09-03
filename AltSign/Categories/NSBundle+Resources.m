//
//  NSBundle+Resources.m
//  AltSign
//
//  Created by Riley Testut on 9/2/20.
//  Copyright © 2020 Riley Testut. All rights reserved.
//

#import "NSBundle+Resources.h"

#import <Foundation/Foundation.h>

@implementation NSBundle (Resources)

+ (NSBundle *)resourcesBundle
{
#if SWIFT_PACKAGE
    return SWIFTPM_MODULE_BUNDLE;
#else
    return [NSBundle bundleForClass:[ALTAppleAPI class]];
#endif
}

@end
