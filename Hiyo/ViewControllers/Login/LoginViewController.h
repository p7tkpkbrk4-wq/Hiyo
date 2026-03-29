#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LoginViewController : UIViewController

@property (nonatomic, copy) void (^onLoginSuccess)(void);
@property (nonatomic, copy) void (^onRegisterClick)(void);
@property (nonatomic, copy) void (^onBackClick)(void);

@end

NS_ASSUME_NONNULL_END
