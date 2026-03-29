#import "HYWebSocketManager.h"
#import "HYAPIClient.h"

NSNotificationName const HYWebSocketMessageReceivedNotification = @"HYWebSocketMessageReceivedNotification";
NSNotificationName const HYWebSocketConnectionStateChangedNotification = @"HYWebSocketConnectionStateChangedNotification";
NSNotificationName const HYWebSocketPostNotificationReceivedNotification = @"HYWebSocketPostNotificationReceivedNotification";
NSNotificationName const HYWebSocketCommentNotificationReceivedNotification = @"HYWebSocketCommentNotificationReceivedNotification";
NSNotificationName const HYWebSocketLikeNotificationReceivedNotification = @"HYWebSocketLikeNotificationReceivedNotification";
NSNotificationName const HYWebSocketGiftNotificationReceivedNotification = @"HYWebSocketGiftNotificationReceivedNotification";

static NSString * const kWSBaseURL = @"wss://api.hiyochat.live/ws";
static const NSTimeInterval kBaseRetryInterval = 1.0;
static const NSTimeInterval kMaxRetryInterval = 30.0;
static const NSInteger kMaxRetryAttempts = 5;

@interface HYWebSocketManager () <NSURLSessionWebSocketDelegate>

@property (nonatomic, strong) NSURLSessionWebSocketTask *webSocketTask;
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, assign) HYWebSocketState connectionState;
@property (nonatomic, assign) NSInteger retryAttempts;
@property (nonatomic, strong) NSTimer *retryTimer;
@property (nonatomic, assign) long long currentSeqId;
@property (nonatomic, strong) NSMutableSet *receivedMsgIds;
@property (nonatomic, assign) BOOL shouldReconnect;

@end

@implementation HYWebSocketManager

+ (instancetype)shared {
    static HYWebSocketManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[HYWebSocketManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _connectionState = HYWebSocketStateDisconnected;
        _retryAttempts = 0;
        _currentSeqId = 0;
        _receivedMsgIds = [NSMutableSet set];
        _shouldReconnect = YES;

        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        _session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    }
    return self;
}

- (void)connect {
    if (self.connectionState == HYWebSocketStateConnecting || self.connectionState == HYWebSocketStateConnected) {
        return;
    }

    [self disconnect];

    NSString *token = [HYAPIClient shared].token;
    if (!token) return;

    NSString *urlString = [NSString stringWithFormat:@"%@?token=%@", kWSBaseURL, token];
    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) return;

    self.shouldReconnect = YES;
    [self setConnectionState:HYWebSocketStateConnecting];

    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    self.webSocketTask = [self.session webSocketTaskWithRequest:request];
    [self.webSocketTask resume];
    [self receiveMessage];
}

- (void)disconnect {
    self.shouldReconnect = NO;
    [self.retryTimer invalidate];
    self.retryTimer = nil;
    [self.webSocketTask cancelWithCloseCode:NSURLSessionWebSocketCloseCodeNormalClosure reason:nil];
    self.webSocketTask = nil;
    [self setConnectionState:HYWebSocketStateDisconnected];
}

- (void)reconnect {
    [self disconnect];
    self.shouldReconnect = YES;
    [self connect];
}

- (void)setConnectionState:(HYWebSocketState)connectionState {
    _connectionState = connectionState;
    [[NSNotificationCenter defaultCenter] postNotificationName:HYWebSocketConnectionStateChangedNotification
                                                        object:@(connectionState)];
}

- (void)receiveMessage {
    __weak typeof(self) weakSelf = self;
    [self.webSocketTask receiveMessageWithCompletionHandler:^(NSURLSessionWebSocketMessage * _Nullable message, NSError * _Nullable error) {
        if (error) {
            [weakSelf handleDisconnection];
            return;
        }

        if (message.type == NSURLSessionWebSocketMessageTypeString) {
            [weakSelf handleMessageString:message.string];
        } else if (message.type == NSURLSessionWebSocketMessageTypeData) {
            NSString *str = [[NSString alloc] initWithData:message.data encoding:NSUTF8StringEncoding];
            if (str) {
                [weakSelf handleMessageString:str];
            }
        }

        [weakSelf receiveMessage];
    }];
}

- (void)handleMessageString:(NSString *)messageString {
    NSData *data = [messageString dataUsingEncoding:NSUTF8StringEncoding];
    if (!data) return;

    NSError *error;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (error || ![json isKindOfClass:[NSDictionary class]]) return;

    NSString *type = json[@"type"];
    id payload = json[@"payload"];

    if ([type isEqualToString:@"chat"] || [type isEqualToString:@"chat_response"]) {
        [self handleChatMessage:payload];
    } else if ([type isEqualToString:@"post_notification"]) {
        [self handlePostNotification:payload];
    } else if ([type isEqualToString:@"comment_notification"]) {
        [self handleCommentNotification:payload];
    } else if ([type isEqualToString:@"like_notification"]) {
        [self handleLikeNotification:payload];
    } else if ([type isEqualToString:@"onboarding_notification"]) {
        [self handleOnboardingNotification:payload];
    } else if ([type isEqualToString:@"gift"]) {
        [self handleGiftNotification:payload];
    }
}

