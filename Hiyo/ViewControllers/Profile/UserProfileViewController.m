#import "UserProfileViewController.h"
#import "HYAPIClient.h"
#import "HYUser.h"
#import "HYPhotoItem.h"
#import "HYModels.h"
#import "FollowListViewController.h"
#import "FullscreenPhotoViewController.h"
#import "ChatDetailViewController.h"
#import "PostDetailViewController.h"
#import "HYPostCell.h"
#import "HYLoginRequiredView.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/SDWebImage.h>

@interface UserProfileViewController () <UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate>

@property (nonatomic, copy) NSString *userId;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;

// Header
@property (nonatomic, strong) UIImageView *bgImageView;
@property (nonatomic, strong) UIImageView *avatarView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *bioLabel;
@property (nonatomic, strong) UILabel *genderAgeLabel;
@property (nonatomic, strong) UILabel *idLabel;
@property (nonatomic, strong) UIView *onlineIndicator;

// Cards
@property (nonatomic, strong) UIView *introCard;
@property (nonatomic, strong) UIView *aboutCard;
@property (nonatomic, strong) UIView *photoWallCard;

// Tags
@property (nonatomic, strong) UIView *tagsContainer;

// Action buttons
@property (nonatomic, strong) UIButton *followButton;
@property (nonatomic, strong) UIButton *chatButton;

// Posts
@property (nonatomic, strong) UITableView *postsTableView;
@property (nonatomic, strong) NSMutableArray<HYPost *> *posts;
@property (nonatomic, assign) BOOL isLoadingPosts;
@property (nonatomic, assign) NSInteger postsPage;

// Data
@property (nonatomic, strong) HYUser *user;
@property (nonatomic, strong) NSMutableArray<HYPhotoItem *> *photos;
@property (nonatomic, strong) HYLoginRequiredView *loginRequiredView;

@end

@implementation UserProfileViewController

- (instancetype)initWithUserId:(NSString *)userId {
    self = [super init];
    if (self) {
        _userId = userId;
        _posts = [NSMutableArray array];
        _photos = [NSMutableArray array];
        _postsPage = 1;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithRed:0.04 green:0.04 blue:0.08 alpha:1.0];
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;

    [self setupUI];
    [self setupConstraints];
    [self loadData];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.prefersLargeTitles = NO;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.navigationController.navigationBar.prefersLargeTitles = YES;
}

