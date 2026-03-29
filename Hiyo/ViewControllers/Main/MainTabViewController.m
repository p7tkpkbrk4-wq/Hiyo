#import "MainTabViewController.h"
#import "MeetViewController.h"
#import "MomentsViewController.h"
#import "MessagesViewController.h"
#import "MyProfileViewController.h"
#import "HYWebSocketManager.h"
#import "HYAPIClient.h"

@interface MainTabViewController ()

@property (nonatomic, strong) UITabBarItem *messagesTabItem;

@end

@implementation MainTabViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupAppearance];
    [self setupViewControllers];
    [self setupNotifications];
    [self refreshUnreadBadge];
}

- (void)setupAppearance {
    if (@available(iOS 15.0, *)) {
        UITabBarAppearance *appearance = [[UITabBarAppearance alloc] init];
        [appearance configureWithOpaqueBackground];
        appearance.backgroundColor = [UIColor systemBackgroundColor];

        appearance.stackedLayoutAppearance.normal.iconColor = [UIColor systemGrayColor];
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = @{
            NSForegroundColorAttributeName: [UIColor systemGrayColor]
        };

        appearance.stackedLayoutAppearance.selected.iconColor = [UIColor systemPinkColor];
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = @{
            NSForegroundColorAttributeName: [UIColor systemPinkColor]
        };

        self.tabBar.standardAppearance = appearance;
        self.tabBar.scrollEdgeAppearance = appearance;
    } else {
        self.tabBar.tintColor = [UIColor systemPinkColor];
        self.tabBar.unselectedItemTintColor = [UIColor systemGrayColor];
    }

    // Add blur effect
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterial];
    UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    blurView.frame = self.tabBar.bounds;
    blurView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.tabBar insertSubview:blurView atIndex:0];
}

- (void)setupViewControllers {
    // Meet - Match Cards
    MeetViewController *meetVC = [[MeetViewController alloc] init];
    UINavigationController *meetNav = [[UINavigationController alloc] initWithRootViewController:meetVC];
    meetNav.navigationBar.prefersLargeTitles = NO;
    meetNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"遇见"
                                                       image:[UIImage systemImageNamed:@"heart"]
                                               selectedImage:[UIImage systemImageNamed:@"heart.fill"]];

    // Moments - Social Feed
    MomentsViewController *momentsVC = [[MomentsViewController alloc] init];
    UINavigationController *momentsNav = [[UINavigationController alloc] initWithRootViewController:momentsVC];
    momentsNav.navigationBar.prefersLargeTitles = NO;
    momentsNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"动态广场"
                                                          image:[UIImage systemImageNamed:@"message"]
                                                  selectedImage:[UIImage systemImageNamed:@"message.fill"]];

    // Messages - Chat List
    MessagesViewController *messagesVC = [[MessagesViewController alloc] init];
    UINavigationController *messagesNav = [[UINavigationController alloc] initWithRootViewController:messagesVC];
    messagesNav.navigationBar.prefersLargeTitles = YES;
    messagesNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"消息"
                                                            image:[UIImage systemImageNamed:@"bubble.left.and.bubble.right"]
                                                    selectedImage:[UIImage systemImageNamed:@"bubble.left.and.bubble.right.fill"]];

    // Profile
    MyProfileViewController *profileVC = [[MyProfileViewController alloc] init];
    UINavigationController *profileNav = [[UINavigationController alloc] initWithRootViewController:profileVC];
    profileNav.navigationBar.prefersLargeTitles = YES;
    profileNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"我的"
                                                          image:[UIImage systemImageNamed:@"person"]
                                                  selectedImage:[UIImage systemImageNamed:@"person.fill"]];

    self.viewControllers = @[meetNav, momentsNav, messagesNav, profileNav];

    self.messagesTabItem = messagesNav.tabBarItem;
}

- (void)setupNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshUnreadBadge)
                                                 name:HYWebSocketMessageReceivedNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshUnreadBadge)
                                                 name:@"HYConversationsUpdatedNotification"
                                               object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)refreshUnreadBadge {
    [[HYAPIClient shared] getUnreadCountWithCompletion:^(NSDictionary *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSInteger total = 0;
            if (!error && [response isKindOfClass:[NSDictionary class]]) {
                NSDictionary *data = response[@"data"];
                if ([data isKindOfClass:[NSDictionary class]]) {
                    total = [data[@"total"] integerValue];
                }
            }
            if (total > 0) {
                if (total > 99) {
                    self.messagesTabItem.badgeValue = @"99+";
                } else {
                    self.messagesTabItem.badgeValue = [NSString stringWithFormat:@"%ld", (long)total];
                }
                self.messagesTabItem.badgeColor = [UIColor colorWithRed:1.0 green:0.42 blue:0.616 alpha:1.0];
            } else {
                self.messagesTabItem.badgeValue = nil;
            }
        });
    }];
}

@end
