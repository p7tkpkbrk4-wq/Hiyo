#import "MeetViewController.h"
#import "HYAPIClient.h"
#import "HYUser.h"
#import "ChatDetailViewController.h"
#import "HYColors.h"
#import <Masonry/Masonry.h>
#import <ZLSwipeableView.h>
#import <SDWebImage/SDWebImage.h>
#import <AVFoundation/AVFoundation.h>

static NSInteger const kPrefetchImageCount = 6;

#pragma mark - HYUserCardView

@interface HYUserCardView : UIView

@property (nonatomic, strong, nullable) HYUser *user;
@property (nonatomic, assign) BOOL isTopCard;

// Avatar
@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic, strong) CAGradientLayer *gradientLayer;
// Info section (white background below avatar)
@property (nonatomic, strong) UIView *infoSection;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UIView *ageBadge;
@property (nonatomic, strong) UILabel *ageLabel;
@property (nonatomic, strong) UILabel *genderDistanceLabel;
@property (nonatomic, strong) UIView *vipBadge;
@property (nonatomic, strong) UILabel *vipLabel;
@property (nonatomic, strong) UILabel *bioLabel1;
@property (nonatomic, strong) UILabel *bioLabel2;
@property (nonatomic, strong) UIView *tagsContainer;
@property (nonatomic, strong) NSMutableArray<UIView *> *tagViews;
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
        self.tagViews = [NSMutableArray array];
        [self setupViews];
    }
    return self;
}

- (void)setupViews {
    // Card: white with 24pt corner radius + purple glow shadow
    self.backgroundColor = LightCard;
    self.layer.cornerRadius = 24;
    self.clipsToBounds = NO;
    self.layer.shadowColor = PurpleGradEnd.CGColor;
    self.layer.shadowOffset = CGSizeMake(0, 4);
    self.layer.shadowRadius = 12;
    self.layer.shadowOpacity = 0.15;

    // Avatar (top area ~65% of card)
    self.avatarImageView = [[UIImageView alloc] init];
    self.avatarImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.avatarImageView.clipsToBounds = YES;
    self.avatarImageView.backgroundColor = [UIColor colorWithRed:0.906 green:0.875 blue:1.0 alpha:1.0];
    [self addSubview:self.avatarImageView];

    // Gradient overlay on avatar bottom ~35%
    self.gradientLayer = [CAGradientLayer layer];
    self.gradientLayer.colors = @[
        (id)[UIColor clearColor].CGColor,
        (id)[UIColor clearColor].CGColor,
        (id)[UIColor colorWithWhite:0 alpha:0.15].CGColor,
        (id)[UIColor colorWithWhite:0 alpha:0.6].CGColor,
        (id)[UIColor colorWithWhite:0 alpha:0.85].CGColor
    ];
    self.gradientLayer.locations = @[@0.0, @0.55, @0.70, @0.88, @1.0];
    [self.layer addSublayer:self.gradientLayer];

    // Info section (white background below avatar)
    self.infoSection = [[UIView alloc] init];
    self.infoSection.backgroundColor = LightCard;
    [self addSubview:self.infoSection];

    // Name (on gradient overlay)
    self.nameLabel = [[UILabel alloc] init];
    self.nameLabel.font = [UIFont systemFontOfSize:26 weight:UIFontWeightBold];
    self.nameLabel.textColor = [UIColor whiteColor];
    self.nameLabel.layer.shadowColor = [UIColor blackColor].CGColor;
    self.nameLabel.layer.shadowOffset = CGSizeMake(0, 1);
    self.nameLabel.layer.shadowOpacity = 0.5;
    self.nameLabel.layer.shadowRadius = 2;
    [self addSubview:self.nameLabel];

    // Age badge (on gradient overlay)
    self.ageBadge = [[UIView alloc] init];
    self.ageBadge.backgroundColor = [UIColor colorWithWhite:1 alpha:0.3];
    self.ageBadge.layer.cornerRadius = 6;
    self.ageBadge.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.5].CGColor;
    self.ageBadge.layer.borderWidth = 1;
    [self addSubview:self.ageBadge];

    self.ageLabel = [[UILabel alloc] init];
    self.ageLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightBold];
    self.ageLabel.textColor = [UIColor whiteColor];
    [self.ageBadge addSubview:self.ageLabel];

    // Gender + distance (on gradient overlay)
    self.genderDistanceLabel = [[UILabel alloc] init];
    self.genderDistanceLabel.font = [UIFont systemFontOfSize:12];
    self.genderDistanceLabel.textColor = [UIColor colorWithWhite:1 alpha:0.9];
    [self addSubview:self.genderDistanceLabel];

    // VIP badge (on gradient overlay)
    self.vipBadge = [[UIView alloc] init];
    self.vipBadge.backgroundColor = VipGold;
    self.vipBadge.layer.cornerRadius = 9;
    self.vipBadge.alpha = 0;
    [self addSubview:self.vipBadge];

    self.vipLabel = [[UILabel alloc] init];
    self.vipLabel.text = @"⭐ VIP";
    self.vipLabel.font = [UIFont systemFontOfSize:9 weight:UIFontWeightBold];
    self.vipLabel.textColor = [UIColor colorWithRed:0.545 green:0.412 blue:0.078 alpha:1.0];
    [self.vipBadge addSubview:self.vipLabel];

    // Bio labels (in info section - dark text on white)
    self.bioLabel1 = [[UILabel alloc] init];
    self.bioLabel1.font = [UIFont systemFontOfSize:13];
    self.bioLabel1.textColor = [UIColor colorWithRed:0.25 green:0.25 blue:0.25 alpha:1.0];
    self.bioLabel1.numberOfLines = 2;
    [self.infoSection addSubview:self.bioLabel1];

    self.bioLabel2 = [[UILabel alloc] init];
    self.bioLabel2.font = [UIFont systemFontOfSize:13];
    self.bioLabel2.textColor = [UIColor colorWithRed:0.25 green:0.25 blue:0.25 alpha:1.0];
    self.bioLabel2.numberOfLines = 1;
    [self.infoSection addSubview:self.bioLabel2];

    // Interest tags (in info section - dark text)
    self.tagsContainer = [[UIView alloc] init];
    [self.infoSection addSubview:self.tagsContainer];

    // LIKE overlay
    self.likeLabel = [[UILabel alloc] init];
    self.likeLabel.text = @"LIKE";
    self.likeLabel.font = [UIFont systemFontOfSize:42 weight:UIFontWeightBold];
    self.likeLabel.textColor = OnlineGreenLight;
    self.likeLabel.alpha = 0;
    self.likeLabel.layer.borderColor = OnlineGreenLight.CGColor;
    self.likeLabel.layer.borderWidth = 3;
    self.likeLabel.layer.cornerRadius = 8;
    self.likeLabel.textAlignment = NSTextAlignmentCenter;
    [self.likeLabel sizeToFit];
    [self addSubview:self.likeLabel];

    // NOPE overlay
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
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.gradientLayer.frame = self.avatarImageView.frame;
}

