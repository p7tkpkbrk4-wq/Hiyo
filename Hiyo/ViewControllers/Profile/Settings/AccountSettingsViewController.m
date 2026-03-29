#import "AccountSettingsViewController.h"
#import "HYAPIClient.h"
#import "HYColors.h"

@interface AccountSettingsViewController () <UITextFieldDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UITextField *oldPasswordField;
@property (nonatomic, strong) UITextField *updatedPasswordField;
@property (nonatomic, strong) UITextField *confirmPasswordField;
@property (nonatomic, strong) UIButton *saveButton;
@property (nonatomic, strong) UIActivityIndicatorView *loadingIndicator;
@property (nonatomic, assign) NSInteger currentMode; // 0=password, 1=email, 2=phone

@end

@implementation AccountSettingsViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        _currentMode = 0; // Default to password change
    }
    return self;
}

- (instancetype)initWithMode:(NSInteger)mode {
    self = [super init];
    if (self) {
        _currentMode = mode;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = [self titleForMode];
    [self setupNavigationBarDark];
    [self setupUI];
    [self setupConstraints];
}

- (NSString *)titleForMode {
    switch (self.currentMode) {
        case 1: return @"修改邮箱";
        case 2: return @"绑定手机";
        default: return @"修改密码";
    }
}

- (void)setupUI {
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    [self.view addSubview:self.scrollView];

    self.contentView = [[UIView alloc] init];
    [self.scrollView addSubview:self.contentView];

    if (self.currentMode == 0) {
        self.oldPasswordField = [self createTextField:@"旧密码" placeholder:@"请输入旧密码" secure:YES];
        self.updatedPasswordField = [self createTextField:@"新密码" placeholder:@"请输入新密码" secure:YES];
        self.confirmPasswordField = [self createTextField:@"确认密码" placeholder:@"请再次输入新密码" secure:YES];
        [self.contentView addSubview:self.oldPasswordField];
        [self.contentView addSubview:self.updatedPasswordField];
        [self.contentView addSubview:self.confirmPasswordField];
    } else {
        self.updatedPasswordField = [self createTextField:self.currentMode == 1 ? @"新邮箱" : @"手机号" placeholder:self.currentMode == 1 ? @"请输入新邮箱" : @"请输入手机号" secure:NO];
        self.confirmPasswordField = [self createTextField:@"验证码" placeholder:@"请输入验证码" secure:NO];
        [self.contentView addSubview:self.updatedPasswordField];
        [self.contentView addSubview:self.confirmPasswordField];

        UIButton *sendCodeButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [sendCodeButton setTitle:@"发送验证码" forState:UIControlStateNormal];
        [sendCodeButton setTitleColor:PrimaryPink forState:UIControlStateNormal];
        sendCodeButton.titleLabel.font = [UIFont systemFontOfSize:14];
        sendCodeButton.tag = 100;
        [self.contentView addSubview:sendCodeButton];
    }

    self.saveButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.saveButton setTitle:@"保存" forState:UIControlStateNormal];
    [self.saveButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.saveButton.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    self.saveButton.backgroundColor = PrimaryPink;
    self.saveButton.layer.cornerRadius = 24;
    [self.saveButton addTarget:self action:@selector(saveTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.saveButton];

    self.loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    self.loadingIndicator.color = [UIColor whiteColor];
    self.loadingIndicator.hidesWhenStopped = YES;
    [self.saveButton addSubview:self.loadingIndicator];
}

- (UITextField *)createTextField:(NSString *)label placeholder:(NSString *)placeholder secure:(BOOL)secure {
    UIView *row = [[UIView alloc] init];
    row.backgroundColor = DarkCard;
    row.layer.cornerRadius = 12;
    row.tag = 999; // mark as field row

    UILabel *labelView = [[UILabel alloc] init];
    labelView.text = label;
    labelView.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    labelView.textColor = TextSecondary;
    [row addSubview:labelView];

    UITextField *field = [[UITextField alloc] init];
    field.placeholder = placeholder;
    field.font = [UIFont systemFontOfSize:15];
    field.textColor = TextPrimary;
    field.secureTextEntry = secure;
    field.attributedPlaceholder = [[NSAttributedString alloc] initWithString:placeholder attributes:@{NSForegroundColorAttributeName: TextMuted}];
    field.textAlignment = NSTextAlignmentRight;
    field.returnKeyType = UIReturnKeyDone;
    field.delegate = self;
    field.keyboardAppearance = UIKeyboardAppearanceDark;
    [row addSubview:field];

    labelView.translatesAutoresizingMaskIntoConstraints = NO;
    field.translatesAutoresizingMaskIntoConstraints = NO;

    [NSLayoutConstraint activateConstraints:@[
        [labelView.leadingAnchor constraintEqualToAnchor:row.leadingAnchor constant:16],
        [labelView.centerYAnchor constraintEqualToAnchor:row.centerYAnchor],
        [field.trailingAnchor constraintEqualToAnchor:row.trailingAnchor constant:-16],
        [field.centerYAnchor constraintEqualToAnchor:row.centerYAnchor],
        [field.leadingAnchor constraintEqualToAnchor:labelView.trailingAnchor constant:12]
    ]];

    return (UITextField *)field;
}

- (void)setupConstraints {
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
    self.saveButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.loadingIndicator.translatesAutoresizingMaskIntoConstraints = NO;

    [NSLayoutConstraint activateConstraints:@[
        [self.scrollView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [self.scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.scrollView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

        [self.contentView.topAnchor constraintEqualToAnchor:self.scrollView.topAnchor],
        [self.contentView.leadingAnchor constraintEqualToAnchor:self.scrollView.leadingAnchor],
        [self.contentView.trailingAnchor constraintEqualToAnchor:self.scrollView.trailingAnchor],
        [self.contentView.bottomAnchor constraintEqualToAnchor:self.scrollView.bottomAnchor],
        [self.contentView.widthAnchor constraintEqualToAnchor:self.scrollView.widthAnchor]
    ]];

    UIView *prev = nil;
    NSArray *fields = @[];
    if (self.currentMode == 0) {
        fields = @[self.oldPasswordField, self.updatedPasswordField, self.confirmPasswordField];
    } else {
        fields = @[self.updatedPasswordField, self.confirmPasswordField];
    }

    for (UITextField *field in fields) {
        UIView *row = field.superview;
        row.translatesAutoresizingMaskIntoConstraints = NO;
        [NSLayoutConstraint activateConstraints:@[
            [row.topAnchor constraintEqualToAnchor:prev ? prev.bottomAnchor : self.contentView.topAnchor constant:prev ? 16 : 24],
            [row.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16],
            [row.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-16],
            [row.heightAnchor constraintEqualToConstant:52]
        ]];
        prev = row;
    }

    if (self.currentMode != 0) {
        UIView *codeRow = self.confirmPasswordField.superview;
        UIButton *sendCode = [self.contentView viewWithTag:100];
        if (sendCode) {
            sendCode.translatesAutoresizingMaskIntoConstraints = NO;
            [NSLayoutConstraint activateConstraints:@[
                [sendCode.trailingAnchor constraintEqualToAnchor:codeRow.trailingAnchor constant:-16],
                [sendCode.centerYAnchor constraintEqualToAnchor:codeRow.centerYAnchor]
            ]];
        }
    }

    [NSLayoutConstraint activateConstraints:@[
        [self.saveButton.topAnchor constraintEqualToAnchor:prev.bottomAnchor constant:40],
        [self.saveButton.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:40],
        [self.saveButton.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-40],
        [self.saveButton.heightAnchor constraintEqualToConstant:48],
        [self.saveButton.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-40],

        [self.loadingIndicator.centerXAnchor constraintEqualToAnchor:self.saveButton.centerXAnchor],
        [self.loadingIndicator.centerYAnchor constraintEqualToAnchor:self.saveButton.centerYAnchor]
    ]];
}

- (void)saveTapped {
    [self.view endEditing:YES];

    if (self.currentMode == 0) {
        NSString *oldPass = self.oldPasswordField.text;
        NSString *newPass = self.updatedPasswordField.text;
        NSString *confirmPass = self.confirmPasswordField.text;

        if (oldPass.length < 6 || newPass.length < 6) {
            [self showAlert:@"密码长度至少6位"];
            return;
        }
        if (![newPass isEqualToString:confirmPass]) {
            [self showAlert:@"两次输入的密码不一致"];
            return;
        }

        [self setLoading:YES];
        [[HYAPIClient shared] changePasswordWithOldPassword:oldPass newPassword:newPass completion:^(NSDictionary *response, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self setLoading:NO];
                if (error) {
                    [self showAlert:error.localizedDescription];
                } else {
                    [self showToast:@"密码修改成功"];
                    [self.navigationController popViewControllerAnimated:YES];
                }
            });
        }];
    } else {
        [self showToast:@"功能开发中"];
    }
}

- (void)setLoading:(BOOL)loading {
    self.saveButton.enabled = !loading;
    if (loading) {
        [self.saveButton setTitle:@"" forState:UIControlStateNormal];
        [self.loadingIndicator startAnimating];
    } else {
        [self.saveButton setTitle:@"保存" forState:UIControlStateNormal];
        [self.loadingIndicator stopAnimating];
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

@end
