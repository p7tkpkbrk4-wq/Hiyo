#import "MyProfileViewController.h"
#import "HYAPIClient.h"
#import "HYUser.h"
#import "HYModels.h"
#import "HYColors.h"
#import "HYLoginRequiredView.h"
#import "EditProfileViewController.h"
#import "SettingsViewController.h"
#import "FollowListViewController.h"
#import "FullscreenPhotoViewController.h"
#import "PostDetailViewController.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/SDWebImage.h>
#import <PhotosUI/PhotosUI.h>

@interface MyProfileViewController () <UIScrollViewDelegate, PHPickerViewControllerDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;

// Header card
@property (nonatomic, strong) UIView *headerCard;
@property (nonatomic, strong) UIImageView *coverImageView;
@property (nonatomic, strong) UIView *coverOverlay;
@property (nonatomic, strong) UIView *avatarContainer;
@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic, strong) UIImageView *crownImageView;
@property (nonatomic, strong) UIView *onlineIndicator;
@property (nonatomic, strong) UIView *onlineGreenDot;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UIView *genderAgeBadge;
@property (nonatomic, strong) UILabel *genderAgeLabel;
@property (nonatomic, strong) UIView *vipBadge;
@property (nonatomic, strong) UILabel *vipLabel;
@property (nonatomic, strong) UIView *statsDivider;
@property (nonatomic, strong) UILabel *followersCount;
@property (nonatomic, strong) UILabel *followersTitle;
@property (nonatomic, strong) UILabel *followingCount;
@property (nonatomic, strong) UILabel *followingTitle;
@property (nonatomic, strong) UILabel *visitorsCount;
@property (nonatomic, strong) UILabel *visitorsTitle;

// Nav bar buttons
@property (nonatomic, strong) UIButton *settingsButton;
@property (nonatomic, strong) UIButton *editButton;

// Photo wall
@property (nonatomic, strong) UIView *photoWallCard;
@property (nonatomic, strong) UILabel *photoTitle;
@property (nonatomic, strong) UIView *photoScrollContent;
@property (nonatomic, strong) NSMutableArray<UIImageView *> *photoImageViews;
@property (nonatomic, strong) UIButton *addPhotoButton;

// Bio card
@property (nonatomic, strong) UIView *bioCard;
@property (nonatomic, strong) UIView *bioAccentBar;
@property (nonatomic, strong) UILabel *bioTitle;
@property (nonatomic, strong) UILabel *bioContent;

// About me card
@property (nonatomic, strong) UIView *aboutCard;
@property (nonatomic, strong) UIView *aboutAccentBar;
@property (nonatomic, strong) UILabel *aboutTitle;
@property (nonatomic, strong) UIView *aboutTagsContainer;

// Interests card
@property (nonatomic, strong) UIView *interestsCard;
@property (nonatomic, strong) UIView *interestsAccentBar;
@property (nonatomic, strong) UILabel *interestsTitle;
@property (nonatomic, strong) UIView *interestsTagsContainer;

// My posts card
@property (nonatomic, strong) UIView *postsCard;
@property (nonatomic, strong) UIView *postsAccentBar;
@property (nonatomic, strong) UILabel *postsTitle;
@property (nonatomic, strong) UILabel *postsSubtitle;

@property (nonatomic, strong) NSMutableArray<HYPost *> *myPosts;

@property (nonatomic, strong) HYLoginRequiredView *loginRequiredView;
@property (nonatomic, strong) HYUser *currentUser;
@property (nonatomic, assign) BOOL isLoading;
@property (nonatomic, strong) NSMutableArray<NSString *> *photoUrls;

@end

@implementation MyProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"我的";
    self.view.backgroundColor = LightBg1;
    self.photoUrls = [NSMutableArray array];
    self.photoImageViews = [NSMutableArray array];
    self.myPosts = [NSMutableArray array];
    [self setupNavigationBar];
    [self setupUI];
    [self setupNotifications];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.hidden = NO;
    if ([HYAPIClient shared].isLoggedIn) {
        [self hideLoginRequired];
        [self loadData];
    } else {
        [self showLoginRequired];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    // Update gradient overlay frame
    for (CALayer *layer in self.coverOverlay.layer.sublayers) {
        if ([layer isKindOfClass:[CAGradientLayer class]]) {
            layer.frame = self.coverOverlay.bounds;
        }
    }

    // Layout photo thumbnails with fixed frames (inside scroll content)
    CGFloat thumbW = 64, thumbH = 44, thumbGap = 8;
    for (NSInteger i = 0; i < 5; i++) {
        UIImageView *thumb = [self.photoScrollContent viewWithTag:100 + i];
        thumb.frame = CGRectMake(i * (thumbW + thumbGap), 0, thumbW, thumbH);
    }
    self.addPhotoButton.frame = CGRectMake(5 * (thumbW + thumbGap), 0, thumbW, thumbH);
}

#pragma mark - Setup

