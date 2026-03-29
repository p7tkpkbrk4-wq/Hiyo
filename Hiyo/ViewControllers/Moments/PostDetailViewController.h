#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PostDetailViewController : UIViewController

@property (nonatomic, copy, nullable) void (^onPostDeleted)(void);
@property (nonatomic, copy, nullable) void (^onPostUpdated)(id post);

- (instancetype)initWithPostId:(NSInteger)postId;

@end

NS_ASSUME_NONNULL_END
