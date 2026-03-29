#import "LoginViewController.h"
#import "HYAPIClient.h"
#import <Masonry/Masonry.h>

@interface LoginViewController ()

@property (nonatomic, strong) UIView *gradientView;
@property (nonatomic, strong) UIButton *backButton;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UIView *formCard;
@property (nonatomic, strong) UITextField *usernameTextField;
@property (nonatomic, strong) UITextField *passwordTextField;
@property (nonatomic, strong) UIButton *loginButton;
@property (nonatomic, strong) UIActivityIndicatorView *loadingIndicator;
@property (nonatomic, strong) UIButton *registerButton;
@property (nonatomic, strong) UILabel *errorLabel;

@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"登录";
    [self setupUI];
}

- (void)setupUI {
    self.view.backgroundColor = [UIColor blackColor];

    // Gradient background view
    self.gradientView = [[UIView alloc] init];
    [self.view addSubview:self.gradientView];

    // Back button
    self.backButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.backButton setImage:[UIImage systemImageNamed:@"chevron.left"] forState:UIControlStateNormal];
    self.backButton.tintColor = [UIColor whiteColor];
    [self.backButton addTarget:self action:@selector(backTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.backButton];

    // Title
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.text = @"欢迎回来！";
    self.titleLabel.font = [UIFont systemFontOfSize:32 weight:UIFontWeightBold];
    self.titleLabel.textColor = [UIColor whiteColor];
    [self.view addSubview:self.titleLabel];

    // Subtitle
    self.subtitleLabel = [[UILabel alloc] init];
    self.subtitleLabel.text = @"登录你的账号";
    self.subtitleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightRegular];
    self.subtitleLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.6];
    [self.view addSubview:self.subtitleLabel];

    // Form card
    self.formCard = [[UIView alloc] init];
    self.formCard.backgroundColor = [UIColor clearColor];
    self.formCard.layer.cornerRadius = 24;
    [self.view addSubview:self.formCard];

    // Username text field
    self.usernameTextField = [[UITextField alloc] init];
    self.usernameTextField.placeholder = @"用户名";
    self.usernameTextField.borderStyle = UITextBorderStyleNone;
    self.usernameTextField.backgroundColor = [UIColor whiteColor];
    self.usernameTextField.textColor = [UIColor colorWithWhite:0.1 alpha:1.0];
    self.usernameTextField.layer.cornerRadius = 12;
    self.usernameTextField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 16, 0)];
    self.usernameTextField.leftViewMode = UITextFieldViewModeAlways;
    self.usernameTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.usernameTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    [self.formCard addSubview:self.usernameTextField];

    // Password text field
    self.passwordTextField = [[UITextField alloc] init];
    self.passwordTextField.placeholder = @"密码";
    self.passwordTextField.secureTextEntry = YES;
    self.passwordTextField.borderStyle = UITextBorderStyleNone;
    self.passwordTextField.backgroundColor = [UIColor whiteColor];
    self.passwordTextField.textColor = [UIColor colorWithWhite:0.1 alpha:1.0];
    self.passwordTextField.layer.cornerRadius = 12;
    self.passwordTextField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 16, 0)];
    self.passwordTextField.leftViewMode = UITextFieldViewModeAlways;
    [self.formCard addSubview:self.passwordTextField];

    // Error label
    self.errorLabel = [[UILabel alloc] init];
    self.errorLabel.font = [UIFont systemFontOfSize:14];
    self.errorLabel.textColor = [UIColor systemRedColor];
    self.errorLabel.hidden = YES;
    [self.formCard addSubview:self.errorLabel];

    // Login button
    self.loginButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.loginButton setTitle:@"登录" forState:UIControlStateNormal];
    [self.loginButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.loginButton.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    self.loginButton.layer.cornerRadius = 12;
    [self.loginButton addTarget:self action:@selector(loginTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.formCard addSubview:self.loginButton];

    // Register button
    self.registerButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.registerButton setTitle:@"没有账号？立即注册" forState:UIControlStateNormal];
    [self.registerButton setTitleColor:[UIColor systemPinkColor] forState:UIControlStateNormal];
    self.registerButton.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    [self.registerButton addTarget:self action:@selector(registerTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.formCard addSubview:self.registerButton];

    // Loading indicator
    self.loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    self.loadingIndicator.color = [UIColor whiteColor];
    self.loadingIndicator.hidesWhenStopped = YES;
    [self.loginButton addSubview:self.loadingIndicator];

    [self setupConstraints];
}

- (void)setupConstraints {
    [self.gradientView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];

    [self.backButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(8);
        make.left.equalTo(self.view).offset(8);
        make.width.height.equalTo(@44);
    }];

    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.backButton.mas_bottom).offset(24);
        make.left.equalTo(self.view).offset(24);
    }];

    [self.subtitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(8);
        make.left.equalTo(self.view).offset(24);
    }];

    [self.formCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.subtitleLabel.mas_bottom).offset(32);
        make.left.equalTo(self.view).offset(24);
        make.right.equalTo(self.view).offset(-24);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-24);
    }];

    [self.usernameTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.formCard).offset(32);
        make.left.equalTo(self.formCard).offset(20);
        make.right.equalTo(self.formCard).offset(-20);
        make.height.equalTo(@50);
    }];

    [self.passwordTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.usernameTextField.mas_bottom).offset(16);
        make.left.equalTo(self.formCard).offset(20);
        make.right.equalTo(self.formCard).offset(-20);
        make.height.equalTo(@50);
    }];

    [self.errorLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.passwordTextField.mas_bottom).offset(8);
        make.left.equalTo(self.formCard).offset(20);
        make.right.equalTo(self.formCard).offset(-20);
    }];

    [self.loginButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.errorLabel.mas_bottom).offset(24);
        make.left.equalTo(self.formCard).offset(20);
        make.right.equalTo(self.formCard).offset(-20);
        make.height.equalTo(@50);
    }];

    [self.registerButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.loginButton.mas_bottom).offset(16);
        make.centerX.equalTo(self.formCard);
        make.height.equalTo(@30);
    }];

    [self.loadingIndicator mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.loginButton);
    }];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.gradientView.frame = self.view.bounds;
    for (CALayer *layer in self.gradientView.layer.sublayers) {
        if ([layer isKindOfClass:[CAGradientLayer class]]) {
            layer.frame = self.view.bounds;
        }
    }
    for (CALayer *layer in self.loginButton.layer.sublayers) {
        if ([layer isKindOfClass:[CAGradientLayer class]]) {
            layer.frame = self.loginButton.bounds;
        }
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setupGradientIfNeeded];
}

