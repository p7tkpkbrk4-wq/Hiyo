#import <Foundation/Foundation.h>
#import "HYChatMessage.h"

NS_ASSUME_NONNULL_BEGIN

extern NSNotificationName const HYWebSocketMessageReceivedNotification;
extern NSNotificationName const HYWebSocketConnectionStateChangedNotification;
extern NSNotificationName const HYWebSocketPostNotificationReceivedNotification;
extern NSNotificationName const HYWebSocketCommentNotificationReceivedNotification;
extern NSNotificationName const HYWebSocketLikeNotificationReceivedNotification;
extern NSNotificationName const HYWebSocketGiftNotificationReceivedNotification;

typedef NS_ENUM(NSInteger, HYWebSocketState) {
    HYWebSocketStateDisconnected,
    HYWebSocketStateConnecting,
    HYWebSocketStateConnected,
    HYWebSocketStateFailed
};

@interface HYWebSocketManager : NSObject

+ (instancetype)shared;

@property (nonatomic, assign, readonly) HYWebSocketState connectionState;

- (void)connect;
- (void)disconnect;
- (void)reconnect;

// Send messages
- (void)sendMessageWithContent:(NSString *)content type:(NSString *)type extra:(NSString *)extra receiverId:(NSString *)receiverId;

@end

NS_ASSUME_NONNULL_END
