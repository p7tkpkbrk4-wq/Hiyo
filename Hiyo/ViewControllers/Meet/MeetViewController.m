#import "MeetViewController.h"
#import "HYAPIClient.h"
#import "HYUser.h"
#import "ChatDetailViewController.h"
#import <Masonry/Masonry.h>
#import <ZLSwipeableView.h>
#import <SDWebImage/SDWebImage.h>
#import <AVFoundation/AVFoundation.h>

static NSInteger const kPrefetchImageCount = 6;

// Color definitions (matching Android theme)
#define PrimaryPink [UIColor colorWithRed:1.0 green:0.42 blue:0.616 alpha:1.0]
#define PrimaryPurple [UIColor colorWithRed:0.77 green:0.31 blue:0.886 alpha:1.0]
#define PrimaryViolet [UIColor colorWithRed:0.482 green:0.373 blue:1.0 alpha:1.0]
#define DarkBackground [UIColor colorWithRed:0.039 green:0.039 blue:0.078 alpha:1.0]
#define DarkCard [UIColor colorWithRed:0.11 green:0.11 blue:0.18 alpha:1.0]
#define TextPrimary [UIColor whiteColor]
#define TextSecondary [UIColor colorWithRed:0.702 green:0.702 blue:0.8 alpha:1.0]
#define GlassPurple [UIColor colorWithRed:0.15 green:0.31 blue:0.886 alpha:0.15]
#define BorderPurple [UIColor colorWithRed:0.77 green:0.31 blue:0.886 alpha:0.4]
#define BorderLight [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.15]
#define BorderGlow [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.3]
#define OnlineGreen [UIColor colorWithRed:0.298 green:0.686 blue:0.314 alpha:1.0]
#define DislikeRed [UIColor colorWithRed:0.898 green:0.224 blue:0.208 alpha:1.0]
#define LikeGreen [UIColor colorWithRed:0.298 green:0.686 blue:0.314 alpha:1.0]

#pragma mark - HYUserCardView

@interface HYUserCardView : UIView

@property (nonatomic, strong, nullable) HYUser *user;
@property (nonatomic, assign) BOOL isTopCard;

// UI elements
@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic, strong) CAGradientLayer *gradientLayer;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *onlineLabel;
@property (nonatomic, strong) UIView *onlineDot;
@property (nonatomic, strong) UILabel *addressLabel;
@property (nonatomic, strong) UILabel *bioLabel;
@property (nonatomic, strong) UILabel *likeLabel;
@property (nonatomic, strong) UILabel *nopeLabel;
@property (nonatomic, strong) UIButton *voiceButton;
@property (nonatomic, strong) AVAudioPlayer *audioPlayer;
@property (nonatomic, assign) BOOL isPlayingVoice;

- (void)updateWithUser:(HYUser *)user isTopCard:(BOOL)isTopCard;
- (void)updateSwipeOverlay:(CGFloat)offsetX swipeThreshold:(CGFloat)threshold;

@end

@implementation HYUserCardView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupViews];
    }
    return self;
}

- (void)setupViews {
    self.backgroundColor = [UIColor whiteColor];
    self.layer.cornerRadius = 8;
    self.clipsToBounds = YES;
    self.layer.shadowColor = [UIColor blackColor].CGColor;
    self.layer.shadowOffset = CGSizeMake(0, 4);
    self.layer.shadowRadius = 8;
    self.layer.shadowOpacity = 0.15;
    self.layer.masksToBounds = NO;

    // Avatar
    self.avatarImageView = [[UIImageView alloc] init];
    self.avatarImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.avatarImageView.clipsToBounds = YES;
    self.avatarImageView.backgroundColor = [UIColor systemGray5Color];
    [self addSubview:self.avatarImageView];

    // Gradient overlay
    self.gradientLayer = [CAGradientLayer layer];
    self.gradientLayer.colors = @[
        (id)[UIColor clearColor].CGColor,
        (id)[PrimaryPurple colorWithAlphaComponent:0.15].CGColor,
        (id)[PrimaryViolet colorWithAlphaComponent:0.35].CGColor,
        (id)[UIColor colorWithWhite:0 alpha:0.7].CGColor
    ];
    self.gradientLayer.locations = @[@0.0, @0.45, @0.7, @1.0];
    [self.layer addSublayer:self.gradientLayer];

    // Online indicator
    self.onlineDot = [[UIView alloc] init];
    self.onlineDot.backgroundColor = OnlineGreen;
    self.onlineDot.layer.cornerRadius = 4;
    [self addSubview:self.onlineDot];

    self.onlineLabel = [[UILabel alloc] init];
    self.onlineLabel.text = @"当前在线";
    self.onlineLabel.font = [UIFont systemFontOfSize:11];
    self.onlineLabel.textColor = OnlineGreen;
    [self addSubview:self.onlineLabel];

    // Name + Age
    self.nameLabel = [[UILabel alloc] init];
    self.nameLabel.font = [UIFont systemFontOfSize:26 weight:UIFontWeightBold];
    self.nameLabel.textColor = TextPrimary;
    [self addSubview:self.nameLabel];

    // Address
    self.addressLabel = [[UILabel alloc] init];
    self.addressLabel.font = [UIFont systemFontOfSize:14];
    self.addressLabel.textColor = [TextPrimary colorWithAlphaComponent:0.8];
    [self addSubview:self.addressLabel];

    // Bio
    self.bioLabel = [[UILabel alloc] init];
    self.bioLabel.font = [UIFont systemFontOfSize:14];
    self.bioLabel.textColor = [TextPrimary colorWithAlphaComponent:0.9];
    self.bioLabel.numberOfLines = 2;
    [self addSubview:self.bioLabel];

    // LIKE label
    self.likeLabel = [[UILabel alloc] init];
    self.likeLabel.text = @"LIKE";
    self.likeLabel.font = [UIFont systemFontOfSize:42 weight:UIFontWeightBold];
    self.likeLabel.textColor = LikeGreen;
    self.likeLabel.alpha = 0;
    self.likeLabel.layer.borderColor = LikeGreen.CGColor;
    self.likeLabel.layer.borderWidth = 3;
    self.likeLabel.layer.cornerRadius = 8;
    self.likeLabel.textAlignment = NSTextAlignmentCenter;
    [self.likeLabel sizeToFit];
    [self addSubview:self.likeLabel];

    // NOPE label
    self.nopeLabel = [[UILabel alloc] init];
    self.nopeLabel.text = @"NOPE";
    self.nopeLabel.font = [UIFont systemFontOfSize:42 weight:UIFontWeightBold];
    self.nopeLabel.textColor = DislikeRed;
    self.nopeLabel.alpha = 0;
    self.nopeLabel.layer.borderColor = DislikeRed.CGColor;
    self.nopeLabel.layer.borderWidth = 3;
    self.nopeLabel.layer.cornerRadius = 8;
    self.nopeLabel.textAlignment = NSTextAlignmentCenter;
    [self.nopeLabel sizeToFit];
    [self addSubview:self.nopeLabel];

    // Voice button
    self.voiceButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.voiceButton.alpha = 0;
    [self.voiceButton setImage:[UIImage systemImageNamed:@"play.fill"] forState:UIControlStateNormal];
    self.voiceButton.tintColor = [UIColor whiteColor];
    self.voiceButton.backgroundColor = [PrimaryPurple colorWithAlphaComponent:0.85];
    self.voiceButton.layer.cornerRadius = 24;
    self.voiceButton.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.3].CGColor;
    self.voiceButton.layer.borderWidth = 1.5;
    [self.voiceButton addTarget:self action:@selector(voiceButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.voiceButton];

    [self setupConstraints];
}