- (void)setupConstraintsWithCardSize:(CGSize)cardSize {
    CGFloat avatarH = cardSize.height * 0.85;
    CGFloat padding = 20;
    CGFloat infoH = cardSize.height - avatarH;

    [self.avatarImageView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self);
        make.height.equalTo(@(avatarH));
    }];

    [self.infoSection mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.avatarImageView.mas_bottom);
        make.left.right.bottom.equalTo(self);
    }];

    [self.nameLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).offset(padding);
        make.top.equalTo(self.avatarImageView).offset(avatarH - 80);
    }];

    [self.ageBadge mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.nameLabel.mas_right).offset(10);
        make.centerY.equalTo(self.nameLabel);
        make.height.equalTo(@22);
    }];

    [self.ageLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.ageBadge).insets(UIEdgeInsetsMake(0, 10, 0, 10));
    }];

    [self.vipBadge mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.ageBadge.mas_right).offset(8);
        make.centerY.equalTo(self.ageBadge);
        make.height.equalTo(@18);
    }];

    [self.vipLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.vipBadge).insets(UIEdgeInsetsMake(0, 6, 0, 6));
    }];

    [self.genderDistanceLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).offset(padding);
        make.top.equalTo(self.nameLabel.mas_bottom).offset(4);
    }];

    [self.voiceButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self).offset(-padding);
        make.bottom.equalTo(self.avatarImageView).offset(-padding);
        make.width.height.equalTo(@48);
    }];

    // Info section layout
    [self.bioLabel1 mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.infoSection).offset(padding);
        make.right.equalTo(self.infoSection).offset(-padding);
        make.top.equalTo(self.infoSection).offset(14);
    }];

    [self.bioLabel2 mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.infoSection).offset(padding);
        make.right.equalTo(self.infoSection).offset(-padding);
        make.top.equalTo(self.bioLabel1.mas_bottom).offset(2);
    }];

    [self.tagsContainer mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.infoSection).offset(padding);
        make.right.lessThanOrEqualTo(self.infoSection).offset(-padding);
        make.top.equalTo(self.bioLabel2.mas_bottom).offset(10);
        make.height.equalTo(@22);
    }];
}

