#import "WalletViewController.h"
#import "RechargeViewController.h"
#import "HYAPIClient.h"
#import "HYWalletInfo.h"
#import <Masonry/Masonry.h>
#import <MJRefresh/MJRefresh.h>

static NSString * const kWalletFlowCellId = @"WalletFlowCell";

@interface HYWalletFlowCell : UITableViewCell
- (void)configWithFlow:(HYWalletFlow *)flow;
@end

@implementation HYWalletFlowCell
- (void)configWithFlow:(HYWalletFlow *)flow {
    self.textLabel.text = [self labelForType:flow.type remark:flow.remark];
    self.textLabel.font = [UIFont systemFontOfSize:15];
    self.textLabel.textColor = [UIColor labelColor];

    NSInteger amount = flow.amount;
    NSString *sign = flow.direction == 1 ? @"+" : @"-";
    self.detailTextLabel.text = [NSString stringWithFormat:@"%@%ld", sign, (long)amount];
    self.detailTextLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    self.detailTextLabel.textColor = flow.direction == 1 ? [UIColor colorWithRed:34/255.0 green:197/255.0 blue:94/255.0 alpha:1] : [UIColor colorWithRed:239/255.0 green:68/255.0 blue:68/255.0 alpha:1];

    UIImage *icon = [self iconForType:flow.type direction:flow.direction];
    self.imageView.image = icon;
    self.imageView.contentMode = UIViewContentModeCenter;

    // Format date
    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    fmt.dateFormat = @"yyyy-MM-dd HH:mm";
    fmt.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    NSString *dateStr = @"";
    if (flow.createdAt.length >= 16) {
        dateStr = [flow.createdAt substringToIndex:16];
    }
    self.detailTextLabel.text = [NSString stringWithFormat:@"%@ %@", dateStr, self.detailTextLabel.text];
}

- (NSString *)labelForType:(NSString *)type remark:(NSString *)remark {
    if (remark.length > 0) return remark;
    NSDictionary *map = @{
        @"recharge": @"Coin Purchase",
        @"gift_send": @"Send Gift",
        @"gift_receive": @"Receive Gift",
        @"checkin": @"Daily Checkin",
        @"vip": @"VIP Subscription"
    };
    return map[type] ?: type;
}

- (UIImage *)iconForType:(NSString *)type direction:(NSInteger)direction {
    NSString *sysName = @"creditcard";
    if ([type isEqualToString:@"recharge"]) sysName = @"creditcard.fill";
    else if ([type isEqualToString:@"gift_send"]) sysName = @"gift";
    else if ([type isEqualToString:@"gift_receive"]) sysName = @"gift.fill";
    else if ([type isEqualToString:@"checkin"]) sysName = @"calendar";

    UIImageSymbolConfiguration *cfg = [UIImageSymbolConfiguration configurationWithPointSize:20];
    UIImage *img = [UIImage systemImageNamed:sysName withConfiguration:cfg];
    if (direction == 1) {
        return [img imageWithTintColor:[UIColor colorWithRed:34/255.0 green:197/255.0 blue:94/255.0 alpha:1] renderingMode:UIImageRenderingModeAlwaysOriginal];
    } else {
        return [img imageWithTintColor:[UIColor colorWithRed:239/255.0 green:68/255.0 blue:68/255.0 alpha:1] renderingMode:UIImageRenderingModeAlwaysOriginal];
    }
}
@end

@interface WalletViewController () <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) UIView *balanceCard;
@property (nonatomic, strong) UILabel *balanceLabel;
@property (nonatomic, strong) UILabel *rechargedLabel;
@property (nonatomic, strong) UILabel *consumedLabel;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray<HYWalletFlow *> *flows;
@property (nonatomic, strong) UIActivityIndicatorView *loadingIndicator;
@property (nonatomic, strong) UILabel *emptyLabel;
@property (nonatomic, assign) NSInteger currentPage;
@property (nonatomic, assign) BOOL hasMore;
@property (nonatomic, assign) BOOL isLoading;
@property (nonatomic, assign) NSInteger currentBalance;
@end

@implementation WalletViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Wallet";
    self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];
    self.flows = [NSMutableArray array];
    self.currentPage = 1;
    self.hasMore = YES;
    [self setupUI];
    [self loadBalance];
    [self loadFlows:YES];
}

#pragma mark - Setup