- (void)setupConstraints {
    [self.avatarImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];

    [self.onlineDot mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).offset(20);
        make.bottom.equalTo(self.nameLabel.mas_top).offset(-8);
        make.width.height.equalTo(@8);
    }];

    [self.onlineLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.onlineDot.mas_right).offset(6);
        make.centerY.equalTo(self.onlineDot);
    }];

    [self.nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).offset(20);
        make.bottom.equalTo(self.bioLabel.mas_top).offset(-8);
    }];

    [self.addressLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).offset(20);
        make.bottom.equalTo(self.nameLabel.mas_top).offset(-4);
    }];

    [self.bioLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).offset(20);
        make.right.equalTo(self).offset(-20);
        make.bottom.equalTo(self).offset(-20);
    }];

    [self.voiceButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self).offset(-20);
        make.bottom.equalTo(self).offset(-20);
        make.width.height.equalTo(@48);
    }];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.gradientLayer.frame = self.bounds;
}

- (void)updateWithUser:(HYUser *)user isTopCard:(BOOL)isTopCard {
    _user = user;
    _isTopCard = isTopCard;

    self.voiceButton.alpha = isTopCard && user.voiceUrl.length > 0 ? 1.0 : 0.0;

    if (!user) return;

    NSString *avatarUrl = user.avatar.length > 0 ? user.avatar : nil;
    if (avatarUrl) {
        [self.avatarImageView sd_setImageWithURL:[NSURL URLWithString:avatarUrl]
                                placeholderImage:[UIImage systemImageNamed:@"person.circle.fill"]];
    } else {
        self.avatarImageView.image = [UIImage systemImageNamed:@"person.circle.fill"];
        self.avatarImageView.tintColor = [UIColor systemGray3Color];
    }

    // Name + Age
    if (user.age > 0) {
        self.nameLabel.text = [NSString stringWithFormat:@"%@, %ld", user.name, (long)user.age];
    } else {
        self.nameLabel.text = user.name.length > 0 ? user.name : @"未知";
    }

    // Online indicator
    self.onlineDot.hidden = !user.isOnline;
    self.onlineLabel.hidden = !user.isOnline;

    // Address
    if (user.currentAddress.length > 0) {
        self.addressLabel.text = user.currentAddress;
        self.addressLabel.hidden = NO;
    } else {
        self.addressLabel.hidden = YES;
    }

    // Bio
    if (user.bio.length > 0) {
        self.bioLabel.text = [NSString stringWithFormat:@"\"\" %@", user.bio];
        self.bioLabel.hidden = NO;
    } else {
        self.bioLabel.hidden = YES;
    }

    // Reset swipe overlays
    self.likeLabel.alpha = 0;
    self.nopeLabel.alpha = 0;

    // Reset voice state
    self.isPlayingVoice = NO;
    [self.voiceButton setImage:[UIImage systemImageNamed:@"play.fill"] forState:UIControlStateNormal];
    [self.audioPlayer stop];
    self.audioPlayer = nil;
}

- (void)updateSwipeOverlay:(CGFloat)offsetX swipeThreshold:(CGFloat)threshold {
    if (!self.isTopCard) return;

    CGFloat progress = MIN(ABS(offsetX) / threshold, 1.0);

    if (offsetX > 50) {
        self.likeLabel.alpha = progress;
        self.likeLabel.transform = CGAffineTransformMakeRotation(-0.26); // -15deg
    } else {
        self.likeLabel.alpha = 0;
    }

    if (offsetX < -50) {
        self.nopeLabel.alpha = progress;
        self.nopeLabel.transform = CGAffineTransformMakeRotation(0.26); // +15deg
    } else {
        self.nopeLabel.alpha = 0;
    }

    // Position labels
    self.likeLabel.frame = CGRectMake(24, 24, 120, 56);
    self.nopeLabel.frame = CGRectMake(self.bounds.size.width - 144, 24, 120, 56);
}

