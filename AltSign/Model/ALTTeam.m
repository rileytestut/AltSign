//
//  ALTTeam.m
//  AltSign
//
//  Created by Riley Testut on 5/10/19.
//  Copyright © 2019 Riley Testut. All rights reserved.
//

#import "ALTTeam.h"

@implementation ALTTeam

- (nullable instancetype)initWithAccount:(ALTAccount *)account responseDictionary:(NSDictionary *)responseDictionary
{
    self = [super init];
    if (self)
    {
        _account = account;
        
        NSString *name = responseDictionary[@"name"];
        NSString *identifier = responseDictionary[@"teamId"];
        
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
    return [NSString stringWithFormat:@"<%@: %p, Name: %@>", NSStringFromClass([self class]), self, self.name];
}

- (BOOL)isEqual:(id)object
{
    ALTTeam *team = (ALTTeam *)object;
    if (![team isKindOfClass:[ALTTeam class]])
    {
        return NO;
    }
    
    BOOL isEqual = (self.identifier == team.identifier);
    return isEqual;
}

- (NSUInteger)hash
{
    return self.identifier.hash;
}

@end
