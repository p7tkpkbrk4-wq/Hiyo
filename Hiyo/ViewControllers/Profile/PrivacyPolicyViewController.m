#import "PrivacyPolicyViewController.h"
#import "HYColors.h"
#import <WebKit/WebKit.h>

@interface PrivacyPolicyViewController () <WKNavigationDelegate>

@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) UIActivityIndicatorView *loadingIndicator;

@end

@implementation PrivacyPolicyViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"隐私政策";
    self.view.backgroundColor = DarkBackground;
    [self setupNavigationBarDark];
    [self setupUI];
    [self loadContent];
}

- (void)setupNavigationBarDark {
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    self.navigationController.navigationBar.barTintColor = DarkBackground;

    if (@available(iOS 15.0, *)) {
        UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
        [appearance configureWithOpaqueBackground];
        appearance.backgroundColor = DarkBackground;
        appearance.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor whiteColor]};
        appearance.largeTitleTextAttributes = @{NSForegroundColorAttributeName: [UIColor whiteColor]};
        self.navigationController.navigationBar.standardAppearance = appearance;
        self.navigationController.navigationBar.scrollEdgeAppearance = appearance;
    }
}

- (void)setupUI {
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    self.webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:config];
    self.webView.navigationDelegate = self;
    self.webView.backgroundColor = DarkBackground;
    self.webView.opaque = NO;
    [self.view addSubview:self.webView];

    self.webView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [self.webView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [self.webView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.webView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.webView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];

    self.loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    self.loadingIndicator.color = [UIColor whiteColor];
    self.loadingIndicator.hidesWhenStopped = YES;
    self.loadingIndicator.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.loadingIndicator];

    [NSLayoutConstraint activateConstraints:@[
        [self.loadingIndicator.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.loadingIndicator.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor]
    ]];
}

- (void)loadContent {
    [self.loadingIndicator startAnimating];

    NSString *html = @"<!DOCTYPE html>"
                     @"<html>"
                     @"<head>"
                     @"<meta name='viewport' content='width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no'>"
                     @"<style>"
                     @"body { background:#0a0a14; color:#b0b0cc; padding:16px; font-family:-apple-system, BlinkMacSystemFont, sans-serif; font-size:14px; line-height:1.6; }"
                     @"h2 { color:#ffffff; font-size:18px; margin-top:24px; }"
                     @"h3 { color:#d0d0e0; font-size:15px; margin-top:16px; }"
                     @"p { margin:8px 0; }"
                     @"ul { padding-left:20px; }"
                     @"li { margin:4px 0; }"
                     @"a { color:#cc66ff; }"
                     @"</style>"
                     @"</head>"
                     @"<body>"
                     @"<h2>隐私政策</h2>"
                     @"<p>更新日期：2024年1月1日</p>"
                     @"<p>Hiyo（以下简称「我们」或「Hiyo」）非常重视您的个人信息和隐私保护。本隐私政策说明了当您使用Hiyo应用时，我们如何收集、使用、存储和保护您的个人信息。</p>"
                     @"<h3>1. 信息收集</h3>"
                     @"<p>我们可能会收集以下类型的信息：</p>"
                     @"<ul>"
                     @"<li><strong>账户信息：</strong>包括昵称、头像、性别、生日等您主动填写的资料。</li>"
                     @"<li><strong>联系方式：</strong>邮箱地址、手机号码（仅用于验证，不会公开）。</li>"
                     @"<li><strong>位置信息：</strong>用于向您推荐附近的其他用户。</li>"
                     @"<li><strong>使用信息：</strong>包括浏览记录、点赞、评论、聊天记录等应用内行为。</li>"
                     @"<li><strong>设备信息：</strong>设备型号、操作系统版本、网络类型等。</li>"
                     @"</ul>"
                     @"<h3>2. 信息使用</h3>"
                     @"<p>我们收集的信息将用于：</p>"
                     @"<ul>"
                     @"<li>提供和维护应用的基本功能。</li>"
                     @"<li>向您推荐可能感兴趣的其他用户。</li>"
                     @"<li>处理您的消息和通知。</li>"
                     @"<li>改进我们的服务和用户体验。</li>"
                     @"<li>遵守法律法规的要求。</li>"
                     @"</ul>"
                     @"<h3>3. 信息共享</h3>"
                     @"<p>未经您的同意，我们不会与任何第三方共享您的个人信息，以下情况除外：</p>"
                     @"<ul>"
                     @"<li>法律法规要求的情况下。</li>"
                     @"<li>保护Hiyo或其他用户的权益。</li>"
                     @"<li>您主动选择公开的个人信息（如您在动态中发布的内容）。</li>"
                     @"</ul>"
                     @"<h3>4. 信息存储</h3>"
                     @"<p>您的个人信息将存储在安全的服务器上。我们会采取合理的技术和管理措施来保护您的信息不被未经授权的访问、使用或泄露。</p>"
                     @"<h3>5. 您的权利</h3>"
                     @"<p>您有权：</p>"
                     @"<ul>"
                     @"<li>访问和更正您的个人信息。</li>"
                     @"<li>删除您的账户和个人信息。</li>"
                     @"<li>撤回您的同意。</li>"
                     @"<li>联系我们了解更多关于您个人信息的处理情况。</li>"
                     @"</ul>"
                     @"<h3>6. 未成年人保护</h3>"
                     @"<p>Hiyo不向18岁以下的未成年人提供服务，我们不会故意收集未成年人的个人信息。</p>"
                     @"<h3>7. 政策更新</h3>"
                     @"<p>我们可能会不时更新本隐私政策。更新后的政策将在应用内公布。如果更新涉及重大变更，我们将通过应用内通知或其他方式提前告知您。</p>"
                     @"<h3>8. 联系我们</h3>"
                     @"<p>如果您对本隐私政策有任何疑问，请通过以下方式联系我们：</p>"
                     @"<p>邮箱：hiyo@example.com</p>"
                     @"</body>"
                     @"</html>";

    [self.webView loadHTMLString:html baseURL:nil];
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    [self.loadingIndicator stopAnimating];
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    [self.loadingIndicator stopAnimating];
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler {
    decisionHandler(WKNavigationResponsePolicyAllow);
}

@end