- (void)setupUI {
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.showsVerticalScrollIndicator = NO;
    [self.view addSubview:self.scrollView];

    self.contentView = [[UIView alloc] init];
    [self.scrollView addSubview:self.contentView];

    // Background image
    self.bgImageView = [[UIImageView alloc] init];
    self.bgImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.bgImageView.clipsToBounds = YES;
    self.bgImageView.backgroundColor = [UIColor colorWithRed:0.15 green:0.12 blue:0.25 alpha:1.0];
    [self.contentView addSubview:self.bgImageView];

    // Gradient overlay
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.colors = @[(id)[[UIColor clearColor] CGColor],
                       (id)[[UIColor colorWithRed:0.04 green:0.04 blue:0.08 alpha:1.0] CGColor]];
    gradient.locations = @[@0.4, @1.0];
    [self.bgImageView.layer addSublayer:gradient];

    // Avatar
    self.avatarView = [[UIImageView alloc] init];
    self.avatarView.contentMode = UIViewContentModeScaleAspectFill;
    self.avatarView.layer.cornerRadius = 45;
    self.avatarView.layer.borderWidth = 3;
    self.avatarView.layer.borderColor = [UIColor systemPinkColor].CGColor;
    self.avatarView.clipsToBounds = YES;
    self.avatarView.backgroundColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.3 alpha:1.0];
    [self.contentView addSubview:self.avatarView];

    // Online indicator
    self.onlineIndicator = [[UIView alloc] init];
    self.onlineIndicator.backgroundColor = [UIColor systemGreenColor];
    self.onlineIndicator.layer.cornerRadius = 6;
    self.onlineIndicator.layer.borderWidth = 2;
    self.onlineIndicator.layer.borderColor = [UIColor colorWithRed:0.04 green:0.04 blue:0.08 alpha:1.0].CGColor;
    self.onlineIndicator.hidden = YES;
    [self.contentView addSubview:self.onlineIndicator];

    // Name
    self.nameLabel = [[UILabel alloc] init];
    self.nameLabel.font = [UIFont systemFontOfSize:22 weight:UIFontWeightBold];
    self.nameLabel.textColor = [UIColor whiteColor];
    self.nameLabel.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:self.nameLabel];

    // ID label
    self.idLabel = [[UILabel alloc] init];
    self.idLabel.font = [UIFont systemFontOfSize:12];
    self.idLabel.textColor = [UIColor systemGrayColor];
    self.idLabel.textAlignment = NSTextAlignmentCenter;
    self.idLabel.userInteractionEnabled = YES;
    UITapGestureRecognizer *idTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(idLabelTapped)];
    [self.idLabel addGestureRecognizer:idTap];
    [self.contentView addSubview:self.idLabel];

    // Gender + Age label
    self.genderAgeLabel = [[UILabel alloc] init];
    self.genderAgeLabel.font = [UIFont systemFontOfSize:13];
    self.genderAgeLabel.textColor = [UIColor systemGrayColor];
    self.genderAgeLabel.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:self.genderAgeLabel];

    // Bio
    self.bioLabel = [[UILabel alloc] init];
    self.bioLabel.font = [UIFont systemFontOfSize:14];
    self.bioLabel.textColor = [UIColor systemGrayColor];
    self.bioLabel.textAlignment = NSTextAlignmentCenter;
    self.bioLabel.numberOfLines = 2;
    [self.contentView addSubview:self.bioLabel];

    // Action buttons
    self.followButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.followButton.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    self.followButton.layer.cornerRadius = 20;
    self.followButton.layer.borderWidth = 1;
    [self.followButton addTarget:self action:@selector(followTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.followButton];

    self.chatButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.chatButton setImage:[UIImage systemImageNamed:@"bubble.left.fill"] forState:UIControlStateNormal];
    self.chatButton.tintColor = [UIColor whiteColor];
    self.chatButton.backgroundColor = [UIColor systemPinkColor];
    self.chatButton.layer.cornerRadius = 20;
    [self.chatButton addTarget:self action:@selector(chatTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.chatButton];

    // Intro card
    self.introCard = [self createCardView];
    [self.contentView addSubview:self.introCard];

    // About card
    self.aboutCard = [self createCardView];
    [self.contentView addSubview:self.aboutCard];

    // Photo wall card
    self.photoWallCard = [self createCardView];
    [self.contentView addSubview:self.photoWallCard];

    // Tags container
    self.tagsContainer = [[UIView alloc] init];
    [self.contentView addSubview:self.tagsContainer];

    // Posts table
    self.postsTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.postsTableView.delegate = self;
    self.postsTableView.dataSource = self;
    self.postsTableView.backgroundColor = [UIColor clearColor];
    self.postsTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.postsTableView.scrollEnabled = NO;
    self.postsTableView.tag = 999;
    [self.postsTableView registerClass:[HYPostCell class] forCellReuseIdentifier:@"PostCell"];
    [self.contentView addSubview:self.postsTableView];

    // Login required
    if (![[HYAPIClient shared] isLoggedIn]) {
        self.loginRequiredView = [[HYLoginRequiredView alloc] init];
        self.loginRequiredView.tipText = @"登录后查看更多信息";
        [self.loginRequiredView setLoginButtonTitle:@"去登录"];
        __weak typeof(self) weakSelf = self;
        self.loginRequiredView.onLoginTapped = ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:@"HYNeedLoginNotification" object:nil];
        };
        [self.view addSubview:self.loginRequiredView];
    }
}

- (UIView *)createCardView {
    UIView *card = [[UIView alloc] init];
    card.backgroundColor = [UIColor colorWithRed:0.11 green:0.11 blue:0.18 alpha:1.0];
    card.layer.cornerRadius = 16;
    return card;
}

