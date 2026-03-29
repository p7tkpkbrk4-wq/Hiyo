#import "HYBaseViewController.h"
#import "HYColors.h"
#import "HYNotificationConstants.h"
#import <SVProgressHUD/SVProgressHUD.h>

@implementation HYBaseViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        self.hidesBottomBarWhenPushed = YES;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = DarkBackground;
    [self setupKeyboardDismissal];
    [self setupNotificationObservers];
    [self setupSVProgressHUD];
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

- (void)setupSVProgressHUD {
    [SVProgressHUD setDefaultStyle:SVProgressHUDStyleDark];
    [SVProgressHUD setCornerRadius:12];
    [SVProgressHUD setFont:[UIFont systemFontOfSize:14]];
    [SVProgressHUD setForegroundColor:[UIColor whiteColor]];
    [SVProgressHUD setBackgroundColor:[DarkCard colorWithAlphaComponent:0.9]];
    [SVProgressHUD setMinimumDismissTimeInterval:2.0];
    [SVProgressHUD setRingThickness:2.5];
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
    [SVProgressHUD show];
}

- (void)hideLoading {
    [SVProgressHUD dismiss];
}

- (void)showAlert:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showToast:(NSString *)message {
    [SVProgressHUD showInfoWithStatus:message];
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
