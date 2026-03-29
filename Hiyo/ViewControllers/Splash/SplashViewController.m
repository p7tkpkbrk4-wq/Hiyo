#import "SplashViewController.h"
#import "HYAPIClient.h"
#import "HYWebSocketManager.h"
#import <SDWebImage/SDWebImage.h>

@interface SplashViewController ()

@property (nonatomic, strong) UIView *gradientView;
@property (nonatomic, strong) UILabel *logoLabel;
@property (nonatomic, strong) UILabel *appNameLabel;
@property (nonatomic, strong) UIActivityIndicatorView *loadingIndicator;
@property (nonatomic, assign) BOOL hasNavigated;

@end

@implementation SplashViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.hasNavigated = NO;
    [self setupUI];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self setupGradient];
    [self checkLoginState];
}

- (void)checkLoginState {
    if (self.hasNavigated) return;
    self.hasNavigated = YES;

    // Hide logo briefly while checking
    self.logoLabel.alpha = 0.3f;
    self.appNameLabel.alpha = 0.3f;

    if ([HYAPIClient shared].isLoggedIn) {
        // Token exists - try to refresh it (Android parity)
        [[HYAPIClient shared] refreshTokenWithCompletion:^(NSDictionary *response, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!error && response) {
                    // Token refresh succeeded - connect WebSocket and go to Main
                    [[HYWebSocketManager shared] connect];
                    // Preload default avatars
                    [self preloadDefaultAvatars];
                    if (self.onLoggedIn) {
                        self.onLoggedIn();
                    }
                } else {
                    // Token invalid/expired - clear and go to Welcome
                    [[HYAPIClient shared] clearToken];
                    [[HYWebSocketManager shared] disconnect];
                    if (self.onNotLoggedIn) {
                        self.onNotLoggedIn();
                    }
                }
            });
        }];
    } else {
        // No token - go to Welcome
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (self.onNotLoggedIn) {
                self.onNotLoggedIn();
            }
        });
    }
}

- (void)preloadDefaultAvatars {
    // Preload 8 default avatars (Android parity - instant display on first load)
    NSArray *defaultAvatars = @[
        @"http://statics.hiyochat.live/user/head1.png?imageView2/2/h/400",
        @"http://statics.hiyochat.live/user/head2.png?imageView2/2/h/400",
        @"http://statics.hiyochat.live/user/head3.png?imageView2/2/h/400",
        @"http://statics.hiyochat.live/user/head4.png?imageView2/2/h/400",
        @"http://statics.hiyochat.live/user/head5.png?imageView2/2/h/400",
        @"http://statics.hiyochat.live/user/head6.png?imageView2/2/h/400",
        @"http://statics.hiyochat.live/user/head7.png?imageView2/2/h/400",
        @"http://statics.hiyochat.live/user/head8.png?imageView2/2/h/400"
    ];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for (NSString *url in defaultAvatars) {
            NSURL *nsUrl = [NSURL URLWithString:url];
            if (nsUrl) {
                // Use SDWebImage prefetching if available
                [[SDWebImagePrefetcher sharedImagePrefetcher] prefetchURLs:@[nsUrl]];
            }
        }
    });
}

- (void)setupUI {
    self.view.backgroundColor = [UIColor blackColor];

    // Gradient background
    self.gradientView = [[UIView alloc] init];
    self.gradientView.frame = self.view.bounds;
    [self.view addSubview:self.gradientView];

    // Logo "Hi"
    self.logoLabel = [[UILabel alloc] init];
    self.logoLabel.text = @"Hi";
    self.logoLabel.font = [UIFont systemFontOfSize:80 weight:UIFontWeightBold];
    self.logoLabel.textColor = [UIColor whiteColor];
    self.logoLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.logoLabel];

    // App name
    self.appNameLabel = [[UILabel alloc] init];
    self.appNameLabel.text = @"Hiyo";
    self.appNameLabel.font = [UIFont systemFontOfSize:24 weight:UIFontWeightMedium];
    self.appNameLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.8];
    [self.view addSubview:self.appNameLabel];

    // Loading indicator
    self.loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    self.loadingIndicator.color = [UIColor colorWithWhite:1.0 alpha:0.6];
    self.loadingIndicator.hidesWhenStopped = YES;
    [self.view addSubview:self.loadingIndicator];

    // Layout
    self.logoLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.appNameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.loadingIndicator.translatesAutoresizingMaskIntoConstraints = NO;

    [NSLayoutConstraint activateConstraints:@[
        [self.logoLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.logoLabel.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor constant:-20],
        [self.appNameLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.appNameLabel.topAnchor constraintEqualToAnchor:self.logoLabel.bottomAnchor constant:16],
        [self.loadingIndicator.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.loadingIndicator.topAnchor constraintEqualToAnchor:self.appNameLabel.bottomAnchor constant:24]
    ]];
}

- (void)setupGradient {
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.frame = self.view.bounds;
    gradientLayer.colors = @[
        (id)[UIColor colorWithRed:139/255.0 green:92/255.0 blue:246/255.0 alpha:1].CGColor,
        (id)[UIColor colorWithRed:236/255.0 green:72/255.0 blue:153/255.0 alpha:1].CGColor
    ];
    gradientLayer.startPoint = CGPointMake(0, 0);
    gradientLayer.endPoint = CGPointMake(1, 1);
    [self.gradientView.layer insertSublayer:gradientLayer atIndex:0];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.gradientView.frame = self.view.bounds;
}

@end
