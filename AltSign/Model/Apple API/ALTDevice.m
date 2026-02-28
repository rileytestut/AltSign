//
//  ALTDevice.m
//  AltSign
//
//  Created by Riley Testut on 5/10/19.
//  Copyright © 2019 Riley Testut. All rights reserved.
//

#import "ALTDevice.h"

#ifdef __cplusplus
extern "C" {
#endif

NSOperatingSystemVersion const NSOperatingSystemVersionUnknown = (NSOperatingSystemVersion){0, 0, 0};

NSOperatingSystemVersion NSOperatingSystemVersionFromString(NSString *osVersionString)
{
    NSArray *versionComponents = [osVersionString componentsSeparatedByString:@"."];
    
    NSInteger majorVersion = [versionComponents.firstObject integerValue];
    NSInteger minorVersion = (versionComponents.count > 1) ? [versionComponents[1] integerValue] : 0;
    NSInteger patchVersion = (versionComponents.count > 2) ? [versionComponents[2] integerValue] : 0;
    
    NSOperatingSystemVersion osVersion;
    osVersion.majorVersion = majorVersion;
    osVersion.minorVersion = minorVersion;
    osVersion.patchVersion = patchVersion;
    return osVersion;
}
    
NSString *_Nonnull NSStringFromOperatingSystemVersion(NSOperatingSystemVersion osVersion)
{
    NSString *stringValue = [NSString stringWithFormat:@"%@.%@", @(osVersion.majorVersion), @(osVersion.minorVersion)];
    if (osVersion.patchVersion != 0)
    {
        stringValue = [NSString stringWithFormat:@"%@.%@", stringValue, @(osVersion.patchVersion)];
    }
    
    return stringValue;
}
    
NSString *_Nullable ALTOperatingSystemNameForDeviceType(ALTDeviceType deviceType)
{
    switch (deviceType)
    {
        case ALTDeviceTypeiPhone:
        case ALTDeviceTypeiPad:
            return @"iOS";
            
        case ALTDeviceTypeAppleTV:
            return @"tvOS";
            
        case ALTDeviceTypeNone:
        case ALTDeviceTypeAll:
        default:
            return nil;
    }
}

#ifdef __cplusplus
}
#endif

@implementation ALTDevice

- (instancetype)initWithName:(NSString *)name identifier:(NSString *)identifier type:(ALTDeviceType)type
{
    self = [super init];
    if (self)
    {
        _name = [name copy];
        _identifier = [identifier copy];
        _type = type;
    }
    
    return self;
}

- (nullable instancetype)initWithResponseDictionary:(NSDictionary *)responseDictionary
{
    NSString *name = responseDictionary[@"name"];
    NSString *identifier = responseDictionary[@"deviceNumber"];
    
    if (name == nil || identifier == nil)
    {
        return nil;
    }
    
    ALTDeviceType deviceType = ALTDeviceTypeNone;
    
    NSString *deviceClass = responseDictionary[@"deviceClass"] ?: @"iphone";
    if ([deviceClass isEqualToString:@"iphone"])
    {
        deviceType = ALTDeviceTypeiPhone;
    }
    else if ([deviceClass isEqualToString:@"ipad"])
    {
        deviceType = ALTDeviceTypeiPad;
    }
    else if ([deviceClass isEqualToString:@"tvOS"])
    {
        deviceType = ALTDeviceTypeAppleTV;
    }
    
    self = [self initWithName:name identifier:identifier type:deviceType];
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
    
    BOOL isEqual = [self.identifier isEqualToString:device.identifier];
    return isEqual;
}

- (NSUInteger)hash
{
    return self.identifier.hash;
}

#pragma mark - <NSCopying> -

- (nonnull id)copyWithZone:(nullable NSZone *)zone
{
    ALTDevice *device = [[ALTDevice alloc] initWithName:self.name identifier:self.identifier type:self.type];
    device.osVersion = self.osVersion;
    return device;
}

@end
