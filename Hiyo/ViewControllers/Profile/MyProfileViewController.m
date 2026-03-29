#import "MyProfileViewController.h"
#import "HYAPIClient.h"
#import "HYUser.h"
#import "HYModels.h"
#import "HYLoginRequiredView.h"
#import "EditProfileViewController.h"
#import "SettingsViewController.h"
#import "FollowListViewController.h"
#import "FullscreenPhotoViewController.h"
#import "PostDetailViewController.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/SDWebImage.h>
#import <PhotosUI/PhotosUI.h>

static CGFloat const kHeaderHeight = 300.0;
static CGFloat const kAvatarSize = 90.0;
static CGFloat const kPhotoSize = 120.0;

@interface HYGradientCard : UIView
@property (nonatomic, strong) CAGradientLayer *gradientLayer;
- (void)setGradientColors:(NSArray *)colors;
@end

@implementation HYGradientCard

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _gradientLayer = [CAGradientLayer layer];
        _gradientLayer.cornerRadius = 20;
        _gradientLayer.borderWidth = 1.0;
        _gradientLayer.borderColor = [[UIColor systemPurpleColor] colorWithAlphaComponent:0.3].CGColor;
        [self.layer addSublayer:_gradientLayer];
        self.backgroundColor = [UIColor colorWithRed:0.11 green:0.11 blue:0.18 alpha:1.0];
        self.layer.cornerRadius = 20;
        self.layer.shadowColor = [UIColor systemPurpleColor].CGColor;
        self.layer.shadowOffset = CGSizeMake(0, 4);
        self.layer.shadowRadius = 12;
        self.layer.shadowOpacity = 0.3;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.gradientLayer.frame = self.bounds;
}

- (void)setGradientColors:(NSArray *)colors {
    self.gradientLayer.colors = colors;
}

@end

@interface HYProfileTag : UIView
- (instancetype)initWithIcon:(NSString *)icon text:(NSString *)text;
@end

@implementation HYProfileTag

- (instancetype)initWithIcon:(NSString *)icon text:(NSString *)text {
    self = [super init];
    if (self) {
        self.backgroundColor = [[UIColor systemPurpleColor] colorWithAlphaComponent:0.15];
        self.layer.cornerRadius = 14;
        self.layer.borderWidth = 1;
        self.layer.borderColor = [[UIColor systemPurpleColor] colorWithAlphaComponent:0.3].CGColor;

        UIImageView *iconView = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:icon]];
        iconView.tintColor = [UIColor systemPurpleColor];
        iconView.contentMode = UIViewContentModeScaleAspectFit;
        [self addSubview:iconView];

        UILabel *label = [[UILabel alloc] init];
        label.text = text;
        label.font = [UIFont systemFontOfSize:12];
        label.textColor = [UIColor colorWithWhite:0.7 alpha:1.0];
        [self addSubview:label];

        iconView.frame = CGRectMake(8, 0, 16, 28);
        label.frame = CGRectMake(28, 0, 200, 28);
    }
    return self;
}

@end

@interface MyProfileViewController () <UIScrollViewDelegate, UITableViewDelegate, UITableViewDataSource, PHPickerViewControllerDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UIImageView *bgImageView;
@property (nonatomic, strong) CAGradientLayer *gradientOverlay;
@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *genderAgeLabel;
@property (nonatomic, strong) UILabel *idLabel;
@property (nonatomic, strong) UIButton *settingsButton;
@property (nonatomic, strong) UIButton *editButton;

@property (nonatomic, strong) HYGradientCard *introCard;
@property (nonatomic, strong) HYGradientCard *aboutCard;
@property (nonatomic, strong) UIView *tagsContainer;
@property (nonatomic, strong) UIView *photoWallView;
@property (nonatomic, strong) UIScrollView *photoScrollView;
@property (nonatomic, strong) UIButton *addPhotoButton;
@property (nonatomic, strong) NSMutableArray<NSString *> *photoUrls;
@property (nonatomic, strong) NSMutableArray<UIImageView *> *photoImageViews;

