#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// Notification for unauthorized errors
extern NSNotificationName const HYAPIClientUnauthorizedNotification;

typedef void (^HYAPICompletion)(NSDictionary * _Nullable response, NSError * _Nullable error);
typedef void (^HYLikeCompletion)(NSDictionary * _Nullable response, BOOL matched, NSError * _Nullable error);


@interface HYAPIClient : NSObject

+ (instancetype)shared;

// Auth
- (void)sendCodeWithEmail:(NSString *)email completion:(HYAPICompletion)completion;
- (void)registerWithEmail:(NSString *)email username:(NSString *)username password:(NSString *)password code:(NSString *)code avatarUrl:(NSString *)avatarUrl completion:(HYAPICompletion)completion;
- (void)loginWithEmail:(NSString *)email password:(NSString *)password completion:(HYAPICompletion)completion;

// Match
- (void)getMatchCardsWithLimit:(NSInteger)limit offset:(NSInteger)offset completion:(HYAPICompletion)completion;
- (void)likeUserWithId:(NSInteger)userId completion:(HYLikeCompletion)completion;
- (void)dislikeUserWithId:(NSInteger)userId completion:(HYAPICompletion)completion;
- (void)favoriteUserWithId:(NSInteger)userId completion:(HYAPICompletion)completion;

// Posts
- (void)getPostsWithPage:(NSInteger)page pageSize:(NSInteger)pageSize completion:(HYAPICompletion)completion;
- (void)getPostDetailWithId:(NSInteger)postId completion:(HYAPICompletion)completion;
- (void)createPostWithTitle:(NSString *)title content:(NSString *)content imageUrl:(NSString *)imageUrl completion:(HYAPICompletion)completion;
- (void)likePostWithId:(NSInteger)postId completion:(HYAPICompletion)completion;
- (void)deletePostWithId:(NSInteger)postId completion:(HYAPICompletion)completion;
- (void)createCommentWithPostId:(NSInteger)postId content:(NSString *)content completion:(HYAPICompletion)completion;
- (void)deleteCommentWithId:(NSInteger)commentId completion:(HYAPICompletion)completion;
- (void)uploadImageWithData:(NSData *)imageData fileName:(NSString *)fileName completion:(HYAPICompletion)completion;
- (void)getUploadTokenWithCompletion:(void (^)(NSString * _Nullable apiBaseUrl, NSString * _Nullable token, NSError * _Nullable error))completion;
- (void)uploadAvatarImage:(NSData *)imageData completion:(void (^)(NSString * _Nullable imageUrl, NSError * _Nullable error))completion;

// Notifications
- (void)getUnreadCountWithCompletion:(HYAPICompletion)completion;
- (void)markNotificationsReadWithCompletion:(HYAPICompletion)completion;
- (void)getNotificationsWithPage:(NSInteger)page pageSize:(NSInteger)pageSize completion:(HYAPICompletion)completion;

// Conversations
- (void)getConversationsWithLimit:(NSInteger)limit offset:(NSInteger)offset completion:(HYAPICompletion)completion;

// Chat
- (void)getChatHistoryWithPartnerId:(NSString *)partnerId limit:(NSInteger)limit offset:(NSInteger)offset completion:(HYAPICompletion)completion;
- (void)sendMessageToPartnerId:(NSString *)partnerId content:(NSString *)content type:(NSString *)type extra:(NSString *)extra completion:(HYAPICompletion)completion;
- (void)markChatReadWithPartnerId:(NSString *)partnerId chatType:(NSInteger)chatType completion:(HYAPICompletion)completion;
- (void)searchUsersWithKeyword:(NSString *)keyword completion:(HYAPICompletion)completion;

// Profile
- (void)updateProfileWithData:(NSDictionary *)data completion:(HYAPICompletion)completion;
- (void)followUserWithId:(NSString *)userId completion:(HYAPICompletion)completion;
- (void)unfollowUserWithId:(NSString *)userId completion:(HYAPICompletion)completion;
- (void)getFollowersWithUserId:(NSString *)userId limit:(NSInteger)limit lastId:(NSInteger)lastId completion:(HYAPICompletion)completion;
- (void)getFollowingsWithUserId:(NSString *)userId limit:(NSInteger)limit lastId:(NSInteger)lastId completion:(HYAPICompletion)completion;
- (void)addPhotoWithUrl:(NSString *)photoUrl isWall:(BOOL)isWall completion:(HYAPICompletion)completion;
- (void)deletePhotoWithId:(NSInteger)photoId completion:(HYAPICompletion)completion;
- (void)getLocationsWithCompletion:(HYAPICompletion)completion;
- (void)getInterestsWithCompletion:(HYAPICompletion)completion;
- (void)submitFeedbackWithContent:(NSString *)content completion:(HYAPICompletion)completion;
- (void)getMyPostsWithPage:(NSInteger)page pageSize:(NSInteger)pageSize completion:(HYAPICompletion)completion;

