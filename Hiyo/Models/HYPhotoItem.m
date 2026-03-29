#import "HYPhotoItem.h"

static NSString *HYStringFromValue(id value) {
    if (!value) return @"";
    if ([value isKindOfClass:[NSString class]]) return value;
    if ([value isKindOfClass:[NSNumber class]]) return [value stringValue];
    return @"";
}

@implementation HYPhotoItem

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        _photoId = [dict[@"id"] longLongValue];
        _photoUrl = HYStringFromValue(dict[@"photo_url"]);
        _isPrivacy = [dict[@"is_privacy"] integerValue];
        _isWall = [dict[@"is_wall"] integerValue];
    }
    return self;
}

@end
