#import "HYChatMessage.h"

static NSString *HYStringFromValue(id value) {
    if (!value) return @"";
    if ([value isKindOfClass:[NSString class]]) return value;
    if ([value isKindOfClass:[NSNumber class]]) return [value stringValue];
    return @"";
}

@implementation HYChatMessage

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        _msgId = [NSString stringWithFormat:@"%@", dict[@"msg_id"] ?: @""];
        _seqId = [dict[@"seq_id"] longLongValue];
        _content = HYStringFromValue(dict[@"content"]);
        _type = HYStringFromValue(dict[@"type"]);
        if (_type.length == 0) _type = @"text";
        _timestamp = HYStringFromValue(dict[@"timestamp"]);
        _sendStatus = HYMessageSendStatusSuccess;
        _localImagePath = HYStringFromValue(dict[@"local_image_path"]);

        // Parse gift fields from extra JSON (for type == "gift")
        _giftIconUrl = @"";
        _giftQuantity = 1;
        _giftEffectUrl = @"";
        _giftName = @"";
        if ([_type isEqualToString:@"gift"]) {
            NSString *extra = HYStringFromValue(dict[@"extra"]);
            if (extra.length > 0) {
                NSData *data = [extra dataUsingEncoding:NSUTF8StringEncoding];
                NSError *parseError;
                NSDictionary *extraDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseError];
                if ([extraDict isKindOfClass:[NSDictionary class]] && !parseError) {
                    _giftIconUrl = HYStringFromValue(extraDict[@"icon_url"]);
                    _giftQuantity = [extraDict[@"quantity"] integerValue];
                    _giftEffectUrl = HYStringFromValue(extraDict[@"effect_url"]);
                    _giftName = HYStringFromValue(extraDict[@"name"]);
                }
            }
        }
        _conversationId = [NSString stringWithFormat:@"%@", dict[@"conversation_id"] ?: @""];

        NSDictionary *sender = dict[@"sender"];
        if ([sender isKindOfClass:[NSDictionary class]]) {
            _senderId = [NSString stringWithFormat:@"%@", sender[@"id"] ?: sender[@"uid"] ?: @""];
            _senderName = HYStringFromValue(sender[@"name"]);
            _senderAvatar = HYStringFromValue(sender[@"avatar"]);
        } else {
            _senderId = [NSString stringWithFormat:@"%@", dict[@"sender_id"] ?: dict[@"sender"] ?: @""];
            _senderName = HYStringFromValue(dict[@"sender_name"]);
            _senderAvatar = HYStringFromValue(dict[@"sender_avatar"]);
        }

        NSDictionary *receiver = dict[@"receiver"];
        if ([receiver isKindOfClass:[NSDictionary class]]) {
            _receiverId = [NSString stringWithFormat:@"%@", receiver[@"id"] ?: receiver[@"uid"] ?: @""];
        } else {
            _receiverId = [NSString stringWithFormat:@"%@", dict[@"receiver_id"] ?: dict[@"receiver"] ?: @""];
        }
    }
    return self;
}

+ (instancetype)pendingMessageWithContent:(NSString *)content
                                     type:(HYMessageType)type
                              receiverId:(NSString *)receiverId
                          localImagePath:(NSString *)localImagePath {
    HYChatMessage *msg = [[HYChatMessage alloc] init];
    msg.msgId = [NSString stringWithFormat:@"local_%@", [[NSUUID UUID] UUIDString]];
    msg.content = content ?: @"";
    msg.type = (type == HYMessageTypeImage) ? @"image" : @"text";
    msg.receiverId = receiverId;
    msg.localImagePath = localImagePath ?: @"";
    msg.sendStatus = HYMessageSendStatusSending;
    msg.timestamp = [self isoTimestamp];
    msg.isFromMe = YES;
    return msg;
}

+ (NSString *)isoTimestamp {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSSZ";
    formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    return [formatter stringFromDate:[NSDate date]];
}

@end
