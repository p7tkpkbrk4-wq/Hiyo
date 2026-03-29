#import "ProfileViewController.h"
#import "HYAPIClient.h"
#import "HYUser.h"
#import "SettingsViewController.h"
#import "EditProfileViewController.h"
#import "FeedbackViewController.h"
#import "AboutViewController.h"
#import "FavoritesViewController.h"
#import "HistoryViewController.h"
#import "HYColors.h"
#import <Masonry/Masonry.h>

@interface ProfileViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UIImageView *avatarView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *bioLabel;
@property (nonatomic, strong) UIView *statsView;
@property (nonatomic, strong) UILabel *fansCountLabel;
@property (nonatomic, strong) UILabel *attentionCountLabel;
@property (nonatomic, strong) UILabel *likesCountLabel;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *menuItems;
@property (nonatomic, strong) HYUser *currentUser;

// Login required view
@property (nonatomic, strong) UIView *loginRequiredView;
@property (nonatomic, strong) UIButton *loginButton;

@end

@implementation ProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"我的";
    self.view.backgroundColor = DarkBackground;
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
    self.headerView.hidden = YES;
    self.tableView.hidden = YES;
}

- (void)hideLoginRequired {
    self.loginRequiredView.hidden = YES;
    self.headerView.hidden = NO;
    self.tableView.hidden = NO;
}

