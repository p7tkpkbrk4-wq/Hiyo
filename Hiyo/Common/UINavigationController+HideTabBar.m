#import "UINavigationController+HideTabBar.h"
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

@implementation UINavigationController (HideTabBar)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SEL originalSelector = @selector(pushViewController:animated:);
        SEL swizzledSelector = @selector(hideTabBar_pushViewController:animated:);
        Method originalMethod = class_getInstanceMethod(self, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(self, swizzledSelector);
        if (originalMethod && swizzledMethod) {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
    });
}

- (void)hideTabBar_pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    // Set hidesBottomBarWhenPushed before push so tab bar hides on animation
    viewController.hidesBottomBarWhenPushed = YES;
    [self hideTabBar_pushViewController:viewController animated:animated];
}

@end