// User
- (void)getUserInfoWithId:(NSString *)userId completion:(HYAPICompletion)completion;
- (void)completeProfileWithData:(NSDictionary *)data completion:(HYAPICompletion)completion;

// Background
- (void)uploadBackgroundImage:(NSData *)imageData completion:(void (^)(NSString * _Nullable imageUrl, NSError * _Nullable error))completion;

// Settings
- (void)updateNotificationSettings:(NSDictionary *)settings completion:(HYAPICompletion)completion;
- (void)updatePrivacySettings:(NSDictionary *)settings completion:(HYAPICompletion)completion;
- (void)changePasswordWithOldPassword:(NSString *)oldPassword newPassword:(NSString *)newPassword completion:(HYAPICompletion)completion;

// Favorites & Matches
- (void)getFavoritesWithPage:(NSInteger)page pageSize:(NSInteger)pageSize completion:(HYAPICompletion)completion;
- (void)getMatchesWithPage:(NSInteger)page pageSize:(NSInteger)pageSize completion:(HYAPICompletion)completion;
- (void)deleteConversationWithId:(NSString *)conversationId completion:(HYAPICompletion)completion;

// Wallet
- (void)getWalletBalanceWithCompletion:(HYAPICompletion)completion;
- (void)getWalletFlowsWithType:(nullable NSString *)type page:(NSInteger)page pageSize:(NSInteger)pageSize completion:(HYAPICompletion)completion;

// Recharge
- (void)getCoinProductsWithCompletion:(HYAPICompletion)completion;
- (void)createRechargeOrderWithProductId:(NSInteger)productId completion:(HYAPICompletion)completion;
- (void)verifyRechargeWithOrderNo:(NSString *)orderNo purchaseToken:(NSString *)purchaseToken completion:(HYAPICompletion)completion;
- (void)getRechargeOrdersWithPage:(NSInteger)page pageSize:(NSInteger)pageSize completion:(HYAPICompletion)completion;

// Subscription / VIP
- (void)getSubscriptionPlansWithCompletion:(HYAPICompletion)completion;
- (void)verifySubscriptionWithPlanId:(NSInteger)planId purchaseToken:(NSString *)purchaseToken completion:(HYAPICompletion)completion;
- (void)getVipStatusWithCompletion:(HYAPICompletion)completion;
- (void)getVipPrivilegesWithCompletion:(HYAPICompletion)completion;

// Checkin
- (void)getCheckinStatusWithCompletion:(HYAPICompletion)completion;
- (void)performCheckinWithCompletion:(HYAPICompletion)completion;

// Gift
- (void)getGiftsWithCompletion:(HYAPICompletion)completion;
- (void)sendGiftToReceiverId:(NSInteger)receiverId giftId:(NSInteger)giftId quantity:(NSInteger)quantity completion:(HYAPICompletion)completion;
- (void)getGiftOrdersWithDirection:(NSString *)direction page:(NSInteger)page pageSize:(NSInteger)pageSize completion:(HYAPICompletion)completion;

// Social
- (void)getWhoLikedMeWithPage:(NSInteger)page pageSize:(NSInteger)pageSize completion:(HYAPICompletion)completion;
- (void)getProfileVisitorsWithPage:(NSInteger)page pageSize:(NSInteger)pageSize completion:(HYAPICompletion)completion;

// Token
@property (nonatomic, strong, nullable) NSString *token;
- (void)setToken:(NSString *)token;
- (void)clearToken;
- (BOOL)isLoggedIn;

// Refresh token
- (void)refreshTokenWithCompletion:(HYAPICompletion)completion;

// Language
- (void)updateAcceptLanguageHeader;

@end

NS_ASSUME_NONNULL_END