- (void)setupUI {
    self.view.backgroundColor = DarkBackground;

    // Login required view
    self.loginRequiredView = [[UIView alloc] init];
    self.loginRequiredView.backgroundColor = DarkBackground;
    self.loginRequiredView.hidden = YES;
    [self.view addSubview:self.loginRequiredView];

    UILabel *tipLabel = [[UILabel alloc] init];
    tipLabel.text = @"登录后可以看到我的资料";
    tipLabel.font = [UIFont systemFontOfSize:16];
    tipLabel.textColor = TextMuted;
    tipLabel.textAlignment = NSTextAlignmentCenter;
    [self.loginRequiredView addSubview:tipLabel];

    self.loginButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.loginButton setTitle:@"去登录" forState:UIControlStateNormal];
    [self.loginButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.loginButton.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    self.loginButton.backgroundColor = PrimaryPink;
    self.loginButton.layer.cornerRadius = 12;
    [self.loginButton addTarget:self action:@selector(loginButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.loginRequiredView addSubview:self.loginButton];

    // Header View
    self.headerView = [[UIView alloc] init];
    self.headerView.backgroundColor = DarkBackground;
    [self.view addSubview:self.headerView];

    // Avatar
    self.avatarView = [[UIImageView alloc] init];
    self.avatarView.image = [UIImage systemImageNamed:@"person.circle.fill"];
    self.avatarView.tintColor = TextMuted;
    self.avatarView.contentMode = UIViewContentModeScaleAspectFill;
    self.avatarView.layer.cornerRadius = 50;
    self.avatarView.clipsToBounds = YES;
    [self.headerView addSubview:self.avatarView];

    // Name
    self.nameLabel = [[UILabel alloc] init];
    self.nameLabel.text = @"Hiyo用户";
    self.nameLabel.font = [UIFont systemFontOfSize:24 weight:UIFontWeightBold];
    self.nameLabel.textColor = [UIColor whiteColor];
    self.nameLabel.textAlignment = NSTextAlignmentCenter;
    [self.headerView addSubview:self.nameLabel];

    // Bio
    self.bioLabel = [[UILabel alloc] init];
    self.bioLabel.text = @"这个人很懒，什么都没写";
    self.bioLabel.font = [UIFont systemFontOfSize:14];
    self.bioLabel.textColor = TextMuted;
    self.bioLabel.textAlignment = NSTextAlignmentCenter;
    [self.headerView addSubview:self.bioLabel];

    // Stats View
    self.statsView = [[UIView alloc] init];
    [self.headerView addSubview:self.statsView];

    CGFloat width = self.view.bounds.size.width / 3;

    // Fans count
    UIView *fansView = [[UIView alloc] init];
    [self.statsView addSubview:fansView];
    self.fansCountLabel = [[UILabel alloc] init];
    self.fansCountLabel.text = @"0";
    self.fansCountLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
    self.fansCountLabel.textColor = [UIColor whiteColor];
    self.fansCountLabel.textAlignment = NSTextAlignmentCenter;
    [fansView addSubview:self.fansCountLabel];
    UILabel *fansTitleLabel = [[UILabel alloc] init];
    fansTitleLabel.text = @"粉丝";
    fansTitleLabel.font = [UIFont systemFontOfSize:12];
    fansTitleLabel.textColor = TextMuted;
    fansTitleLabel.textAlignment = NSTextAlignmentCenter;
    [fansView addSubview:fansTitleLabel];

    // Attention count
    UIView *attentionView = [[UIView alloc] init];
    [self.statsView addSubview:attentionView];
    self.attentionCountLabel = [[UILabel alloc] init];
    self.attentionCountLabel.text = @"0";
    self.attentionCountLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
    self.attentionCountLabel.textColor = [UIColor whiteColor];
    self.attentionCountLabel.textAlignment = NSTextAlignmentCenter;
    [attentionView addSubview:self.attentionCountLabel];
    UILabel *attentionTitleLabel = [[UILabel alloc] init];
    attentionTitleLabel.text = @"关注";
    attentionTitleLabel.font = [UIFont systemFontOfSize:12];
    attentionTitleLabel.textColor = TextMuted;
    attentionTitleLabel.textAlignment = NSTextAlignmentCenter;
    [attentionView addSubview:attentionTitleLabel];

    // Likes count
    UIView *likesView = [[UIView alloc] init];
    [self.statsView addSubview:likesView];
    self.likesCountLabel = [[UILabel alloc] init];
    self.likesCountLabel.text = @"0";
    self.likesCountLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
    self.likesCountLabel.textColor = [UIColor whiteColor];
    self.likesCountLabel.textAlignment = NSTextAlignmentCenter;
    [likesView addSubview:self.likesCountLabel];
    UILabel *likesTitleLabel = [[UILabel alloc] init];
    likesTitleLabel.text = @"获赞";
    likesTitleLabel.font = [UIFont systemFontOfSize:12];
    likesTitleLabel.textColor = TextMuted;
    likesTitleLabel.textAlignment = NSTextAlignmentCenter;
    [likesView addSubview:likesTitleLabel];

    // Edit Profile Button
    UIButton *editButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [editButton setTitle:@"编辑资料" forState:UIControlStateNormal];
    [editButton setTitleColor:PrimaryPink forState:UIControlStateNormal];
    editButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    editButton.layer.cornerRadius = 8;
    editButton.layer.borderWidth = 1;
    editButton.layer.borderColor = PrimaryPink.CGColor;
    [editButton addTarget:self action:@selector(editProfileTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.headerView addSubview:editButton];

    // Table View
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleInsetGrouped];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = DarkBackground;
    self.tableView.separatorColor = DarkLighter;
    [self.view addSubview:self.tableView];

    [self setupConstraints];

    [fansView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.bottom.equalTo(self.statsView);
        make.width.equalTo(self.statsView).dividedBy(3);
    }];

    [attentionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.top.bottom.equalTo(self.statsView);
        make.width.equalTo(self.statsView).dividedBy(3);
    }];

    [likesView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.top.bottom.equalTo(self.statsView);
        make.width.equalTo(self.statsView).dividedBy(3);
    }];

    [self.fansCountLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(fansView);
        make.top.equalTo(fansView).offset(8);
    }];

    [fansTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(fansView);
        make.top.equalTo(self.fansCountLabel.mas_bottom).offset(4);
    }];

    [self.attentionCountLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(attentionView);
        make.top.equalTo(attentionView).offset(8);
    }];

    [attentionTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(attentionView);
        make.top.equalTo(self.attentionCountLabel.mas_bottom).offset(4);
    }];

    [self.likesCountLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(likesView);
        make.top.equalTo(likesView).offset(8);
    }];

    [likesTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(likesView);
        make.top.equalTo(self.likesCountLabel.mas_bottom).offset(4);
    }];

    [editButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.statsView.mas_bottom).offset(16);
        make.centerX.equalTo(self.headerView);
        make.width.equalTo(@120);
        make.height.equalTo(@36);
    }];

    // Login required constraints
    [self.loginRequiredView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];

    [tipLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.loginRequiredView);
    }];

    [self.loginButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(tipLabel.mas_bottom).offset(20);
        make.centerX.equalTo(self.loginRequiredView);
        make.width.equalTo(@120);
        make.height.equalTo(@44);
    }];
}

