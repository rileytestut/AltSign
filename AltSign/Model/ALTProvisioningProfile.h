//
//  ALTProvisioningProfile.h
//  AltSign
//
//  Created by Riley Testut on 5/22/19.
//  Copyright © 2019 Riley Testut. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ALTProvisioningProfile : NSObject

@property (copy, nonatomic) NSString *name;
@property (copy, nonatomic) NSString *identifier;

@property (copy, nonatomic) NSData *data;

- (nullable instancetype)initWithResponseDictionary:(NSDictionary *)responseDictionary;

@end

NS_ASSUME_NONNULL_END