- (void)setupNavigationBar {
    self.navigationController.navigationBar.tintColor = PinkGradStart;

    if (@available(iOS 15.0, *)) {
        UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
        [appearance configureWithOpaqueBackground];
        appearance.backgroundColor = [UIColor whiteColor];
        appearance.shadowColor = [UIColor colorWithRed:0.933 green:0.933 blue:1.0 alpha:1.0];
        appearance.titleTextAttributes = @{
            NSForegroundColorAttributeName: [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0],
            NSFontAttributeName: [UIFont systemFontOfSize:18 weight:UIFontWeightBold]
        };
        self.navigationController.navigationBar.standardAppearance = appearance;
        self.navigationController.navigationBar.scrollEdgeAppearance = appearance;
    }

    // Settings button (top right, purple circle)
    UIView *settingsWrapper = [[UIView alloc] init];
    settingsWrapper.backgroundColor = [UIColor colorWithRed:0.961 green:0.941 blue:1.0 alpha:1.0];
    settingsWrapper.layer.cornerRadius = 18;

    UIButton *settingsBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [settingsBtn setImage:[UIImage systemImageNamed:@"gearshape.fill"] forState:UIControlStateNormal];
    settingsBtn.tintColor = PurpleGradStart;
    settingsBtn.frame = CGRectMake(0, 0, 36, 36);
    [settingsBtn addTarget:self action:@selector(settingsTapped) forControlEvents:UIControlEventTouchUpInside];
    [settingsWrapper addSubview:settingsBtn];
    [settingsWrapper mas_makeConstraints:^(MASConstraintMaker *make) { make.width.height.equalTo(@36); }];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:settingsWrapper];

    // Edit button (top left, pink circle) - using left bar button
    UIView *editWrapper = [[UIView alloc] init];
    editWrapper.backgroundColor = [UIColor colorWithRed:1.0 green:0.941 blue:0.961 alpha:1.0];
    editWrapper.layer.cornerRadius = 18;

    UIButton *editBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [editBtn setImage:[UIImage systemImageNamed:@"pencil"] forState:UIControlStateNormal];
    editBtn.tintColor = PinkGradStart;
    editBtn.frame = CGRectMake(0, 0, 36, 36);
    [editBtn addTarget:self action:@selector(editTapped) forControlEvents:UIControlEventTouchUpInside];
    [editWrapper addSubview:editBtn];
    [editWrapper mas_makeConstraints:^(MASConstraintMaker *make) { make.width.height.equalTo(@36); }];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:editWrapper];
}

- (void)setupUI {
    [self setupScrollView];
    [self setupHeaderCard];
    [self setupPhotoWallCard];
    [self setupBioCard];
    [self setupAboutCard];
    [self setupInterestsCard];
    [self setupPostsCard];
    [self setupLoginRequired];
    [self setupConstraints];
}

- (void)setupScrollView {
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.delegate = self;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    self.scrollView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.scrollView];

    self.contentView = [[UIView alloc] init];
    self.contentView.backgroundColor = [UIColor clearColor];
    [self.scrollView addSubview:self.contentView];
}

#pragma mark - Header Card

