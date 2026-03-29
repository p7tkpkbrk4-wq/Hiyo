#import "HYVip.h"

static NSString *HYStringFromValue(id value) {
    if (!value) return @"";
    if ([value isKindOfClass:[NSString class]]) return value;
    if ([value isKindOfClass:[NSNumber class]]) return [value stringValue];
    return @"";
}

@implementation HYSubscriptionPlan
- (instancetype)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        _planId = [dict[@"id"] integerValue];
        _name = HYStringFromValue(dict[@"name"]);
        _durationDays = [dict[@"duration_days"] integerValue];
        _platformProductId = HYStringFromValue(dict[@"platform_product_id"]);
        _priceDisplay = HYStringFromValue(dict[@"price_display"]);
        _planDescription = HYStringFromValue(dict[@"description"]);
        _features = dict[@"features"];
    }
    return self;
}
@end

@implementation HYVipStatus
- (instancetype)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        _isVip = [dict[@"is_vip"] boolValue];
        _expireAt = HYStringFromValue(dict[@"expire_at"]);
        _autoRenew = [dict[@"auto_renew"] boolValue];
        _planName = HYStringFromValue(dict[@"plan_name"]);
        _daysLeft = [dict[@"days_left"] integerValue];
    }
    return self;
}
@end

@implementation HYVipPrivilege
- (instancetype)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        _privilegeId = [dict[@"id"] integerValue];
        _privilegeKey = HYStringFromValue(dict[@"privilege_key"]);
        _freeValue = HYStringFromValue(dict[@"free_value"]);
        _vipValue = HYStringFromValue(dict[@"vip_value"]);
        _description_text = HYStringFromValue(dict[@"description"]);
    }
    return self;
}
@end

@implementation HYCheckinStatus
- (instancetype)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        _currentDay = [dict[@"current_day"] integerValue];
        _checkedDays = dict[@"checked_days"] ?: @[];
        _todayChecked = [dict[@"today_checked"] boolValue];
        _todayReward = [dict[@"today_reward"] integerValue];
        _rewards = dict[@"rewards"] ?: @[];
    }
    return self;
}
@end

@implementation HYCheckinResult
- (instancetype)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        _dayNum = [dict[@"day_num"] integerValue];
        _coinsEarned = [dict[@"coins_earned"] integerValue];
        _newBalance = [dict[@"new_balance"] integerValue];
    }
    return self;
}
@end
