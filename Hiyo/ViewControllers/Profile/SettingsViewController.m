#import "SettingsViewController.h"
#import "HYAPIClient.h"
#import "HYWebSocketManager.h"
#import "FeedbackViewController.h"
#import "AccountSettingsViewController.h"
#import "LanguageSettingsViewController.h"
#import "NotificationSettingsViewController.h"
#import "PrivacySettingsViewController.h"
#import "AboutViewController.h"
#import "HelpCenterViewController.h"
#import "UserAgreementViewController.h"
#import "HYColors.h"
#import "WalletViewController.h"
#import "VipViewController.h"
#import "CheckinViewController.h"
#import "WhoLikedMeViewController.h"
#import "ProfileVisitorsViewController.h"
#import <Masonry/Masonry.h>

@interface SettingsViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray<NSArray<NSDictionary *> *> *sections;

@end

@implementation SettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"设置";
    self.view.backgroundColor = DarkBackground;
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    [self setupData];
    [self setupUI];
}

- (void)setupData {
    self.sections = @[
        // Monetization
        @[
            @{@"icon": @"creditcard.fill", @"title": @"钱包 / Wallet", @"color": @"PrimaryPurple", @"class": @"WalletViewController"},
            @{@"icon": @"crown.fill", @"title": @"VIP会员 / VIP", @"color": @"PrimaryPink", @"class": @"VipViewController"},
            @{@"icon": @"calendar.badge.checkmark", @"title": @"每日签到 / Check-in", @"color": @"PrimaryViolet", @"class": @"CheckinViewController"},
        ],
        // Social
        @[
            @{@"icon": @"heart.fill", @"title": @"谁喜欢我 / Who Liked Me", @"color": @"PrimaryPink", @"class": @"WhoLikedMeViewController"},
            @{@"icon": @"eye.fill", @"title": @"我的访客 / Profile Visitors", @"color": @"ElectricPurple", @"class": @"ProfileVisitorsViewController"},
        ],
        // Account
        @[
            @{@"icon": @"lock.fill", @"title": @"修改密码", @"color": @"PrimaryPurple", @"class": @"AccountSettingsViewController"},
            @{@"icon": @"envelope.fill", @"title": @"绑定邮箱", @"color": @"PrimaryViolet", @"class": @"AccountSettingsViewController"},
            @{@"icon": @"phone.fill", @"title": @"绑定手机", @"color": @"ElectricPurple", @"class": @"AccountSettingsViewController"},
        ],
        // App
        @[
            @{@"icon": @"globe", @"title": @"语言", @"color": @"PrimaryPink", @"class": @"LanguageSettingsViewController"},
            @{@"icon": @"bell.fill", @"title": @"消息通知", @"color": @"PrimaryPurple", @"class": @"NotificationSettingsViewController"},
            @{@"icon": @"eye.slash.fill", @"title": @"隐私设置", @"color": @"DeepPurple", @"class": @"PrivacySettingsViewController"},
        ],
        // Support
        @[
            @{@"icon": @"bubble.left.fill", @"title": @"帮助与反馈", @"color": @"PrimaryViolet", @"class": @"FeedbackViewController"},
            @{@"icon": @"questionmark.circle.fill", @"title": @"帮助中心", @"color": @"PrimaryPurple", @"class": @"HelpCenterViewController"},
            @{@"icon": @"info.circle.fill", @"title": @"关于我们", @"color": @"PrimaryPink", @"class": @"AboutViewController"},
        ],
    ];
}

