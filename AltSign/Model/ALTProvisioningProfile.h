//
//  ALTProvisioningProfile.h
//  AltSign
//
//  Created by Riley Testut on 5/22/19.
//  Copyright © 2019 Riley Testut. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ALTAppID;

NS_ASSUME_NONNULL_BEGIN

@interface ALTProvisioningProfile : NSObject

@property (copy, nonatomic) NSString *name;
@property (copy, nonatomic) NSString *identifier;
@property (copy, nonatomic) NSDate *expirationDate;

@property (copy, nonatomic) NSData *data;

@property (copy, nonatomic) ALTAppID *appID;

@end

NS_ASSUME_NONNULL_END
