#import "AboutViewController.h"
#import "HYColors.h"
#import "HYRouter.h"
#import "PrivacyPolicyViewController.h"

@interface AboutViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;

@end

@implementation AboutViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"关于我们";
    [self setupNavigationBarDark];
    self.view.backgroundColor = DarkBackground;
    [self setupUI];
}

- (void)setupUI {
    // Header
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 200)];
    headerView.backgroundColor = [UIColor clearColor];

    UIImageView *logoView = [[UIImageView alloc] init];
    logoView.image = [UIImage systemImageNamed:@"bubble.left.and.bubble.right.fill"];
    logoView.tintColor = PrimaryPink;
    logoView.contentMode = UIViewContentModeScaleAspectFit;
    [headerView addSubview:logoView];

    UILabel *nameLabel = [[UILabel alloc] init];
    nameLabel.text = @"Hiyo";
    nameLabel.font = [UIFont systemFontOfSize:28 weight:UIFontWeightBold];
    nameLabel.textColor = TextPrimary;
    nameLabel.textAlignment = NSTextAlignmentCenter;
    [headerView addSubview:nameLabel];

    UILabel *versionLabel = [[UILabel alloc] init];
    versionLabel.text = @"Version 1.0.0";
    versionLabel.font = [UIFont systemFontOfSize:14];
    versionLabel.textColor = TextMuted;
    versionLabel.textAlignment = NSTextAlignmentCenter;
    [headerView addSubview:versionLabel];

    logoView.translatesAutoresizingMaskIntoConstraints = NO;
    nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    versionLabel.translatesAutoresizingMaskIntoConstraints = NO;

    [NSLayoutConstraint activateConstraints:@[
        [logoView.centerXAnchor constraintEqualToAnchor:headerView.centerXAnchor],
        [logoView.topAnchor constraintEqualToAnchor:headerView.topAnchor constant:40],
        [logoView.widthAnchor constraintEqualToConstant:60],
        [logoView.heightAnchor constraintEqualToConstant:60],

        [nameLabel.topAnchor constraintEqualToAnchor:logoView.bottomAnchor constant:16],
        [nameLabel.centerXAnchor constraintEqualToAnchor:headerView.centerXAnchor],

        [versionLabel.topAnchor constraintEqualToAnchor:nameLabel.bottomAnchor constant:8],
        [versionLabel.centerXAnchor constraintEqualToAnchor:headerView.centerXAnchor]
    ]];

    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleInsetGrouped];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.backgroundColor = DarkBackground;
    self.tableView.separatorColor = DarkLighter;
    self.tableView.tableHeaderView = headerView;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
    [self.view addSubview:self.tableView];

    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [self.tableView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return section == 0 ? 2 : 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return section == 0 ? @"法律" : @"开发者";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    cell.backgroundColor = DarkCard;
    cell.textLabel.textColor = TextPrimary;
    cell.textLabel.font = [UIFont systemFontOfSize:16];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            cell.textLabel.text = @"隐私政策";
            cell.imageView.image = [UIImage systemImageNamed:@"lock.shield.fill"];
            cell.imageView.tintColor = PrimaryPurple;
        } else {
            cell.textLabel.text = @"用户协议";
            cell.imageView.image = [UIImage systemImageNamed:@"doc.text.fill"];
            cell.imageView.tintColor = PrimaryViolet;
        }
    } else {
        cell.textLabel.text = @"联系开发者";
        cell.imageView.image = [UIImage systemImageNamed:@"envelope.fill"];
        cell.imageView.tintColor = PrimaryPink;
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && indexPath.row == 0) {
        PrivacyPolicyViewController *vc = [[PrivacyPolicyViewController alloc] init];
        [self.navigationController pushViewController:vc animated:YES];
    } else if (indexPath.section == 0 && indexPath.row == 1) {
        [HYRouter pushUserAgreement];
    } else if (indexPath.section == 1) {
        [self showAlert:@"欢迎联系我们：hiyo@example.com"];
    }
}

@end
