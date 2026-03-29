#import "HYSearchUser.h"

static NSString *HYStringFromValue(id value) {
    if (!value) return @"";
    if ([value isKindOfClass:[NSString class]]) return value;
    if ([value isKindOfClass:[NSNumber class]]) return [value stringValue];
    return @"";
}

@implementation HYSearchUser

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        _uid = [NSString stringWithFormat:@"%@", dict[@"uid"] ?: @""];
        _userId = [NSString stringWithFormat:@"%@", dict[@"id"] ?: @""];
        _accountId = [dict[@"account_id"] longLongValue];
        _name = HYStringFromValue(dict[@"name"]);
        _avatarUrl = HYStringFromValue(dict[@"avatar_url"]);
        _signature = HYStringFromValue(dict[@"signature"]);
        _status = [dict[@"status"] integerValue];
    }
    return self;
}

@end
