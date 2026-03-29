#import "WelcomeViewController.h"

typedef NS_ENUM(NSInteger, UserType) {
    UserTypeGuest,
    UserTypeLogin
};

@interface WelcomeViewController ()

@property (nonatomic, strong) UIView *gradientView;
@property (nonatomic, strong) UIView *logoView;
@property (nonatomic, strong) UILabel *logoLabel;
@property (nonatomic, strong) UILabel *appNameLabel;
@property (nonatomic, strong) UILabel *sloganLabel;

@property (nonatomic, strong) UIView *guestCard;
@property (nonatomic, strong) UIImageView *guestIcon;
@property (nonatomic, strong) UILabel *guestLabel;
@property (nonatomic, strong) UIView *loginCard;
@property (nonatomic, strong) UIImageView *loginIcon;
@property (nonatomic, strong) UILabel *loginLabel;

@property (nonatomic, strong) UIButton *startButton;

@property (nonatomic, assign) UserType selectedType;

@end

@implementation WelcomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.selectedType = UserTypeGuest;
    [self setupUI];
}

- (void)setupUI {
    self.view.backgroundColor = [UIColor blackColor];

    // Gradient background
    self.gradientView = [[UIView alloc] init];
    self.gradientView.frame = self.view.bounds;
    [self.view addSubview:self.gradientView];

    // Logo container
    self.logoView = [[UIView alloc] init];
    self.logoView.backgroundColor = [UIColor clearColor];
    self.logoView.layer.cornerRadius = 24;
    [self.view addSubview:self.logoView];

    // Logo text "Hi"
    self.logoLabel = [[UILabel alloc] init];
    self.logoLabel.text = @"Hi";
    self.logoLabel.font = [UIFont systemFontOfSize:40 weight:UIFontWeightBold];
    self.logoLabel.textColor = [UIColor whiteColor];
    self.logoLabel.textAlignment = NSTextAlignmentCenter;
    [self.logoView addSubview:self.logoLabel];

    // App name
    self.appNameLabel = [[UILabel alloc] init];
    self.appNameLabel.text = @"Hiyo";
    self.appNameLabel.font = [UIFont systemFontOfSize:28 weight:UIFontWeightBold];
    self.appNameLabel.textColor = [UIColor whiteColor];
    [self.view addSubview:self.appNameLabel];

    // Slogan
    self.sloganLabel = [[UILabel alloc] init];
    self.sloganLabel.text = @"与陌生人交朋友";
    self.sloganLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
    self.sloganLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.6];
    [self.view addSubview:self.sloganLabel];

    // Guest card
    self.guestCard = [[UIView alloc] init];
    self.guestCard.backgroundColor = [UIColor colorWithWhite:0.2 alpha:1.0];
    self.guestCard.layer.cornerRadius = 16;
    self.guestCard.layer.borderWidth = 2;
    self.guestCard.layer.borderColor = [UIColor systemPinkColor].CGColor;
    self.guestCard.tag = UserTypeGuest;
    UITapGestureRecognizer *guestTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cardTapped:)];
    [self.guestCard addGestureRecognizer:guestTap];
    [self.view addSubview:self.guestCard];

    self.guestIcon = [[UIImageView alloc] init];
    self.guestIcon.image = [UIImage systemImageNamed:@"person"];
    self.guestIcon.tintColor = [UIColor systemPinkColor];
    self.guestIcon.contentMode = UIViewContentModeScaleAspectFit;
    [self.guestCard addSubview:self.guestIcon];

    self.guestLabel = [[UILabel alloc] init];
    self.guestLabel.text = @"游客";
    self.guestLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    self.guestLabel.textColor = [UIColor whiteColor];
    [self.guestCard addSubview:self.guestLabel];

    // Login card
    self.loginCard = [[UIView alloc] init];
    self.loginCard.backgroundColor = [UIColor clearColor];
    self.loginCard.layer.cornerRadius = 16;
    self.loginCard.layer.borderWidth = 2;
    self.loginCard.layer.borderColor = [UIColor colorWithWhite:0.3 alpha:1.0].CGColor;
    self.loginCard.tag = UserTypeLogin;
    UITapGestureRecognizer *loginTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cardTapped:)];
    [self.loginCard addGestureRecognizer:loginTap];
    [self.view addSubview:self.loginCard];

    self.loginIcon = [[UIImageView alloc] init];
    self.loginIcon.image = [UIImage systemImageNamed:@"person.fill"];
    self.loginIcon.tintColor = [UIColor colorWithWhite:0.6 alpha:1.0];
    self.loginIcon.contentMode = UIViewContentModeScaleAspectFit;
    [self.loginCard addSubview:self.loginIcon];

    self.loginLabel = [[UILabel alloc] init];
    self.loginLabel.text = @"登录";
    self.loginLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    self.loginLabel.textColor = [UIColor colorWithWhite:0.6 alpha:1.0];
    [self.loginCard addSubview:self.loginLabel];

    // Start button
    self.startButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.startButton setTitle:@"开始" forState:UIControlStateNormal];
    [self.startButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.startButton.titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];
    self.startButton.backgroundColor = [UIColor clearColor];
    self.startButton.layer.cornerRadius = 28;
    [self.startButton addTarget:self action:@selector(startTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.startButton];

    [self updateCardSelection];
    [self setupConstraints];
}

