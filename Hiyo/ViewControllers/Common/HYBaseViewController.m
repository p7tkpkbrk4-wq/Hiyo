#import "HYBaseViewController.h"
#import "HYColors.h"
#import "HYNotificationConstants.h"

@interface HYBaseViewController ()

@property (nonatomic, strong, readwrite) UIActivityIndicatorView *loadingIndicator;
@property (nonatomic, strong, readwrite) UIView *loadingOverlay;

@end

@implementation HYBaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = DarkBackground;
    [self setupLoadingOverlay];
    [self setupKeyboardDismissal];
    [self setupNotificationObservers];
}

- (void)setupNavigationBarDark {
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    self.navigationController.navigationBar.titleTextAttributes = @{
        NSForegroundColorAttributeName: [UIColor whiteColor]
    };
    if (@available(iOS 15.0, *)) {
        UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
        [appearance configureWithOpaqueBackground];
        appearance.backgroundColor = DarkBackground;
        appearance.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor whiteColor]};
        self.navigationController.navigationBar.standardAppearance = appearance;
        self.navigationController.navigationBar.scrollEdgeAppearance = appearance;
    }
}

- (void)setupLoadingOverlay {
    self.loadingOverlay = [[UIView alloc] init];
    self.loadingOverlay.backgroundColor = [DarkBackground colorWithAlphaComponent:0.7];
    self.loadingOverlay.hidden = YES;
    [self.view addSubview:self.loadingOverlay];
    self.loadingOverlay.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [self.loadingOverlay.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.loadingOverlay.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.loadingOverlay.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.loadingOverlay.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];

    self.loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    self.loadingIndicator.color = [UIColor whiteColor];
    [self.loadingOverlay addSubview:self.loadingIndicator];
    self.loadingIndicator.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [self.loadingIndicator.centerXAnchor constraintEqualToAnchor:self.loadingOverlay.centerXAnchor],
        [self.loadingIndicator.centerYAnchor constraintEqualToAnchor:self.loadingOverlay.centerYAnchor]
    ]];
}

- (void)setupKeyboardDismissal {
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    tap.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tap];
}

- (void)setupNotificationObservers {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleNeedLogin:)
                                                 name:HYNeedLoginNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleProfileUpdate:)
                                                 name:HYProfileDidUpdateNotification
                                               object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Public Methods

- (void)showLoading {
    self.loadingOverlay.hidden = NO;
    [self.loadingIndicator startAnimating];
}

- (void)hideLoading {
    self.loadingOverlay.hidden = YES;
    [self.loadingIndicator stopAnimating];
}

- (void)showAlert:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showToast:(NSString *)message {
    [self showToast:message duration:2.0 color:DarkCard];
}

- (void)showToast:(NSString *)message duration:(NSTimeInterval)duration color:(UIColor *)backgroundColor {
    UILabel *toast = [[UILabel alloc] init];
    toast.text = message;
    toast.font = [UIFont systemFontOfSize:14];
    toast.textColor = [UIColor whiteColor];
    toast.backgroundColor = backgroundColor;
    toast.textAlignment = NSTextAlignmentCenter;
    toast.layer.cornerRadius = 20;
    toast.clipsToBounds = YES;
    toast.alpha = 0;
    [self.view addSubview:toast];

    CGSize maxSize = CGSizeMake(self.view.bounds.size.width - 80, 100);
    CGSize size = [message sizeWithAttributes:@{NSFontAttributeName: toast.font}];
    CGFloat width = MIN(size.width + 40, maxSize.width);

    toast.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [toast.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [toast.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-40],
        [toast.widthAnchor constraintGreaterThanOrEqualToConstant:width],
        [toast.heightAnchor constraintEqualToConstant:40]
    ]];

    [UIView animateWithDuration:0.3 animations:^{
        toast.alpha = 1;
    } completion:^(BOOL finished) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.3 animations:^{
                toast.alpha = 0;
            } completion:^(BOOL finished) {
                [toast removeFromSuperview];
            }];
        });
    }];
}

- (void)dismissKeyboard {
    [self.view endEditing:YES];
}

#pragma mark - Notification Handlers

- (void)handleNeedLogin:(NSNotification *)notification {
    // Subclasses override if needed
}

- (void)handleProfileUpdate:(NSNotification *)notification {
    // Subclasses override if needed
}

@end
