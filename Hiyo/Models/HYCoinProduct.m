#import "HYCoinProduct.h"

static NSString *HYStringFromValue(id value) {
    if (!value) return @"";
    if ([value isKindOfClass:[NSString class]]) return value;
    if ([value isKindOfClass:[NSNumber class]]) return [value stringValue];
    return @"";
}

@implementation HYCoinProduct
- (instancetype)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        _productId = [dict[@"id"] integerValue];
        _name = HYStringFromValue(dict[@"name"]);
        _coinAmount = [dict[@"coin_amount"] integerValue];
        _priceCents = [dict[@"price_cents"] integerValue];
        _currency = HYStringFromValue(dict[@"currency"]);
        _bonusCoins = [dict[@"bonus_coins"] integerValue];
        _productKey = HYStringFromValue(dict[@"product_key"]);
        _iconUrl = HYStringFromValue(dict[@"icon_url"]);
    }
    return self;
}
@end

@implementation HYRechargeOrder
- (instancetype)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        _orderId = [dict[@"id"] integerValue];
        _orderNo = HYStringFromValue(dict[@"order_no"]);
        _coinAmount = [dict[@"coin_amount"] integerValue];
        _payAmountCents = [dict[@"pay_amount_cents"] integerValue];
        _currency = HYStringFromValue(dict[@"currency"]);
        _status = [dict[@"status"] integerValue];
        _createdAt = HYStringFromValue(dict[@"created_at"]);
    }
    return self;
}
@end
