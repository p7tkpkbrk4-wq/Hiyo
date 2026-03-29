#ifndef HYBaseViewController_h
#define HYBaseViewController_h

#import <UIKit/UIKit.h>
#import "HYColors.h"

@interface HYBaseViewController : UIViewController

- (void)showLoading;
- (void)hideLoading;
- (void)showAlert:(NSString *)message;
- (void)showToast:(NSString *)message;
- (void)setupNavigationBarDark;
- (void)dismissKeyboard;

@end

#endif