- (void)updateWithUser:(HYUser *)user isTopCard:(BOOL)isTopCard {
    _user = user;
    _isTopCard = isTopCard;

    self.voiceButton.alpha = isTopCard && user.voiceUrl.length > 0 ? 1.0 : 0.0;

    if (!user) return;

    // Avatar
    NSString *avatarUrl = user.avatar.length > 0 ? user.avatar : nil;
    if (avatarUrl) {
        [self.avatarImageView sd_setImageWithURL:[NSURL URLWithString:avatarUrl]
                                placeholderImage:[UIImage systemImageNamed:@"person.circle.fill"]];
    } else {
        self.avatarImageView.image = [UIImage systemImageNamed:@"person.circle.fill"];
        self.avatarImageView.tintColor = [UIColor colorWithRed:0.6 green:0.55 blue:0.75 alpha:1.0];
        self.avatarImageView.contentMode = UIViewContentModeCenter;
    }

    // Name
    self.nameLabel.text = user.name ?: @"未知";
    [self.nameLabel sizeToFit];

    // Age badge
    if (user.age > 0) {
        self.ageLabel.text = [NSString stringWithFormat:@"%ld", (long)user.age];
        self.ageBadge.hidden = NO;
    } else {
        self.ageBadge.hidden = YES;
    }
    [self.ageBadge sizeToFit];
    [self.ageLabel sizeToFit];

    // VIP badge
    self.vipBadge.alpha = user.isVip ? 1.0 : 0.0;

    // Gender + distance
    NSMutableString *gd = [NSMutableString string];
    if (user.sex == 1) {
        [gd appendString:@"♀  "];
    } else if (user.sex == 2) {
        [gd appendString:@"♂  "];
    }
    if (user.distance.length > 0) {
        [gd appendFormat:@"%@km", user.distance];
    }
    self.genderDistanceLabel.text = gd;
    [self.genderDistanceLabel sizeToFit];

    // Bio (dark text on white)
    NSString *bio = user.bio ?: @"";
    if (bio.length > 0) {
        NSArray *lines = [bio componentsSeparatedByString:@"\n"];
        self.bioLabel1.text = lines.count > 0 ? lines[0] : bio;
        self.bioLabel1.hidden = NO;
        self.bioLabel2.text = lines.count > 1 ? lines[1] : nil;
        self.bioLabel2.hidden = (lines.count <= 1);
    } else {
        self.bioLabel1.text = nil;
        self.bioLabel1.hidden = YES;
        self.bioLabel2.text = nil;
        self.bioLabel2.hidden = YES;
    }

    // Interest tags
    for (UIView *v in self.tagViews) [v removeFromSuperview];
    [self.tagViews removeAllObjects];

    if (user.interests.count > 0) {
        self.tagsContainer.hidden = NO;
        NSInteger tagCount = MIN(user.interests.count, 4);
        UIView *prev = nil;
        for (NSInteger i = 0; i < tagCount; i++) {
            NSString *tag = user.interests[i];
            UIView *tagView = [self makeTagView:tag index:i];
            [self.tagsContainer addSubview:tagView];
            [self.tagViews addObject:tagView];

            [tagView mas_remakeConstraints:^(MASConstraintMaker *make) {
                if (prev) {
                    make.left.equalTo(prev.mas_right).offset(8);
                } else {
                    make.left.equalTo(self.tagsContainer);
                }
                make.centerY.equalTo(self.tagsContainer);
                make.height.equalTo(@22);
            }];
            prev = tagView;
        }
    } else {
        self.tagsContainer.hidden = YES;
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

- (UIView *)makeTagView:(NSString *)tag index:(NSInteger)index {
    UIColor *bgColor;
    UIColor *textColor;
    if (index % 2 == 0) {
        bgColor = [UIColor colorWithRed:1.0 green:0.42 blue:0.62 alpha:0.15];
        textColor = PinkGradStart;
    } else {
        bgColor = [UIColor colorWithRed:0.608 green:0.498 blue:1.0 alpha:0.15];
        textColor = PurpleGradStart;
    }

    UIView *tagView = [[UIView alloc] init];
    tagView.backgroundColor = bgColor;
    tagView.layer.cornerRadius = 11;

    UILabel *tagLabel = [[UILabel alloc] init];
    tagLabel.text = tag;
    tagLabel.font = [UIFont systemFontOfSize:10 weight:UIFontWeightSemibold];
    tagLabel.textColor = textColor;
    [tagView addSubview:tagLabel];

    [tagLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(tagView).insets(UIEdgeInsetsMake(0, 12, 0, 12));
    }];

    return tagView;
}

- (void)updateSwipeOverlay:(CGFloat)offsetX swipeThreshold:(CGFloat)threshold {
    if (!self.isTopCard) return;

    CGFloat progress = MIN(ABS(offsetX) / threshold, 1.0);

    if (offsetX > 50) {
        self.likeLabel.alpha = progress;
        self.likeLabel.transform = CGAffineTransformMakeRotation(-0.26);
    } else {
        self.likeLabel.alpha = 0;
    }

    if (offsetX < -50) {
        self.nopeLabel.alpha = progress;
        self.nopeLabel.transform = CGAffineTransformMakeRotation(0.26);
    } else {
        self.nopeLabel.alpha = 0;
    }

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

@property (nonatomic, strong) UIButton *vipButton;
@property (nonatomic, strong) ZLSwipeableView *swipeableView;
@property (nonatomic, strong) UIView *actionBar;
@property (nonatomic, strong) UIButton *undoButton;
@property (nonatomic, strong) UIButton *dislikeButton;
@property (nonatomic, strong) UIView *likeContainer;
@property (nonatomic, strong) UIImageView *likeHeartView;
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
@property (nonatomic, strong) UILabel *hintLabel;

@end

@implementation MeetViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"遇见";
    self.matchUsers = [NSMutableArray array];
    self.currentIndex = 0;
    self.currentOffset = 0;
    self.isLoadingMore = NO;

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
    self.hintLabel.hidden = YES;
}

- (void)hideLoginRequired {
    self.loginRequiredView.hidden = YES;
    self.swipeableView.hidden = NO;
    self.actionBar.hidden = NO;
    self.hintLabel.hidden = NO;
}

#pragma mark - UI Setup

- (void)setupUI {
    [self setupBackground];
    [self setupNavigationBar];
    [self setupSwipeableView];
    [self setupActionBar];
    [self setupHintLabel];
    [self setupLoadingIndicator];
    [self setupLoginRequiredView];
    [self setupEmptyView];
    [self setupMatchOverlay];
}

- (void)setupBackground {
    self.view.backgroundColor = LightBg1;
}

- (void)setupNavigationBar {
    self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
    self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:0.608 green:0.498 blue:1.0 alpha:1.0];
    self.navigationController.navigationBar.titleTextAttributes = @{
        NSForegroundColorAttributeName: [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0],
        NSFontAttributeName: [UIFont systemFontOfSize:18 weight:UIFontWeightBlack]
    };
    if (@available(iOS 15.0, *)) {
        UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
        [appearance configureWithOpaqueBackground];
        appearance.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.9];
        appearance.titleTextAttributes = @{
            NSForegroundColorAttributeName: [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0],
            NSFontAttributeName: [UIFont systemFontOfSize:18 weight:UIFontWeightBlack]
        };
        appearance.shadowColor = [UIColor colorWithRed:0.933 green:0.933 blue:1.0 alpha:1.0];
        self.navigationController.navigationBar.standardAppearance = appearance;
        self.navigationController.navigationBar.scrollEdgeAppearance = appearance;
    } else {
        self.navigationController.navigationBar.translucent = NO;
        self.navigationController.navigationBar.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.9];
        UIView *navBorder = [[UIView alloc] init];
        navBorder.backgroundColor = [UIColor colorWithRed:0.933 green:0.933 blue:1.0 alpha:1.0];
        navBorder.translatesAutoresizingMaskIntoConstraints = NO;
        [self.navigationController.navigationBar addSubview:navBorder];
        [navBorder mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.bottom.equalTo(self.navigationController.navigationBar);
            make.height.equalTo(@1);
        }];
    }

    // VIP crown button wrapper with gradient circle background
    UIView *vipWrapper = [[UIView alloc] init];
    vipWrapper.layer.cornerRadius = 14;
    vipWrapper.clipsToBounds = YES;

    CAGradientLayer *vipGrad = [CAGradientLayer layer];
    vipGrad.colors = @[(id)PurpleGradStart.CGColor, (id)PurpleGradEnd.CGColor];
    vipGrad.startPoint = CGPointMake(0, 0);
    vipGrad.endPoint = CGPointMake(1, 1);
    vipGrad.frame = CGRectMake(0, 0, 28, 28);
    vipGrad.cornerRadius = 14;
    [vipWrapper.layer insertSublayer:vipGrad atIndex:0];

    // Solid inner circle
    CALayer *innerCircle = [CALayer layer];
    innerCircle.backgroundColor = PurpleGradStart.CGColor;
    innerCircle.cornerRadius = 8;
    innerCircle.frame = CGRectMake(6, 6, 16, 16);
    [vipWrapper.layer addSublayer:innerCircle];

    self.vipButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.vipButton.frame = CGRectMake(0, 0, 28, 28);
    [self.vipButton setImage:[UIImage imageNamed:@"crown_fill"] forState:UIControlStateNormal];
    self.vipButton.tintColor = [UIColor whiteColor];
    self.vipButton.backgroundColor = [UIColor clearColor];
    [self.vipButton addTarget:self action:@selector(vipButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [vipWrapper addSubview:self.vipButton];

    [vipWrapper mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.equalTo(@28);
    }];

    UIBarButtonItem *vipBarButton = [[UIBarButtonItem alloc] initWithCustomView:vipWrapper];
    self.navigationItem.rightBarButtonItem = vipBarButton;
}