- (void)setupUI {
    // Header gradient bar
    UIView *gradientBar = [[UIView alloc] init];
    [self.view addSubview:gradientBar];

    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.colors = @[
        (id)[PrimaryPurple colorWithAlphaComponent:0.2].CGColor,
        (id)[PrimaryViolet colorWithAlphaComponent:0.2].CGColor
    ];
    gradient.startPoint = CGPointMake(0, 0.5);
    gradient.endPoint = CGPointMake(1, 0.5);
    [gradientBar.layer addSublayer:gradient];

    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleInsetGrouped];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = DarkBackground;
    self.tableView.separatorColor = DarkLighter;
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 72, 0, 0);
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
    [self.view addSubview:self.tableView];

    [gradientBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.trailing.equalTo(self.view);
        make.height.equalTo(@120);
    }];

    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];

    dispatch_async(dispatch_get_main_queue(), ^{
        gradient.frame = gradientBar.bounds;
    });
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.sections[section].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];

    NSDictionary *item = self.sections[indexPath.section][indexPath.row];

    cell.backgroundColor = DarkCard;
    cell.textLabel.text = item[@"title"];
    cell.textLabel.textColor = TextPrimary;
    cell.textLabel.font = [UIFont systemFontOfSize:16];
    cell.imageView.tintColor = PrimaryPink;
    cell.imageView.image = [UIImage systemImageNamed:item[@"icon"]];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;

    // Set icon color based on color key
    NSString *colorKey = item[@"color"];
    if ([colorKey isEqualToString:@"PrimaryPurple"]) cell.imageView.tintColor = PrimaryPurple;
    else if ([colorKey isEqualToString:@"PrimaryViolet"]) cell.imageView.tintColor = PrimaryViolet;
    else if ([colorKey isEqualToString:@"ElectricPurple"]) cell.imageView.tintColor = ElectricPurple;
    else if ([colorKey isEqualToString:@"DeepPurple"]) cell.imageView.tintColor = DeepPurple;
    else cell.imageView.tintColor = PrimaryPink;

    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    NSDictionary *item = self.sections[indexPath.section][indexPath.row];
    NSString *className = item[@"class"];
    Class vcClass = NSClassFromString(className);

    UIViewController *vc = nil;
    if ([className isEqualToString:@"AccountSettingsViewController"]) {
        vc = [[AccountSettingsViewController alloc] initWithMode:indexPath.row];
    } else if ([className isEqualToString:@"FeedbackViewController"]) {
        vc = [[FeedbackViewController alloc] init];
    } else if ([className isEqualToString:@"LanguageSettingsViewController"]) {
        vc = [[LanguageSettingsViewController alloc] init];
    } else if ([className isEqualToString:@"NotificationSettingsViewController"]) {
        vc = [[NotificationSettingsViewController alloc] init];
    } else if ([className isEqualToString:@"PrivacySettingsViewController"]) {
        vc = [[PrivacySettingsViewController alloc] init];
    } else if ([className isEqualToString:@"AboutViewController"]) {
        vc = [[AboutViewController alloc] init];
    } else if ([className isEqualToString:@"HelpCenterViewController"]) {
        vc = [[HelpCenterViewController alloc] init];
    } else if ([className isEqualToString:@"UserAgreementViewController"]) {
        vc = [[UserAgreementViewController alloc] init];
    } else if ([className isEqualToString:@"WalletViewController"]) {
        vc = [[WalletViewController alloc] init];
    } else if ([className isEqualToString:@"VipViewController"]) {
        vc = [[VipViewController alloc] init];
    } else if ([className isEqualToString:@"CheckinViewController"]) {
        vc = [[CheckinViewController alloc] init];
    } else if ([className isEqualToString:@"WhoLikedMeViewController"]) {
        vc = [[WhoLikedMeViewController alloc] init];
    } else if ([className isEqualToString:@"ProfileVisitorsViewController"]) {
        vc = [[ProfileVisitorsViewController alloc] init];
    }

    if (vc) {
        [self.navigationController pushViewController:vc animated:YES];
    }
}

// Add logout button as table footer
- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if (section == 4) {
        UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, 140)];

        UIButton *logoutButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [logoutButton setTitle:@"退出登录" forState:UIControlStateNormal];
        [logoutButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        logoutButton.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
        logoutButton.backgroundColor = ErrorRed;
        logoutButton.layer.cornerRadius = 28;
        [logoutButton setImage:[UIImage systemImageNamed:@"arrow.right.square"] forState:UIControlStateNormal];
        logoutButton.tintColor = [UIColor whiteColor];
        logoutButton.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 8);
        [logoutButton addTarget:self action:@selector(logoutTapped) forControlEvents:UIControlEventTouchUpInside];
        [footer addSubview:logoutButton];

        UILabel *versionLabel = [[UILabel alloc] init];
        versionLabel.text = @"Hiyo v1.0.0";
        versionLabel.font = [UIFont systemFontOfSize:12];
        versionLabel.textColor = TextMuted;
        versionLabel.textAlignment = NSTextAlignmentCenter;
        [footer addSubview:versionLabel];

        [logoutButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(footer).offset(20);
            make.left.equalTo(footer).offset(40);
            make.right.equalTo(footer).offset(-40);
            make.height.equalTo(@56);
        }];

        [versionLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(logoutButton.mas_bottom).offset(16);
            make.centerX.equalTo(footer);
        }];

        return footer;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == self.sections.count - 1) return 140;
    return 20;
}

- (void)logoutTapped {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"确定退出登录？" message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"退出登录" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [[HYAPIClient shared] clearToken];
        [[HYWebSocketManager shared] disconnect];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"HYNeedLoginNotification" object:nil];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