- (void)voiceButtonTapped {
    if (!self.user.voiceUrl || self.user.voiceUrl.length == 0) return;

    if (self.isPlayingVoice) {
        [self.audioPlayer pause];
        self.isPlayingVoice = NO;
        [self.voiceButton setImage:[UIImage systemImageNamed:@"play.fill"] forState:UIControlStateNormal];
    } else {
        if (!self.audioPlayer) {
            NSURL *voiceURL = [NSURL URLWithString:self.user.voiceUrl];
            if (!voiceURL) return;

            NSError *error;
            self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:voiceURL error:&error];
            if (error) {
                NSLog(@"Voice playback error: %@", error.localizedDescription);
                return;
            }
            self.audioPlayer.delegate = (id<AVAudioPlayerDelegate>)self;
            [self.audioPlayer prepareToPlay];
        }
        [self.audioPlayer play];
        self.isPlayingVoice = YES;
        [self.voiceButton setImage:[UIImage systemImageNamed:@"pause.fill"] forState:UIControlStateNormal];
    }
}

#pragma mark - AVAudioPlayerDelegate

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    self.isPlayingVoice = NO;
    [self.voiceButton setImage:[UIImage systemImageNamed:@"play.fill"] forState:UIControlStateNormal];
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error {
    self.isPlayingVoice = NO;
    [self.voiceButton setImage:[UIImage systemImageNamed:@"play.fill"] forState:UIControlStateNormal];
}

- (void)dealloc {
    [self.audioPlayer stop];
    self.audioPlayer = nil;
}

@end

#pragma mark - MeetViewController

@interface MeetViewController () <ZLSwipeableViewDelegate, ZLSwipeableViewDataSource>

@property (nonatomic, strong) UIButton *filterButton;
@property (nonatomic, strong) ZLSwipeableView *swipeableView;
@property (nonatomic, strong) UIView *actionBar;
@property (nonatomic, strong) UIButton *undoButton;
@property (nonatomic, strong) UIButton *dislikeButton;
@property (nonatomic, strong) UIButton *likeButton;
@property (nonatomic, strong) UIButton *favoriteButton;
@property (nonatomic, strong) NSMutableArray<HYUser *> *matchUsers;
@property (nonatomic, strong) UIActivityIndicatorView *loadingIndicator;
@property (nonatomic, assign) NSInteger currentIndex;
@property (nonatomic, assign) NSInteger currentOffset;
@property (nonatomic, assign) BOOL isLoadingMore;
@property (nonatomic, strong) HYUser *lastSwipedUser;
@property (nonatomic, strong) HYUser *lastMatchedUser;

@property (nonatomic, strong) UIView *loginRequiredView;
@property (nonatomic, strong) UIView *emptyView;

@property (nonatomic, strong) UIView *matchOverlay;
@property (nonatomic, strong) UIImageView *matchAvatarImageView;
@property (nonatomic, strong) UILabel *matchTitleLabel;
@property (nonatomic, strong) UILabel *matchSubtitleLabel;
@property (nonatomic, strong) SDWebImagePrefetcher *imagePrefetcher;

@end

@implementation MeetViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"遇见";
    self.view.backgroundColor = DarkBackground;
    self.matchUsers = [NSMutableArray array];
    self.currentIndex = 0;
    self.currentOffset = 0;
    self.isLoadingMore = NO;

    // Initialize image prefetcher
    self.imagePrefetcher = [SDWebImagePrefetcher new];
    self.imagePrefetcher.maxConcurrentPrefetchCount = 4;

    [self setupUI];
    [self setupNotifications];
    [self loadData];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setupNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleUnauthorized)
                                                 name:HYAPIClientUnauthorizedNotification
                                               object:nil];
}

- (void)handleUnauthorized {
    [self showLoginRequired];
}

- (void)showLoginRequired {
    self.loginRequiredView.hidden = NO;
    self.swipeableView.hidden = YES;
    self.actionBar.hidden = YES;
}

- (void)hideLoginRequired {
    self.loginRequiredView.hidden = YES;
    self.swipeableView.hidden = NO;
    self.actionBar.hidden = NO;
}

#pragma mark - UI Setup

