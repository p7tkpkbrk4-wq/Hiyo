#import "HYWalletInfo.h"

static NSString *HYStringFromValue(id value) {
    if (!value) return @"";
    if ([value isKindOfClass:[NSString class]]) return value;
    if ([value isKindOfClass:[NSNumber class]]) return [value stringValue];
    return @"";
}

@implementation HYWalletInfo
- (instancetype)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        _balance = [dict[@"balance"] integerValue];
        _totalRecharged = [dict[@"total_recharged"] integerValue];
        _totalConsumed = [dict[@"total_consumed"] integerValue];
    }
    return self;
}
@end

@implementation HYWalletFlow
- (instancetype)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        _flowId = [dict[@"id"] integerValue];
        _flowNo = HYStringFromValue(dict[@"flow_no"]);
        _direction = [dict[@"direction"] integerValue];
        _amount = [dict[@"amount"] integerValue];
        _balanceAfter = [dict[@"balance_after"] integerValue];
        _type = HYStringFromValue(dict[@"type"]);
        _refId = HYStringFromValue(dict[@"ref_id"]);
        _remark = HYStringFromValue(dict[@"remark"]);
        _createdAt = HYStringFromValue(dict[@"created_at"]);
    }
    return self;
}
@end