- (void)setupGradientIfNeeded {
    // Only add gradient once
    for (CALayer *layer in self.gradientView.layer.sublayers) {
        if ([layer isKindOfClass:[CAGradientLayer class]]) return;
    }

    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.frame = CGRectEqualToRect(self.gradientView.bounds, CGRectZero) ? self.view.bounds : self.gradientView.bounds;
    gradientLayer.colors = @[
        (id)[UIColor colorWithRed:139/255.0 green:92/255.0 blue:246/255.0 alpha:1].CGColor,
        (id)[UIColor colorWithRed:236/255.0 green:72/255.0 blue:153/255.0 alpha:1].CGColor
    ];
    gradientLayer.startPoint = CGPointMake(0, 0);
    gradientLayer.endPoint = CGPointMake(1, 1);
    [self.gradientView.layer insertSublayer:gradientLayer atIndex:0];

    // Button gradient
    CAGradientLayer *buttonGradient = [CAGradientLayer layer];
    buttonGradient.frame = self.loginButton.bounds;
    buttonGradient.colors = @[
        (id)[UIColor colorWithRed:236/255.0 green:72/255.0 blue:153/255.0 alpha:1].CGColor,
        (id)[UIColor colorWithRed:139/255.0 green:92/255.0 blue:246/255.0 alpha:1].CGColor
    ];
    buttonGradient.startPoint = CGPointMake(0, 0);
    buttonGradient.endPoint = CGPointMake(1, 1);
    buttonGradient.cornerRadius = 12;
    [self.loginButton.layer insertSublayer:buttonGradient atIndex:0];
}

- (void)backTapped {
    if (self.onBackClick) {
        self.onBackClick();
    }
}

- (void)loginTapped {
    NSString *username = self.usernameTextField.text;
    NSString *password = self.passwordTextField.text;

    if (username.length == 0 || password.length == 0) {
        self.errorLabel.text = @"请输入用户名和密码";
        self.errorLabel.hidden = NO;
        return;
    }

    [self setLoading:YES];
    self.errorLabel.hidden = YES;

    // Call real API
    [[HYAPIClient shared] loginWithEmail:username password:password completion:^(NSDictionary *response, NSError *error) {
        [self setLoading:NO];

        if (error) {
            self.errorLabel.text = error.localizedDescription;
            self.errorLabel.hidden = NO;
            return;
        }

        if (response) {
            // Save token (token is inside data object)
            NSDictionary *data = response[@"data"];
            NSString *token = [data isKindOfClass:[NSDictionary class]] ? data[@"token"] : nil;
            if (token) {
                [[HYAPIClient shared] setToken:token];
            }

            // Save userId (Android parity)
            if ([data isKindOfClass:[NSDictionary class]]) {
                NSString *userId = data[@"id"];
                if (!userId || ![userId isKindOfClass:[NSString class]]) {
                    id userIdVal = data[@"id"];
                    if ([userIdVal isKindOfClass:[NSNumber class]]) {
                        userId = [NSString stringWithFormat:@"%@", userIdVal];
                    }
                }
                if (userId) {
                    [[NSUserDefaults standardUserDefaults] setObject:userId forKey:@"hiyo_user_id"];
                }
            }

            if (self.onLoginSuccess) {
                self.onLoginSuccess();
            }
        }
    }];
}

- (void)setLoading:(BOOL)loading {
    self.loginButton.enabled = !loading;
    self.usernameTextField.enabled = !loading;
    self.passwordTextField.enabled = !loading;

    if (loading) {
        [self.loginButton setTitle:@"" forState:UIControlStateNormal];
        [self.loadingIndicator startAnimating];
    } else {
        [self.loginButton setTitle:@"登录" forState:UIControlStateNormal];
        [self.loadingIndicator stopAnimating];
    }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

- (void)registerTapped {
    if (self.onRegisterClick) {
        self.onRegisterClick();
    }
}

@end
