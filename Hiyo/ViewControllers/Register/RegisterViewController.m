#import "RegisterViewController.h"
#import "HYAPIClient.h"
#import <Masonry/Masonry.h>
#import <PhotosUI/PhotosUI.h>

@interface RegisterViewController () <PHPickerViewControllerDelegate>

@property (nonatomic, strong) UIView *gradientView;
@property (nonatomic, strong) UIButton *backButton;
@property (nonatomic, strong) UILabel *titleLabel;

@property (nonatomic, strong) UIView *avatarContainer;
@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic, strong) UILabel *avatarHintLabel;

@property (nonatomic, strong) UITextField *emailTextField;
@property (nonatomic, strong) UITextField *codeTextField;
@property (nonatomic, strong) UIButton *sendCodeButton;
@property (nonatomic, strong) UITextField *usernameTextField;
@property (nonatomic, strong) UITextField *passwordTextField;

@property (nonatomic, strong) UIButton *registerButton;
@property (nonatomic, strong) UILabel *loginLinkLabel;
@property (nonatomic, strong) UIActivityIndicatorView *loadingIndicator;

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIView *codeContainer;
@property (nonatomic, strong) UILabel *errorLabel;

@property (nonatomic, strong) UIImage *selectedAvatarImage;
@property (nonatomic, strong) NSString *uploadedAvatarUrl;
@property (nonatomic, strong) UIActivityIndicatorView *avatarLoadingIndicator;

@end

@implementation RegisterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
}