- (void)setupConstraints {
    if (![[HYAPIClient shared] isLoggedIn]) {
        [self.loginRequiredView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.view);
        }];
        return;
    }

    [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];

    [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.scrollView);
        make.width.equalTo(self.scrollView);
    }];

    CGFloat screenW = [UIScreen mainScreen].bounds.size.width;

    [self.bgImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.contentView);
        make.height.equalTo(@200);
    }];

    [self.avatarView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.contentView);
        make.top.equalTo(self.contentView).offset(120);
        make.width.height.equalTo(@90);
    }];

    [self.onlineIndicator mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.bottom.equalTo(self.avatarView);
        make.width.height.equalTo(@12);
    }];

    [self.nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.avatarView.mas_bottom).offset(12);
        make.centerX.equalTo(self.contentView);
    }];

    [self.idLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.nameLabel.mas_bottom).offset(4);
        make.centerX.equalTo(self.contentView);
    }];

    [self.genderAgeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.idLabel.mas_bottom).offset(4);
        make.centerX.equalTo(self.contentView);
    }];

    [self.bioLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.genderAgeLabel.mas_bottom).offset(8);
        make.left.equalTo(self.contentView).offset(32);
        make.right.equalTo(self.contentView).offset(-32);
    }];

    [self.followButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.bioLabel.mas_bottom).offset(16);
        make.right.equalTo(self.contentView.mas_centerX).offset(-8);
        make.width.equalTo(@120);
        make.height.equalTo(@40);
    }];

    [self.chatButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.followButton);
        make.left.equalTo(self.contentView.mas_centerX).offset(8);
        make.width.height.equalTo(@40);
    }];

    [self.introCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.followButton.mas_bottom).offset(20);
        make.left.equalTo(self.contentView).offset(16);
        make.right.equalTo(self.contentView).offset(-16);
        make.height.equalTo(@80);
    }];

    [self.aboutCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.introCard.mas_bottom).offset(12);
        make.left.right.equalTo(self.introCard);
        make.height.greaterThanOrEqualTo(@60);
    }];

    [self.tagsContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.aboutCard.mas_bottom).offset(12);
        make.left.equalTo(self.contentView).offset(16);
        make.right.equalTo(self.contentView).offset(-16);
        make.height.greaterThanOrEqualTo(@0);
    }];

    [self.photoWallCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tagsContainer.mas_bottom).offset(12);
        make.left.right.equalTo(self.introCard);
        make.height.equalTo(@140);
    }];

    [self.postsTableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.photoWallCard.mas_bottom).offset(12);
        make.left.right.equalTo(self.contentView);
        make.height.equalTo(@400);
        make.bottom.equalTo(self.contentView).offset(-20);
    }];
}

- (void)loadData {
    __weak typeof(self) weakSelf = self;
    [[HYAPIClient shared] getUserInfoWithId:self.userId completion:^(NSDictionary *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf updateUIWithResponse:response error:error];
        });
    }];

    [self loadPosts];
}

- (void)updateUIWithResponse:(NSDictionary *)response error:(NSError *)error {
    if (error) return;
    NSDictionary *data = response[@"data"];
    if (![data isKindOfClass:[NSDictionary class]]) return;

    self.user = [[HYUser alloc] initWithDictionary:data];
    [self updateUI];
}

- (void)updateUI {
    if (!self.user) return;

    if (self.user.backgroundImage.length > 0) {
        [self.bgImageView sd_setImageWithURL:[NSURL URLWithString:self.user.backgroundImage]];
    }
    if (self.user.avatar.length > 0) {
        [self.avatarView sd_setImageWithURL:[NSURL URLWithString:self.user.avatar]];
    }

    self.nameLabel.text = self.user.name;
    self.idLabel.text = [NSString stringWithFormat:@"ID: %ld", (long)self.user.accountId];
    self.bioLabel.text = self.user.bio;

    // Gender + Age badge
    NSMutableString *badge = [NSMutableString string];
    if (self.user.sex == 2) {
        [badge appendString:@"♀ "];
    } else if (self.user.sex == 1) {
        [badge appendString:@"♂ "];
    }
    if (self.user.age > 0) {
        [badge appendFormat:@"%ld岁", (long)self.user.age];
    }
    self.genderAgeLabel.text = badge.length > 0 ? badge : nil;
    self.genderAgeLabel.textColor = self.user.sex == 2 ? [UIColor systemPinkColor] : [UIColor colorWithRed:0.482 green:0.373 blue:1.0 alpha:1.0];
    self.onlineIndicator.hidden = !self.user.isOnline;

    // Follow button
    if (self.user.isFollowing) {
        [self.followButton setTitle:@"已关注" forState:UIControlStateNormal];
        [self.followButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        self.followButton.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.3].CGColor;
        self.followButton.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.1];
    } else {
        [self.followButton setTitle:@"关注" forState:UIControlStateNormal];
        [self.followButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        self.followButton.layer.borderColor = [UIColor systemPinkColor].CGColor;
        self.followButton.backgroundColor = [UIColor systemPinkColor];
    }

    // Intro card: stats
    [self setupIntroCard];

    // About card
    [self setupAboutCard];

    // Tags
    [self setupTags];

    // Photo wall
    [self setupPhotoWall];

    // Layout posts table
    CGFloat postsHeight = self.posts.count * 160;
    if (postsHeight < 100) postsHeight = 200;
    [self.postsTableView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@(postsHeight));
    }];
    [self.view layoutIfNeeded];
}

