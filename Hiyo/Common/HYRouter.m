#import "HYRouter.h"
#import "LoginViewController.h"
#import "EditProfileViewController.h"
#import "UserProfileViewController.h"
#import "SettingsViewController.h"
#import "MyProfileViewController.h"
#import "FollowListViewController.h"
#import "FullscreenPhotoViewController.h"
#import "FeedbackViewController.h"
#import "AboutViewController.h"
#import "PrivacySettingsViewController.h"
#import "NotificationSettingsViewController.h"
#import "LanguageSettingsViewController.h"
#import "UserAgreementViewController.h"
#import "HelpCenterViewController.h"
#import "ChatDetailViewController.h"
#import "AccountSettingsViewController.h"

@implementation HYRouter

+ (UINavigationController *)topNavigationController {
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    if (!window) return nil;

    UIViewController *root = window.rootViewController;
    if (!root) return nil;

    if ([root isKindOfClass:[UINavigationController class]]) {
        return (UINavigationController *)root;
    }

    if ([root isKindOfClass:[UITabBarController class]]) {
        UITabBarController *tab = (UITabBarController *)root;
        UIViewController *selected = tab.selectedViewController;
        if ([selected isKindOfClass:[UINavigationController class]]) {
            return (UINavigationController *)selected;
        }
        return nil;
    }

    if ([root isKindOfClass:[UINavigationController class]]) {
        return (UINavigationController *)root;
    }

    return nil;
}

+ (void)pushViewController:(UIViewController *)vc animated:(BOOL)animated {
    UINavigationController *nav = [self topNavigationController];
    if (nav) {
        [nav pushViewController:vc animated:animated];
    } else {
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        if (window.rootViewController) {
            UINavigationController *navVC = [[UINavigationController alloc] initWithRootViewController:vc];
            [window.rootViewController presentViewController:navVC animated:animated completion:nil];
        }
    }
}

+ (void)presentViewController:(UIViewController *)vc animated:(BOOL)animated completion:(void (^)(void))completion {
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    if (!window || !window.rootViewController) return;

    UIViewController *presenter = window.rootViewController;
    while (presenter.presentedViewController) {
        presenter = presenter.presentedViewController;
    }
    [presenter presentViewController:vc animated:animated completion:completion];
}

+ (void)popViewControllerAnimated:(BOOL)animated {
    UINavigationController *nav = [self topNavigationController];
    if (nav) {
        [nav popViewControllerAnimated:animated];
    }
}

+ (void)popToRootAnimated:(BOOL)animated {
    UINavigationController *nav = [self topNavigationController];
    if (nav) {
        [nav popToRootViewControllerAnimated:animated];
    }
}

+ (void)dismissToRootAnimated:(BOOL)animated completion:(void (^)(void))completion {
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    if (!window || !window.rootViewController) {
        if (completion) completion();
        return;
    }

    UIViewController *presenter = window.rootViewController;
    while (presenter.presentedViewController) {
        presenter = presenter.presentedViewController;
    }
    [presenter dismissViewControllerAnimated:animated completion:completion];
}

#pragma mark - Navigation Helpers

+ (void)pushEditProfile {
    EditProfileViewController *vc = [[EditProfileViewController alloc] init];
    [self pushViewController:vc animated:YES];
}

+ (void)pushUserProfileWithUserId:(NSString *)userId {
    UserProfileViewController *vc = [[UserProfileViewController alloc] initWithUserId:userId];
    [self pushViewController:vc animated:YES];
}

+ (void)pushSettings {
    SettingsViewController *vc = [[SettingsViewController alloc] init];
    [self pushViewController:vc animated:YES];
}

+ (void)pushMyProfile {
    MyProfileViewController *vc = [[MyProfileViewController alloc] init];
    [self pushViewController:vc animated:YES];
}

+ (void)pushChatWithUserId:(NSString *)userId name:(NSString *)name avatar:(NSString *)avatar {
    ChatDetailViewController *vc = [[ChatDetailViewController alloc] initWithPartnerId:userId partnerName:name partnerAvatar:avatar];
    UINavigationController *nav = [self topNavigationController];
    if (nav) {
        [nav pushViewController:vc animated:YES];
    }
}

+ (void)pushFollowListWithUserId:(NSString *)userId type:(HYFollowListType)type title:(NSString *)title {
    FollowListViewController *vc = [[FollowListViewController alloc] initWithUserId:userId type:type userName:title];
    vc.title = title;
    [self pushViewController:vc animated:YES];
}

+ (void)pushFullscreenPhoto:(NSArray<NSString *> *)urls startIndex:(NSInteger)index {
    FullscreenPhotoViewController *vc = [[FullscreenPhotoViewController alloc] initWithPhotoUrls:urls startIndex:index];
    vc.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:vc animated:YES completion:nil];
}

+ (void)pushFeedback {
    FeedbackViewController *vc = [[FeedbackViewController alloc] init];
    [self pushViewController:vc animated:YES];
}

+ (void)pushAbout {
    AboutViewController *vc = [[AboutViewController alloc] init];
    [self pushViewController:vc animated:YES];
}

+ (void)pushPrivacySettings {
    PrivacySettingsViewController *vc = [[PrivacySettingsViewController alloc] init];
    [self pushViewController:vc animated:YES];
}

+ (void)pushNotificationSettings {
    NotificationSettingsViewController *vc = [[NotificationSettingsViewController alloc] init];
    [self pushViewController:vc animated:YES];
}

+ (void)pushLanguageSettings {
    LanguageSettingsViewController *vc = [[LanguageSettingsViewController alloc] init];
    [self pushViewController:vc animated:YES];
}

+ (void)pushUserAgreement {
    UserAgreementViewController *vc = [[UserAgreementViewController alloc] init];
    [self pushViewController:vc animated:YES];
}

+ (void)pushHelpCenter {
    HelpCenterViewController *vc = [[HelpCenterViewController alloc] init];
    [self pushViewController:vc animated:YES];
}

+ (void)showLoginFromSource:(HYRouterSource)source {
    LoginViewController *vc = [[LoginViewController alloc] init];
    vc.onLoginSuccess = ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"HYNeedLoginNotification" object:nil];
    };
    [self dismissToRootAnimated:NO completion:^{
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        nav.modalPresentationStyle = UIModalPresentationFullScreen;
        [self presentViewController:nav animated:YES completion:nil];
    }];
}

@end