@property (nonatomic, strong) UITableView *postsTableView;
@property (nonatomic, strong) NSMutableArray<HYPost *> *myPosts;

@property (nonatomic, strong) UIView *statsView;
@property (nonatomic, strong) UIButton *followersBtn;
@property (nonatomic, strong) UIButton *followingsBtn;
@property (nonatomic, strong) UILabel *visitorsLabel;

@property (nonatomic, strong) HYLoginRequiredView *loginRequiredView;
@property (nonatomic, strong) HYUser *currentUser;
@property (nonatomic, assign) BOOL isLoading;

@end

@implementation MyProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"我的";
    self.view.backgroundColor = [UIColor colorWithRed:0.04 green:0.04 blue:0.08 alpha:1.0];
    self.photoUrls = [NSMutableArray array];
    self.photoImageViews = [NSMutableArray array];
    self.myPosts = [NSMutableArray array];
    [self setupUI];
    [self setupNotifications];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.hidden = YES;
    if ([HYAPIClient shared].isLoggedIn) {
        [self hideLoginRequired];
        [self loadData];
    } else {
        [self showLoginRequired];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.navigationController.navigationBar.hidden = NO;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.gradientOverlay.frame = self.headerView.bounds;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Setup

- (void)setupUI {
    [self setupScrollView];
    [self setupHeader];
    [self setupIntroCard];
    [self setupAboutCard];
    [self setupPhotoWall];
    [self setupPostsSection];
    [self setupStatsSection];
    [self setupLoginRequired];
    [self setupConstraints];
}

- (void)setupScrollView {
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.delegate = self;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    [self.view addSubview:self.scrollView];

    self.contentView = [[UIView alloc] init];
    [self.scrollView addSubview:self.contentView];
}

- (void)setupHeader {
    self.headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, kHeaderHeight)];
    self.headerView.backgroundColor = [UIColor colorWithRed:0.04 green:0.04 blue:0.08 alpha:1.0];
    [self.contentView addSubview:self.headerView];

    // Blurred background
    self.bgImageView = [[UIImageView alloc] init];
    self.bgImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.bgImageView.clipsToBounds = YES;
    [self.headerView addSubview:self.bgImageView];

    // Gradient overlay (handled in layoutSubviews)
    self.gradientOverlay = [CAGradientLayer layer];
    self.gradientOverlay.colors = @[
        (id)[[UIColor colorWithRed:0.04 green:0.04 blue:0.08 alpha:0.8] CGColor],
        (id)[[UIColor colorWithRed:0.04 green:0.04 blue:0.08 alpha:1.0] CGColor]
    ];
    self.gradientOverlay.locations = @[@0, @1];
    [self.headerView.layer addSublayer:self.gradientOverlay];

    // Settings button (top right)
    self.settingsButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.settingsButton setImage:[UIImage systemImageNamed:@"gearshape.fill"] forState:UIControlStateNormal];
    self.settingsButton.tintColor = [UIColor whiteColor];
    [self.settingsButton addTarget:self action:@selector(settingsTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.headerView addSubview:self.settingsButton];

    // Edit button
    self.editButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.editButton setImage:[UIImage systemImageNamed:@"pencil"] forState:UIControlStateNormal];
    self.editButton.tintColor = [UIColor whiteColor];
    [self.editButton addTarget:self action:@selector(editTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.headerView addSubview:self.editButton];

    // Avatar with glow
    self.avatarImageView = [[UIImageView alloc] init];
    self.avatarImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.avatarImageView.clipsToBounds = YES;
    self.avatarImageView.layer.cornerRadius = kAvatarSize / 2;
    self.avatarImageView.layer.borderWidth = 3;
    self.avatarImageView.layer.borderColor = [UIColor systemPurpleColor].CGColor;
    self.avatarImageView.backgroundColor = [UIColor systemGray5Color];
    self.avatarImageView.image = [UIImage systemImageNamed:@"person.circle.fill"];
    [self.headerView addSubview:self.avatarImageView];

    // Glow layer
    CALayer *glow = [CALayer layer];
    glow.frame = CGRectMake(0, 0, kAvatarSize + 16, kAvatarSize + 16);
    glow.cornerRadius = (kAvatarSize + 16) / 2;
    glow.shadowColor = [UIColor systemPurpleColor].CGColor;
    glow.shadowOffset = CGSizeZero;
    glow.shadowRadius = 20;
    glow.shadowOpacity = 0.8;
    glow.position = self.avatarImageView.center;
    [self.headerView.layer insertSublayer:glow below:self.avatarImageView.layer];

    // Name
    self.nameLabel = [[UILabel alloc] init];
    self.nameLabel.text = @"Hiyo用户";
    self.nameLabel.font = [UIFont systemFontOfSize:24 weight:UIFontWeightBold];
    self.nameLabel.textColor = [UIColor whiteColor];
    self.nameLabel.textAlignment = NSTextAlignmentCenter;
    [self.headerView addSubview:self.nameLabel];

    // Gender + Age badge
    self.genderAgeLabel = [[UILabel alloc] init];
    self.genderAgeLabel.font = [UIFont systemFontOfSize:14];
    self.genderAgeLabel.textColor = [UIColor colorWithWhite:0.7 alpha:1.0];
    self.genderAgeLabel.textAlignment = NSTextAlignmentCenter;
    self.genderAgeLabel.tag = 101;
    [self.headerView addSubview:self.genderAgeLabel];

    // ID label (copyable)
    self.idLabel = [[UILabel alloc] init];
    self.idLabel.text = @"ID: --";
    self.idLabel.font = [UIFont systemFontOfSize:12];
    self.idLabel.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.6];
    self.idLabel.textAlignment = NSTextAlignmentCenter;
    self.idLabel.userInteractionEnabled = YES;
    UITapGestureRecognizer *idTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(idLabelTapped)];
    [self.idLabel addGestureRecognizer:idTap];
    [self.headerView addSubview:self.idLabel];
}