- (void)handlePostNotification:(id)payload {
    if (![payload isKindOfClass:[NSDictionary class]]) return;
    [[NSNotificationCenter defaultCenter] postNotificationName:HYWebSocketPostNotificationReceivedNotification
                                                    object:payload];
}

- (void)handleCommentNotification:(id)payload {
    if (![payload isKindOfClass:[NSDictionary class]]) return;
    [[NSNotificationCenter defaultCenter] postNotificationName:HYWebSocketCommentNotificationReceivedNotification
                                                    object:payload];
}

- (void)handleLikeNotification:(id)payload {
    if (![payload isKindOfClass:[NSDictionary class]]) return;
    [[NSNotificationCenter defaultCenter] postNotificationName:HYWebSocketLikeNotificationReceivedNotification
                                                    object:payload];
}

- (void)handleOnboardingNotification:(id)payload {
    // Onboarding tips - can be displayed as toast or banner
    if (![payload isKindOfClass:[NSDictionary class]]) return;
    NSLog(@"Onboarding notification: %@", payload);
}

- (void)handleGiftNotification:(id)payload {
    if (![payload isKindOfClass:[NSDictionary class]]) return;
    [[NSNotificationCenter defaultCenter] postNotificationName:HYWebSocketGiftNotificationReceivedNotification
                                                        object:payload];
}

- (void)handleChatMessage:(id)payload {
    if (![payload isKindOfClass:[NSDictionary class]]) return;

    NSDictionary *msgData = payload;
    NSString *msgId = [NSString stringWithFormat:@"%@", msgData[@"msg_id"] ?: @""];

    // Deduplicate
    if (msgId.length > 0 && [self.receivedMsgIds containsObject:msgId]) {
        return;
    }
    if (msgId.length > 0) {
        [self.receivedMsgIds addObject:msgId];
    }

    HYChatMessage *message = [[HYChatMessage alloc] initWithDictionary:msgData];

    // Update seqId
    long long seqId = [msgData[@"seq_id"] longLongValue];
    if (seqId > self.currentSeqId) {
        self.currentSeqId = seqId;
    }

    // Determine isFromMe
    NSString *currentUserId = [NSString stringWithFormat:@"%@", [[HYAPIClient shared] token] ?: @""];
    // Use a simple comparison: if sender_id matches stored userId
    message.isFromMe = [message.senderId isEqualToString:msgData[@"my_id"]];

    [[NSNotificationCenter defaultCenter] postNotificationName:HYWebSocketMessageReceivedNotification
                                                        object:message];
}

- (void)handleDisconnection {
    if (!self.shouldReconnect) {
        [self setConnectionState:HYWebSocketStateDisconnected];
        return;
    }

    [self setConnectionState:HYWebSocketStateFailed];

    [self.retryTimer invalidate];
    self.retryAttempts++;

    if (self.retryAttempts > kMaxRetryAttempts) {
        [self setConnectionState:HYWebSocketStateDisconnected];
        return;
    }

    NSTimeInterval interval = MIN(kBaseRetryInterval * pow(2, self.retryAttempts - 1), kMaxRetryInterval);

    self.retryTimer = [NSTimer scheduledTimerWithTimeInterval:interval repeats:NO block:^(NSTimer * _Nonnull timer) {
        [self connect];
    }];
}

#pragma mark - NSURLSessionWebSocketDelegate

- (void)URLSession:(NSURLSession *)session webSocketTask:(NSURLSessionWebSocketTask *)webSocketTask didOpenWithProtocol:(NSString *)protocol {
    self.retryAttempts = 0;
    [self setConnectionState:HYWebSocketStateConnected];
}

- (void)URLSession:(NSURLSession *)session webSocketTask:(NSURLSessionWebSocketTask *)webSocketTask didCloseWithCode:(NSURLSessionWebSocketCloseCode)closeCode reason:(NSData *)reason {
    [self handleDisconnection];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (error) {
        [self handleDisconnection];
    }
}

#pragma mark - Send Messages

- (void)sendMessageWithContent:(NSString *)content type:(NSString *)type extra:(NSString *)extra receiverId:(NSString *)receiverId {
    if (self.connectionState != HYWebSocketStateConnected) return;

    NSMutableDictionary *msg = [NSMutableDictionary dictionary];
    msg[@"type"] = type;
    msg[@"receiver_id"] = receiverId;
    if (content.length > 0) msg[@"content"] = content;
    if (extra.length > 0) msg[@"extra"] = extra;

    NSError *error;
    NSData *data = [NSJSONSerialization dataWithJSONObject:msg options:0 error:&error];
    if (error) return;

    NSString *jsonStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSURLSessionWebSocketMessage *wsMsg = [[NSURLSessionWebSocketMessage alloc] initWithString:jsonStr];
    [self.webSocketTask sendMessage:wsMsg completionHandler:^(NSError * _Nullable sendError) {
        if (sendError) {
            NSLog(@"WebSocket send error: %@", sendError.localizedDescription);
        }
    }];
}

@end
