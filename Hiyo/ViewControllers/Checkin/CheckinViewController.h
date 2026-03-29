#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CheckinViewController : UIViewController
@property (nonatomic, copy, nullable) void (^onCheckinComplete)(NSInteger coinsEarned, NSInteger newBalance);
@end

NS_ASSUME_NONNULL_END