- (void)setupUI {
    // Balance card
    self.balanceCard = [[UIView alloc] init];
    self.balanceCard.backgroundColor = [UIColor colorWithRed:139/255.0 green:92/255.0 blue:246/255.0 alpha:1];
    self.balanceCard.layer.cornerRadius = 16;
    [self.view addSubview:self.balanceCard];

    self.balanceLabel = [[UILabel alloc] init];
    self.balanceLabel.text = @"0";
    self.balanceLabel.font = [UIFont systemFontOfSize:36 weight:UIFontWeightBold];
    self.balanceLabel.textColor = [UIColor whiteColor];
    self.balanceLabel.textAlignment = NSTextAlignmentCenter;
    [self.balanceCard addSubview:self.balanceLabel];

    UILabel *coinLabel = [[UILabel alloc] init];
    coinLabel.text = @"Coins";
    coinLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    coinLabel.textColor = [UIColor colorWithWhite:1 alpha:0.8];
    coinLabel.textAlignment = NSTextAlignmentCenter;
    [self.balanceCard addSubview:coinLabel];

    // Stats row
    UIView *statsRow = [[UIView alloc] init];
    statsRow.backgroundColor = [UIColor colorWithWhite:1 alpha:0.15];
    statsRow.layer.cornerRadius = 12;
    [self.balanceCard addSubview:statsRow];

    self.rechargedLabel = [[UILabel alloc] init];
    self.rechargedLabel.text = @"Recharged: 0";
    self.rechargedLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    self.rechargedLabel.textColor = [UIColor whiteColor];
    self.rechargedLabel.textAlignment = NSTextAlignmentCenter;
    [statsRow addSubview:self.rechargedLabel];

    UIView *divider = [[UIView alloc] init];
    divider.backgroundColor = [UIColor colorWithWhite:1 alpha:0.3];
    [statsRow addSubview:divider];

    self.consumedLabel = [[UILabel alloc] init];
    self.consumedLabel.text = @"Spent: 0";
    self.consumedLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    self.consumedLabel.textColor = [UIColor whiteColor];
    self.consumedLabel.textAlignment = NSTextAlignmentCenter;
    [statsRow addSubview:self.consumedLabel];

    // Recharge button
    UIButton *rechargeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [rechargeBtn setTitle:@"Recharge" forState:UIControlStateNormal];
    [rechargeBtn setTitleColor:[UIColor colorWithRed:139/255.0 green:92/255.0 blue:246/255.0 alpha:1] forState:UIControlStateNormal];
    rechargeBtn.backgroundColor = [UIColor whiteColor];
    rechargeBtn.layer.cornerRadius = 22;
    rechargeBtn.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    [rechargeBtn addTarget:self action:@selector(rechargeTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.balanceCard addSubview:rechargeBtn];

    // Table view
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = @"Transaction History";
    titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    titleLabel.textColor = [UIColor labelColor];
    [self.view addSubview:titleLabel];

    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.rowHeight = 60;
    self.tableView.backgroundColor = [UIColor systemGroupedBackgroundColor];
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 60, 0, 0);
    [self.tableView registerClass:[HYWalletFlowCell class] forCellReuseIdentifier:kWalletFlowCellId];
    [self.view addSubview:self.tableView];

    self.tableView.mj_header = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(pullToRefresh)];
    self.tableView.mj_footer = [MJRefreshAutoNormalFooter footerWithRefreshingTarget:self refreshingAction:@selector(loadMoreData)];

    self.loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    self.loadingIndicator.color = [UIColor systemPurpleColor];
    self.loadingIndicator.hidesWhenStopped = YES;
    [self.view addSubview:self.loadingIndicator];

    self.emptyLabel = [[UILabel alloc] init];
    self.emptyLabel.text = @"No transactions yet";
    self.emptyLabel.font = [UIFont systemFontOfSize:15];
    self.emptyLabel.textColor = [UIColor secondaryLabelColor];
    self.emptyLabel.textAlignment = NSTextAlignmentCenter;
    self.emptyLabel.hidden = YES;
    [self.view addSubview:self.emptyLabel];

    // Layout
    self.balanceCard.translatesAutoresizingMaskIntoConstraints = NO;
    self.balanceLabel.translatesAutoresizingMaskIntoConstraints = NO;
    coinLabel.translatesAutoresizingMaskIntoConstraints = NO;
    statsRow.translatesAutoresizingMaskIntoConstraints = NO;
    self.rechargedLabel.translatesAutoresizingMaskIntoConstraints = NO;
    divider.translatesAutoresizingMaskIntoConstraints = NO;
    self.consumedLabel.translatesAutoresizingMaskIntoConstraints = NO;
    rechargeBtn.translatesAutoresizingMaskIntoConstraints = NO;
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.loadingIndicator.translatesAutoresizingMaskIntoConstraints = NO;
    self.emptyLabel.translatesAutoresizingMaskIntoConstraints = NO;

    [NSLayoutConstraint activateConstraints:@[
        [self.balanceCard.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:16],
        [self.balanceCard.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        [self.balanceCard.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],
        [self.balanceCard.heightAnchor constraintEqualToConstant:200],

        [self.balanceLabel.centerXAnchor constraintEqualToAnchor:self.balanceCard.centerXAnchor],
        [self.balanceLabel.topAnchor constraintEqualToAnchor:self.balanceCard.topAnchor constant:24],

        [coinLabel.centerXAnchor constraintEqualToAnchor:self.balanceCard.centerXAnchor],
        [coinLabel.topAnchor constraintEqualToAnchor:self.balanceLabel.bottomAnchor constant:4],

        [statsRow.leadingAnchor constraintEqualToAnchor:self.balanceCard.leadingAnchor constant:16],
        [statsRow.trailingAnchor constraintEqualToAnchor:self.balanceCard.trailingAnchor constant:-16],
        [statsRow.topAnchor constraintEqualToAnchor:coinLabel.bottomAnchor constant:16],
        [statsRow.heightAnchor constraintEqualToConstant:36],

        [self.rechargedLabel.leadingAnchor constraintEqualToAnchor:statsRow.leadingAnchor constant:16],
        [self.rechargedLabel.centerYAnchor constraintEqualToAnchor:statsRow.centerYAnchor],

        [divider.centerXAnchor constraintEqualToAnchor:statsRow.centerXAnchor],
        [divider.centerYAnchor constraintEqualToAnchor:statsRow.centerYAnchor],
        [divider.widthAnchor constraintEqualToConstant:1],
        [divider.heightAnchor constraintEqualToConstant:20],

        [self.consumedLabel.trailingAnchor constraintEqualToAnchor:statsRow.trailingAnchor constant:-16],
        [self.consumedLabel.centerYAnchor constraintEqualToAnchor:statsRow.centerYAnchor],

        [rechargeBtn.centerXAnchor constraintEqualToAnchor:self.balanceCard.centerXAnchor],
        [rechargeBtn.bottomAnchor constraintEqualToAnchor:self.balanceCard.bottomAnchor constant:-16],
        [rechargeBtn.widthAnchor constraintEqualToConstant:120],
        [rechargeBtn.heightAnchor constraintEqualToConstant:44],

        [titleLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        [titleLabel.topAnchor constraintEqualToAnchor:self.balanceCard.bottomAnchor constant:24],

        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.tableView.topAnchor constraintEqualToAnchor:titleLabel.bottomAnchor constant:8],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

        [self.loadingIndicator.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.loadingIndicator.centerYAnchor constraintEqualToAnchor:self.tableView.centerYAnchor],

        [self.emptyLabel.centerXAnchor constraintEqualToAnchor:self.tableView.centerXAnchor],
        [self.emptyLabel.topAnchor constraintEqualToAnchor:self.tableView.topAnchor constant:40],
    ]];
}

