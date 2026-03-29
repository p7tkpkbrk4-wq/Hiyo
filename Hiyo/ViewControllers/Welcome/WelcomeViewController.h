#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WelcomeViewController : UIViewController

@property (nonatomic, copy) void (^onGuestStart)(void);
@property (nonatomic, copy) void (^onLoginClick)(void);

@end

NS_ASSUME_NONNULL_END