- (void)setupUI {
    self.view.backgroundColor = DarkBackground;

    // Configure navigation bar appearance
    if (@available(iOS 15.0, *)) {
        UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
        [appearance configureWithTransparentBackground];
        appearance.backgroundColor = [DarkBackground colorWithAlphaComponent:0.8];
        appearance.titleTextAttributes = @{NSForegroundColorAttributeName: TextPrimary};
        appearance.largeTitleTextAttributes = @{NSForegroundColorAttributeName: TextPrimary};
        self.navigationController.navigationBar.standardAppearance = appearance;
        self.navigationController.navigationBar.scrollEdgeAppearance = appearance;
    }
    self.navigationController.navigationBar.tintColor = PrimaryPurple;

    // Hiyo logo as navigation title view
    UIView *titleContainer = [[UIView alloc] init];
    UIImageView *hiyoHeart = [[UIImageView alloc] init];
    hiyoHeart.image = [UIImage systemImageNamed:@"heart.fill"];
    hiyoHeart.tintColor = PrimaryPink;
    hiyoHeart.contentMode = UIViewContentModeScaleAspectFit;
    [titleContainer addSubview:hiyoHeart];

    UILabel *hiyoLabel = [[UILabel alloc] init];
    hiyoLabel.text = @"Hiyo";
    hiyoLabel.font = [UIFont systemFontOfSize:22 weight:UIFontWeightBold];
    hiyoLabel.textColor = TextPrimary;
    [titleContainer addSubview:hiyoLabel];

    [hiyoHeart mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(titleContainer);
        make.centerY.equalTo(titleContainer);
        make.width.height.equalTo(@22);
    }];

    [hiyoLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(hiyoHeart.mas_right).offset(6);
        make.right.equalTo(titleContainer);
        make.centerY.equalTo(titleContainer);
    }];

    [titleContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@30);
    }];

    self.navigationItem.titleView = titleContainer;

    // Filter button as right bar button item
    self.filterButton = [UIButton buttonWithType:UIButtonTypeSystem];
    UIImage *starImg = [UIImage systemImageNamed:@"star.fill"];
    [self.filterButton setImage:starImg forState:UIControlStateNormal];
    self.filterButton.tintColor = PrimaryPurple;
    self.filterButton.backgroundColor = GlassPurple;
    self.filterButton.layer.cornerRadius = 18;
    self.filterButton.layer.borderColor = BorderPurple.CGColor;
    self.filterButton.layer.borderWidth = 1;
    [self.filterButton addTarget:self action:@selector(filterButtonTapped) forControlEvents:UIControlEventTouchUpInside];

    UIBarButtonItem *filterBarButton = [[UIBarButtonItem alloc] initWithCustomView:self.filterButton];
    self.navigationItem.rightBarButtonItem = filterBarButton;

    // Swipeable View
    self.swipeableView = [[ZLSwipeableView alloc] init];
    self.swipeableView.dataSource = self;
    self.swipeableView.delegate = self;
    self.swipeableView.numberOfActiveViews = 2;
    self.swipeableView.allowedDirection = ZLSwipeableViewDirectionHorizontal;
    self.swipeableView.minTranslationInPercent = 0.25;
    self.swipeableView.minVelocityInPointPerSecond = 500;
    [self.view addSubview:self.swipeableView];

    // Action Bar
    self.actionBar = [[UIView alloc] init];
    [self.view addSubview:self.actionBar];

    // Container for evenly spaced buttons
    UIStackView *buttonStack = [[UIStackView alloc] init];
    buttonStack.axis = UILayoutConstraintAxisHorizontal;
    buttonStack.distribution = UIStackViewDistributionEqualSpacing;
    buttonStack.alignment = UIStackViewAlignmentCenter;
    [self.actionBar addSubview:buttonStack];

    // Undo button (small)
    self.undoButton = [self makeActionButton:@"arrow.counterclockwise"
                                      size:52
                              backgroundColor:GlassPurple
                                    tintColor:PrimaryPurple
                                   borderColor:BorderPurple];
    [self.undoButton addTarget:self action:@selector(undoTapped) forControlEvents:UIControlEventTouchUpInside];
    [buttonStack addArrangedSubview:self.undoButton];

    // Dislike button (medium)
    self.dislikeButton = [self makeActionButton:@"xmark"
                                         size:64
                                 backgroundColor:DarkCard
                                       tintColor:DislikeRed
                                      borderColor:BorderLight];
    [self.dislikeButton addTarget:self action:@selector(dislikeTapped) forControlEvents:UIControlEventTouchUpInside];
    [buttonStack addArrangedSubview:self.dislikeButton];

    // Like button (large, gradient) - custom container approach
    UIView *likeContainer = [[UIView alloc] init];
    likeContainer.layer.cornerRadius = 38;
    likeContainer.layer.borderColor = BorderGlow.CGColor;
    likeContainer.layer.borderWidth = 1;
    likeContainer.layer.shadowColor = [UIColor blackColor].CGColor;
    likeContainer.layer.shadowOffset = CGSizeMake(0, 3);
    likeContainer.layer.shadowRadius = 6;
    likeContainer.layer.shadowOpacity = 0.2;

    // Gradient background inside container
    CAGradientLayer *likeGradient = [CAGradientLayer layer];
    likeGradient.colors = @[(id)PrimaryPink.CGColor, (id)PrimaryPurple.CGColor, (id)PrimaryViolet.CGColor];
    likeGradient.startPoint = CGPointMake(0, 0.5);
    likeGradient.endPoint = CGPointMake(1, 0.5);
    likeGradient.frame = CGRectMake(0, 0, 76, 76);
    likeGradient.cornerRadius = 38;
    [likeContainer.layer insertSublayer:likeGradient atIndex:0];

    // Heart icon image view (on top of gradient)
    UIImageView *likeHeartImageView = [[UIImageView alloc] init];
    likeHeartImageView.image = [UIImage systemImageNamed:@"heart.fill"];
    likeHeartImageView.tintColor = [UIColor whiteColor];
    likeHeartImageView.contentMode = UIViewContentModeScaleAspectFit;
    likeHeartImageView.userInteractionEnabled = NO;
    [likeContainer addSubview:likeHeartImageView];

    // Transparent button for tap handling (on top of everything)
    self.likeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.likeButton.frame = CGRectMake(0, 0, 76, 76);
    [self.likeButton addTarget:self action:@selector(likeTapped) forControlEvents:UIControlEventTouchUpInside];
    [likeContainer addSubview:self.likeButton];

    [likeContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.equalTo(@76);
    }];

    [likeHeartImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(likeContainer);
        make.width.height.equalTo(@36);
    }];

    [buttonStack addArrangedSubview:likeContainer];
    [self startHeartBobAnimation:likeHeartImageView];

    // Favorite button (small)
    self.favoriteButton = [self makeActionButton:@"star.fill"
                                         size:52
                                 backgroundColor:GlassPurple
                                       tintColor:PrimaryViolet
                                      borderColor:BorderPurple];
    [self.favoriteButton addTarget:self action:@selector(favoriteTapped) forControlEvents:UIControlEventTouchUpInside];
    [buttonStack addArrangedSubview:self.favoriteButton];

    // Loading indicator
    self.loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    self.loadingIndicator.color = PrimaryPink;
    self.loadingIndicator.hidesWhenStopped = YES;
    [self.view addSubview:self.loadingIndicator];

    // Login required view
    [self setupLoginRequiredView];

    // Empty view
    [self setupEmptyView];

    // Match overlay
    [self setupMatchOverlay];

    // Constraints
    [self setupConstraints];
}