- (void)setupHeaderCard {
    self.headerCard = [[UIView alloc] init];
    self.headerCard.backgroundColor = LightCard;
    self.headerCard.layer.cornerRadius = 24;
    self.headerCard.layer.shadowColor = [UIColor colorWithRed:0.545 green:0.31 blue:0.965 alpha:1.0].CGColor;
    self.headerCard.layer.shadowOffset = CGSizeMake(0, 3);
    self.headerCard.layer.shadowRadius = 10;
    self.headerCard.layer.shadowOpacity = 0.1;
    self.headerCard.layer.masksToBounds = NO;
    [self.contentView addSubview:self.headerCard];

    // Cover image
    self.coverImageView = [[UIImageView alloc] init];
    self.coverImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.coverImageView.clipsToBounds = YES;
    self.coverImageView.backgroundColor = [UIColor colorWithRed:0.878 green:0.82 blue:1.0 alpha:1.0];
    self.coverImageView.layer.cornerRadius = 24;
    self.coverImageView.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    [self.headerCard addSubview:self.coverImageView];

    // Cover overlay (bottom gradient)
    self.coverOverlay = [[UIView alloc] init];
    [self.headerCard addSubview:self.coverOverlay];

    // Avatar container
    self.avatarContainer = [[UIView alloc] init];
    self.avatarContainer.backgroundColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.3];
    self.avatarContainer.layer.cornerRadius = 52;
    [self.headerCard addSubview:self.avatarContainer];

    // Avatar
    self.avatarImageView = [[UIImageView alloc] init];
    self.avatarImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.avatarImageView.clipsToBounds = YES;
    self.avatarImageView.layer.cornerRadius = 46;
    self.avatarImageView.backgroundColor = [UIColor colorWithRed:0.878 green:0.82 blue:1.0 alpha:1.0];
    self.avatarImageView.image = [UIImage systemImageNamed:@"person.circle.fill"];
    self.avatarImageView.tintColor = [UIColor colorWithRed:0.878 green:0.867 blue:1.0 alpha:1.0];
    [self.headerCard addSubview:self.avatarImageView];

    // Crown (VIP)
    self.crownImageView = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"crown.fill"]];
    self.crownImageView.tintColor = VipGold;
    self.crownImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.headerCard addSubview:self.crownImageView];

    // Online indicator
    self.onlineIndicator = [[UIView alloc] init];
    self.onlineIndicator.backgroundColor = [UIColor whiteColor];
    self.onlineIndicator.layer.cornerRadius = 10;
    [self.headerCard addSubview:self.onlineIndicator];

    self.onlineGreenDot = [[UIView alloc] init];
    self.onlineGreenDot.backgroundColor = OnlineGreenLight;
    self.onlineGreenDot.layer.cornerRadius = 7.5;
    [self.onlineIndicator addSubview:self.onlineGreenDot];

    // Name
    self.nameLabel = [[UILabel alloc] init];
    self.nameLabel.text = @"Hiyo用户";
    self.nameLabel.font = [UIFont systemFontOfSize:22 weight:UIFontWeightBold];
    self.nameLabel.textColor = [UIColor whiteColor];
    self.nameLabel.textAlignment = NSTextAlignmentCenter;
    [self.headerCard addSubview:self.nameLabel];

    // Gender + Age badge
    self.genderAgeBadge = [[UIView alloc] init];
    self.genderAgeBadge.backgroundColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.3];
    self.genderAgeBadge.layer.cornerRadius = 5;
    self.genderAgeBadge.layer.borderWidth = 1;
    self.genderAgeBadge.layer.borderColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.5].CGColor;
    [self.headerCard addSubview:self.genderAgeBadge];

    self.genderAgeLabel = [[UILabel alloc] init];
    self.genderAgeLabel.text = @"♂ 25";
    self.genderAgeLabel.font = [UIFont systemFontOfSize:10 weight:UIFontWeightSemibold];
    self.genderAgeLabel.textColor = [UIColor whiteColor];
    self.genderAgeLabel.textAlignment = NSTextAlignmentCenter;
    [self.genderAgeBadge addSubview:self.genderAgeLabel];

    // VIP badge
    self.vipBadge = [[UIView alloc] init];
    self.vipBadge.backgroundColor = [VipGold colorWithAlphaComponent:0.95];
    self.vipBadge.layer.cornerRadius = 9;
    self.vipBadge.hidden = YES; // show only if user is VIP
    [self.headerCard addSubview:self.vipBadge];

    self.vipLabel = [[UILabel alloc] init];
    self.vipLabel.text = @"⭐ VIP";
    self.vipLabel.font = [UIFont systemFontOfSize:9 weight:UIFontWeightHeavy];
    self.vipLabel.textColor = [UIColor colorWithRed:0.545 green:0.412 blue:0.078 alpha:1.0];
    self.vipLabel.textAlignment = NSTextAlignmentCenter;
    [self.vipBadge addSubview:self.vipLabel];

    // Stats divider
    self.statsDivider = [[UIView alloc] init];
    self.statsDivider.backgroundColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.3];
    [self.headerCard addSubview:self.statsDivider];

    // Followers
    self.followersCount = [self makeStatLabel:@"0" fontSize:18 color:[UIColor whiteColor]];
    self.followersTitle = [self makeStatLabel:@"粉丝" fontSize:11 color:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.7]];
    [self.headerCard addSubview:self.followersCount];
    [self.headerCard addSubview:self.followersTitle];

    // Following
    self.followingCount = [self makeStatLabel:@"0" fontSize:18 color:[UIColor whiteColor]];
    self.followingTitle = [self makeStatLabel:@"关注" fontSize:11 color:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.7]];
    [self.headerCard addSubview:self.followingCount];
    [self.headerCard addSubview:self.followingTitle];

    // Visitors
    self.visitorsCount = [self makeStatLabel:@"0" fontSize:18 color:[UIColor whiteColor]];
    self.visitorsTitle = [self makeStatLabel:@"访客" fontSize:11 color:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.7]];
    [self.headerCard addSubview:self.visitorsCount];
    [self.headerCard addSubview:self.visitorsTitle];
}

- (UILabel *)makeStatLabel:(NSString *)text fontSize:(CGFloat)fontSize color:(UIColor *)color {
    UILabel *label = [[UILabel alloc] init];
    label.text = text;
    label.font = [UIFont systemFontOfSize:fontSize weight:UIFontWeightBold];
    label.textColor = color;
    label.textAlignment = NSTextAlignmentCenter;
    return label;
}

#pragma mark - Photo Wall

- (void)setupPhotoWallCard {
    self.photoWallCard = [self makeCardWithRadius:18];
    [self.contentView addSubview:self.photoWallCard];

    self.photoTitle = [[UILabel alloc] init];
    self.photoTitle.text = @"相册";
    self.photoTitle.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
    self.photoTitle.textColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0];
    [self.photoWallCard addSubview:self.photoTitle];

    self.photoScrollContent = [[UIView alloc] init];
    self.photoScrollContent.backgroundColor = [UIColor clearColor];
    [self.photoWallCard addSubview:self.photoScrollContent];

    // 5 photo thumbnails + 1 add button
    NSArray *bgColors = @[
        [UIColor colorWithRed:0.941 green:0.91 blue:1.0 alpha:1.0],
        [UIColor colorWithRed:1.0 green:0.878 blue:0.933 alpha:1.0],
        [UIColor colorWithRed:0.91 green:0.961 blue:0.914 alpha:1.0],
        [UIColor colorWithRed:1.0 green:0.953 blue:0.878 alpha:1.0],
        [UIColor colorWithRed:0.961 green:0.961 blue:0.961 alpha:1.0]
    ];

    for (NSInteger i = 0; i < 5; i++) {
        UIImageView *thumb = [[UIImageView alloc] init];
        thumb.contentMode = UIViewContentModeScaleAspectFill;
        thumb.clipsToBounds = YES;
        thumb.layer.cornerRadius = 8;
        thumb.backgroundColor = bgColors[i];
        thumb.tag = 100 + i;
        [self.photoScrollContent addSubview:thumb];
        [self.photoImageViews addObject:thumb];
    }

    self.addPhotoButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.addPhotoButton.backgroundColor = [UIColor colorWithRed:0.961 green:0.961 blue:0.961 alpha:1.0];
    self.addPhotoButton.layer.cornerRadius = 8;
    self.addPhotoButton.layer.borderWidth = 1;
    self.addPhotoButton.layer.borderColor = [UIColor colorWithRed:0.933 green:0.933 blue:1.0 alpha:1.0].CGColor;
    [self.addPhotoButton setImage:[UIImage systemImageNamed:@"plus"] forState:UIControlStateNormal];
    self.addPhotoButton.tintColor = [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:1.0];
    [self.addPhotoButton addTarget:self action:@selector(addPhotoTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.photoScrollContent addSubview:self.addPhotoButton];
}

