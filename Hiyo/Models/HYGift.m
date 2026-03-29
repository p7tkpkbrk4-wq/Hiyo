#import "HYGift.h"

static NSString *HYStringFromValue(id value) {
    if (!value) return @"";
    if ([value isKindOfClass:[NSString class]]) return value;
    if ([value isKindOfClass:[NSNumber class]]) return [value stringValue];
    return @"";
}

@implementation HYGift
- (instancetype)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        _giftId = [dict[@"id"] integerValue];
        _name = HYStringFromValue(dict[@"name"]);
        _price = [dict[@"price"] integerValue];
        _sortOrder = [dict[@"sort_order"] integerValue];
        _iconUrl = HYStringFromValue(dict[@"icon_url"]);
        _effectUrl = HYStringFromValue(dict[@"effect_url"]);
    }
    return self;
}
@end

@implementation HYGiftGroup
- (instancetype)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        _groupId = [dict[@"group_id"] integerValue];
        _groupName = HYStringFromValue(dict[@"group_name"]);
        NSArray *gifts = dict[@"gifts"];
        if ([gifts isKindOfClass:[NSArray class]]) {
            NSMutableArray *parsed = [NSMutableArray array];
            for (NSDictionary *g in gifts) {
                [parsed addObject:[[HYGift alloc] initWithDictionary:g]];
            }
            _gifts = parsed;
        } else {
            _gifts = @[];
        }
    }
    return self;
}
@end

@implementation HYGiftBubble
- (instancetype)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        _iconUrl = HYStringFromValue(dict[@"icon_url"]);
        _name = HYStringFromValue(dict[@"name"]);
        _quantity = [dict[@"quantity"] integerValue];
        _effectUrl = HYStringFromValue(dict[@"effect_url"]);
    }
    return self;
}
@end

@implementation HYGiftSendResult
- (instancetype)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        _orderNo = HYStringFromValue(dict[@"order_no"]);
        _balanceAfter = [dict[@"balance_after"] integerValue];
        NSDictionary *giftDict = dict[@"gift"];
        if ([giftDict isKindOfClass:[NSDictionary class]]) {
            _gift = [[HYGift alloc] initWithDictionary:giftDict];
        }
    }
    return self;
}
@end