- (void)setupIntroCard {
    self.introCard = [[HYGradientCard alloc] init];
    [self.contentView addSubview:self.introCard];

    UIImageView *starIcon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"star.fill"]];
    starIcon.tintColor = [UIColor systemPurpleColor];
    [self.introCard addSubview:starIcon];

    UILabel *introTitle = [[UILabel alloc] init];
    introTitle.text = @"个人简介";
    introTitle.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    introTitle.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.5];
    [self.introCard addSubview:introTitle];

    UILabel *bioLabel = [[UILabel alloc] init];
    bioLabel.text = @"这个人很懒，什么都没写";
    bioLabel.font = [UIFont systemFontOfSize:15];
    bioLabel.textColor = [UIColor whiteColor];
    bioLabel.numberOfLines = 0;
    bioLabel.tag = 100;
    [self.introCard addSubview:bioLabel];

    starIcon.frame = CGRectMake(16, 16, 16, 16);
    introTitle.frame = CGRectMake(40, 14, 100, 20);
    bioLabel.frame = CGRectMake(16, 40, self.view.bounds.size.width - 64, 60);
}

- (void)setupAboutCard {
    self.aboutCard = [[HYGradientCard alloc] init];
    [self.contentView addSubview:self.aboutCard];

    UILabel *aboutTitle = [[UILabel alloc] init];
    aboutTitle.text = @"关于我";
    aboutTitle.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    aboutTitle.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.5];
    [self.aboutCard addSubview:aboutTitle];
    aboutTitle.frame = CGRectMake(16, 14, 100, 20);

    self.tagsContainer = [[UIView alloc] init];
    [self.aboutCard addSubview:self.tagsContainer];
}

