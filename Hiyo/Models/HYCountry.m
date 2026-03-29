#import "HYCountry.h"

static NSString *HYStringFromValue(id value) {
    if (!value) return @"";
    if ([value isKindOfClass:[NSString class]]) return value;
    if ([value isKindOfClass:[NSNumber class]]) return [value stringValue];
    return @"";
}

@implementation HYCountry

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        _countryId = [dict[@"id"] integerValue];
        _name = HYStringFromValue(dict[@"name"]);
        _cities = dict[@"cities"] ?: @[];
    }
    return self;
}

@end