#pragma mark - Bio Card

- (void)setupBioCard {
    self.bioCard = [self makeCardWithRadius:18];
    [self.contentView addSubview:self.bioCard];

    self.bioAccentBar = [self makeAccentBarWithColor:PinkGradStart];
    [self.bioCard addSubview:self.bioAccentBar];

    self.bioTitle = [[UILabel alloc] init];
    self.bioTitle.text = @"个人简介";
    self.bioTitle.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
    self.bioTitle.textColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0];
    [self.bioCard addSubview:self.bioTitle];

    self.bioContent = [[UILabel alloc] init];
    self.bioContent.text = @"这个人很懒，什么都没写";
    self.bioContent.font = [UIFont systemFontOfSize:13];
    self.bioContent.textColor = [UIColor colorWithRed:0.4 green:0.4 blue:0.4 alpha:1.0];
    self.bioContent.numberOfLines = 0;
    [self.bioCard addSubview:self.bioContent];
}

#pragma mark - About Card

- (void)setupAboutCard {
    self.aboutCard = [self makeCardWithRadius:18];
    [self.contentView addSubview:self.aboutCard];

    self.aboutAccentBar = [self makeAccentBarWithColor:PurpleGradStart];
    [self.aboutCard addSubview:self.aboutAccentBar];

    self.aboutTitle = [[UILabel alloc] init];
    self.aboutTitle.text = @"关于我";
    self.aboutTitle.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
    self.aboutTitle.textColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0];
    [self.aboutCard addSubview:self.aboutTitle];

    self.aboutTagsContainer = [[UIView alloc] init];
    [self.aboutCard addSubview:self.aboutTagsContainer];
}

#pragma mark - Interests Card

- (void)setupInterestsCard {
    self.interestsCard = [self makeCardWithRadius:18];
    [self.contentView addSubview:self.interestsCard];

    self.interestsAccentBar = [self makeAccentBarWithColor:PinkGradStart];
    [self.interestsCard addSubview:self.interestsAccentBar];

    self.interestsTitle = [[UILabel alloc] init];
    self.interestsTitle.text = @"兴趣爱好";
    self.interestsTitle.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
    self.interestsTitle.textColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0];
    [self.interestsCard addSubview:self.interestsTitle];

    self.interestsTagsContainer = [[UIView alloc] init];
    [self.interestsCard addSubview:self.interestsTagsContainer];
}

#pragma mark - Posts Card

- (void)setupPostsCard {
    self.postsCard = [self makeCardWithRadius:18];
    [self.contentView addSubview:self.postsCard];

    self.postsAccentBar = [self makeAccentBarWithColor:PurpleGradStart];
    [self.postsCard addSubview:self.postsAccentBar];

    self.postsTitle = [[UILabel alloc] init];
    self.postsTitle.text = @"我的动态";
    self.postsTitle.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
    self.postsTitle.textColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0];
    [self.postsCard addSubview:self.postsTitle];

    self.postsSubtitle = [[UILabel alloc] init];
    self.postsSubtitle.text = @"查看全部 0 条动态 →";
    self.postsSubtitle.font = [UIFont systemFontOfSize:12];
    self.postsSubtitle.textColor = [UIColor colorWithRed:0.667 green:0.667 blue:0.667 alpha:1.0];
    [self.postsCard addSubview:self.postsSubtitle];
}

#pragma mark - Helpers

- (UIView *)makeCardWithRadius:(CGFloat)radius {
    UIView *card = [[UIView alloc] init];
    card.backgroundColor = LightCard;
    card.layer.cornerRadius = radius;
    card.layer.shadowColor = [UIColor colorWithRed:0.545 green:0.31 blue:0.965 alpha:1.0].CGColor;
    card.layer.shadowOffset = CGSizeMake(0, 3);
    card.layer.shadowRadius = 10;
    card.layer.shadowOpacity = 0.1;
    card.layer.masksToBounds = NO;
    return card;
}

- (UIView *)makeAccentBarWithColor:(UIColor *)color {
    UIView *bar = [[UIView alloc] init];
    bar.backgroundColor = color;
    bar.layer.cornerRadius = 1.5;
    return bar;
}