- (void)setupPhotoWall {
    self.photoWallView = [[UIView alloc] init];
    self.photoWallView.backgroundColor = [UIColor clearColor];
    [self.contentView addSubview:self.photoWallView];

    UILabel *photoTitle = [[UILabel alloc] init];
    photoTitle.text = @"照片墙";
    photoTitle.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    photoTitle.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.5];
    [self.photoWallView addSubview:photoTitle];
    photoTitle.frame = CGRectMake(16, 0, 100, 20);

    self.photoScrollView = [[UIScrollView alloc] init];
    self.photoScrollView.showsHorizontalScrollIndicator = NO;
    [self.photoWallView addSubview:self.photoScrollView];

    self.addPhotoButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.addPhotoButton setImage:[UIImage systemImageNamed:@"plus"] forState:UIControlStateNormal];
    self.addPhotoButton.tintColor = [UIColor systemGrayColor];
    self.addPhotoButton.backgroundColor = [[UIColor systemGrayColor] colorWithAlphaComponent:0.2];
    self.addPhotoButton.layer.cornerRadius = 12;
    self.addPhotoButton.layer.borderWidth = 1;
    self.addPhotoButton.layer.borderColor = [UIColor systemGrayColor].CGColor;
    [self.addPhotoButton addTarget:self action:@selector(addPhotoTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.photoScrollView addSubview:self.addPhotoButton];
}

- (void)setupPostsSection {
    UIView *postsSection = [[UIView alloc] init];
    postsSection.backgroundColor = [UIColor clearColor];
    postsSection.tag = 200;
    [self.contentView addSubview:postsSection];

    UILabel *postsTitle = [[UILabel alloc] init];
    postsTitle.text = @"我的动态";
    postsTitle.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    postsTitle.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.5];
    [postsSection addSubview:postsTitle];
    postsTitle.frame = CGRectMake(16, 0, 100, 20);

    self.postsTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.postsTableView.delegate = self;
    self.postsTableView.dataSource = self;
    self.postsTableView.backgroundColor = [UIColor clearColor];
    self.postsTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.postsTableView.scrollEnabled = NO;
    self.postsTableView.rowHeight = UITableViewAutomaticDimension;
    self.postsTableView.estimatedRowHeight = 80;
    [self.postsTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"PostCell"];
    [postsSection addSubview:self.postsTableView];
}

- (void)setupStatsSection {
    self.statsView = [[UIView alloc] init];
    self.statsView.backgroundColor = [UIColor clearColor];
    [self.contentView addSubview:self.statsView];

    UIView *statsBg = [[UIView alloc] init];
    statsBg.backgroundColor = [UIColor colorWithRed:0.11 green:0.11 blue:0.18 alpha:1.0];
    statsBg.layer.cornerRadius = 20;
    [self.statsView addSubview:statsBg];

    self.followersBtn = [self makeStatButtonWithTitle:@"粉丝" count:0];
    [self.followersBtn addTarget:self action:@selector(followersTapped) forControlEvents:UIControlEventTouchUpInside];
    [statsBg addSubview:self.followersBtn];

    self.followingsBtn = [self makeStatButtonWithTitle:@"关注" count:0];
    [self.followingsBtn addTarget:self action:@selector(followingsTapped) forControlEvents:UIControlEventTouchUpInside];
    [statsBg addSubview:self.followingsBtn];

    UIView *visitorsView = [self makeStatButtonWithTitle:@"访客" count:0];
    visitorsView.tag = 300;
    [statsBg addSubview:visitorsView];

    [statsBg mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.statsView).insets(UIEdgeInsetsMake(0, 16, 0, 16));
    }];

    [self.followersBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.top.bottom.equalTo(statsBg);
        make.width.equalTo(statsBg).dividedBy(3);
    }];

    [self.followingsBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.top.bottom.equalTo(statsBg);
        make.width.equalTo(statsBg).dividedBy(3);
    }];

    [visitorsView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.top.bottom.equalTo(statsBg);
        make.width.equalTo(statsBg).dividedBy(3);
    }];
}

