#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, HYFollowListType) {
    HYFollowListTypeFollowers,
    HYFollowListTypeFollowings
};

@interface FollowListViewController : UIViewController

- (instancetype)initWithUserId:(NSString *)userId
                            type:(HYFollowListType)type
                      userName:(NSString *)userName;

@end

NS_ASSUME_NONNULL_END
