#import "HYFollowUser.h"

static NSString *HYStringFromValue(id value) {
    if (!value) return @"";
    if ([value isKindOfClass:[NSString class]]) return value;
    if ([value isKindOfClass:[NSNumber class]]) return [value stringValue];
    return @"";
}

@implementation HYFollowUser

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        _followId = [dict[@"follow_id"] longLongValue];
        _userId = [NSString stringWithFormat:@"%@", dict[@"user_id"] ?: @""];
        _accountId = [dict[@"account_id"] longLongValue];
        _name = HYStringFromValue(dict[@"name"]);
        _avatarUrl = HYStringFromValue(dict[@"avatar_url"]);
        _signature = HYStringFromValue(dict[@"signature"]);
        _sex = [dict[@"sex"] integerValue];
        _isFollowing = [dict[@"is_following"] boolValue];
    }
    return self;
}

@end