- (void)setupUI {
    self.view.backgroundColor = [UIColor blackColor];

    // Gradient background
    self.gradientView = [[UIView alloc] init];
    [self.view addSubview:self.gradientView];

    // Scroll view for content
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.scrollView];

    self.contentView = [[UIView alloc] init];
    self.contentView.backgroundColor = [UIColor clearColor];
    [self.scrollView addSubview:self.contentView];

    // Back button
    self.backButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.backButton setImage:[UIImage systemImageNamed:@"chevron.left"] forState:UIControlStateNormal];
    self.backButton.tintColor = [UIColor whiteColor];
    [self.backButton addTarget:self action:@selector(backTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.backButton];

    // Title
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.text = @"注册新账号";
    self.titleLabel.font = [UIFont systemFontOfSize:32 weight:UIFontWeightBold];
    self.titleLabel.textColor = [UIColor whiteColor];
    [self.contentView addSubview:self.titleLabel];

    // Avatar container
    self.avatarContainer = [[UIView alloc] init];
    self.avatarContainer.backgroundColor = [UIColor clearColor];
    self.avatarContainer.layer.cornerRadius = 50;
    self.avatarContainer.layer.borderWidth = 3;
    self.avatarContainer.layer.borderColor = [UIColor systemPinkColor].CGColor;
    [self.contentView addSubview:self.avatarContainer];

    self.avatarImageView = [[UIImageView alloc] init];
    self.avatarImageView.image = [UIImage systemImageNamed:@"person"];
    self.avatarImageView.tintColor = [UIColor colorWithWhite:0.6 alpha:1.0];
    self.avatarImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.avatarImageView.clipsToBounds = YES;
    self.avatarImageView.layer.cornerRadius = 50;
    [self.avatarContainer addSubview:self.avatarImageView];

    UITapGestureRecognizer *avatarTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(avatarTapped)];
    [self.avatarContainer addGestureRecognizer:avatarTap];
    self.avatarContainer.userInteractionEnabled = YES;

    self.avatarLoadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    self.avatarLoadingIndicator.color = [UIColor whiteColor];
    self.avatarLoadingIndicator.hidesWhenStopped = YES;
    [self.avatarContainer addSubview:self.avatarLoadingIndicator];

    self.avatarHintLabel = [[UILabel alloc] init];
    self.avatarHintLabel.text = @"点击上传头像（选填）";
    self.avatarHintLabel.font = [UIFont systemFontOfSize:12];
    self.avatarHintLabel.textColor = [UIColor colorWithWhite:0.6 alpha:1.0];
    [self.contentView addSubview:self.avatarHintLabel];

    // Email text field
    self.emailTextField = [[UITextField alloc] init];
    self.emailTextField.placeholder = @"邮箱";
    self.emailTextField.borderStyle = UITextBorderStyleNone;
    self.emailTextField.backgroundColor = [UIColor whiteColor];
    self.emailTextField.textColor = [UIColor colorWithWhite:0.15 alpha:1.0];
    self.emailTextField.layer.cornerRadius = 16;
    self.emailTextField.keyboardType = UIKeyboardTypeEmailAddress;
    self.emailTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    [self.contentView addSubview:self.emailTextField];

    // Code text field with send button
    self.codeContainer = [[UIView alloc] init];
    self.codeContainer.backgroundColor = [UIColor whiteColor];
    self.codeContainer.layer.cornerRadius = 16;
    [self.contentView addSubview:self.codeContainer];

    self.codeTextField = [[UITextField alloc] init];
    self.codeTextField.placeholder = @"验证码";
    self.codeTextField.borderStyle = UITextBorderStyleNone;
    self.codeTextField.backgroundColor = [UIColor whiteColor];
    self.codeTextField.textColor = [UIColor colorWithWhite:0.15 alpha:1.0];
    self.codeTextField.keyboardType = UIKeyboardTypeNumberPad;
    [self.codeContainer addSubview:self.codeTextField];

    self.sendCodeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.sendCodeButton setTitle:@"发送验证码" forState:UIControlStateNormal];
    [self.sendCodeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.sendCodeButton.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    self.sendCodeButton.backgroundColor = [UIColor systemPurpleColor];
    self.sendCodeButton.layer.cornerRadius = 12;
    [self.sendCodeButton addTarget:self action:@selector(sendCodeTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.codeContainer addSubview:self.sendCodeButton];

    // Username text field
    self.usernameTextField = [[UITextField alloc] init];
    self.usernameTextField.placeholder = @"用户名";
    self.usernameTextField.borderStyle = UITextBorderStyleNone;
    self.usernameTextField.backgroundColor = [UIColor whiteColor];
    self.usernameTextField.textColor = [UIColor colorWithWhite:0.15 alpha:1.0];
    self.usernameTextField.layer.cornerRadius = 16;
    [self.contentView addSubview:self.usernameTextField];

    // Password text field
    self.passwordTextField = [[UITextField alloc] init];
    self.passwordTextField.placeholder = @"密码";
    self.passwordTextField.secureTextEntry = YES;
    self.passwordTextField.borderStyle = UITextBorderStyleNone;
    self.passwordTextField.backgroundColor = [UIColor whiteColor];
    self.passwordTextField.textColor = [UIColor colorWithWhite:0.15 alpha:1.0];
    self.passwordTextField.layer.cornerRadius = 16;
    [self.contentView addSubview:self.passwordTextField];

    // Error label
    self.errorLabel = [[UILabel alloc] init];
    self.errorLabel.font = [UIFont systemFontOfSize:14];
    self.errorLabel.textColor = [UIColor systemRedColor];
    self.errorLabel.hidden = YES;
    self.errorLabel.numberOfLines = 0;
    [self.contentView addSubview:self.errorLabel];

    // Register button
    self.registerButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.registerButton setTitle:@"注册" forState:UIControlStateNormal];
    [self.registerButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.registerButton.titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];
    self.registerButton.layer.cornerRadius = 28;
    [self.registerButton addTarget:self action:@selector(registerTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.registerButton];

    // Login link
    self.loginLinkLabel = [[UILabel alloc] init];
    self.loginLinkLabel.text = @"已有账号？返回登录";
    self.loginLinkLabel.font = [UIFont systemFontOfSize:14];
    self.loginLinkLabel.textColor = [UIColor systemPinkColor];
    self.loginLinkLabel.textAlignment = NSTextAlignmentCenter;
    UITapGestureRecognizer *loginTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(loginLinkTapped)];
    [self.loginLinkLabel addGestureRecognizer:loginTap];
    self.loginLinkLabel.userInteractionEnabled = YES;
    [self.contentView addSubview:self.loginLinkLabel];

    // Loading indicator
    self.loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    self.loadingIndicator.color = [UIColor whiteColor];
    self.loadingIndicator.hidesWhenStopped = YES;
    [self.registerButton addSubview:self.loadingIndicator];

    [self setupConstraints];
}

