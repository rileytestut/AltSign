//
//  ALTProvisioningProfile.m
//  AltSign
//
//  Created by Riley Testut on 5/22/19.
//  Copyright © 2019 Riley Testut. All rights reserved.
//

#import "ALTProvisioningProfile.h"

@implementation ALTProvisioningProfile

- (nullable instancetype)initWithResponseDictionary:(NSDictionary *)responseDictionary
{
    self = [super init];
    if (self)
    {
        NSString *name = responseDictionary[@"name"];
        NSString *identifier = responseDictionary[@"UUID"];
        NSData *data = responseDictionary[@"encodedProfile"];
        
        if (name == nil || identifier == nil || data == nil)
        {
            return nil;
        }
        
        _name = [name copy];
        _identifier = [identifier copy];
        _data = [data copy];
    }
    
    return self;
}

#pragma mark - NSObject -

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p, Name: %@, UUID: %@>", NSStringFromClass([self class]), self, self.name, self.identifier];
}

- (BOOL)isEqual:(id)object
{
    ALTProvisioningProfile *profile = (ALTProvisioningProfile *)object;
    if (![profile isKindOfClass:[ALTProvisioningProfile class]])
    {
        return NO;
    }
    
    BOOL isEqual = (self.identifier == profile.identifier && self.data == profile.data);
    return isEqual;
}

- (NSUInteger)hash
{
    return self.identifier.hash ^ self.data.hash;
}

@end
