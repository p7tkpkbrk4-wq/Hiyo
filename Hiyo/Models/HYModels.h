#import <Foundation/Foundation.h>
#import "HYUser.h"

NS_ASSUME_NONNULL_BEGIN

@interface HYMatchUser : HYUser
@end

@interface HYPost : NSObject
@property (nonatomic, assign) NSInteger postId;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *content;
@property (nonatomic, assign) NSInteger userId;
@property (nonatomic, copy) NSString *userName;
@property (nonatomic, copy) NSString *userAvatar;
@property (nonatomic, copy) NSString *firstImage;
@property (nonatomic, assign) NSInteger likesCount;
@property (nonatomic, assign) NSInteger commentsCount;
@property (nonatomic, assign) BOOL isLiked;
@property (nonatomic, copy) NSString *createdAt;

- (instancetype)initWithDictionary:(NSDictionary *)dict;
@end

@interface HYPostAuthor : NSObject
@property (nonatomic, assign) NSInteger userId;
@property (nonatomic, copy) NSString *userName;
@property (nonatomic, copy) NSString *avatar;
- (instancetype)initWithDictionary:(NSDictionary *)dict;
@end

@interface HYPostComment : NSObject
@property (nonatomic, assign) NSInteger commentId;
@property (nonatomic, assign) NSInteger postId;
@property (nonatomic, assign) NSInteger userId;
@property (nonatomic, copy) NSString *userName;
@property (nonatomic, copy) NSString *userAvatar;
@property (nonatomic, copy) NSString *content;
@property (nonatomic, copy) NSString *createdAt;
- (instancetype)initWithDictionary:(NSDictionary *)dict;
@end

@interface HYPostDetail : NSObject
@property (nonatomic, assign) NSInteger postId;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *content;
@property (nonatomic, copy) NSString *imageUrl;
@property (nonatomic, strong) HYPostAuthor *author;
@property (nonatomic, assign) BOOL isLiked;
@property (nonatomic, assign) NSInteger likesCount;
@property (nonatomic, strong) NSArray<HYPostComment *> *comments;
@property (nonatomic, copy) NSString *createdAt;
- (instancetype)initWithDictionary:(NSDictionary *)dict;
@end

@interface HYNotification : NSObject
@property (nonatomic, assign) NSInteger notificationId;
@property (nonatomic, assign) NSInteger actorId;
@property (nonatomic, copy) NSString *type;
@property (nonatomic, assign) NSInteger postId;
@property (nonatomic, copy) NSString *actorName;
@property (nonatomic, copy) NSString *actorAvatar;
@property (nonatomic, copy) NSString *content;
@property (nonatomic, copy) NSString *createdAt;
- (instancetype)initWithDictionary:(NSDictionary *)dict;
@end

@interface HYConversation : NSObject
@property (nonatomic, copy) NSString *partnerId;
@property (nonatomic, copy) NSString *partnerName;
@property (nonatomic, copy) NSString *partnerAvatar;
@property (nonatomic, copy) NSString *lastMessage;
@property (nonatomic, copy) NSString *lastMessageType;
@property (nonatomic, copy) NSString *lastTime;
@property (nonatomic, assign) NSInteger unreadCount;
@property (nonatomic, assign) NSInteger chatType;

- (instancetype)initWithDictionary:(NSDictionary *)dict;
@end

NS_ASSUME_NONNULL_END