- (void)setupConstraints {
    [self.gradientView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];

    [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
        make.left.right.bottom.equalTo(self.view);
    }];

    [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.scrollView);
        make.width.equalTo(self.scrollView);
    }];

    [self.backButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(8);
        make.left.equalTo(self.view).offset(8);
        make.width.height.equalTo(@44);
    }];

    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.backButton.mas_bottom).offset(24);
        make.left.equalTo(self.contentView).offset(24);
    }];

    [self.avatarContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(32);
        make.centerX.equalTo(self.contentView);
        make.width.height.equalTo(@100);
    }];

    [self.avatarImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.avatarContainer);
        make.width.height.equalTo(@50);
    }];

    [self.avatarHintLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.avatarContainer.mas_bottom).offset(8);
        make.centerX.equalTo(self.contentView);
    }];

    [self.emailTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.avatarHintLabel.mas_bottom).offset(24);
        make.left.equalTo(self.contentView).offset(24);
        make.right.equalTo(self.contentView).offset(-24);
        make.height.equalTo(@56);
    }];

    [self.codeContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.emailTextField.mas_bottom).offset(16);
        make.left.equalTo(self.contentView).offset(24);
        make.right.equalTo(self.contentView).offset(-24);
        make.height.equalTo(@56);
    }];

    [self.codeTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.codeContainer).offset(16);
        make.centerY.equalTo(self.codeContainer);
        make.right.equalTo(self.sendCodeButton.mas_left).offset(-8);
    }];

    [self.sendCodeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.codeContainer).offset(-8);
        make.centerY.equalTo(self.codeContainer);
        make.width.equalTo(@110);
        make.height.equalTo(@40);
    }];

    [self.usernameTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.codeContainer.mas_bottom).offset(16);
        make.left.equalTo(self.contentView).offset(24);
        make.right.equalTo(self.contentView).offset(-24);
        make.height.equalTo(@56);
    }];

    [self.passwordTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.usernameTextField.mas_bottom).offset(16);
        make.left.equalTo(self.contentView).offset(24);
        make.right.equalTo(self.contentView).offset(-24);
        make.height.equalTo(@56);
    }];

    [self.errorLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.passwordTextField.mas_bottom).offset(8);
        make.left.equalTo(self.contentView).offset(24);
        make.right.equalTo(self.contentView).offset(-24);
    }];

    [self.registerButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.errorLabel.mas_bottom).offset(16);
        make.left.equalTo(self.contentView).offset(24);
        make.right.equalTo(self.contentView).offset(-24);
        make.height.equalTo(@56);
    }];

    [self.loginLinkLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.registerButton.mas_bottom).offset(24);
        make.centerX.equalTo(self.contentView);
        make.bottom.equalTo(self.contentView).offset(-40);
    }];

    [self.loadingIndicator mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.registerButton);
    }];

    [self.avatarLoadingIndicator mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.avatarContainer);
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
    for (CALayer *layer in self.registerButton.layer.sublayers) {
        if ([layer isKindOfClass:[CAGradientLayer class]]) {
            layer.frame = self.registerButton.bounds;
        }
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setupGradientIfNeeded];
}

- (void)setupGradientIfNeeded {
    for (CALayer *layer in self.gradientView.layer.sublayers) {
        if ([layer isKindOfClass:[CAGradientLayer class]]) return;
    }

    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.frame = self.gradientView.bounds;
    gradientLayer.colors = @[
        (id)[UIColor colorWithRed:139/255.0 green:92/255.0 blue:246/255.0 alpha:1].CGColor,
        (id)[UIColor colorWithRed:236/255.0 green:72/255.0 blue:153/255.0 alpha:1].CGColor
    ];
    gradientLayer.startPoint = CGPointMake(0, 0);
    gradientLayer.endPoint = CGPointMake(1, 1);
    [self.gradientView.layer insertSublayer:gradientLayer atIndex:0];

    // Button gradient
    CAGradientLayer *buttonGradient = [CAGradientLayer layer];
    buttonGradient.frame = self.registerButton.bounds;
    buttonGradient.colors = @[
        (id)[UIColor colorWithRed:236/255.0 green:72/255.0 blue:153/255.0 alpha:1].CGColor,
        (id)[UIColor colorWithRed:139/255.0 green:92/255.0 blue:246/255.0 alpha:1].CGColor
    ];
    buttonGradient.startPoint = CGPointMake(0, 0);
    buttonGradient.endPoint = CGPointMake(1, 1);
    buttonGradient.cornerRadius = 28;
    [self.registerButton.layer insertSublayer:buttonGradient atIndex:0];
}

- (void)backTapped {
    if (self.onBackClick) {
        self.onBackClick();
    }
}

- (void)sendCodeTapped {
    NSString *email = self.emailTextField.text;
    if (email.length == 0) {
        self.errorLabel.text = @"请输入邮箱地址";
        self.errorLabel.hidden = NO;
        return;
    }

    [self.sendCodeButton setTitle:@"发送中..." forState:UIControlStateNormal];
    self.sendCodeButton.enabled = NO;

    [[HYAPIClient shared] sendCodeWithEmail:email completion:^(NSDictionary *response, NSError *error) {
        [self.sendCodeButton setTitle:@"发送验证码" forState:UIControlStateNormal];
        self.sendCodeButton.enabled = YES;

        if (error) {
            self.errorLabel.text = error.localizedDescription;
            self.errorLabel.hidden = NO;
        } else {
            self.errorLabel.hidden = YES;
            [self showAlert:@"验证码已发送到您的邮箱"];
        }
    }];
}