- (void)setupConstraints {
    self.logoView.translatesAutoresizingMaskIntoConstraints = NO;
    self.logoLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.appNameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.sloganLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.guestCard.translatesAutoresizingMaskIntoConstraints = NO;
    self.guestIcon.translatesAutoresizingMaskIntoConstraints = NO;
    self.guestLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.loginCard.translatesAutoresizingMaskIntoConstraints = NO;
    self.loginIcon.translatesAutoresizingMaskIntoConstraints = NO;
    self.loginLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.startButton.translatesAutoresizingMaskIntoConstraints = NO;

    UILayoutGuide *safeArea = self.view.safeAreaLayoutGuide;

    [NSLayoutConstraint activateConstraints:@[
        // Logo view
        [self.logoView.topAnchor constraintEqualToAnchor:safeArea.topAnchor constant:80],
        [self.logoView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.logoView.widthAnchor constraintEqualToConstant:100],
        [self.logoView.heightAnchor constraintEqualToConstant:100],

        // Logo label
        [self.logoLabel.centerXAnchor constraintEqualToAnchor:self.logoView.centerXAnchor],
        [self.logoLabel.centerYAnchor constraintEqualToAnchor:self.logoView.centerYAnchor],

        // App name
        [self.appNameLabel.topAnchor constraintEqualToAnchor:self.logoView.bottomAnchor constant:16],
        [self.appNameLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],

        // Slogan
        [self.sloganLabel.topAnchor constraintEqualToAnchor:self.appNameLabel.bottomAnchor constant:8],
        [self.sloganLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],

        // Guest card
        [self.guestCard.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:24],
        [self.guestCard.trailingAnchor constraintEqualToAnchor:self.view.centerXAnchor constant:-8],
        [self.guestCard.bottomAnchor constraintEqualToAnchor:self.startButton.topAnchor constant:-40],
        [self.guestCard.heightAnchor constraintEqualToConstant:120],

        // Guest icon
        [self.guestIcon.centerXAnchor constraintEqualToAnchor:self.guestCard.centerXAnchor],
        [self.guestIcon.topAnchor constraintEqualToAnchor:self.guestCard.topAnchor constant:24],
        [self.guestIcon.widthAnchor constraintEqualToConstant:40],
        [self.guestIcon.heightAnchor constraintEqualToConstant:40],

        // Guest label
        [self.guestLabel.centerXAnchor constraintEqualToAnchor:self.guestCard.centerXAnchor],
        [self.guestLabel.topAnchor constraintEqualToAnchor:self.guestIcon.bottomAnchor constant:8],

        // Login card
        [self.loginCard.leadingAnchor constraintEqualToAnchor:self.view.centerXAnchor constant:8],
        [self.loginCard.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-24],
        [self.loginCard.bottomAnchor constraintEqualToAnchor:self.startButton.topAnchor constant:-40],
        [self.loginCard.heightAnchor constraintEqualToConstant:120],

        // Login icon
        [self.loginIcon.centerXAnchor constraintEqualToAnchor:self.loginCard.centerXAnchor],
        [self.loginIcon.topAnchor constraintEqualToAnchor:self.loginCard.topAnchor constant:24],
        [self.loginIcon.widthAnchor constraintEqualToConstant:40],
        [self.loginIcon.heightAnchor constraintEqualToConstant:40],

        // Login label
        [self.loginLabel.centerXAnchor constraintEqualToAnchor:self.loginCard.centerXAnchor],
        [self.loginLabel.topAnchor constraintEqualToAnchor:self.loginIcon.bottomAnchor constant:8],

        // Start button
        [self.startButton.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:24],
        [self.startButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-24],
        [self.startButton.bottomAnchor constraintEqualToAnchor:safeArea.bottomAnchor constant:-48],
        [self.startButton.heightAnchor constraintEqualToConstant:56]
    ]];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.gradientView.frame = self.view.bounds;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self setupGradientIfNeeded];
}