- (UIButton *)makeStatButtonWithTitle:(NSString *)title count:(NSInteger)count {
    UIButton *view = [UIButton buttonWithType:UIButtonTypeCustom];

    UILabel *countLabel = [[UILabel alloc] init];
    countLabel.text = [NSString stringWithFormat:@"%ld", (long)count];
    countLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightBold];
    countLabel.textColor = [UIColor whiteColor];
    countLabel.textAlignment = NSTextAlignmentCenter;
    countLabel.tag = 10;
    [view addSubview:countLabel];

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = title;
    titleLabel.font = [UIFont systemFontOfSize:12];
    titleLabel.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.5];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [view addSubview:titleLabel];

    [countLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(view);
        make.top.equalTo(view).offset(12);
    }];

    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(view);
        make.top.equalTo(countLabel.mas_bottom).offset(4);
        make.bottom.equalTo(view).offset(-12);
    }];

    return view;
}

- (void)setupLoginRequired {
    self.loginRequiredView = [[HYLoginRequiredView alloc] init];
    self.loginRequiredView.tipText = @"登录后可以看到我的资料";
    [self.loginRequiredView setLoginButtonTitle:@"去登录"];
    __weak typeof(self) weakSelf = self;
    self.loginRequiredView.onLoginTapped = ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"HYNeedLoginNotification" object:nil];
    };
    self.loginRequiredView.hidden = YES;
    [self.view addSubview:self.loginRequiredView];

    [self.loginRequiredView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
}

- (void)setupConstraints {
    [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];

    [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.scrollView);
        make.width.equalTo(self.scrollView);
    }];

    [self.headerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.trailing.equalTo(self.contentView);
        make.height.equalTo(@(kHeaderHeight));
    }];

    [self.bgImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.headerView);
    }];

    [self.settingsButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.headerView.mas_safeAreaLayoutGuideTop).offset(8);
        make.trailing.equalTo(self.headerView).offset(-16);
        make.width.height.equalTo(@44);
    }];

    [self.editButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.settingsButton);
        make.trailing.equalTo(self.settingsButton.mas_leading).offset(-8);
        make.width.height.equalTo(@44);
    }];

    [self.avatarImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.headerView);
        make.top.equalTo(self.headerView).offset(50);
        make.width.height.equalTo(@(kAvatarSize));
    }];

    [self.nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.headerView);
        make.top.equalTo(self.avatarImageView.mas_bottom).offset(12);
    }];

    [self.genderAgeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.headerView);
        make.top.equalTo(self.nameLabel.mas_bottom).offset(4);
    }];

    [self.idLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.headerView);
        make.top.equalTo(self.genderAgeLabel.mas_bottom).offset(4);
    }];

    // Intro card
    [self.introCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.headerView.mas_bottom).offset(16);
        make.leading.trailing.equalTo(self.contentView).inset(16);
        make.height.equalTo(@120);
    }];

    // About card
    [self.aboutCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.introCard.mas_bottom).offset(12);
        make.leading.trailing.equalTo(self.contentView).inset(16);
        make.height.equalTo(@120);
    }];

    [self.tagsContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.aboutCard).offset(40);
        make.leading.trailing.equalTo(self.aboutCard).inset(16);
    }];

    // Photo wall
    [self.photoWallView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.aboutCard.mas_bottom).offset(12);
        make.leading.trailing.equalTo(self.contentView);
        make.height.equalTo(@(kPhotoSize + 30));
    }];

    [self.photoScrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.photoWallView).offset(24);
        make.leading.trailing.equalTo(self.photoWallView);
        make.height.equalTo(@(kPhotoSize));
    }];

    [self.addPhotoButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.photoScrollView).offset(16);
        make.top.bottom.equalTo(self.photoScrollView);
        make.width.height.equalTo(@(kPhotoSize));
    }];

    // Posts section
    UIView *postsSection = [self.contentView viewWithTag:200];
    [postsSection mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.photoWallView.mas_bottom).offset(12);
        make.leading.trailing.equalTo(self.contentView);
    }];

    [postsSection.subviews.lastObject mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(postsSection).offset(24);
        make.leading.trailing.equalTo(postsSection);
        make.height.equalTo(@100);
        make.bottom.equalTo(postsSection);
    }];

    // Stats
    [self.statsView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(postsSection.mas_bottom).offset(12);
        make.leading.trailing.equalTo(self.contentView);
        make.height.equalTo(@80);
        make.bottom.equalTo(self.contentView).offset(-40);
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

        [self.postsTableView reloadData];
        [self updatePostsSectionHeight];
    }];
}