- (void)setupSwipeableView {
    self.swipeableView = [[ZLSwipeableView alloc] init];
    self.swipeableView.dataSource = self;
    self.swipeableView.delegate = self;
    self.swipeableView.layer.maskedCorners = YES;
    self.swipeableView.layer.cornerRadius = 8.0f;
    self.swipeableView.numberOfActiveViews = 2;
    self.swipeableView.allowedDirection = ZLSwipeableViewDirectionHorizontal;
    self.swipeableView.minTranslationInPercent = 0.25;
    self.swipeableView.minVelocityInPointPerSecond = 500;
    [self.view addSubview:self.swipeableView];

    [self.swipeableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(0);
        make.left.equalTo(self.view).offset(8);
        make.right.equalTo(self.view).offset(-8);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-160);
    }];
}

- (void)setupActionBar {
    self.actionBar = [[UIView alloc] init];
    [self.view addSubview:self.actionBar];

    UIStackView *buttonStack = [[UIStackView alloc] init];
    buttonStack.axis = UILayoutConstraintAxisHorizontal;
    buttonStack.distribution = UIStackViewDistributionEqualSpacing;
    buttonStack.alignment = UIStackViewAlignmentCenter;
    [self.actionBar addSubview:buttonStack];

    // Undo (leftmost, small)
    self.undoButton = [self makeActionButton:@"arrow.counterclockwise"
                                        size:56
                                backgroundColor:[UIColor whiteColor]
                                      tintColor:PurpleGradStart
                                     borderColor:PurpleGradStart.CGColor
                                     borderWidth:1.5];
    self.undoButton.alpha = 0.4;
    [self.undoButton addTarget:self action:@selector(undoTapped) forControlEvents:UIControlEventTouchUpInside];
    [buttonStack addArrangedSubview:self.undoButton];

    // Dislike (X, medium)
    self.dislikeButton = [self makeActionButton:@"xmark"
                                         size:56
                                 backgroundColor:[UIColor whiteColor]
                                       tintColor:[UIColor colorWithRed:1.0 green:0.42 blue:0.42 alpha:1.0]
                                      borderColor:[UIColor colorWithRed:1.0 green:0.42 blue:0.42 alpha:1.0].CGColor
                                     borderWidth:2];
    [self.dislikeButton addTarget:self action:@selector(dislikeTapped) forControlEvents:UIControlEventTouchUpInside];
    [buttonStack addArrangedSubview:self.dislikeButton];

    // Like (large gradient heart)
    self.likeContainer = [[UIView alloc] init];
    self.likeContainer.layer.cornerRadius = 28;
    self.likeContainer.layer.shadowColor = PinkGradStart.CGColor;
    self.likeContainer.layer.shadowOffset = CGSizeMake(0, 0);
    self.likeContainer.layer.shadowRadius = 12;
    self.likeContainer.layer.shadowOpacity = 0.5;

    CAGradientLayer *likeGradient = [CAGradientLayer layer];
    likeGradient.colors = @[(id)PinkGradStart.CGColor, (id)PinkGradEnd.CGColor, (id)PrimaryViolet.CGColor];
    likeGradient.startPoint = CGPointMake(0, 0.5);
    likeGradient.endPoint = CGPointMake(1, 0.5);
    likeGradient.frame = CGRectMake(0, 0, 56, 56);
    likeGradient.cornerRadius = 28;
    [self.likeContainer.layer insertSublayer:likeGradient atIndex:0];

    self.likeHeartView = [[UIImageView alloc] init];
    self.likeHeartView.image = [UIImage imageNamed:@"heart"];
    self.likeHeartView.tintColor = [UIColor whiteColor];
    self.likeHeartView.contentMode = UIViewContentModeScaleAspectFit;
    self.likeHeartView.userInteractionEnabled = NO;
    [self.likeContainer addSubview:self.likeHeartView];

    self.likeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.likeButton.frame = CGRectMake(0, 0, 56, 56);
    [self.likeButton addTarget:self action:@selector(likeTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.likeContainer addSubview:self.likeButton];

    [self.likeContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.equalTo(@56);
    }];

    [self.likeHeartView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.likeContainer);
        make.width.height.equalTo(@36);
    }];

    [buttonStack addArrangedSubview:self.likeContainer];
    [self startHeartBobAnimation:self.likeHeartView];

    // Favorite (rightmost, small)
    self.favoriteButton = [self makeActionButton:@"star.fill"
                                         size:56
                                 backgroundColor:[UIColor whiteColor]
                                       tintColor:PrimaryViolet
                                      borderColor:PrimaryViolet.CGColor
                                      borderWidth:1.5];
    [self.favoriteButton addTarget:self action:@selector(favoriteTapped) forControlEvents:UIControlEventTouchUpInside];
    [buttonStack addArrangedSubview:self.favoriteButton];

    // Constraints
    [self.actionBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(24);
        make.right.equalTo(self.view).offset(-24);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-16);
        make.height.equalTo(@80);
    }];

    [buttonStack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.actionBar);
    }];
}

