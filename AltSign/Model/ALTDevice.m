//
//  ALTDevice.m
//  AltSign
//
//  Created by Riley Testut on 5/10/19.
//  Copyright © 2019 Riley Testut. All rights reserved.
//

#import "ALTDevice.h"

@implementation ALTDevice

- (nullable instancetype)initWithResponseDictionary:(NSDictionary *)responseDictionary
{
    self = [super init];
    if (self)
    {
        NSString *name = responseDictionary[@"name"];
        NSString *identifier = responseDictionary[@"deviceNumber"];
        
        if (name == nil || identifier == nil)
        {
            return nil;
        }
        
        _name = [name copy];
        _identifier = [identifier copy];
    }
    
    return self;
}

#pragma mark - NSObject -

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p, Name: %@, UDID: %@>", NSStringFromClass([self class]), self, self.name, self.identifier];
}

- (BOOL)isEqual:(id)object
{
    ALTDevice *device = (ALTDevice *)object;
    if (![device isKindOfClass:[ALTDevice class]])
    {
        return NO;
    }
    
    BOOL isEqual = (self.identifier == device.identifier);
    return isEqual;
}

- (NSUInteger)hash
{
    return self.identifier.hash;
}

@end