- (UIView *)makeInterestTag:(NSString *)text color:(UIColor *)bgColor textColor:(UIColor *)textColor {
    UIView *tag = [[UIView alloc] init];
    tag.backgroundColor = bgColor;
    tag.layer.cornerRadius = 10;

    UILabel *label = [[UILabel alloc] init];
    label.text = text;
    label.font = [UIFont systemFontOfSize:11 weight:UIFontWeightSemibold];
    label.textColor = textColor;
    label.textAlignment = NSTextAlignmentCenter;
    [tag addSubview:label];

    [label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(tag);
    }];

    return tag;
}

- (UIView *)makeAboutTag:(NSString *)emoji bgColor:(UIColor *)bgColor textColor:(UIColor *)textColor label:(NSString *)labelText {
    UIView *tag = [[UIView alloc] init];

    UIView *circle = [[UIView alloc] init];
    circle.backgroundColor = bgColor;
    circle.layer.cornerRadius = 8;
    [tag addSubview:circle];

    UILabel *emojiLabel = [[UILabel alloc] init];
    emojiLabel.text = emoji;
    emojiLabel.font = [UIFont systemFontOfSize:9];
    emojiLabel.textAlignment = NSTextAlignmentCenter;
    [circle addSubview:emojiLabel];

    UILabel *textLabel = [[UILabel alloc] init];
    textLabel.text = labelText;
    textLabel.font = [UIFont systemFontOfSize:12];
    textLabel.textColor = [UIColor colorWithRed:0.4 green:0.4 blue:0.4 alpha:1.0];
    [tag addSubview:textLabel];

    [circle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.centerY.equalTo(tag);
        make.width.height.equalTo(@16);
    }];

    [emojiLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(circle);
    }];

    [textLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(circle.mas_trailing).offset(4);
        make.centerY.equalTo(tag);
        make.trailing.lessThanOrEqualTo(tag);
    }];

    return tag;
}

- (void)setupLoginRequired {
    self.loginRequiredView = [[HYLoginRequiredView alloc] init];
    self.loginRequiredView.tipText = @"登录后可以看到我的资料";
    self.loginRequiredView.backgroundColor = LightBg1;
    [self.loginRequiredView setLoginButtonTitle:@"去登录"];
    self.loginRequiredView.onLoginTapped = ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"HYNeedLoginNotification" object:nil];
    };
    self.loginRequiredView.hidden = YES;
    [self.view addSubview:self.loginRequiredView];

    [self.loginRequiredView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
}

#pragma mark - Constraints