- (UIButton *)makeActionButton:(NSString *)imageName
                          size:(CGFloat)size
                 backgroundColor:(UIColor *)bgColor
                      tintColor:(UIColor *)tintColor
                     borderColor:(CGColorRef)borderColor
                     borderWidth:(CGFloat)borderWidth {

    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    UIImage *img = [UIImage imageNamed:imageName];
    if (!img) img = [UIImage systemImageNamed:imageName];
    [button setImage:img forState:UIControlStateNormal];
    button.tintColor = tintColor;
    button.backgroundColor = bgColor;
    button.layer.cornerRadius = size / 2.0;
    button.layer.borderColor = borderColor;
    button.layer.borderWidth = borderWidth;
    button.layer.shadowColor = [UIColor blackColor].CGColor;
    button.layer.shadowOffset = CGSizeMake(0, 3);
    button.layer.shadowRadius = 6;
    button.layer.shadowOpacity = 0.15;

    [button mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.equalTo(@(size));
    }];

    // Center image inside button using contentEdgeInsets
    CGFloat imgW = 0, imgH = 0;
    if (img) {
        imgW = img.size.width;
        imgH = img.size.height;
    }
    CGFloat horiz = (size - imgW) / 2.0;
    CGFloat vert = (size - imgH) / 2.0;
    button.contentEdgeInsets = UIEdgeInsetsMake(vert, horiz, vert, horiz);
    button.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 0);

    return button;
}