- (void)setupIntroCard {
    for (UIView *subview in [self.introCard subviews]) {
        [subview removeFromSuperview];
    }

    NSArray *stats = @[
        @{@"label": @"粉丝", @"value": [NSString stringWithFormat:@"%lld", self.user.fansCount]},
        @{@"label": @"关注", @"value": [NSString stringWithFormat:@"%lld", self.user.attentionCount]},
        @{@"label": @"魅力", @"value": [NSString stringWithFormat:@"%lld", self.user.charm]},
    ];

    CGFloat itemW = ([UIScreen mainScreen].bounds.size.width - 64) / 3;

    for (NSInteger i = 0; i < stats.count; i++) {
        UIView *item = [[UIView alloc] init];
        item.tag = 300 + i;
        [self.introCard addSubview:item];

        UILabel *valueLabel = [[UILabel alloc] init];
        valueLabel.text = stats[i][@"value"];
        valueLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
        valueLabel.textColor = [UIColor whiteColor];
        valueLabel.textAlignment = NSTextAlignmentCenter;
        valueLabel.tag = 400 + i;
        [item addSubview:valueLabel];

        UILabel *titleLabel = [[UILabel alloc] init];
        titleLabel.text = stats[i][@"label"];
        titleLabel.font = [UIFont systemFontOfSize:12];
        titleLabel.textColor = [UIColor systemGrayColor];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        [item addSubview:titleLabel];

        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(statsTapped:)];
        [item addGestureRecognizer:tap];
        item.userInteractionEnabled = YES;
        item.tag = 500 + i;

        [item mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.introCard).offset(i * itemW);
            make.top.bottom.equalTo(self.introCard);
            make.width.equalTo(@(itemW));
        }];

        [valueLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(item);
            make.centerY.equalTo(item).offset(-8);
        }];

        [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(item);
            make.top.equalTo(valueLabel.mas_bottom).offset(4);
        }];
    }
}

- (void)statsTapped:(UITapGestureRecognizer *)gesture {
    NSInteger idx = gesture.view.tag - 500;
    HYFollowListType type = (idx == 0) ? HYFollowListTypeFollowers : HYFollowListTypeFollowings;
    NSString *title = (idx == 0) ? @"粉丝" : @"关注";
    FollowListViewController *vc = [[FollowListViewController alloc] initWithUserId:self.userId type:type userName:title];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)setupAboutCard {
    for (UIView *subview in [self.aboutCard subviews]) {
        [subview removeFromSuperview];
    }

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = @"基本信息";
    titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    titleLabel.textColor = [UIColor whiteColor];
    [self.aboutCard addSubview:titleLabel];

    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.aboutCard).offset(16);
        make.left.equalTo(self.aboutCard).offset(16);
    }];

    UIView *lastRow = titleLabel;
    NSArray *items = @[];
    if (self.user.height > 0) {
        items = @[@[@"身高", [NSString stringWithFormat:@"%ld cm", (long)self.user.height]],
                  @[@"体重", [NSString stringWithFormat:@"%ld kg", (long)self.user.weight]],
                  @[@"职业", self.user.job ?: @"未知"],
                  @[@"位置", self.user.currentAddress ?: @"未知"],
                  @[@"星座", self.user.constellation ?: @"未知"]];
    }

    UIView *lastItem = nil;
    for (NSArray *item in items) {
        UIView *row = [[UIView alloc] init];
        row.tag = 600;
        [self.aboutCard addSubview:row];

        UILabel *keyLabel = [[UILabel alloc] init];
        keyLabel.text = item[0];
        keyLabel.font = [UIFont systemFontOfSize:13];
        keyLabel.textColor = [UIColor systemGrayColor];
        [row addSubview:keyLabel];

        UILabel *valLabel = [[UILabel alloc] init];
        valLabel.text = item[1];
        valLabel.font = [UIFont systemFontOfSize:13];
        valLabel.textColor = [UIColor whiteColor];
        valLabel.textAlignment = NSTextAlignmentRight;
        [row addSubview:valLabel];

        [row mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(lastRow.mas_bottom).offset(8);
            make.left.equalTo(self.aboutCard).offset(16);
            make.right.equalTo(self.aboutCard).offset(-16);
            make.height.equalTo(@20);
        }];

        [keyLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.centerY.equalTo(row);
        }];

        [valLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.centerY.equalTo(row);
        }];

        lastRow = row;
        lastItem = row;
    }

    if (lastItem) {
        [lastItem mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(self.aboutCard).offset(-16);
        }];
    }

    [self.aboutCard mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.greaterThanOrEqualTo(@(items.count > 0 ? items.count * 28 + 40 : 60));
    }];
}

