#import "UserAgreementViewController.h"
#import "HYColors.h"

@interface UserAgreementViewController () <UIWebViewDelegate>

@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, strong) UIActivityIndicatorView *loadingIndicator;

@end

@implementation UserAgreementViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"用户协议";
    [self setupNavigationBarDark];
    self.view.backgroundColor = DarkBackground;

    self.webView = [[UIWebView alloc] init];
    self.webView.backgroundColor = DarkBackground;
    self.webView.opaque = NO;
    self.webView.delegate = self;
    [self.view addSubview:self.webView];

    self.loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    self.loadingIndicator.color = [UIColor whiteColor];
    self.loadingIndicator.hidesWhenStopped = YES;
    [self.view addSubview:self.loadingIndicator];

    self.webView.translatesAutoresizingMaskIntoConstraints = NO;
    self.loadingIndicator.translatesAutoresizingMaskIntoConstraints = NO;

    [NSLayoutConstraint activateConstraints:@[
        [self.webView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [self.webView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.webView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.webView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

        [self.loadingIndicator.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.loadingIndicator.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor]
    ]];

    [self.loadingIndicator startAnimating];
    NSString *html = @"<html><body style='background:#0a0a14;color:#b0b0cc;padding:20px;font-size:15px;'>"
                     @"<h2 style='color:#fff'>用户协议</h2>"
                     @"<p>欢迎使用Hiyo应用。使用本应用即表示您同意以下条款：</p>"
                     @"<p>1. 您承诺在使用本应用时遵守当地法律法规。</p>"
                     @"<p>2. 您的个人资料必须真实有效。</p>"
                     @"<p>3. 禁止发布违法、违规或不当内容。</p>"
                     @"<p>4. 我们重视您的隐私，您的数据将按照隐私政策处理。</p>"
                     @"<p>5. 账号所有权归Hiyo所有，我们保留终止违规账号的权利。</p>"
                     @"</body></html>";
    [self.webView loadHTMLString:html baseURL:nil];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [self.loadingIndicator stopAnimating];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [self.loadingIndicator stopAnimating];
}

@end