- (void)updateUI {
    if (!self.currentUser) return;

    self.nameLabel.text = self.currentUser.name.length > 0 ? self.currentUser.name : @"Hiyo用户";
    self.idLabel.text = [NSString stringWithFormat:@"ID: %ld", (long)self.currentUser.accountId];

    // Gender + Age badge
    NSMutableString *badge = [NSMutableString string];
    if (self.currentUser.sex == 2) {
        [badge appendString:@"♀ "];
    } else if (self.currentUser.sex == 1) {
        [badge appendString:@"♂ "];
    }
    if (self.currentUser.age > 0) {
        [badge appendFormat:@"%ld岁", (long)self.currentUser.age];
    }
    self.genderAgeLabel.text = badge.length > 0 ? badge : nil;
    self.genderAgeLabel.textColor = self.currentUser.sex == 2 ? [UIColor systemPinkColor] : [UIColor colorWithRed:0.482 green:0.373 blue:1.0 alpha:1.0];

    if (self.currentUser.avatar.length > 0) {
        [self.avatarImageView sd_setImageWithURL:[NSURL URLWithString:self.currentUser.avatar]
                               placeholderImage:[UIImage systemImageNamed:@"person.circle.fill"]];
        // Use avatar as background blur if no background image
        if (self.currentUser.backgroundImage.length == 0) {
            [self.bgImageView sd_setImageWithURL:[NSURL URLWithString:self.currentUser.avatar]];
            self.bgImageView.alpha = 0.3;
        }
    }

    if (self.currentUser.backgroundImage.length > 0) {
        [self.bgImageView sd_setImageWithURL:[NSURL URLWithString:self.currentUser.backgroundImage]];
        self.bgImageView.alpha = 1.0;
    }

    UILabel *bioLabel = [self.introCard viewWithTag:100];
    bioLabel.text = self.currentUser.bio.length > 0 ? self.currentUser.bio : @"这个人很懒，什么都没写";

    [self updateTags];
    [self updatePhotoWall];
    [self updateStats];
}

- (void)updateTags {
    // Remove existing tags
    for (UIView *subview in self.tagsContainer.subviews) {
        [subview removeFromSuperview];
    }

    NSMutableArray *tags = [NSMutableArray array];
    if (self.currentUser.height > 0) {
        [tags addObject:@{@"icon": @"ruler", @"text": [NSString stringWithFormat:@"%ldcm", (long)self.currentUser.height]}];
    }
    if (self.currentUser.weight > 0) {
        [tags addObject:@{@"icon": @"scalemass", @"text": [NSString stringWithFormat:@"%ldkg", (long)self.currentUser.weight]}];
    }
    if (self.currentUser.job.length > 0) {
        [tags addObject:@{@"icon": @"briefcase", @"text": self.currentUser.job}];
    }
    if (self.currentUser.currentAddress.length > 0) {
        [tags addObject:@{@"icon": @"location", @"text": self.currentUser.currentAddress}];
    }
    if (self.currentUser.constellation.length > 0) {
        [tags addObject:@{@"icon": @"moon.stars", @"text": self.currentUser.constellation}];
    }

    CGFloat x = 0, y = 0;
    CGFloat maxWidth = self.view.bounds.size.width - 64;
    CGFloat tagHeight = 28;

    for (NSDictionary *tag in tags) {
        HYProfileTag *tagView = [[HYProfileTag alloc] initWithIcon:tag[@"icon"] text:tag[@"text"]];
        CGSize size = [tagView systemLayoutSizeFittingSize:CGSizeMake(maxWidth, tagHeight)];
        tagView.frame = CGRectMake(x, y, size.width, tagHeight);
        [self.tagsContainer addSubview:tagView];

        x += size.width + 8;
        if (x > maxWidth) {
            x = 0;
            y += tagHeight + 8;
        }
    }

    CGFloat totalHeight = MAX(y + tagHeight, 60);
    [self.aboutCard mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@(totalHeight + 50));
    }];
}