- (void)setupConstraints {
    UIView *content = self.contentView;
    CGFloat screenW = [UIScreen mainScreen].bounds.size.width;
    CGFloat cardMargin = 16;

    [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];

    [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.scrollView);
        make.width.equalTo(self.scrollView);
    }];

    // Header card
    [self.headerCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(content).offset(8);
        make.leading.equalTo(content).offset(cardMargin);
        make.trailing.equalTo(content).offset(-cardMargin);
        make.height.equalTo(@240);
    }];

    [self.coverImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.trailing.equalTo(self.headerCard);
        make.height.equalTo(@140);
    }];

    [self.coverOverlay mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.bottom.equalTo(self.coverImageView);
        make.height.equalTo(@60);
    }];

    // Gradient overlay
    CAGradientLayer *overlayGradient = [CAGradientLayer layer];
    overlayGradient.colors = @[(id)[UIColor clearColor].CGColor, (id)[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.5].CGColor];
    overlayGradient.locations = @[@0, @1];
    [self.coverOverlay.layer addSublayer:overlayGradient];
    self.coverOverlay.layer.masksToBounds = YES;
    self.coverOverlay.layer.cornerRadius = 24;
    self.coverOverlay.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;

    [self.avatarContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.headerCard);
        make.centerY.equalTo(self.coverImageView);
        make.width.height.equalTo(@104);
    }];

    [self.avatarImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.avatarContainer);
        make.width.height.equalTo(@92);
    }];

    [self.crownImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.headerCard);
        make.bottom.equalTo(self.avatarContainer.mas_top).offset(6);
        make.width.height.equalTo(@24);
    }];

    [self.onlineIndicator mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.bottom.equalTo(self.avatarContainer);
        make.width.height.equalTo(@20);
    }];

    [self.onlineGreenDot mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.onlineIndicator);
        make.width.height.equalTo(@15);
    }];

    [self.nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.headerCard);
        make.top.equalTo(self.coverImageView.mas_bottom).offset(12);
    }];

    [self.genderAgeBadge mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.nameLabel.mas_trailing).offset(8);
        make.centerY.equalTo(self.nameLabel);
        make.height.equalTo(@18);
    }];

    [self.genderAgeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.genderAgeBadge).insets(UIEdgeInsetsMake(0, 6, 0, 6));
    }];

    [self.vipBadge mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.genderAgeBadge.mas_trailing).offset(6);
        make.centerY.equalTo(self.nameLabel);
        make.width.equalTo(@48);
        make.height.equalTo(@18);
    }];

    [self.vipLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.vipBadge);
    }];

    [self.statsDivider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.headerCard).offset(60);
        make.trailing.equalTo(self.headerCard).offset(-60);
        make.top.equalTo(self.nameLabel.mas_bottom).offset(16);
        make.height.equalTo(@1);
    }];

    // Stats row
    CGFloat statW = (screenW - cardMargin * 2 - 120) / 3;
    [self.followersCount mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.headerCard).offset(-statW);
        make.top.equalTo(self.statsDivider.mas_bottom).offset(8);
    }];
    [self.followersTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.followersCount);
        make.top.equalTo(self.followersCount.mas_bottom).offset(2);
    }];

    [self.followingCount mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.headerCard);
        make.top.equalTo(self.statsDivider.mas_bottom).offset(8);
    }];
    [self.followingTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.followingCount);
        make.top.equalTo(self.followingCount.mas_bottom).offset(2);
    }];

    [self.visitorsCount mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.headerCard).offset(statW);
        make.top.equalTo(self.statsDivider.mas_bottom).offset(8);
    }];
    [self.visitorsTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.visitorsCount);
        make.top.equalTo(self.visitorsCount.mas_bottom).offset(2);
    }];

    // Photo wall card
    [self.photoWallCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.headerCard.mas_bottom).offset(12);
        make.leading.trailing.equalTo(self.contentView).inset(cardMargin);
        make.height.equalTo(@90);
    }];

    [self.photoTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.equalTo(self.photoWallCard).offset(16);
    }];

    [self.photoScrollContent mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.photoTitle.mas_bottom).offset(12);
        make.leading.equalTo(self.photoWallCard).offset(16);
        make.trailing.equalTo(self.photoWallCard).offset(-16);
        make.height.equalTo(@44);
    }];

    // Bio card
    [self.bioCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.photoWallCard.mas_bottom).offset(12);
        make.leading.trailing.equalTo(self.contentView).inset(cardMargin);
        make.height.equalTo(@70);
    }];

    [self.bioAccentBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.top.bottom.equalTo(self.bioCard);
        make.width.equalTo(@3);
    }];

    [self.bioTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.bioCard).offset(14);
        make.leading.equalTo(self.bioCard).offset(20);
    }];

    [self.bioContent mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.bioTitle.mas_bottom).offset(6);
        make.leading.equalTo(self.bioCard).offset(20);
        make.trailing.equalTo(self.bioCard).offset(-16);
    }];

    // About card
    [self.aboutCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.bioCard.mas_bottom).offset(12);
        make.leading.trailing.equalTo(self.contentView).inset(cardMargin);
        make.height.equalTo(@130);
    }];

    [self.aboutAccentBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.top.bottom.equalTo(self.aboutCard);
        make.width.equalTo(@3);
    }];

    [self.aboutTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.aboutCard).offset(14);
        make.leading.equalTo(self.aboutCard).offset(20);
    }];

    [self.aboutTagsContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.aboutTitle.mas_bottom).offset(12);
        make.leading.equalTo(self.aboutCard).offset(16);
        make.trailing.equalTo(self.aboutCard).offset(-16);
    }];

    // Interests card
    [self.interestsCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.aboutCard.mas_bottom).offset(12);
        make.leading.trailing.equalTo(self.contentView).inset(cardMargin);
        make.height.equalTo(@62);
    }];

    [self.interestsAccentBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.top.bottom.equalTo(self.interestsCard);
        make.width.equalTo(@3);
    }];

    [self.interestsTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.interestsCard).offset(14);
        make.leading.equalTo(self.interestsCard).offset(20);
    }];

    [self.interestsTagsContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.interestsTitle.mas_bottom).offset(10);
        make.leading.equalTo(self.interestsCard).offset(16);
        make.trailing.lessThanOrEqualTo(self.interestsCard).offset(-16);
        make.height.equalTo(@20);
    }];

    // Posts card
    [self.postsCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.interestsCard.mas_bottom).offset(12);
        make.leading.trailing.equalTo(self.contentView).inset(cardMargin);
        make.height.equalTo(@60);
        make.bottom.equalTo(self.contentView).offset(-40);
    }];

    [self.postsAccentBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.top.bottom.equalTo(self.postsCard);
        make.width.equalTo(@3);
    }];

    [self.postsTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.postsCard).offset(14);
        make.leading.equalTo(self.postsCard).offset(20);
    }];

    [self.postsSubtitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.postsTitle.mas_bottom).offset(6);
        make.leading.equalTo(self.postsCard).offset(20);
    }];
}

#pragma mark - Data Loading

- (void)loadData {
    if (self.isLoading) return;
    self.isLoading = YES;

    [[HYAPIClient shared] getUserInfoWithId:@"me" completion:^(NSDictionary *response, NSError *error) {
        self.isLoading = NO;
        if (error) {
            NSLog(@"Failed to load profile: %@", error.localizedDescription);
            return;
        }
        NSDictionary *data = response[@"data"];
        if ([data isKindOfClass:[NSDictionary class]]) {
            self.currentUser = [[HYUser alloc] initWithDictionary:data];
            [self updateUI];
        }
    }];

    [[HYAPIClient shared] getMyPostsWithPage:1 pageSize:10 completion:^(NSDictionary *response, NSError *error) {
        if (error) return;
        id data = response[@"data"];
        NSArray *postsData = nil;
        if ([data isKindOfClass:[NSDictionary class]]) {
            postsData = data[@"posts"];
        } else if ([data isKindOfClass:[NSArray class]]) {
            postsData = data;
        }
        if (![postsData isKindOfClass:[NSArray class]]) postsData = @[];
        [self.myPosts removeAllObjects];
        for (NSDictionary *dict in postsData) {
            HYPost *post = [[HYPost alloc] initWithDictionary:dict];
            [self.myPosts addObject:post];
        }
        self.postsSubtitle.text = [NSString stringWithFormat:@"查看全部 %lu 条动态 →", (unsigned long)self.myPosts.count];
    }];
}

