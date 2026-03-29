#import "HYInterestCategory.h"

static NSString *HYStringFromValue(id value) {
    if (!value) return @"";
    if ([value isKindOfClass:[NSString class]]) return value;
    if ([value isKindOfClass:[NSNumber class]]) return [value stringValue];
    return @"";
}

@implementation HYInterestCategory

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        _name = HYStringFromValue(dict[@"name"]);
        _tags = dict[@"tags"] ?: @[];
    }
    return self;
}

@end