- (UIButton *)makeActionButton:(NSString *)imageName size:(CGFloat)size backgroundColor:(UIColor *)bgColor tintColor:(UIColor *)tintColor borderColor:(UIColor *)borderColor {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    UIImage *img = [UIImage systemImageNamed:imageName];
    [button setImage:img forState:UIControlStateNormal];
    button.tintColor = tintColor;
    button.layer.cornerRadius = size / 2.0;
    button.layer.borderColor = borderColor.CGColor;
    button.layer.borderWidth = 1;
    button.layer.shadowColor = [UIColor blackColor].CGColor;
    button.layer.shadowOffset = CGSizeMake(0, 3);
    button.layer.shadowRadius = 6;
    button.layer.shadowOpacity = 0.2;

    if (bgColor) {
        button.backgroundColor = bgColor;
    } else {
        // Gradient background for like button
        CAGradientLayer *gradient = [CAGradientLayer layer];
        gradient.colors = @[(id)PrimaryPink.CGColor, (id)PrimaryPurple.CGColor, (id)PrimaryViolet.CGColor];
        gradient.startPoint = CGPointMake(0, 0.5);
        gradient.endPoint = CGPointMake(1, 0.5);
        gradient.frame = CGRectMake(0, 0, size, size);
        gradient.cornerRadius = size / 2.0;
        [button.layer insertSublayer:gradient atIndex:0];
    }

    [button mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.equalTo(@(size));
    }];

    return button;
}

- (void)setupConstraints {
    [self.swipeableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(8);
        make.left.equalTo(self.view).offset(12);
        make.right.equalTo(self.view).offset(-12);
        make.bottom.equalTo(self.actionBar.mas_top).offset(-12);
    }];

    [self.actionBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(24);
        make.right.equalTo(self.view).offset(-24);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-16);
        make.height.equalTo(@80);
    }];

    UIStackView *buttonStack = self.actionBar.subviews.firstObject;
    [buttonStack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.actionBar);
    }];

    [self.loadingIndicator mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.swipeableView);
    }];
}

- (void)setupLoginRequiredView {
    self.loginRequiredView = [[UIView alloc] init];
    self.loginRequiredView.backgroundColor = DarkBackground;
    self.loginRequiredView.hidden = YES;
    [self.view addSubview:self.loginRequiredView];

    UIView *card = [[UIView alloc] init];
    card.backgroundColor = DarkCard;
    card.layer.cornerRadius = 28;
    card.layer.borderColor = BorderPurple.CGColor;
    card.layer.borderWidth = 1;
    [self.loginRequiredView addSubview:card];

    UIImageView *iconView = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"lock.fill"]];
    iconView.tintColor = PrimaryPurple;
    iconView.contentMode = UIViewContentModeScaleAspectFit;
    [card addSubview:iconView];

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = @"需要登录";
    titleLabel.font = [UIFont systemFontOfSize:24 weight:UIFontWeightBold];
    titleLabel.textColor = TextPrimary;
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [card addSubview:titleLabel];

    UILabel *descLabel = [[UILabel alloc] init];
    descLabel.text = @"登录后查看更多精彩内容\n发现更多有趣的灵魂";
    descLabel.font = [UIFont systemFontOfSize:15];
    descLabel.textColor = TextSecondary;
    descLabel.textAlignment = NSTextAlignmentCenter;
    descLabel.numberOfLines = 0;
    [card addSubview:descLabel];

    UIButton *loginButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [loginButton setTitle:@"立即登录" forState:UIControlStateNormal];
    [loginButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    loginButton.titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
    loginButton.backgroundColor = PrimaryPink;
    loginButton.layer.cornerRadius = 28;
    [loginButton addTarget:self action:@selector(loginButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [card addSubview:loginButton];

    [self.loginRequiredView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];

    [card mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.loginRequiredView);
        make.left.equalTo(self.loginRequiredView).offset(32);
        make.right.equalTo(self.loginRequiredView).offset(-32);
    }];

    [iconView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(card).offset(32);
        make.centerX.equalTo(card);
        make.width.height.equalTo(@60);
    }];

    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(iconView.mas_bottom).offset(16);
        make.left.equalTo(card).offset(16);
        make.right.equalTo(card).offset(-16);
    }];

    [descLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(titleLabel.mas_bottom).offset(12);
        make.left.equalTo(card).offset(16);
        make.right.equalTo(card).offset(-16);
    }];

    [loginButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(descLabel.mas_bottom).offset(28);
        make.left.equalTo(card).offset(32);
        make.right.equalTo(card).offset(-32);
        make.height.equalTo(@56);
        make.bottom.equalTo(card).offset(-32);
    }];
}

- (void)setupEmptyView {
    self.emptyView = [[UIView alloc] init];
    self.emptyView.backgroundColor = [UIColor clearColor];
    self.emptyView.hidden = YES;
    [self.view addSubview:self.emptyView];

    UIView *iconBg = [[UIView alloc] init];
    iconBg.backgroundColor = GlassPurple;
    iconBg.layer.cornerRadius = 60;
    iconBg.layer.borderColor = BorderPurple.CGColor;
    iconBg.layer.borderWidth = 2;
    [self.emptyView addSubview:iconBg];

    UIImageView *refreshIcon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"arrow.counterclockwise"]];
    refreshIcon.tintColor = PrimaryPurple;
    refreshIcon.contentMode = UIViewContentModeScaleAspectFit;
    [iconBg addSubview:refreshIcon];

    UILabel *emptyTitle = [[UILabel alloc] init];
    emptyTitle.text = @"暂无更多推荐";
    emptyTitle.font = [UIFont systemFontOfSize:20 weight:UIFontWeightBold];
    emptyTitle.textColor = TextPrimary;
    emptyTitle.textAlignment = NSTextAlignmentCenter;
    [self.emptyView addSubview:emptyTitle];

    UILabel *emptyDesc = [[UILabel alloc] init];
    emptyDesc.text = @"刷新以查看新的推荐";
    emptyDesc.font = [UIFont systemFontOfSize:14];
    emptyDesc.textColor = TextSecondary;
    emptyDesc.textAlignment = NSTextAlignmentCenter;
    [self.emptyView addSubview:emptyDesc];

    UIButton *refreshButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [refreshButton setTitle:@"刷新" forState:UIControlStateNormal];
    [refreshButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    refreshButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightBold];
    refreshButton.backgroundColor = PrimaryPink;
    refreshButton.layer.cornerRadius = 28;
    [refreshButton addTarget:self action:@selector(refreshTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.emptyView addSubview:refreshButton];

    [self.emptyView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.swipeableView);
    }];

    [iconBg mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.emptyView);
        make.centerY.equalTo(self.emptyView).offset(-60);
        make.width.height.equalTo(@120);
    }];

    [refreshIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(iconBg);
        make.width.height.equalTo(@56);
    }];

    [emptyTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(iconBg.mas_bottom).offset(24);
        make.centerX.equalTo(self.emptyView);
    }];

    [emptyDesc mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(emptyTitle.mas_bottom).offset(8);
        make.centerX.equalTo(self.emptyView);
    }];

    [refreshButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(emptyDesc.mas_bottom).offset(28);
        make.centerX.equalTo(self.emptyView);
        make.height.equalTo(@56);
        make.width.equalTo(@140);
    }];
}