- (void)updateUI {
    if (!self.currentUser) return;

    self.nameLabel.text = self.currentUser.name.length > 0 ? self.currentUser.name : @"Hiyo用户";

    // Gender + Age
    NSMutableString *gaText = [NSMutableString string];
    if (self.currentUser.sex == 2) {
        [gaText appendString:@"♀ "];
    } else if (self.currentUser.sex == 1) {
        [gaText appendString:@"♂ "];
    }
    if (self.currentUser.age > 0) {
        [gaText appendFormat:@"%ld", (long)self.currentUser.age];
    }
    self.genderAgeLabel.text = gaText.length > 0 ? gaText : @"--";

    // Avatar
    if (self.currentUser.avatar.length > 0) {
        [self.avatarImageView sd_setImageWithURL:[NSURL URLWithString:self.currentUser.avatar]
                               placeholderImage:[UIImage systemImageNamed:@"person.circle.fill"]];
    }
    if (self.currentUser.backgroundImage.length > 0) {
        [self.coverImageView sd_setImageWithURL:[NSURL URLWithString:self.currentUser.backgroundImage]];
    }

    // Bio
    self.bioContent.text = self.currentUser.bio.length > 0 ? self.currentUser.bio : @"这个人很懒，什么都没写";

    // Stats
    self.followersCount.text = [self formatCount:self.currentUser.fansCount];
    self.followingCount.text = [self formatCount:self.currentUser.attentionCount];
    self.visitorsCount.text = [self formatCount:self.currentUser.lookMeCount];

    // VIP badge
    self.vipBadge.hidden = (self.currentUser.isVip != 1);
    self.crownImageView.hidden = (self.currentUser.isVip != 1);

    [self updateAboutTags];
    [self updateInterestsTags];
    [self updatePhotoWall];
}

- (NSString *)formatCount:(long long)count {
    if (count >= 1000) {
        return [NSString stringWithFormat:@"%.1fK", count / 1000.0];
    }
    return [NSString stringWithFormat:@"%lld", count];
}

- (void)updateAboutTags {
    for (UIView *sub in self.aboutTagsContainer.subviews) {
        [sub removeFromSuperview];
    }

    NSMutableArray *tags = [NSMutableArray array];
    if (self.currentUser.sex > 0 && self.currentUser.age > 0) {
        NSString *emoji = self.currentUser.sex == 2 ? @"♀" : @"♂";
        [tags addObject:@{@"emoji": emoji, @"text": [NSString stringWithFormat:@"%ld岁", (long)self.currentUser.age], @"color": [UIColor colorWithRed:1.0 green:0.878 blue:0.933 alpha:1.0]}];
    }
    if (self.currentUser.constellation.length > 0) {
        [tags addObject:@{@"emoji": @"♈", @"text": self.currentUser.constellation, @"color": [UIColor colorWithRed:0.91 green:0.878 blue:1.0 alpha:1.0]}];
    }
    if (self.currentUser.height > 0) {
        [tags addObject:@{@"emoji": @"📏", @"text": [NSString stringWithFormat:@"%ldcm", (long)self.currentUser.height], @"color": [UIColor colorWithRed:1.0 green:0.878 blue:0.933 alpha:1.0]}];
    }
    if (self.currentUser.weight > 0) {
        [tags addObject:@{@"emoji": @"⚖️", @"text": [NSString stringWithFormat:@"%ldkg", (long)self.currentUser.weight], @"color": [UIColor colorWithRed:0.91 green:0.878 blue:1.0 alpha:1.0]}];
    }
    if (self.currentUser.currentAddress.length > 0) {
        [tags addObject:@{@"emoji": @"📍", @"text": self.currentUser.currentAddress, @"color": [UIColor colorWithRed:1.0 green:0.878 blue:0.933 alpha:1.0]}];
    }
    if (self.currentUser.job.length > 0) {
        [tags addObject:@{@"emoji": @"💼", @"text": self.currentUser.job, @"color": [UIColor colorWithRed:0.91 green:0.878 blue:1.0 alpha:1.0]}];
    }

    CGFloat x = 0, y = 0;
    CGFloat maxW = [UIScreen mainScreen].bounds.size.width - 32 * 2;
    CGFloat tagH = 20;
    CGFloat tagGap = 12;

    for (NSDictionary *tag in tags) {
        UIView *tagView = [self makeAboutTag:tag[@"emoji"]
                                    bgColor:tag[@"color"]
                                  textColor:[UIColor colorWithRed:0.4 green:0.4 blue:0.4 alpha:1.0]
                                      label:tag[@"text"]];
        [tagView layoutIfNeeded];
        CGSize sz = [tagView systemLayoutSizeFittingSize:CGSizeMake(maxW, tagH)];
        if (x + sz.width > maxW && x > 0) {
            x = 0;
            y += tagH + 8;
        }
        tagView.frame = CGRectMake(x, y, sz.width, tagH);
        [self.aboutTagsContainer addSubview:tagView];
        x += sz.width + tagGap;
    }

    CGFloat totalH = MAX(y + tagH, 20);
    [self.aboutCard mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@(130 + MAX(totalH - tagH, 0)));
    }];
}

