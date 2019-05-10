//
//  ALTDevice.h
//  AltSign
//
//  Created by Riley Testut on 5/10/19.
//  Copyright © 2019 Riley Testut. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ALTDevice : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *identifier;

- (nullable instancetype)initWithResponseDictionary:(NSDictionary *)responseDictionary;

@end

NS_ASSUME_NONNULL_END