- (void)setupMatchOverlay {
    self.matchOverlay = [[UIView alloc] init];
    self.matchOverlay.backgroundColor = [DarkBackground colorWithAlphaComponent:0.9];
    self.matchOverlay.hidden = YES;
    self.matchOverlay.alpha = 0;
    [self.view addSubview:self.matchOverlay];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissMatchOverlay)];
    [self.matchOverlay addGestureRecognizer:tap];

    UIView *matchCard = [[UIView alloc] init];
    matchCard.backgroundColor = DarkCard;
    matchCard.layer.cornerRadius = 28;
    matchCard.layer.borderColor = BorderPurple.CGColor;
    matchCard.layer.borderWidth = 1;
    [self.matchOverlay addSubview:matchCard];

    self.matchAvatarImageView = [[UIImageView alloc] init];
    self.matchAvatarImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.matchAvatarImageView.layer.cornerRadius = 36;
    self.matchAvatarImageView.clipsToBounds = YES;
    self.matchAvatarImageView.layer.borderColor = BorderPurple.CGColor;
    self.matchAvatarImageView.layer.borderWidth = 2;
    [matchCard addSubview:self.matchAvatarImageView];

    self.matchTitleLabel = [[UILabel alloc] init];
    self.matchTitleLabel.text = @"配对成功!";
    self.matchTitleLabel.font = [UIFont systemFontOfSize:28 weight:UIFontWeightBold];
    self.matchTitleLabel.textColor = TextPrimary;
    self.matchTitleLabel.textAlignment = NSTextAlignmentCenter;
    [matchCard addSubview:self.matchTitleLabel];

    self.matchSubtitleLabel = [[UILabel alloc] init];
    self.matchSubtitleLabel.font = [UIFont systemFontOfSize:15];
    self.matchSubtitleLabel.textColor = TextSecondary;
    self.matchSubtitleLabel.textAlignment = NSTextAlignmentCenter;
    self.matchSubtitleLabel.numberOfLines = 0;
    [matchCard addSubview:self.matchSubtitleLabel];

    UIButton *chatButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [chatButton setTitle:@"开始聊天" forState:UIControlStateNormal];
    [chatButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    chatButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightBold];
    chatButton.backgroundColor = PrimaryPurple;
    chatButton.layer.cornerRadius = 24;
    [chatButton addTarget:self action:@selector(startChatTapped) forControlEvents:UIControlEventTouchUpInside];
    [matchCard addSubview:chatButton];

    UIButton *continueButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [continueButton setTitle:@"继续浏览" forState:UIControlStateNormal];
    [continueButton setTitleColor:TextSecondary forState:UIControlStateNormal];
    continueButton.titleLabel.font = [UIFont systemFontOfSize:16];
    [continueButton addTarget:self action:@selector(dismissMatchOverlay) forControlEvents:UIControlEventTouchUpInside];
    [matchCard addSubview:continueButton];

    [self.matchOverlay mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];

    [matchCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.matchOverlay);
        make.left.equalTo(self.matchOverlay).offset(32);
        make.right.equalTo(self.matchOverlay).offset(-32);
    }];

    [self.matchAvatarImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(matchCard).offset(32);
        make.centerX.equalTo(matchCard);
        make.width.height.equalTo(@72);
    }];

    [self.matchTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.matchAvatarImageView.mas_bottom).offset(16);
        make.left.equalTo(matchCard).offset(16);
        make.right.equalTo(matchCard).offset(-16);
    }];

    [self.matchSubtitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.matchTitleLabel.mas_bottom).offset(8);
        make.left.equalTo(matchCard).offset(16);
        make.right.equalTo(matchCard).offset(-16);
    }];

    [chatButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.matchSubtitleLabel.mas_bottom).offset(24);
        make.left.equalTo(matchCard).offset(24);
        make.right.equalTo(matchCard).offset(-24);
        make.height.equalTo(@48);
    }];

    [continueButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(chatButton.mas_bottom).offset(12);
        make.centerX.equalTo(matchCard);
        make.bottom.equalTo(matchCard).offset(-24);
    }];
}

#pragma mark - Heart Bob Animation

- (void)startHeartBobAnimation:(UIImageView *)heartView {
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.y"];
    animation.values = @[@0, @-4, @0];
    animation.keyTimes = @[@0, @0.5, @1];
    animation.duration = 1.2;
    animation.repeatCount = HUGE_VALF;
    animation.timingFunctions = @[
        [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut],
        [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]
    ];
    animation.removedOnCompletion = NO;
    [heartView.layer addAnimation:animation forKey:@"heartBob"];
}

#pragma mark - Actions

- (void)loginButtonTapped {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"HYNeedLoginNotification" object:nil];
}

