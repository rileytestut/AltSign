//
//  ALTApplication.h
//  AltSign
//
//  Created by Riley Testut on 6/24/19.
//  Copyright © 2019 Riley Testut. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ALTCapabilities.h"

NS_ASSUME_NONNULL_BEGIN

@interface ALTApplication : NSObject

@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, copy, readonly) NSString *bundleIdentifier;
@property (nonatomic, copy, readonly) NSString *version;

@property (nonatomic, readonly) NSOperatingSystemVersion minimumiOSVersion;

@property (nonatomic, copy, readonly) NSDictionary<ALTEntitlement, id> *entitlements;

@property (nonatomic, copy, readonly) NSURL *fileURL;

- (nullable instancetype)initWithFileURL:(NSURL *)fileURL;

@end

NS_ASSUME_NONNULL_END
