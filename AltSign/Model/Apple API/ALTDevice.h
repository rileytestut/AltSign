//
//  ALTDevice.h
//  AltSign
//
//  Created by Riley Testut on 5/10/19.
//  Copyright © 2019 Riley Testut. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_OPTIONS(NSInteger, ALTDeviceType)
{
    ALTDeviceTypeiPhone NS_SWIFT_NAME(iphone) = 1 << 1,
    ALTDeviceTypeiPad NS_SWIFT_NAME(ipad) = 1 << 2,
    ALTDeviceTypeAppleTV NS_SWIFT_NAME(appletv) = 1 << 3,
    
    ALTDeviceTypeNone = 0,
    ALTDeviceTypeAll = (ALTDeviceTypeiPhone | ALTDeviceTypeiPad | ALTDeviceTypeAppleTV),
};

NS_ASSUME_NONNULL_BEGIN

@interface ALTDevice : NSObject <NSCopying>

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *identifier;
@property (nonatomic) ALTDeviceType type;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithName:(NSString *)name identifier:(NSString *)identifier type:(ALTDeviceType)type NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
