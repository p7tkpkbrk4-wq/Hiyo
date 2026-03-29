#import "FeedbackViewController.h"
#import "HYAPIClient.h"
#import <Masonry/Masonry.h>

@interface FeedbackViewController () <UITextViewDelegate>

@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) UILabel *placeholderLabel;
@property (nonatomic, strong) UIButton *submitButton;
@property (nonatomic, strong) UIActivityIndicatorView *loadingView;

@end

@implementation FeedbackViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"意见反馈";
    self.view.backgroundColor = [UIColor colorWithRed:0.04 green:0.04 blue:0.08 alpha:1.0];
    [self setupUI];
    [self setupConstraints];
}

- (void)setupUI {
    // Text view
    self.textView = [[UITextView alloc] init];
    self.textView.backgroundColor = [UIColor colorWithRed:0.11 green:0.11 blue:0.18 alpha:1.0];
    self.textView.textColor = [UIColor whiteColor];
    self.textView.font = [UIFont systemFontOfSize:16];
    self.textView.layer.cornerRadius = 12;
    self.textView.textContainerInset = UIEdgeInsetsMake(16, 12, 16, 12);
    self.textView.delegate = self;
    self.textView.keyboardAppearance = UIKeyboardAppearanceDark;
    [self.view addSubview:self.textView];

    // Placeholder
    self.placeholderLabel = [[UILabel alloc] init];
    self.placeholderLabel.text = @"请描述您遇到的问题或建议...";
    self.placeholderLabel.font = [UIFont systemFontOfSize:16];
    self.placeholderLabel.textColor = [UIColor systemGrayColor];
    [self.textView addSubview:self.placeholderLabel];

    // Submit button
    self.submitButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.submitButton setTitle:@"提交反馈" forState:UIControlStateNormal];
    [self.submitButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.submitButton.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    self.submitButton.backgroundColor = [UIColor systemPinkColor];
    self.submitButton.layer.cornerRadius = 24;
    [self.submitButton addTarget:self action:@selector(submitTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.submitButton];

    // Loading indicator
    self.loadingView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    self.loadingView.color = [UIColor whiteColor];
    self.loadingView.hidesWhenStopped = YES;
    [self.submitButton addSubview:self.loadingView];

    // Keyboard dismiss tap
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    tap.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tap];
}

- (void)setupConstraints {
    [self.textView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(16);
        make.left.equalTo(self.view).offset(16);
        make.right.equalTo(self.view).offset(-16);
        make.height.equalTo(@200);
    }];

    [self.placeholderLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.textView).offset(16);
        make.left.equalTo(self.textView).offset(16);
    }];

    [self.submitButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.textView.mas_bottom).offset(24);
        make.left.equalTo(self.view).offset(40);
        make.right.equalTo(self.view).offset(-40);
        make.height.equalTo(@48);
    }];

    [self.loadingView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.submitButton);
    }];
}

- (void)dismissKeyboard {
    [self.view endEditing:YES];
}

- (void)submitTapped {
    NSString *content = [self.textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (content.length == 0) {
        [self showAlert:@"请输入反馈内容"];
        return;
    }

    [self.loadingView startAnimating];
    [self.submitButton setTitle:@"" forState:UIControlStateNormal];
    self.submitButton.enabled = NO;

    __weak typeof(self) weakSelf = self;
    [[HYAPIClient shared] submitFeedbackWithContent:content completion:^(NSDictionary *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) return;

            [strongSelf.loadingView stopAnimating];
            [strongSelf.submitButton setTitle:@"提交反馈" forState:UIControlStateNormal];
            strongSelf.submitButton.enabled = YES;

            if (error) {
                [strongSelf showAlert:@"提交失败，请重试"];
                return;
            }

            [strongSelf showAlert:@"感谢您的反馈！"];
            strongSelf.textView.text = @"";
            strongSelf.placeholderLabel.hidden = NO;
        });
    }];
}

- (void)showAlert:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView {
    self.placeholderLabel.hidden = textView.text.length > 0;
}

@end
