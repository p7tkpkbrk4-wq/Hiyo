#import "HYUser.h"

@implementation HYUser

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        _userId = [dict[@"id"] integerValue];
        _accountId = [dict[@"account_id"] longValue];
        _name = [self stringFromValue:dict[@"name"]];
        _email = [self stringFromValue:dict[@"email"]];
        _age = [dict[@"age"] integerValue];
        _avatar = [self stringFromValue:dict[@"avatar_url"] ?: dict[@"avatar"]];
        _bio = [self stringFromValue:dict[@"signature"] ?: dict[@"bio"]];
        _sex = [dict[@"sex"] integerValue];
        _birthDay = [self stringFromValue:dict[@"birth_day"]];
        _distance = [self stringFromValue:dict[@"distance"]];
        _height = [dict[@"height"] integerValue];
        _weight = [dict[@"weight"] integerValue];
        _constellation = [self stringFromValue:dict[@"constellation"]];
        _currentAddress = [self stringFromValue:dict[@"current_address"]];
        _job = [self stringFromValue:dict[@"job"]];
        _backgroundImage = [self stringFromValue:dict[@"background_image_url"] ?: dict[@"background_image"]];
        _fansCount = [dict[@"fans_count"] longLongValue];
        _attentionCount = [dict[@"attention_count"] longLongValue];
        _lookMeCount = [dict[@"look_me_count"] longLongValue];
        _charm = [dict[@"charm"] longLongValue];
        _isFollowing = [dict[@"is_following"] boolValue];
        _isOnline = [dict[@"is_online"] boolValue];
        _isVip = [dict[@"is_vip"] boolValue];
        _voiceUrl = [self stringFromValue:dict[@"voice_url"]];
        _voiceDuration = [dict[@"voice_duration"] integerValue];

        // Parse interests
        NSArray *interestsArray = dict[@"interests"];
        if ([interestsArray isKindOfClass:[NSArray class]]) {
            NSMutableArray *arr = [NSMutableArray array];
            for (id item in interestsArray) {
                if ([item isKindOfClass:[NSString class]]) {
                    [arr addObject:item];
                } else if ([item isKindOfClass:[NSDictionary class]]) {
                    NSString *name = [self stringFromValue:item[@"name"] ?: item[@"tag"]];
                    if (name.length > 0) [arr addObject:name];
                }
            }
            _interests = [arr copy];
        } else {
            _interests = @[];
        }

        // Parse photos (array of URLs or photo objects)
        id photosData = dict[@"photos"];
        if ([photosData isKindOfClass:[NSArray class]]) {
            NSMutableArray *photos = [NSMutableArray array];
            for (id item in photosData) {
                if ([item isKindOfClass:[NSString class]]) {
                    [photos addObject:item];
                } else if ([item isKindOfClass:[NSDictionary class]]) {
                    NSString *url = [self stringFromValue:item[@"photo_url"]];
                    if (url.length > 0) [photos addObject:url];
                }
            }
            _photos = [photos copy];
        } else {
            _photos = @[];
        }
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
