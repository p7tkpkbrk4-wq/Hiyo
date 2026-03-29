#import "HYModels.h"

@implementation HYMatchUser
@end

@implementation HYPost

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        _postId = [dict[@"post_id"] integerValue];
        _title = [self stringFromValue:dict[@"title"]];
        _content = [self stringFromValue:dict[@"content"]];
        _userId = [dict[@"user_id"] integerValue];
        _userName = [self stringFromValue:dict[@"user_name"]];
        _userAvatar = [self stringFromValue:dict[@"user_avatar"]];
        _firstImage = [self stringFromValue:dict[@"first_image"]];
        _likesCount = [dict[@"likes_count"] integerValue];
        _commentsCount = [dict[@"comments_count"] integerValue];
        _isLiked = [dict[@"is_liked"] boolValue];
        _createdAt = [self stringFromValue:dict[@"created_at"]];
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

@implementation HYPostAuthor

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        _userId = [dict[@"user_id"] integerValue];
        _userName = [self stringFromValue:dict[@"user_name"]];
        _avatar = [self stringFromValue:dict[@"avatar"]];
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

@implementation HYPostComment

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        _commentId = [dict[@"comment_id"] integerValue];
        _postId = [dict[@"post_id"] integerValue];
        _userId = [dict[@"user_id"] integerValue];
        _userName = [self stringFromValue:dict[@"user_name"]];
        _userAvatar = [self stringFromValue:dict[@"user_avatar"]];
        _content = [self stringFromValue:dict[@"content"]];
        _createdAt = [self stringFromValue:dict[@"created_at"]];
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

@implementation HYPostDetail

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        _postId = [dict[@"post_id"] integerValue];
        _title = [self stringFromValue:dict[@"title"]];
        _content = [self stringFromValue:dict[@"content"]];
        _imageUrl = [self stringFromValue:dict[@"image_url"]];
        _isLiked = [dict[@"is_liked"] boolValue];
        _likesCount = [dict[@"likes_count"] integerValue];
        _createdAt = [self stringFromValue:dict[@"created_at"]];

        if (dict[@"author"] && [dict[@"author"] isKindOfClass:[NSDictionary class]]) {
            _author = [[HYPostAuthor alloc] initWithDictionary:dict[@"author"]];
        } else {
            _author = [[HYPostAuthor alloc] init];
        }

        NSMutableArray *comments = [NSMutableArray array];
        NSArray *commentsData = dict[@"comments"];
        if ([commentsData isKindOfClass:[NSArray class]]) {
            for (NSDictionary *commentDict in commentsData) {
                HYPostComment *comment = [[HYPostComment alloc] initWithDictionary:commentDict];
                [comments addObject:comment];
            }
        }
        _comments = [comments copy];
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

@implementation HYNotification

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        _notificationId = [dict[@"id"] integerValue];
        _actorId = [dict[@"actor_id"] integerValue];
        _type = [self stringFromValue:dict[@"type"]];
        _postId = [dict[@"post_id"] integerValue];
        _actorName = [self stringFromValue:dict[@"actor_name"]];
        _actorAvatar = [self stringFromValue:dict[@"actor_avatar"]];
        _content = [self stringFromValue:dict[@"content"]];
        _createdAt = [self stringFromValue:dict[@"created_at"]];
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

@implementation HYConversation

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        _partnerId = [NSString stringWithFormat:@"%@", dict[@"target_id"] ?: dict[@"partner_id"] ?: @""];
        _partnerName = [self stringFromValue:dict[@"partner_name"]];
        _partnerAvatar = [self stringFromValue:dict[@"partner_avatar"]];
        _lastMessage = [self stringFromValue:dict[@"last_message"]];
        _lastMessageType = [self stringFromValue:dict[@"last_message_type"]];
        if (_lastMessageType.length == 0) _lastMessageType = @"text";
        _lastTime = [self stringFromValue:dict[@"last_time"]];
        _unreadCount = [dict[@"unread_count"] integerValue];
        _chatType = [dict[@"chat_type"] integerValue];
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
