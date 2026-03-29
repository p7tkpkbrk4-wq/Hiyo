#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, HYMessageSendStatus) {
    HYMessageSendStatusSending,
    HYMessageSendStatusSuccess,
    HYMessageSendStatusFailed
};

typedef NS_ENUM(NSInteger, HYMessageType) {
    HYMessageTypeText,
    HYMessageTypeImage
};

@interface HYChatMessage : NSObject

@property (nonatomic, copy) NSString *msgId;
@property (nonatomic, assign) long long seqId;
@property (nonatomic, copy) NSString *content;
@property (nonatomic, copy) NSString *type; // "text" or "image"
@property (nonatomic, copy) NSString *senderId;
@property (nonatomic, copy) NSString *receiverId;
@property (nonatomic, copy) NSString *timestamp;
@property (nonatomic, assign) HYMessageSendStatus sendStatus;
@property (nonatomic, copy) NSString *localImagePath;
@property (nonatomic, assign) BOOL isFromMe;
@property (nonatomic, copy) NSString *conversationId;
@property (nonatomic, copy) NSString *senderName;
@property (nonatomic, copy) NSString *senderAvatar;
// Gift fields (used when type == "gift")
@property (nonatomic, copy) NSString *giftIconUrl;
@property (nonatomic, assign) NSInteger giftQuantity;
@property (nonatomic, copy) NSString *giftEffectUrl;
@property (nonatomic, copy) NSString *giftName;

- (instancetype)initWithDictionary:(NSDictionary *)dict;

// Create a local pending message for optimistic UI
+ (instancetype)pendingMessageWithContent:(NSString *)content
                                     type:(HYMessageType)type
                              receiverId:(NSString *)receiverId
                           localImagePath:(nullable NSString *)localImagePath;

// Generate ISO timestamp for messages
+ (NSString *)isoTimestamp;

@end

NS_ASSUME_NONNULL_END