- (void)setupGradientIfNeeded {
    for (CALayer *layer in self.gradientView.layer.sublayers) {
        if ([layer isKindOfClass:[CAGradientLayer class]]) return;
    }

    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.frame = self.view.bounds;
    gradientLayer.colors = @[
        (id)[UIColor colorWithRed:139/255.0 green:92/255.0 blue:246/255.0 alpha:1].CGColor,
        (id)[UIColor colorWithRed:236/255.0 green:72/255.0 blue:153/255.0 alpha:1].CGColor
    ];
    gradientLayer.startPoint = CGPointMake(0, 0);
    gradientLayer.endPoint = CGPointMake(1, 1);
    [self.gradientView.layer insertSublayer:gradientLayer atIndex:0];

    // Logo gradient
    CAGradientLayer *logoGradient = [CAGradientLayer layer];
    logoGradient.frame = self.logoView.bounds;
    logoGradient.colors = @[
        (id)[UIColor colorWithRed:236/255.0 green:72/255.0 blue:153/255.0 alpha:1].CGColor,
        (id)[UIColor colorWithRed:139/255.0 green:92/255.0 blue:246/255.0 alpha:1].CGColor
    ];
    logoGradient.startPoint = CGPointMake(0, 0);
    logoGradient.endPoint = CGPointMake(1, 1);
    logoGradient.cornerRadius = 24;
    [self.logoView.layer insertSublayer:logoGradient atIndex:0];

    // Button gradient
    CAGradientLayer *buttonGradient = [CAGradientLayer layer];
    buttonGradient.frame = self.startButton.bounds;
    buttonGradient.colors = @[
        (id)[UIColor colorWithRed:236/255.0 green:72/255.0 blue:153/255.0 alpha:1].CGColor,
        (id)[UIColor colorWithRed:139/255.0 green:92/255.0 blue:246/255.0 alpha:1].CGColor
    ];
    buttonGradient.startPoint = CGPointMake(0, 0);
    buttonGradient.endPoint = CGPointMake(1, 1);
    buttonGradient.cornerRadius = 28;
    [self.startButton.layer insertSublayer:buttonGradient atIndex:0];
}

- (void)cardTapped:(UITapGestureRecognizer *)gesture {
    UIView *card = gesture.view;
    self.selectedType = (UserType)card.tag;
    [self updateCardSelection];
}

- (void)updateCardSelection {
    if (self.selectedType == UserTypeGuest) {
        self.guestCard.backgroundColor = [UIColor colorWithWhite:0.2 alpha:1.0];
        self.guestCard.layer.borderColor = [UIColor systemPinkColor].CGColor;
        self.guestIcon.tintColor = [UIColor systemPinkColor];
        self.guestLabel.textColor = [UIColor whiteColor];

        self.loginCard.backgroundColor = [UIColor clearColor];
        self.loginCard.layer.borderColor = [UIColor colorWithWhite:0.3 alpha:1.0].CGColor;
        self.loginIcon.tintColor = [UIColor colorWithWhite:0.6 alpha:1.0];
        self.loginLabel.textColor = [UIColor colorWithWhite:0.6 alpha:1.0];
    } else {
        self.guestCard.backgroundColor = [UIColor clearColor];
        self.guestCard.layer.borderColor = [UIColor colorWithWhite:0.3 alpha:1.0].CGColor;
        self.guestIcon.tintColor = [UIColor colorWithWhite:0.6 alpha:1.0];
        self.guestLabel.textColor = [UIColor colorWithWhite:0.6 alpha:1.0];

        self.loginCard.backgroundColor = [UIColor colorWithWhite:0.2 alpha:1.0];
        self.loginCard.layer.borderColor = [UIColor systemPinkColor].CGColor;
        self.loginIcon.tintColor = [UIColor systemPinkColor];
        self.loginLabel.textColor = [UIColor whiteColor];
    }
}

- (void)startTapped {
    if (self.selectedType == UserTypeGuest) {
        if (self.onGuestStart) {
            self.onGuestStart();
        }
    } else {
        if (self.onLoginClick) {
            self.onLoginClick();
        }
    }
}

@end
