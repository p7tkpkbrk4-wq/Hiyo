#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SplashViewController : UIViewController

// Called when user is logged in (navigate to MainApp directly)
@property (nonatomic, copy) void (^onLoggedIn)(void);
// Called when user is not logged in (navigate to Welcome)
@property (nonatomic, copy) void (^onNotLoggedIn)(void);

@end

NS_ASSUME_NONNULL_END
