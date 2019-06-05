//
//  ALTProvisioningProfile.m
//  AltSign
//
//  Created by Riley Testut on 5/22/19.
//  Copyright © 2019 Riley Testut. All rights reserved.
//

#import "ALTProvisioningProfile.h"
#import "ALTAppID.h"

@implementation ALTProvisioningProfile

- (nullable instancetype)initWithAppID:(ALTAppID *)appID responseDictionary:(NSDictionary *)responseDictionary
{
    self = [super init];
    if (self)
    {
        _appID = [appID copy];
        
        NSString *name = responseDictionary[@"name"];
        NSString *identifier = responseDictionary[@"UUID"];
        NSDate *expirationDate = responseDictionary[@"dateExpire"];
        NSData *data = responseDictionary[@"encodedProfile"];
        
        if (name == nil || identifier == nil || expirationDate == nil || data == nil)
        {
            return nil;
        }
        
        _name = [name copy];
        _identifier = [identifier copy];
        _expirationDate = [expirationDate copy];
        _data = [data copy];
    }
    
    return self;
}

#pragma mark - NSObject -

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p, Name: %@, UUID: %@, App ID: %@>", NSStringFromClass([self class]), self, self.name, self.identifier, self.appID.identifier];
}

- (BOOL)isEqual:(id)object
{
    ALTProvisioningProfile *profile = (ALTProvisioningProfile *)object;
    if (![profile isKindOfClass:[ALTProvisioningProfile class]])
    {
        return NO;
    }
    
    BOOL isEqual = (self.identifier == profile.identifier && self.data == profile.data && self.appID == profile.appID);
    return isEqual;
}

- (NSUInteger)hash
{
    return self.identifier.hash ^ self.data.hash ^ self.appID.hash;
}

@end