- (void)updatePhotoWall {
    [self.photoUrls removeAllObjects];
    [self.photoUrls addObjectsFromArray:self.currentUser.photos ?: @[]];

    // Remove existing photo views
    for (UIImageView *iv in self.photoImageViews) {
        [iv removeFromSuperview];
    }
    [self.photoImageViews removeAllObjects];

    for (NSInteger i = 0; i < self.photoUrls.count; i++) {
        UIImageView *iv = [[UIImageView alloc] init];
        iv.contentMode = UIViewContentModeScaleAspectFill;
        iv.clipsToBounds = YES;
        iv.layer.cornerRadius = 12;
        iv.backgroundColor = [UIColor systemGray5Color];
        iv.userInteractionEnabled = YES;
        iv.tag = i;
        [iv sd_setImageWithURL:[NSURL URLWithString:self.photoUrls[i]]];

        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(photoTapped:)];
        [iv addGestureRecognizer:tap];

        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(photoLongPressed:)];
        [iv addGestureRecognizer:longPress];

        [self.photoScrollView insertSubview:iv belowSubview:self.addPhotoButton];
        [self.photoImageViews addObject:iv];
    }

    [self layoutPhotoViews];
}

- (void)layoutPhotoViews {
    CGFloat x = 16 + kPhotoSize + 10;
    for (UIImageView *iv in self.photoImageViews) {
        iv.frame = CGRectMake(x, 0, kPhotoSize, kPhotoSize);
        x += kPhotoSize + 10;
    }
    self.photoScrollView.contentSize = CGSizeMake(x, kPhotoSize);
}

- (void)updateStats {
    UIView *followersV = self.followersBtn;
    UILabel *fc = [followersV viewWithTag:10];
    fc.text = [NSString stringWithFormat:@"%lld", self.currentUser.fansCount];

    UIView *followingsV = self.followingsBtn;
    UILabel *fic = [followingsV viewWithTag:10];
    fic.text = [NSString stringWithFormat:@"%lld", self.currentUser.attentionCount];

    UIView *visitorsV = [self.statsView viewWithTag:300];
    UILabel *vc = [visitorsV viewWithTag:10];
    vc.text = [NSString stringWithFormat:@"%lld", self.currentUser.lookMeCount];
}

- (void)updatePostsSectionHeight {
    [self.postsTableView layoutIfNeeded];
    CGFloat height = self.postsTableView.contentSize.height;
    UIView *postsSection = [self.contentView viewWithTag:200];
    [postsSection.subviews.lastObject mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@(MAX(height, 44)));
    }];
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