- (void)refreshTapped {
    self.currentOffset = 0;
    self.currentIndex = 0;
    self.isLoadingMore = NO;
    [self.matchUsers removeAllObjects];
    [self.swipeableView discardAllViews];
    [self loadData];
}

- (void)filterButtonTapped {
    // TODO: Present filter sheet
    [self showBriefFeedback:@"筛选功能" color:PrimaryPurple];
}

- (void)undoTapped {
    [self.swipeableView rewind];
}

- (void)dislikeTapped {
    [self.swipeableView swipeTopViewToLeft];
}

- (void)likeTapped {
    [self.swipeableView swipeTopViewToRight];
}

- (void)favoriteTapped {
    HYUser *user = [self currentUser];
    if (!user) return;

    [[HYAPIClient shared] favoriteUserWithId:user.userId completion:^(NSDictionary *response, NSError *error) {
        if (error) {
            NSLog(@"Favorite failed: %@", error.localizedDescription);
        } else {
            // Show brief success feedback
            [self showBriefFeedback:@"已收藏" color:PrimaryViolet];
        }
    }];
}

- (void)showBriefFeedback:(NSString *)text color:(UIColor *)color {
    UILabel *label = [[UILabel alloc] init];
    label.text = text;
    label.font = [UIFont systemFontOfSize:16 weight:UIFontWeightBold];
    label.textColor = [UIColor whiteColor];
    label.backgroundColor = color;
    label.textAlignment = NSTextAlignmentCenter;
    label.layer.cornerRadius = 8;
    label.clipsToBounds = YES;
    label.alpha = 0;
    [self.view addSubview:label];

    [label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.centerY.equalTo(self.view);
        make.width.equalTo(@100);
        make.height.equalTo(@40);
    }];

    [UIView animateWithDuration:0.2 animations:^{
        label.alpha = 1.0;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.3 delay:0.8 options:0 animations:^{
            label.alpha = 0;
        } completion:^(BOOL finished) {
            [label removeFromSuperview];
        }];
    }];
}

- (void)dismissMatchOverlay {
    [UIView animateWithDuration:0.3 animations:^{
        self.matchOverlay.alpha = 0;
    } completion:^(BOOL finished) {
        self.matchOverlay.hidden = YES;
    }];
}

- (void)startChatTapped {
    [self dismissMatchOverlay];
    if (!self.lastMatchedUser) return;

    ChatDetailViewController *vc = [[ChatDetailViewController alloc] initWithPartnerId:[NSString stringWithFormat:@"%ld", (long)self.lastMatchedUser.userId]
                                                                        partnerName:self.lastMatchedUser.name
                                                                       partnerAvatar:self.lastMatchedUser.avatar];
    [self.navigationController pushViewController:vc animated:YES];
}

- (HYUser *)currentUser {
    if (self.currentIndex >= 0 && self.currentIndex < self.matchUsers.count) {
        return self.matchUsers[self.currentIndex];
    }
    return nil;
}

- (HYUser *)previousUser {
    if (self.currentIndex > 0 && self.currentIndex - 1 < self.matchUsers.count) {
        return self.matchUsers[self.currentIndex - 1];
    }
    return nil;
}

#pragma mark - Data Loading

- (void)loadData {
    self.isLoadingMore = YES;
    [self.loadingIndicator startAnimating];
    self.emptyView.hidden = YES;

    [self fetchMatchCardsWithCompletion:^(NSDictionary *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.isLoadingMore = NO;
            [self.loadingIndicator stopAnimating];
            [self handleFetchResult:response error:error];
        });
    }];
}

- (void)loadMoreData {
    self.isLoadingMore = YES;

    [self fetchMatchCardsWithCompletion:^(NSDictionary *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.isLoadingMore = NO;
            [self handleFetchResult:response error:error];
        });
    }];
}

- (void)fetchMatchCardsWithCompletion:(HYAPICompletion)completion {
    NSInteger limit = 20;
    [[HYAPIClient shared] getMatchCardsWithLimit:limit offset:self.currentOffset completion:completion];
}

- (void)handleFetchResult:(NSDictionary *)response error:(NSError *)error {
    if (error) {
        NSLog(@"Failed to load match cards: %@", error.localizedDescription);
        NSString *msg = error.localizedDescription.lowercaseString;
        if (error.code == 401 || [msg containsString:@"认证"] || [msg containsString:@"login"]) {
            [self showLoginRequired];
            return;
        }
        [self updateEmptyState];
        return;
    }

    NSDictionary *dataDict = response[@"data"];
    if ([dataDict isKindOfClass:[NSDictionary class]]) {
        NSArray *users = dataDict[@"users"];
        if ([users isKindOfClass:[NSArray class]] && users.count > 0) {
            for (NSDictionary *userDict in users) {
                if ([userDict isKindOfClass:[NSDictionary class]]) {
                    HYUser *user = [[HYUser alloc] initWithDictionary:userDict];
                    [self.matchUsers addObject:user];
                }
            }
            self.currentOffset += users.count;
            [self prefetchImagesForUpcomingCards];
            [self.swipeableView loadViewsIfNeeded];
            [self updateEmptyState];
        } else {
            [self updateEmptyState];
        }
    } else {
        [self updateEmptyState];
    }
}

- (void)prefetchImagesForUpcomingCards {
    NSInteger start = self.currentIndex;
    NSInteger end = MIN(self.currentIndex + kPrefetchImageCount, (NSInteger)self.matchUsers.count);

    if (start >= end) return;

    NSMutableArray<NSURL *> *urls = [NSMutableArray array];
    for (NSInteger i = start; i < end; i++) {
        HYUser *user = self.matchUsers[i];
        if (user.avatar.length > 0) {
            NSURL *url = [NSURL URLWithString:user.avatar];
            if (url) [urls addObject:url];
        }
        // Also preload background image (Android parity)
        if (user.backgroundImage.length > 0) {
            NSURL *bgUrl = [NSURL URLWithString:user.backgroundImage];
            if (bgUrl) [urls addObject:bgUrl];
        }
        // Also preload all photos (Android parity)
        for (NSString *photoUrl in user.photos) {
            if (photoUrl.length > 0) {
                NSURL *photoNSUrl = [NSURL URLWithString:photoUrl];
                if (photoNSUrl) [urls addObject:photoNSUrl];
            }
        }
    }

    if (urls.count == 0) return;

    [self.imagePrefetcher prefetchURLs:urls progress:nil completed:^(NSUInteger finishedCount, NSUInteger skippedCount) {
        NSLog(@"Prefetched %lu images, skipped %lu", (unsigned long)finishedCount, (unsigned long)skippedCount);
    }];
}