- (void)updateInterestsTags {
    for (UIView *sub in self.interestsTagsContainer.subviews) {
        [sub removeFromSuperview];
    }

    NSArray *interests = self.currentUser.interests ?: @[];
    NSArray *colors = @[
        @{@"bg": [UIColor colorWithRed:1.0 green:0.878 blue:0.933 alpha:1.0], @"text": PinkGradStart},
        @{@"bg": [UIColor colorWithRed:0.91 green:0.878 blue:1.0 alpha:1.0], @"text": PurpleGradStart}
    ];

    CGFloat x = 0;
    CGFloat tagW = 50, tagH = 20, tagGap = 8;

    for (NSInteger i = 0; i < interests.count && i < 5; i++) {
        NSDictionary *color = colors[i % 2];
        UIView *tag = [self makeInterestTag:interests[i] color:color[@"bg"] textColor:color[@"text"]];
        tag.frame = CGRectMake(x, 0, tagW, tagH);
        [self.interestsTagsContainer addSubview:tag];
        x += tagW + tagGap;
    }
}

- (void)updatePhotoWall {
    [self.photoUrls removeAllObjects];
    [self.photoUrls addObjectsFromArray:self.currentUser.photos ?: @[]];

    for (NSInteger i = 0; i < 5; i++) {
        UIImageView *thumb = [self.photoScrollContent viewWithTag:100 + i];
        if (i < (NSInteger)self.photoUrls.count) {
            [thumb sd_setImageWithURL:[NSURL URLWithString:self.photoUrls[i]]
                    placeholderImage:nil];
            thumb.userInteractionEnabled = YES;
            thumb.tag = i;
            for (UIGestureRecognizer *g in thumb.gestureRecognizers) {
                [thumb removeGestureRecognizer:g];
            }
            UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(photoTapped:)];
            [thumb addGestureRecognizer:tap];
        } else {
            thumb.image = nil;
            thumb.userInteractionEnabled = NO;
        }
    }
}

#pragma mark - Actions

- (void)settingsTapped {
    SettingsViewController *vc = [[SettingsViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)editTapped {
    EditProfileViewController *vc = [[EditProfileViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)addPhotoTapped {
    PHPickerConfiguration *config = [[PHPickerConfiguration alloc] init];
    config.selectionLimit = 1;
    config.filter = [PHPickerFilter imagesFilter];
    PHPickerViewController *picker = [[PHPickerViewController alloc] initWithConfiguration:config];
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)photoTapped:(UITapGestureRecognizer *)tap {
    NSInteger index = tap.view.tag;
    if (index < (NSInteger)self.photoUrls.count) {
        FullscreenPhotoViewController *vc = [[FullscreenPhotoViewController alloc] initWithPhotoUrls:self.photoUrls startIndex:index];
        vc.modalPresentationStyle = UIModalPresentationFullScreen;
        [self presentViewController:vc animated:YES completion:nil];
    }
}

#pragma mark - PHPickerViewControllerDelegate

- (void)picker:(PHPickerViewController *)picker didFinishPicking:(NSArray<PHPickerResult *> *)results {
    [picker dismissViewControllerAnimated:YES completion:nil];
    if (results.count == 0) return;

    __weak typeof(self) weakSelf = self;
    [results.firstObject.itemProvider loadObjectOfClass:[UIImage class] completionHandler:^(id<NSItemProviderReading> object, NSError *error) {
        if (!object || ![object isKindOfClass:[UIImage class]]) return;
        dispatch_async(dispatch_get_main_queue(), ^{
            UIImage *image = (UIImage *)object;
            CGFloat maxDim = 1080;
            CGFloat ratio = image.size.width / image.size.height;
            CGFloat w = ratio > 1 ? maxDim : maxDim * ratio;
            CGFloat h = ratio > 1 ? maxDim / ratio : maxDim;
            UIGraphicsBeginImageContextWithOptions(CGSizeMake(w, h), NO, 1.0);
            [image drawInRect:CGRectMake(0, 0, w, h)];
            UIImage *resized = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            NSData *data = UIImageJPEGRepresentation(resized ?: image, 0.8);
            if (!data) return;
            NSString *fileName = [NSString stringWithFormat:@"photo_%@.jpg", @([[NSDate date] timeIntervalSince1970])];
            [[HYAPIClient shared] uploadImageWithData:data fileName:fileName completion:^(NSDictionary *response, NSError *error) {
                if (error) return;
                NSString *url = response[@"data"][@"url"];
                if (!url) return;
                [[HYAPIClient shared] addPhotoWithUrl:url isWall:YES completion:^(NSDictionary *response, NSError *error) {
                    if (!error) {
                        [weakSelf.photoUrls addObject:url];
                        [weakSelf updatePhotoWall];
                    }
                }];
            }];
        });
    }];
}

#pragma mark - Notifications

- (void)setupNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleUnauthorized)
                                                 name:HYAPIClientUnauthorizedNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(profileDidUpdate)
                                                 name:@"HYProfileDidUpdateNotification"
                                               object:nil];
}

- (void)handleUnauthorized {
    [self showLoginRequired];
}

- (void)profileDidUpdate {
    [self loadData];
}

#pragma mark - Login

- (void)showLoginRequired {
    self.loginRequiredView.hidden = NO;
    self.scrollView.hidden = YES;
}

- (void)hideLoginRequired {
    self.loginRequiredView.hidden = YES;
    self.scrollView.hidden = NO;
}

@end
