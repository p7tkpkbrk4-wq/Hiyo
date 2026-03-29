#import <UIKit/UIKit.h>

@class HYPost;

NS_ASSUME_NONNULL_BEGIN

extern NSNotificationName const HYPostCellDidTapLikeNotification;
extern NSNotificationName const HYPostCellDidTapCommentNotification;

@interface HYPostCell : UITableViewCell

@property (nonatomic, copy, nullable) void (^onLikeTapped)(HYPost *post);
@property (nonatomic, copy, nullable) void (^onCommentTapped)(HYPost *post);
@property (nonatomic, copy, nullable) void (^onAvatarTapped)(HYPost *post);

- (void)configWithPost:(HYPost *)post;
- (void)updateLikeState:(BOOL)isLiked likesCount:(NSInteger)count;

@end

NS_ASSUME_NONNULL_END
