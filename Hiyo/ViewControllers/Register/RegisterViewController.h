#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface RegisterViewController : UIViewController

@property (nonatomic, copy) void (^onRegisterSuccess)(void);
@property (nonatomic, copy) void (^onBackClick)(void);

@end

NS_ASSUME_NONNULL_END