- (void)registerTapped {
    NSString *email = self.emailTextField.text;
    NSString *code = self.codeTextField.text;
    NSString *username = self.usernameTextField.text;
    NSString *password = self.passwordTextField.text;

    if (email.length == 0 || code.length == 0 || username.length == 0 || password.length == 0) {
        self.errorLabel.text = @"请填写所有必填项";
        self.errorLabel.hidden = NO;
        return;
    }

    [self setLoading:YES];
    self.errorLabel.hidden = YES;

    [[HYAPIClient shared] registerWithEmail:email username:username password:password code:code avatarUrl:self.uploadedAvatarUrl ?: @"" completion:^(NSDictionary *response, NSError *error) {
        [self setLoading:NO];

        if (error) {
            self.errorLabel.text = error.localizedDescription;
            self.errorLabel.hidden = NO;
            return;
        }

        // Save token if returned (token is inside data object)
        NSDictionary *data = response[@"data"];
        NSString *token = [data isKindOfClass:[NSDictionary class]] ? data[@"token"] : nil;
        if (token) {
            [[HYAPIClient shared] setToken:token];
        }

        [self showAlert:@"注册成功"];
        if (self.onRegisterSuccess) {
            self.onRegisterSuccess();
        }
    }];
}

- (void)loginLinkTapped {
    if (self.onBackClick) {
        self.onBackClick();
    }
}

- (void)setLoading:(BOOL)loading {
    self.registerButton.enabled = !loading;
    self.emailTextField.enabled = !loading;
    self.codeTextField.enabled = !loading;
    self.usernameTextField.enabled = !loading;
    self.passwordTextField.enabled = !loading;
    self.avatarContainer.userInteractionEnabled = !loading;

    if (loading) {
        [self.registerButton setTitle:@"" forState:UIControlStateNormal];
        [self.loadingIndicator startAnimating];
    } else {
        [self.registerButton setTitle:@"注册" forState:UIControlStateNormal];
        [self.loadingIndicator stopAnimating];
    }
}

- (void)showAlert:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                               message:message
                                                        preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)avatarTapped {
    [self.view endEditing:YES];
    PHPickerConfiguration *config = [[PHPickerConfiguration alloc] init];
    config.selectionLimit = 1;
    config.filter = [PHPickerFilter imagesFilter];
    PHPickerViewController *picker = [[PHPickerViewController alloc] initWithConfiguration:config];
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:nil];
}

#pragma mark - PHPickerViewControllerDelegate

- (void)picker:(PHPickerViewController *)picker didFinishPicking:(NSArray<PHPickerResult *> *)results {
    [picker dismissViewControllerAnimated:YES completion:nil];
    if (results.count == 0) return;

    [self.avatarLoadingIndicator startAnimating];
    self.avatarHintLabel.hidden = YES;

    PHPickerResult *result = results.firstObject;
    if ([result.itemProvider canLoadObjectOfClass:[UIImage class]]) {
        [result.itemProvider loadObjectOfClass:[UIImage class] completionHandler:^(id<NSItemProviderReading> object, NSError *error) {
            if (![object isKindOfClass:[UIImage class]]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.avatarLoadingIndicator stopAnimating];
                    self.avatarHintLabel.hidden = NO;
                });
                return;
            }
            UIImage *image = (UIImage *)object;
            dispatch_async(dispatch_get_main_queue(), ^{
                self.selectedAvatarImage = image;
                self.avatarImageView.image = image;
                self.avatarImageView.contentMode = UIViewContentModeScaleAspectFill;
                [self.avatarLoadingIndicator stopAnimating];
                [self uploadAvatarImage:image];
            });
        }];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.avatarLoadingIndicator stopAnimating];
            self.avatarHintLabel.hidden = NO;
        });
    }
}

- (void)uploadAvatarImage:(UIImage *)image {
    NSData *imageData = UIImageJPEGRepresentation(image, 0.8);
    if (!imageData) return;

    __weak typeof(self) weakSelf = self;
    [[HYAPIClient shared] uploadAvatarImage:imageData completion:^(NSString *imageUrl, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) return;

            if (error) {
                strongSelf.avatarHintLabel.text = @"上传失败，点击重试";
                strongSelf.avatarHintLabel.hidden = NO;
            } else {
                strongSelf.uploadedAvatarUrl = imageUrl;
                strongSelf.avatarHintLabel.text = @"点击更换头像";
                strongSelf.avatarHintLabel.hidden = NO;
            }
        });
    }];
}

@end
