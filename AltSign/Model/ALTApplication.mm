//
//  ALTApplication.m
//  AltSign
//
//  Created by Riley Testut on 6/24/19.
//  Copyright © 2019 Riley Testut. All rights reserved.
//

#import "ALTApplication.h"

#include "ldid.hpp"

@implementation ALTApplication

- (instancetype)initWithFileURL:(NSURL *)fileURL
{
    self = [super init];
    if (self)
    {
        NSBundle *bundle = [NSBundle bundleWithURL:fileURL];
        if (bundle == nil)
        {
            return nil;
        }
        
        NSString *name = [bundle objectForInfoDictionaryKey:@"CFBundleName"];
        NSString *bundleIdentifier = bundle.bundleIdentifier;
        
        if (name == nil || bundleIdentifier == nil)
        {
            return nil;
        }
        
        NSDictionary<NSString *, id> *appEntitlements = @{};
        
        std::string rawEntitlements = ldid::Entitlements(fileURL.fileSystemRepresentation);
        if (rawEntitlements.size() != 0)
        {
            NSData *entitlementsData = [NSData dataWithBytes:rawEntitlements.c_str() length:rawEntitlements.size()];
            
            NSError *error = nil;
            NSDictionary *entitlements = [NSPropertyListSerialization propertyListWithData:entitlementsData options:0 format:nil error:&error];
            
            if (entitlements != nil)
            {
                appEntitlements = entitlements;
            }
            else
            {
                NSLog(@"Error parsing entitlements: %@", error);
            }
        }
        
        _fileURL = [fileURL copy];
        _name = [name copy];
        _bundleIdentifier = [bundleIdentifier copy];
        _entitlements = [appEntitlements copy];
    }
    
    return self;
}

@end