- (void)setupTags {
    for (UIView *subview in [self.tagsContainer subviews]) {
        [subview removeFromSuperview];
    }

    if (self.user.interests.count == 0) return;

    CGFloat x = 0, y = 0;
    CGFloat maxW = [UIScreen mainScreen].bounds.size.width - 32;
    CGFloat rowH = 32;

    for (NSString *tag in self.user.interests) {
        CGSize size = [tag sizeWithAttributes:@{NSFontAttributeName: [UIFont systemFontOfSize:12]}];
        CGFloat btnW = size.width + 24;

        if (x + btnW > maxW) {
            x = 0;
            y += rowH + 6;
        }

        UIView *chip = [[UIView alloc] initWithFrame:CGRectMake(x, y, btnW, rowH)];
        chip.backgroundColor = [[UIColor systemPurpleColor] colorWithAlphaComponent:0.2];
        chip.layer.cornerRadius = rowH / 2;

        UILabel *lbl = [[UILabel alloc] init];
        lbl.text = tag;
        lbl.font = [UIFont systemFontOfSize:12];
        lbl.textColor = [UIColor systemPurpleColor];
        lbl.textAlignment = NSTextAlignmentCenter;
        [chip addSubview:lbl];
        [self.tagsContainer addSubview:chip];

        lbl.frame = chip.bounds;

        x += btnW + 8;
    }

    [self.tagsContainer mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@(y + rowH));
    }];
}

- (void)setupPhotoWall {
    for (UIView *subview in [self.photoWallCard subviews]) {
        [subview removeFromSuperview];
    }

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = @"相册";
    titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    titleLabel.textColor = [UIColor whiteColor];
    [self.photoWallCard addSubview:titleLabel];

    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.photoWallCard).offset(12);
        make.left.equalTo(self.photoWallCard).offset(16);
    }];

    UIScrollView *scroll = [[UIScrollView alloc] init];
    scroll.showsHorizontalScrollIndicator = NO;
    scroll.tag = 800;
    [self.photoWallCard addSubview:scroll];

    [scroll mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(titleLabel.mas_bottom).offset(8);
        make.left.right.bottom.equalTo(self.photoWallCard);
    }];

    NSArray *photoUrls = self.user.photos ?: @[];
    if (photoUrls.count == 0) {
        UILabel *emptyLabel = [[UILabel alloc] init];
        emptyLabel.text = @"暂无照片";
        emptyLabel.font = [UIFont systemFontOfSize:13];
        emptyLabel.textColor = [UIColor systemGrayColor];
        emptyLabel.textAlignment = NSTextAlignmentCenter;
        [scroll addSubview:emptyLabel];
        [emptyLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(scroll);
        }];
        return;
    }

    CGFloat photoSize = 100;
    CGFloat x = 16;
    for (NSInteger i = 0; i < (NSInteger)photoUrls.count; i++) {
        UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(x + i * (photoSize + 8), 4, photoSize, photoSize)];
        imgView.contentMode = UIViewContentModeScaleAspectFill;
        imgView.clipsToBounds = YES;
        imgView.layer.cornerRadius = 8;
        imgView.backgroundColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.3 alpha:1.0];
        [imgView sd_setImageWithURL:[NSURL URLWithString:photoUrls[i]]];
        imgView.userInteractionEnabled = YES;
        imgView.tag = 900 + i;

        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(photoTapped:)];
        [imgView addGestureRecognizer:tap];

        [scroll addSubview:imgView];
    }

    scroll.contentSize = CGSizeMake(x + photoUrls.count * (photoSize + 8), 108);
}