#pragma mark - Data

- (void)loadBalance {
    [[HYAPIClient shared] getWalletBalanceWithCompletion:^(NSDictionary *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!error && response) {
                NSDictionary *data = response[@"data"];
                if ([data isKindOfClass:[NSDictionary class]]) {
                    HYWalletInfo *info = [[HYWalletInfo alloc] initWithDictionary:data];
                    self.currentBalance = info.balance;
                    self.balanceLabel.text = [NSString stringWithFormat:@"%ld", (long)info.balance];
                    self.rechargedLabel.text = [NSString stringWithFormat:@"Recharged: %ld", (long)info.totalRecharged];
                    self.consumedLabel.text = [NSString stringWithFormat:@"Spent: %ld", (long)info.totalConsumed];
                }
            }
        });
    }];
}

- (void)loadFlows:(BOOL)refresh {
    if (self.isLoading) return;
    self.isLoading = YES;

    if (refresh) {
        self.currentPage = 1;
        self.hasMore = YES;
    }

    if (self.flows.count == 0) {
        [self.loadingIndicator startAnimating];
    }

    [[HYAPIClient shared] getWalletFlowsWithType:nil page:self.currentPage pageSize:20 completion:^(NSDictionary *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.isLoading = NO;
            [self.loadingIndicator stopAnimating];
            [self.tableView.mj_header endRefreshing];
            [self.tableView.mj_footer endRefreshing];

            if (!error && response) {
                NSDictionary *data = response[@"data"];
                NSArray *flowsData = data[@"flows"];
                if ([flowsData isKindOfClass:[NSArray class]]) {
                    if (refresh) {
                        [self.flows removeAllObjects];
                    }
                    for (NSDictionary *f in flowsData) {
                        [self.flows addObject:[[HYWalletFlow alloc] initWithDictionary:f]];
                    }
                    self.hasMore = self.flows.count < [data[@"total"] integerValue];
                    [self.tableView reloadData];
                }
                self.emptyLabel.hidden = self.flows.count > 0;
            }
        });
    }];
}

- (void)pullToRefresh {
    [self loadBalance];
    [self loadFlows:YES];
}

- (void)loadMoreData {
    if (!self.hasMore || self.isLoading) {
        [self.tableView.mj_footer endRefreshing];
        return;
    }
    self.currentPage++;
    [self loadFlows:NO];
}

#pragma mark - Actions

- (void)rechargeTapped {
    RechargeViewController *vc = [[RechargeViewController alloc] init];
    vc.onRechargeComplete = ^{
        [self loadBalance];
        [self loadFlows:YES];
    };
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.flows.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    HYWalletFlowCell *cell = [tableView dequeueReusableCellWithIdentifier:kWalletFlowCellId forIndexPath:indexPath];
    [cell configWithFlow:self.flows[indexPath.row]];
    return cell;
}

@end