- (void)followersTapped {
    FollowListViewController *vc = [[FollowListViewController alloc] initWithUserId:@"me" type:HYFollowListTypeFollowers userName:self.currentUser.name ?: @"我的"];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)followingsTapped {
    FollowListViewController *vc = [[FollowListViewController alloc] initWithUserId:@"me" type:HYFollowListTypeFollowings userName:self.currentUser.name ?: @"我的"];
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

- (void)photoLongPressed:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        [alert addAction:[UIAlertAction actionWithTitle:@"删除照片" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
            NSInteger index = gesture.view.tag;
            if (index < (NSInteger)self.photoUrls.count) {
                [self.photoUrls removeObjectAtIndex:index];
                [self updatePhotoWall];
            }
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.myPosts.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PostCell" forIndexPath:indexPath];
    cell.backgroundColor = [UIColor clearColor];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    for (UIView *subview in cell.contentView.subviews) {
        [subview removeFromSuperview];
    }

    HYPost *post = self.myPosts[indexPath.row];

    UIView *card = [[UIView alloc] init];
    card.backgroundColor = [UIColor colorWithRed:0.11 green:0.11 blue:0.18 alpha:1.0];
    card.layer.cornerRadius = 12;
    [cell.contentView addSubview:card];

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = post.title;
    titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.numberOfLines = 1;
    [card addSubview:titleLabel];

    UILabel *contentLabel = [[UILabel alloc] init];
    contentLabel.text = post.content;
    contentLabel.font = [UIFont systemFontOfSize:13];
    contentLabel.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.6];
    contentLabel.numberOfLines = 2;
    [card addSubview:contentLabel];

    UILabel *statsLabel = [[UILabel alloc] init];
    statsLabel.text = [NSString stringWithFormat:@"♥ %ld  💬 %ld", (long)post.likesCount, (long)post.commentsCount];
    statsLabel.font = [UIFont systemFontOfSize:12];
    statsLabel.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.4];
    [card addSubview:statsLabel];

    [card mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(cell.contentView).insets(UIEdgeInsetsMake(4, 16, 4, 16));
    }];

    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.trailing.equalTo(card).inset(12);
    }];

    [contentLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(titleLabel.mas_bottom).offset(4);
        make.leading.trailing.equalTo(card).inset(12);
    }];

    [statsLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(contentLabel.mas_bottom).offset(8);
        make.leading.bottom.equalTo(card).inset(12);
    }];

    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    HYPost *post = self.myPosts[indexPath.row];
    PostDetailViewController *vc = [[PostDetailViewController alloc] initWithPostId:post.postId];
    [self.navigationController pushViewController:vc animated:YES];
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
            CGFloat w = maxDim, h = maxDim;
            if (image.size.width > image.size.height) {
                w = maxDim;
                h = maxDim / ratio;
            } else {
                h = maxDim;
                w = maxDim * ratio;
            }
            CGSize size = CGSizeMake(w, h);
            UIGraphicsBeginImageContextWithOptions(size, NO, 1.0);
            [image drawInRect:CGRectMake(0, 0, w, h)];
            UIImage *resized = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            NSData *data = UIImageJPEGRepresentation(resized ?: image, 0.8);
            if (!data) return;

            NSString *fileName = [NSString stringWithFormat:@"photo_%@.jpg", @([[NSDate date] timeIntervalSince1970])];
            [[HYAPIClient shared] uploadImageWithData:data fileName:fileName completion:^(NSDictionary *response, NSError *error) {
                if (error) {
                    NSLog(@"Upload failed: %@", error.localizedDescription);
                    return;
                }
                NSDictionary *dict = response[@"data"];
                NSString *url = dict[@"url"];
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

- (void)idLabelTapped {
    if (self.currentUser && self.currentUser.accountId > 0) {
        NSString *accountId = [NSString stringWithFormat:@"%ld", (long)self.currentUser.accountId];
        [UIPasteboard generalPasteboard].string = accountId;
        [self showToast:@"ID已复制"];
    }
}

- (void)showToast:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showLoginRequired {
    self.loginRequiredView.hidden = NO;
    self.scrollView.hidden = YES;
}

- (void)hideLoginRequired {
    self.loginRequiredView.hidden = YES;
    self.scrollView.hidden = NO;
}

@end
