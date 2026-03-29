#ifndef HYRouter_h
#define HYRouter_h

#import <UIKit/UIKit.h>
#import "../ViewControllers/Profile/FollowListViewController.h"

typedef NS_ENUM(NSInteger, HYRouterSource) {
    HYRouterSourceNavigation,
    HYRouterSourceTabBar,
    HYRouterSourceModal
};

@interface HYRouter : NSObject

+ (UINavigationController *)topNavigationController;

+ (void)pushViewController:(UIViewController *)vc animated:(BOOL)animated;
+ (void)presentViewController:(UIViewController *)vc animated:(BOOL)animated completion:(void (^)(void))completion;
+ (void)popViewControllerAnimated:(BOOL)animated;
+ (void)popToRootAnimated:(BOOL)animated;
+ (void)dismissToRootAnimated:(BOOL)animated completion:(void (^)(void))completion;

+ (void)pushEditProfile;
+ (void)pushUserProfileWithUserId:(NSString *)userId;
+ (void)pushSettings;
+ (void)pushMyProfile;
+ (void)pushChatWithUserId:(NSString *)userId name:(NSString *)name avatar:(NSString *)avatar;
+ (void)pushFollowListWithUserId:(NSString *)userId type:(HYFollowListType)type title:(NSString *)title;
+ (void)pushFullscreenPhoto:(NSArray<NSString *> *)urls startIndex:(NSInteger)index;
+ (void)pushFeedback;
+ (void)pushAbout;
+ (void)pushPrivacySettings;
+ (void)pushNotificationSettings;
+ (void)pushLanguageSettings;
+ (void)pushUserAgreement;
+ (void)pushHelpCenter;

+ (void)showLoginFromSource:(HYRouterSource)source;

@end

#endif
