//
//  ALTTeam.h
//  AltSign
//
//  Created by Riley Testut on 5/10/19.
//  Copyright © 2019 Riley Testut. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ALTAccount;

NS_ASSUME_NONNULL_BEGIN

@interface ALTTeam : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *identifier;

@property (nonatomic) ALTAccount *account;

@end

NS_ASSUME_NONNULL_END
