#import "HYLoginRequiredView.h"
#import <Masonry/Masonry.h>

@interface HYLoginRequiredView ()

@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UILabel *tipLabel;
@property (nonatomic, strong) UIButton *loginButton;

@end

@implementation HYLoginRequiredView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.backgroundColor = [UIColor systemBackgroundColor];

    self.containerView = [[UIView alloc] init];
    [self addSubview:self.containerView];

    self.tipLabel = [[UILabel alloc] init];
    self.tipLabel.font = [UIFont systemFontOfSize:16];
    self.tipLabel.textColor = [UIColor secondaryLabelColor];
    self.tipLabel.textAlignment = NSTextAlignmentCenter;
    self.tipLabel.numberOfLines = 0;
    [self.containerView addSubview:self.tipLabel];

    self.loginButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.loginButton.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    [self.loginButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.loginButton.backgroundColor = [UIColor systemPinkColor];
    self.loginButton.layer.cornerRadius = 24;
    [self.loginButton addTarget:self action:@selector(loginTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.containerView addSubview:self.loginButton];

    [self setupConstraints];
}

- (void)setupConstraints {
    [self.containerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self);
        make.leading.trailing.equalTo(self).inset(40);
    }];

    [self.tipLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.trailing.equalTo(self.containerView);
    }];

    [self.loginButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tipLabel.mas_bottom).offset(24);
        make.centerX.equalTo(self.containerView);
        make.width.equalTo(@160);
        make.height.equalTo(@48);
        make.bottom.equalTo(self.containerView);
    }];
}

- (void)setTipText:(NSString *)tipText {
    self.tipLabel.text = tipText;
}

- (void)setLoginButtonTitle:(NSString *)title {
    [self.loginButton setTitle:title forState:UIControlStateNormal];
}

- (void)loginTapped {
    if (self.onLoginTapped) {
        self.onLoginTapped();
    }
}

@end
