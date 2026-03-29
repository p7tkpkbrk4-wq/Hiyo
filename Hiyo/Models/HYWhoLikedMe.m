#import "HYWhoLikedMe.h"

@implementation HYSimpleUserInfo
- (instancetype)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        _userId = [NSString stringWithFormat:@"%@", dict[@"id"] ?: @"0"];
        _name = [self stringFromValue:dict[@"name"]];
        _avatar = [self stringFromValue:dict[@"avatar"]];
        _sex = [dict[@"sex"] integerValue];
        _age = [dict[@"age"] integerValue];
        _bio = [self stringFromValue:dict[@"bio"]];
        _isOnline = [dict[@"is_online"] boolValue];
    }
    return self;
}
- (NSString *)stringFromValue:(id)value {
    if (!value) return @"";
    if ([value isKindOfClass:[NSString class]]) return value;
    if ([value isKindOfClass:[NSNumber class]]) return [value stringValue];
    return @"";
}
@end

@implementation HYWhoLikedMeData
- (instancetype)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        _total = [dict[@"total"] integerValue];
        _locked = [dict[@"locked"] boolValue];
        _upgradeTip = dict[@"upgrade_tip"];
        NSArray *users = dict[@"users"];
        if ([users isKindOfClass:[NSArray class]]) {
            NSMutableArray *parsed = [NSMutableArray array];
            for (NSDictionary *u in users) {
                [parsed addObject:[[HYSimpleUserInfo alloc] initWithDictionary:u]];
            }
            _users = parsed;
        } else {
            _users = @[];
        }
    }
    return self;
}
@end

@implementation HYVisitorInfo
- (instancetype)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        _userId = [NSString stringWithFormat:@"%@", dict[@"id"] ?: @"0"];
        _name = [self stringFromValue:dict[@"name"]];
        _avatar = [self stringFromValue:dict[@"avatar"]];
        _sex = [dict[@"sex"] integerValue];
        _age = [dict[@"age"] integerValue];
        _bio = [self stringFromValue:dict[@"bio"]];
        _isOnline = [dict[@"is_online"] boolValue];
        _visitedAt = [self stringFromValue:dict[@"visited_at"]];
    }
    return self;
}
- (NSString *)stringFromValue:(id)value {
    if (!value) return @"";
    if ([value isKindOfClass:[NSString class]]) return value;
    if ([value isKindOfClass:[NSNumber class]]) return [value stringValue];
    return @"";
}
@end

@implementation HYProfileVisitorsData
- (instancetype)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        _total = [dict[@"total"] integerValue];
        _locked = [dict[@"locked"] boolValue];
        _upgradeTip = dict[@"upgrade_tip"];
        NSArray *visitors = dict[@"visitors"];
        if ([visitors isKindOfClass:[NSArray class]]) {
            NSMutableArray *parsed = [NSMutableArray array];
            for (NSDictionary *v in visitors) {
                [parsed addObject:[[HYVisitorInfo alloc] initWithDictionary:v]];
            }
            _visitors = parsed;
        } else {
            _visitors = @[];
        }
    }
    return self;
}
@end