- (void)loadMoreIfNeeded {
    // Load more when less than 2 cards remaining
    if (self.isLoadingMore) return;
    if (self.matchUsers.count - self.currentIndex <= 2) {
        [self loadMoreData];
    }
}

- (void)updateEmptyState {
    BOOL hasNoUsers = self.currentIndex >= self.matchUsers.count;
    // Don't show empty state if we're currently loading more data
    BOOL shouldShowEmpty = hasNoUsers && !self.isLoadingMore;
    self.emptyView.hidden = !shouldShowEmpty;
    self.actionBar.hidden = hasNoUsers;
}

#pragma mark - ZLSwipeableViewDataSource

- (UIView *)nextViewForSwipeableView:(ZLSwipeableView *)swipeableView {
    if (self.currentIndex >= self.matchUsers.count) {
        [self loadMoreIfNeeded];
        return nil;
    }

    HYUser *user = self.matchUsers[self.currentIndex];
    self.currentIndex++;

    // Create card with correct frame
    HYUserCardView *card = [[HYUserCardView alloc] initWithFrame:swipeableView.bounds];
    [card updateWithUser:user isTopCard:YES];

    self.lastSwipedUser = user;
    [self updateEmptyState];

    return card;
}

#pragma mark - ZLSwipeableViewDelegate

- (void)swipeableView:(ZLSwipeableView *)swipeableView didSwipeView:(UIView *)view inDirection:(ZLSwipeableViewDirection)direction {
    if (!self.lastSwipedUser) return;
    HYUser *user = self.lastSwipedUser;

    if (direction == ZLSwipeableViewDirectionLeft) {
        [[HYAPIClient shared] dislikeUserWithId:user.userId completion:^(NSDictionary *response, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (error) {
                    // Check for rate limit error (Android parity)
                    if ([self isRateLimitError:error.localizedDescription]) {
                        [self showSwipeLimitDialog];
                    }
                }
            });
        }];
    } else if (direction == ZLSwipeableViewDirectionRight) {
        [[HYAPIClient shared] likeUserWithId:user.userId completion:^(NSDictionary *response, BOOL matched, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (error) {
                    // Check for rate limit error (Android parity)
                    if ([self isRateLimitError:error.localizedDescription]) {
                        [self showSwipeLimitDialog];
                    }
                } else if (matched) {
                    [self showMatchOverlayWithUser:user];
                }
            });
        }];
    }

    self.lastSwipedUser = nil;
    [self prefetchImagesForUpcomingCards];
    [self loadMoreIfNeeded];
    [self updateEmptyState];
}

- (void)swipeableView:(ZLSwipeableView *)swipeableView swipingView:(UIView *)view atLocation:(CGPoint)location translation:(CGPoint)translation {
    HYUserCardView *card = (HYUserCardView *)view;
    CGFloat threshold = self.view.bounds.size.width * 0.3;
    [card updateSwipeOverlay:translation.x swipeThreshold:threshold];
}

- (void)swipeableView:(ZLSwipeableView *)swipeableView didCancelSwipe:(UIView *)view {
    HYUserCardView *card = (HYUserCardView *)view;
    [card updateSwipeOverlay:0 swipeThreshold:0];
}

- (void)swipeableView:(ZLSwipeableView *)swipeableView didStartSwipingView:(UIView *)view atLocation:(CGPoint)location {
    // Could pause heartbeat here
}

#pragma mark - Match Overlay

- (void)showMatchOverlayWithUser:(HYUser *)user {
    self.lastMatchedUser = user;
    self.matchSubtitleLabel.text = [NSString stringWithFormat:@"你和 %@ 互相喜欢!", user.name];

    if (user.avatar.length > 0) {
        [self.matchAvatarImageView sd_setImageWithURL:[NSURL URLWithString:user.avatar]
                                    placeholderImage:[UIImage systemImageNamed:@"person.circle.fill"]];
    } else {
        self.matchAvatarImageView.image = [UIImage systemImageNamed:@"person.circle.fill"];
        self.matchAvatarImageView.tintColor = TextSecondary;
    }

    self.matchOverlay.hidden = NO;
    self.matchOverlay.alpha = 0;

    [UIView animateWithDuration:0.3 animations:^{
        self.matchOverlay.alpha = 1.0;
    }];
}

#pragma mark - Rate Limit (Android parity)

- (BOOL)isRateLimitError:(NSString *)message {
    if (!message) return NO;
    NSString *lower = [message lowercaseString];
    return [lower containsString:@"upgrade_vip"] ||
           [lower containsString:@"限额"] ||
           [lower containsString:@"次数"] ||
           [lower containsString:@"limit"] ||
           [lower containsString:@"vip"];
}

- (void)showSwipeLimitDialog {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"今日滑动次数已用完"
                                                                   message:@"升级VIP会员，解锁无限滑动次数"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *upgradeAction = [UIAlertAction actionWithTitle:@"升级VIP"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * _Nonnull action) {
        // TODO: Navigate to VIP upgrade screen when implemented
        [[NSNotificationCenter defaultCenter] postNotificationName:@"HYNavigateToVIPNotification" object:nil];
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"稍后再说"
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil];
    [alert addAction:upgradeAction];
    [alert addAction:cancelAction];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