- (void)photoTapped:(UITapGestureRecognizer *)gesture {
    NSInteger index = gesture.view.tag - 900;
    NSArray *photoUrls = self.user.photos;
    if (photoUrls.count == 0) return;
    if (index < 0) index = 0;
    if (index >= (NSInteger)photoUrls.count) index = photoUrls.count - 1;

    FullscreenPhotoViewController *vc = [[FullscreenPhotoViewController alloc] initWithPhotoUrls:photoUrls startIndex:index];
    vc.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)idLabelTapped {
    if (self.user && self.user.accountId > 0) {
        NSString *accountId = [NSString stringWithFormat:@"%ld", (long)self.user.accountId];
        [UIPasteboard generalPasteboard].string = accountId;
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:@"ID已复制" preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)followTapped {
    if (![[HYAPIClient shared] isLoggedIn]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"HYNeedLoginNotification" object:nil];
        return;
    }

    BOOL willFollow = !self.user.isFollowing;
    self.user.isFollowing = willFollow;

    if (willFollow) {
        [self.followButton setTitle:@"已关注" forState:UIControlStateNormal];
        [self.followButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        self.followButton.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.3].CGColor;
        self.followButton.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.1];
    } else {
        [self.followButton setTitle:@"关注" forState:UIControlStateNormal];
        [self.followButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        self.followButton.layer.borderColor = [UIColor systemPinkColor].CGColor;
        self.followButton.backgroundColor = [UIColor systemPinkColor];
    }

    __weak typeof(self) weakSelf = self;
    void (^completion)(NSDictionary *, NSError *) = ^(NSDictionary *response, NSError *error) {
        if (error) {
            weakSelf.user.isFollowing = !willFollow;
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf updateUI];
            });
        }
    };

    if (willFollow) {
        [[HYAPIClient shared] followUserWithId:self.userId completion:completion];
    } else {
        [[HYAPIClient shared] unfollowUserWithId:self.userId completion:completion];
    }
}

- (void)chatTapped {
    if (![[HYAPIClient shared] isLoggedIn]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"HYNeedLoginNotification" object:nil];
        return;
    }

    ChatDetailViewController *vc = [[ChatDetailViewController alloc] initWithPartnerId:self.userId partnerName:self.user.name partnerAvatar:self.user.avatar];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)loadPosts {
    if (self.isLoadingPosts) return;
    self.isLoadingPosts = YES;

    [[HYAPIClient shared] getMyPostsWithPage:self.postsPage pageSize:10 completion:^(NSDictionary *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.isLoadingPosts = NO;

            id data = response[@"data"];
            if ([data isKindOfClass:[NSArray class]]) {
                for (NSDictionary *dict in data) {
                    if ([dict isKindOfClass:[NSDictionary class]]) {
                        [self.posts addObject:[[HYPost alloc] initWithDictionary:dict]];
                    }
                }
            }

            CGFloat postsHeight = self.posts.count * 160;
            if (postsHeight < 100) postsHeight = 200;
            [self.postsTableView mas_updateConstraints:^(MASConstraintMaker *make) {
                make.height.equalTo(@(postsHeight));
            }];
            [self.postsTableView reloadData];
        });
    }];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.posts.count == 0) {
        return 1; // empty state
    }
    return self.posts.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.posts.count == 0) {
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"EmptyCell"];
        cell.backgroundColor = [UIColor clearColor];
        cell.textLabel.text = @"暂无动态";
        cell.textLabel.textColor = [UIColor systemGrayColor];
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
    }

    HYPostCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PostCell" forIndexPath:indexPath];
    HYPost *post = self.posts[indexPath.row];
    [cell configWithPost:post];

    __weak typeof(self) weakSelf = self;
    cell.onLikeTapped = ^(HYPost *likedPost) {
        [weakSelf toggleLikeForPost:likedPost];
    };
    cell.onCommentTapped = ^(HYPost *commentedPost) {
        PostDetailViewController *vc = [[PostDetailViewController alloc] initWithPostId:commentedPost.postId];
        [weakSelf.navigationController pushViewController:vc animated:YES];
    };

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return self.posts.count == 0 ? 60 : 160;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < self.posts.count) {
        HYPost *post = self.posts[indexPath.row];
        PostDetailViewController *vc = [[PostDetailViewController alloc] initWithPostId:post.postId];
        [self.navigationController pushViewController:vc animated:YES];
    }
}

- (void)toggleLikeForPost:(HYPost *)post {
    post.isLiked = !post.isLiked;
    post.likesCount += post.isLiked ? 1 : -1;

    __weak typeof(self) weakSelf = self;
    [[HYAPIClient shared] likePostWithId:post.postId completion:^(NSDictionary *response, NSError *error) {
        if (error) {
            post.isLiked = !post.isLiked;
            post.likesCount += post.isLiked ? 1 : -1;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.postsTableView reloadData];
        });
    }];
}

@end
