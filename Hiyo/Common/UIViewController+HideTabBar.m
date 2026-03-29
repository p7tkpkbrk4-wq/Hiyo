#import "UIViewController+HideTabBar.h"
#import <objc/runtime.h>

@implementation UIViewController (HideTabBar)

+ (void)load {
    // Swizzle viewDidLoad to hide tab bar for all pushed view controllers
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SEL originalSelector = @selector(viewDidLoad);
        SEL swizzledSelector = @selector(hideTabBar_viewDidLoad);
        Method originalMethod = class_getInstanceMethod(self, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(self, swizzledSelector);
        if (originalMethod && swizzledMethod) {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
    });
}

- (void)hideTabBar_viewDidLoad {
    // Hide tab bar for all pushed view controllers (but not the tab bar root controllers)
    if (self.navigationController && self.navigationController.viewControllers.firstObject != self) {
        self.hidesBottomBarWhenPushed = YES;
    }
    [self hideTabBar_viewDidLoad];
}

@end
