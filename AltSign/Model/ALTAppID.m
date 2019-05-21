//
//  ALTAppID.m
//  AltSign
//
//  Created by Riley Testut on 5/21/19.
//  Copyright © 2019 Riley Testut. All rights reserved.
//

#import "ALTAppID.h"

@implementation ALTAppID

- (nullable instancetype)initWithResponseDictionary:(NSDictionary *)responseDictionary
{
    self = [super init];
    if (self)
    {
        NSString *name = responseDictionary[@"name"];
        NSString *identifier = responseDictionary[@"appIdId"];
        NSString *bundleIdentifier = responseDictionary[@"identifier"];
        
        if (name == nil || identifier == nil || bundleIdentifier == nil)
        {
            return nil;
        }
        
        _name = [name copy];
        _identifier = [identifier copy];
        _bundleIdentifier = [bundleIdentifier copy];
    }
    
    return self;
}

#pragma mark - NSObject -

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p, Name: %@, ID: %@, BundleID: %@>", NSStringFromClass([self class]), self, self.name, self.identifier, self.bundleIdentifier];
}

- (BOOL)isEqual:(id)object
{
    ALTAppID *appID = (ALTAppID *)object;
    if (![appID isKindOfClass:[ALTAppID class]])
    {
        return NO;
    }
    
    BOOL isEqual = (self.identifier == appID.identifier && self.bundleIdentifier == appID.bundleIdentifier);
    return isEqual;
}

- (NSUInteger)hash
{
    return self.identifier.hash ^ self.bundleIdentifier.hash;
}

@end