- (void)loginButtonTapped {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"HYNeedLoginNotification" object:nil];
}

- (void)setupConstraints {
    [self.headerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
        make.left.right.equalTo(self.view);
        make.height.equalTo(@260);
    }];

    [self.avatarView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.headerView).offset(20);
        make.centerX.equalTo(self.headerView);
        make.width.height.equalTo(@100);
    }];

    [self.nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.avatarView.mas_bottom).offset(12);
        make.centerX.equalTo(self.headerView);
    }];

    [self.bioLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.nameLabel.mas_bottom).offset(4);
        make.left.equalTo(self.headerView).offset(20);
        make.right.equalTo(self.headerView).offset(-20);
    }];

    [self.statsView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.bioLabel.mas_bottom).offset(16);
        make.left.right.equalTo(self.headerView);
        make.height.equalTo(@50);
    }];

    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.headerView.mas_bottom);
        make.left.right.bottom.equalTo(self.view);
    }];
}

- (void)loadData {
    self.menuItems = @[
        @{@"icon": @"heart.fill", @"title": @"我的收藏"},
        @{@"icon": @"clock.fill", @"title": @"历史记录"},
        @{@"icon": @"gearshape.fill", @"title": @"设置"},
        @{@"icon": @"questionmark.circle.fill", @"title": @"帮助与反馈"},
        @{@"icon": @"info.circle.fill", @"title": @"关于我们"}
    ];
    [self.tableView reloadData];

    // Load user info if logged in
    if ([[HYAPIClient shared] isLoggedIn]) {
        [[HYAPIClient shared] getUserInfoWithId:@"me" completion:^(NSDictionary *response, NSError *error) {
            if (error) {
                NSLog(@"Failed to load user info: %@", error.localizedDescription);
                return;
            }

            NSDictionary *data = response[@"data"];
            if (data) {
                self.currentUser = [[HYUser alloc] initWithDictionary:data];
                [self updateUI];
            }
        }];
    }
}

- (void)updateUI {
    if (self.currentUser) {
        self.nameLabel.text = self.currentUser.name;
        self.bioLabel.text = self.currentUser.bio;
        self.fansCountLabel.text = [NSString stringWithFormat:@"%ld", (long)self.currentUser.fansCount];
        self.attentionCountLabel.text = [NSString stringWithFormat:@"%ld", (long)self.currentUser.attentionCount];
    }
}

- (void)editProfileTapped {
    if (![[HYAPIClient shared] isLoggedIn]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"HYNeedLoginNotification" object:nil];
        return;
    }
    EditProfileViewController *vc = [[EditProfileViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.menuItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MenuCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"MenuCell"];
    }

    NSDictionary *item = self.menuItems[indexPath.row];
    cell.textLabel.text = item[@"title"];
    cell.textLabel.textColor = TextPrimary;
    cell.imageView.image = [UIImage systemImageNamed:item[@"icon"]];
    cell.imageView.tintColor = PrimaryPink;
    cell.backgroundColor = DarkCard;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (![[HYAPIClient shared] isLoggedIn]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"HYNeedLoginNotification" object:nil];
        return;
    }

    UIViewController *vc = nil;
    switch (indexPath.row) {
        case 0: // 我的收藏
            vc = [[FavoritesViewController alloc] init];
            break;
        case 1: // 历史记录
            vc = [[HistoryViewController alloc] init];
            break;
        case 2: // 设置
            vc = [[SettingsViewController alloc] init];
            break;
        case 3: // 帮助与反馈
            vc = [[FeedbackViewController alloc] init];
            break;
        case 4: // 关于我们
            vc = [[AboutViewController alloc] init];
            break;
        default:
            break;
    }

    if (vc) {
        [self.navigationController pushViewController:vc animated:YES];
    }
}

@end