- (void)setupHintLabel {
    self.hintLabel = [[UILabel alloc] init];
    self.hintLabel.text = @"— 遇见 · 遇见心动 —";
    self.hintLabel.font = [UIFont systemFontOfSize:12];
    self.hintLabel.textColor = [UIColor colorWithRed:0.667 green:0.667 blue:0.667 alpha:1.0];
    self.hintLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.hintLabel];

    [self.hintLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.bottom.equalTo(self.actionBar.mas_top).offset(-8);
    }];
}

- (void)setupLoadingIndicator {
    self.loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    self.loadingIndicator.color = PurpleGradStart;
    self.loadingIndicator.hidesWhenStopped = YES;
    [self.view addSubview:self.loadingIndicator];

    [self.loadingIndicator mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.swipeableView);
    }];
}

- (void)setupLoginRequiredView {
    self.loginRequiredView = [[UIView alloc] init];
    self.loginRequiredView.backgroundColor = [UIColor clearColor];
    self.loginRequiredView.hidden = YES;
    [self.view addSubview:self.loginRequiredView];

    UIView *card = [[UIView alloc] init];
    card.backgroundColor = LightCard;
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
    titleLabel.textColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [card addSubview:titleLabel];

    UILabel *descLabel = [[UILabel alloc] init];
    descLabel.text = @"登录后查看更多精彩内容\n发现更多有趣的灵魂";
    descLabel.font = [UIFont systemFontOfSize:15];
    descLabel.textColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.6 alpha:1.0];
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
        make.edges.equalTo(self.swipeableView);
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
    iconBg.backgroundColor = [PurpleGradStart colorWithAlphaComponent:0.15];
    iconBg.layer.cornerRadius = 60;
    iconBg.layer.borderColor = BorderPurple.CGColor;
    iconBg.layer.borderWidth = 2;
    [self.emptyView addSubview:iconBg];

    UIImageView *refreshIcon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"arrow.counterclockwise"]];
    refreshIcon.tintColor = PurpleGradStart;
    refreshIcon.contentMode = UIViewContentModeScaleAspectFit;
    [iconBg addSubview:refreshIcon];

    UILabel *emptyTitle = [[UILabel alloc] init];
    emptyTitle.text = @"暂无更多推荐";
    emptyTitle.font = [UIFont systemFontOfSize:20 weight:UIFontWeightBold];
    emptyTitle.textColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0];
    emptyTitle.textAlignment = NSTextAlignmentCenter;
    [self.emptyView addSubview:emptyTitle];

    UILabel *emptyDesc = [[UILabel alloc] init];
    emptyDesc.text = @"刷新以查看新的推荐";
    emptyDesc.font = [UIFont systemFontOfSize:14];
    emptyDesc.textColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.6 alpha:1.0];
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
    self.matchOverlay.backgroundColor = [[UIColor colorWithRed:0.1 green:0.1 blue:0.15 alpha:0.9] colorWithAlphaComponent:0.9];
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

