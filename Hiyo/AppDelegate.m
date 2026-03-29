//
//  AppDelegate.m
//  Hiyo
//
//  Created by ningpeichao on 2026/3/14.
//

#import "AppDelegate.h"
#import "SplashViewController.h"
#import "WelcomeViewController.h"
#import "LoginViewController.h"
#import "RegisterViewController.h"
#import "CompleteProfileViewController.h"
#import "MainTabViewController.h"
#import "HYAPIClient.h"
#import "HYWebSocketManager.h"
#import "HYNotificationConstants.h"

@interface AppDelegate ()

@property (nonatomic, strong) SplashViewController *splashVC;
@property (nonatomic, strong) WelcomeViewController *welcomeVC;
@property (nonatomic, strong) LoginViewController *loginVC;
@property (nonatomic, strong) RegisterViewController *registerVC;
@property (nonatomic, strong) CompleteProfileViewController *completeProfileVC;
@property (nonatomic, strong) MainTabViewController *mainTabVC;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];

    // Listen for login required notification
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleNeedLogin)
                                                 name:HYNeedLoginNotification
                                               object:nil];

    // Listen for language changes to update Accept-Language header (Android parity)
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleLanguageChange:)
                                                 name:HYLanguageDidChangeNotification
                                               object:nil];

    // Start with Splash screen
    [self showSplash];

    return YES;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)handleLanguageChange:(NSNotification *)notification {
    [[HYAPIClient shared] updateAcceptLanguageHeader];
}

- (void)handleNeedLogin {
    // Disconnect WebSocket on logout
    [[HYWebSocketManager shared] disconnect];

    // If already on main app (MainTabViewController), present login as modal
    // so user can return to their current screen after login/cancel
    if ([self.window.rootViewController isKindOfClass:[MainTabViewController class]]) {
        [self presentLoginModal];
    } else {
        [self showLogin];
    }
}

- (void)presentLoginModal {
    // Dismiss any existing modal first
    UIViewController *presenting = self.window.rootViewController;
    while (presenting.presentedViewController) {
        presenting = presenting.presentedViewController;
    }

    self.loginVC = [[LoginViewController alloc] init];
    __weak typeof(self) weakSelf = self;

    self.loginVC.onLoginSuccess = ^{
        // Dismiss modal, user stays on main app (will auto-refresh)
        UIViewController *vc = weakSelf.window.rootViewController;
        while (vc.presentedViewController) {
            vc = vc.presentedViewController;
        }
        [vc dismissViewControllerAnimated:YES completion:nil];
    };

    self.loginVC.onRegisterClick = ^{
        // Present register on top of login modal
        [weakSelf presentRegisterModalOver:weakSelf.loginVC];
    };

    self.loginVC.onBackClick = ^{
        // Just dismiss the login modal, return to current screen
        UIViewController *vc = weakSelf.window.rootViewController;
        while (vc.presentedViewController) {
            vc = vc.presentedViewController;
        }
        [vc dismissViewControllerAnimated:YES completion:nil];
    };

    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:self.loginVC];
    nav.modalPresentationStyle = UIModalPresentationFullScreen;
    [presenting presentViewController:nav animated:YES completion:nil];
}

- (void)presentRegisterModalOver:(UIViewController *)parent {
    self.registerVC = [[RegisterViewController alloc] init];
    __weak typeof(self) weakSelf = self;

    self.registerVC.onRegisterSuccess = ^{
        // Dismiss register, then dismiss login, return to main app
        [parent dismissViewControllerAnimated:NO completion:^{
            UIViewController *vc = weakSelf.window.rootViewController;
            while (vc.presentedViewController) {
                vc = vc.presentedViewController;
            }
            [vc dismissViewControllerAnimated:YES completion:nil];
        }];
    };

    self.registerVC.onBackClick = ^{
        [parent dismissViewControllerAnimated:YES completion:nil];
    };

    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:self.registerVC];
    nav.modalPresentationStyle = UIModalPresentationFullScreen;
    [parent presentViewController:nav animated:YES completion:nil];
}

- (void)showSplash {
    self.splashVC = [[SplashViewController alloc] init];
    __weak typeof(self) weakSelf = self;

    self.splashVC.onLoggedIn = ^{
        // User is logged in - skip Welcome, go directly to Main
        [weakSelf showMainApp];
    };

    self.splashVC.onNotLoggedIn = ^{
        // Not logged in - show Welcome screen
        [weakSelf showWelcome];
    };

    self.window.rootViewController = self.splashVC;
    [self.window makeKeyAndVisible];
}

- (void)showWelcome {
    self.welcomeVC = [[WelcomeViewController alloc] init];
    __weak typeof(self) weakSelf = self;

    self.welcomeVC.onGuestStart = ^{
        [weakSelf showMainApp];
    };

    self.welcomeVC.onLoginClick = ^{
        [weakSelf showLogin];
    };

    [UIView transitionWithView:self.window
                      duration:0.3
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
        self.window.rootViewController = self.welcomeVC;
    } completion:nil];
}

- (void)showLogin {
    self.loginVC = [[LoginViewController alloc] init];
    __weak typeof(self) weakSelf = self;

    self.loginVC.onLoginSuccess = ^{
        [weakSelf showMainApp];
    };

    self.loginVC.onRegisterClick = ^{
        [weakSelf showRegister];
    };

    self.loginVC.onBackClick = ^{
        [weakSelf showWelcome];
    };

    [UIView transitionWithView:self.window
                      duration:0.3
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
        self.window.rootViewController = self.loginVC;
    } completion:nil];
}

- (void)showRegister {
    self.registerVC = [[RegisterViewController alloc] init];
    __weak typeof(self) weakSelf = self;

    self.registerVC.onRegisterSuccess = ^{
        [weakSelf showCompleteProfile];
    };

    self.registerVC.onBackClick = ^{
        [weakSelf showLogin];
    };

    [UIView transitionWithView:self.window
                      duration:0.3
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
        self.window.rootViewController = self.registerVC;
    } completion:nil];
}

- (void)showCompleteProfile {
    self.completeProfileVC = [[CompleteProfileViewController alloc] init];
    __weak typeof(self) weakSelf = self;

    self.completeProfileVC.onComplete = ^{
        [weakSelf showMainApp];
    };

    [UIView transitionWithView:self.window
                      duration:0.3
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
        self.window.rootViewController = self.completeProfileVC;
    } completion:nil];
}

- (void)showMainApp {
    self.mainTabVC = [[MainTabViewController alloc] init];

    [UIView transitionWithView:self.window
                      duration:0.5
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
        self.window.rootViewController = self.mainTabVC;
    } completion:^(BOOL finished) {
        // Connect WebSocket after login
        [[HYWebSocketManager shared] connect];
    }];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Reconnect WebSocket when app comes to foreground
    if ([HYAPIClient shared].isLoggedIn) {
        [[HYWebSocketManager shared] reconnect];
    }
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // WebSocket stays connected in background for a while
}

@end
