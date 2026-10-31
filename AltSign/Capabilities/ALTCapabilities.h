//
//  ALTCapabilities.h
//  AltSign
//
//  Created by Riley Testut on 6/25/19.
//  Copyright © 2019 Riley Testut. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// Entitlements
typedef NSString *ALTEntitlement NS_TYPED_EXTENSIBLE_ENUM;
extern ALTEntitlement const ALTEntitlementApplicationIdentifier;
extern ALTEntitlement const ALTEntitlementKeychainAccessGroups;
extern ALTEntitlement const ALTEntitlementAppGroups;
extern ALTEntitlement const ALTEntitlementGetTaskAllow;
extern ALTEntitlement const ALTEntitlementTeamIdentifier;
extern ALTEntitlement const ALTEntitlementHealthKit;
extern ALTEntitlement const ALTEntitlementInterAppAudio;
extern ALTEntitlement const ALTEntitlementIncreasedMemoryLimit;

// Features
typedef NSString *ALTFeature NS_TYPED_EXTENSIBLE_ENUM;
extern ALTFeature const ALTFeatureHealthKit;
extern ALTFeature const ALTFeatureGameCenter;
extern ALTFeature const ALTFeatureAppGroups;
extern ALTFeature const ALTFeatureInterAppAudio;
extern ALTFeature const ALTFeatureIncreasedMemoryLimit;

_Nullable ALTEntitlement ALTEntitlementForFeature(ALTFeature feature) NS_SWIFT_NAME(ALTEntitlement.init(feature:));
_Nullable ALTFeature ALTFeatureForEntitlement(ALTEntitlement entitlement) NS_SWIFT_NAME(ALTFeature.init(entitlement:));

BOOL ALTFeatureIsLegacy(ALTFeature feature) NS_SWIFT_NAME(getter:ALTFeature.isLegacy(self:));

NS_ASSUME_NONNULL_END