- (void)vipButtonTapped {
    [self showBriefFeedback:@"VIP" color:PurpleGradStart];
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
            [self showBriefFeedback:@"已收藏" color:PurpleGradStart];
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
        if (user.backgroundImage.length > 0) {
            NSURL *bgUrl = [NSURL URLWithString:user.backgroundImage];
            if (bgUrl) [urls addObject:bgUrl];
        }
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
    if (self.isLoadingMore) return;
    if (self.matchUsers.count - self.currentIndex <= 2) {
        [self loadMoreData];
    }
}

- (void)updateEmptyState {
    BOOL hasNoUsers = self.currentIndex >= self.matchUsers.count;
    BOOL shouldShowEmpty = hasNoUsers && !self.isLoadingMore;
    self.emptyView.hidden = !shouldShowEmpty;
    self.actionBar.hidden = hasNoUsers;
    self.hintLabel.hidden = hasNoUsers;
}

#pragma mark - ZLSwipeableViewDataSource

- (UIView *)nextViewForSwipeableView:(ZLSwipeableView *)swipeableView {
    if (self.currentIndex >= self.matchUsers.count) {
        [self loadMoreIfNeeded];
        return nil;
    }

    HYUser *user = self.matchUsers[self.currentIndex];
    self.currentIndex++;

    HYUserCardView *card = [[HYUserCardView alloc] initWithFrame:swipeableView.bounds];
    [card setupConstraintsWithCardSize:swipeableView.bounds.size];
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
                if (error && [self isRateLimitError:error.localizedDescription]) {
                    [self showSwipeLimitDialog];
                }
            });
        }];
    } else if (direction == ZLSwipeableViewDirectionRight) {
        [[HYAPIClient shared] likeUserWithId:user.userId completion:^(NSDictionary *response, BOOL matched, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (error && [self isRateLimitError:error.localizedDescription]) {
                    [self showSwipeLimitDialog];
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

#pragma mark - Rate Limit

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
