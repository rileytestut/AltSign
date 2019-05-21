//
//  ALTAppID.h
//  AltSign
//
//  Created by Riley Testut on 5/21/19.
//  Copyright © 2019 Riley Testut. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ALTAppID : NSObject

@property (copy, nonatomic) NSString *name;
@property (copy, nonatomic) NSString *identifier;

@property (copy, nonatomic) NSString *bundleIdentifier;

- (nullable instancetype)initWithResponseDictionary:(NSDictionary *)responseDictionary;

@end

NS_ASSUME_NONNULL_END
