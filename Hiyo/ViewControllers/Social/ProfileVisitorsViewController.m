#import "ProfileVisitorsViewController.h"
#import "HYAPIClient.h"
#import "HYWhoLikedMe.h"
#import "VipViewController.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/SDWebImage.h>
#import <MJRefresh/MJRefresh.h>

static NSString * const kVisitorCellId = @"VisitorCell";

@interface HYVisitorCell : UITableViewCell
- (void)configWithVisitor:(HYVisitorInfo *)visitor;
@end

@implementation HYVisitorCell
- (void)configWithVisitor:(HYVisitorInfo *)visitor {
    self.textLabel.text = visitor.name;
    self.textLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];

    NSString *dateStr = @"";
    if (visitor.visitedAt.length >= 16) {
        dateStr = [visitor.visitedAt substringToIndex:16];
    }
    self.detailTextLabel.text = [NSString stringWithFormat:@"Visited %@", dateStr];
    self.detailTextLabel.font = [UIFont systemFontOfSize:13];
    self.detailTextLabel.textColor = [UIColor secondaryLabelColor];

    [self.imageView sd_setImageWithURL:[NSURL URLWithString:visitor.avatar] placeholderImage:[UIImage systemImageNamed:@"person.circle.fill"]];
    self.imageView.layer.cornerRadius = 24;
    self.imageView.clipsToBounds = YES;

    if (visitor.isOnline) {
        UIView *dot = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
        dot.backgroundColor = [UIColor colorWithRed:52/255.0 green:211/255.0 blue:153/255.0 alpha:1];
        dot.layer.cornerRadius = 5;
        self.accessoryView = dot;
    } else {
        self.accessoryView = nil;
    }
}
@end

@interface ProfileVisitorsViewController () <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIView *paywallView;
@property (nonatomic, strong) NSMutableArray<HYVisitorInfo *> *visitors;
@property (nonatomic, strong) UIActivityIndicatorView *loadingIndicator;
@property (nonatomic, strong) UILabel *emptyLabel;
@property (nonatomic, assign) NSInteger currentPage;
@property (nonatomic, assign) BOOL hasMore;
@property (nonatomic, assign) BOOL isLocked;
@property (nonatomic, assign) BOOL isLoading;
@end

@implementation ProfileVisitorsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Profile Visitors";
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    self.visitors = [NSMutableArray array];
    self.currentPage = 1;
    self.hasMore = YES;
    self.isLocked = YES;
    [self setupUI];
    [self loadData:YES];
}

#pragma mark - Setup

- (void)setupUI {
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.rowHeight = 72;
    self.tableView.backgroundColor = [UIColor systemBackgroundColor];
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 88, 0, 0);
    [self.tableView registerClass:[HYVisitorCell class] forCellReuseIdentifier:kVisitorCellId];
    [self.view addSubview:self.tableView];

    self.tableView.mj_header = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(pullToRefresh)];
    self.tableView.mj_footer = [MJRefreshAutoNormalFooter footerWithRefreshingTarget:self refreshingAction:@selector(loadMoreData)];

    self.loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    self.loadingIndicator.color = [UIColor systemPurpleColor];
    self.loadingIndicator.hidesWhenStopped = YES;
    [self.view addSubview:self.loadingIndicator];

    self.emptyLabel = [[UILabel alloc] init];
    self.emptyLabel.text = @"No visitors yet";
    self.emptyLabel.font = [UIFont systemFontOfSize:15];
    self.emptyLabel.textColor = [UIColor secondaryLabelColor];
    self.emptyLabel.textAlignment = NSTextAlignmentCenter;
    self.emptyLabel.hidden = YES;
    [self.view addSubview:self.emptyLabel];

    self.paywallView = [[UIView alloc] init];
    self.paywallView.backgroundColor = [UIColor systemBackgroundColor];
    self.paywallView.hidden = YES;
    [self.view addSubview:self.paywallView];

    UIImageView *lockIcon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"lock.fill"]];
    lockIcon.tintColor = [UIColor colorWithRed:139/255.0 green:92/255.0 blue:246/255.0 alpha:1];
    lockIcon.contentMode = UIViewContentModeScaleAspectFit;
    [self.paywallView addSubview:lockIcon];

    UILabel *tipLabel = [[UILabel alloc] init];
    tipLabel.text = @"Upgrade to VIP to see who visited your profile";
    tipLabel.font = [UIFont systemFontOfSize:16];
    tipLabel.textColor = [UIColor secondaryLabelColor];
    tipLabel.textAlignment = NSTextAlignmentCenter;
    tipLabel.numberOfLines = 0;
    [self.paywallView addSubview:tipLabel];

    UIButton *upgradeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [upgradeBtn setTitle:@"Upgrade to VIP" forState:UIControlStateNormal];
    [upgradeBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    upgradeBtn.backgroundColor = [UIColor colorWithRed:139/255.0 green:92/255.0 blue:246/255.0 alpha:1];
    upgradeBtn.layer.cornerRadius = 22;
    upgradeBtn.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    [upgradeBtn addTarget:self action:@selector(upgradeTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.paywallView addSubview:upgradeBtn];

    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.loadingIndicator.translatesAutoresizingMaskIntoConstraints = NO;
    self.emptyLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.paywallView.translatesAutoresizingMaskIntoConstraints = NO;
    lockIcon.translatesAutoresizingMaskIntoConstraints = NO;
    tipLabel.translatesAutoresizingMaskIntoConstraints = NO;
    upgradeBtn.translatesAutoresizingMaskIntoConstraints = NO;

    [NSLayoutConstraint activateConstraints:@[
        [self.tableView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

        [self.loadingIndicator.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.loadingIndicator.centerYAnchor constraintEqualToAnchor:self.tableView.centerYAnchor],

        [self.emptyLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.emptyLabel.topAnchor constraintEqualToAnchor:self.tableView.topAnchor constant:40],

        [self.paywallView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [self.paywallView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.paywallView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.paywallView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

        [lockIcon.centerXAnchor constraintEqualToAnchor:self.paywallView.centerXAnchor],
        [lockIcon.centerYAnchor constraintEqualToAnchor:self.paywallView.centerYAnchor constant:-60],
        [lockIcon.widthAnchor constraintEqualToConstant:60],
        [lockIcon.heightAnchor constraintEqualToConstant:60],

        [tipLabel.topAnchor constraintEqualToAnchor:lockIcon.bottomAnchor constant:16],
        [tipLabel.leadingAnchor constraintEqualToAnchor:self.paywallView.leadingAnchor constant:32],
        [tipLabel.trailingAnchor constraintEqualToAnchor:self.paywallView.trailingAnchor constant:-32],

        [upgradeBtn.centerXAnchor constraintEqualToAnchor:self.paywallView.centerXAnchor],
        [upgradeBtn.topAnchor constraintEqualToAnchor:tipLabel.bottomAnchor constant:24],
        [upgradeBtn.widthAnchor constraintEqualToConstant:180],
        [upgradeBtn.heightAnchor constraintEqualToConstant:44],
    ]];
}

#pragma mark - Data

- (void)loadData:(BOOL)refresh {
    if (self.isLoading) return;
    self.isLoading = YES;

    if (refresh) {
        self.currentPage = 1;
        self.hasMore = YES;
    }

    if (self.visitors.count == 0) {
        [self.loadingIndicator startAnimating];
    }

    [[HYAPIClient shared] getProfileVisitorsWithPage:self.currentPage pageSize:20 completion:^(NSDictionary *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.isLoading = NO;
            [self.loadingIndicator stopAnimating];
            [self.tableView.mj_header endRefreshing];
            [self.tableView.mj_footer endRefreshing];

            if (!error && response) {
                NSDictionary *data = response[@"data"];
                if ([data isKindOfClass:[NSDictionary class]]) {
                    self.isLocked = [data[@"locked"] boolValue];

                    if (self.isLocked) {
                        self.paywallView.hidden = NO;
                        self.tableView.hidden = YES;
                    } else {
                        self.paywallView.hidden = YES;
                        self.tableView.hidden = NO;

                        NSArray *visitorsData = data[@"visitors"];
                        if ([visitorsData isKindOfClass:[NSArray class]]) {
                            if (refresh) [self.visitors removeAllObjects];
                            for (NSDictionary *v in visitorsData) {
                                [self.visitors addObject:[[HYVisitorInfo alloc] initWithDictionary:v]];
                            }
                            self.hasMore = self.visitors.count < [data[@"total"] integerValue];
                            [self.tableView reloadData];
                        }
                        self.emptyLabel.hidden = self.visitors.count > 0;
                    }
                }
            }
        });
    }];
}

- (void)pullToRefresh {
    [self loadData:YES];
}

- (void)loadMoreData {
    if (!self.hasMore || self.isLoading) {
        [self.tableView.mj_footer endRefreshing];
        return;
    }
    self.currentPage++;
    [self loadData:NO];
}

- (void)upgradeTapped {
    VipViewController *vc = [[VipViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.visitors.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    HYVisitorCell *cell = [tableView dequeueReusableCellWithIdentifier:kVisitorCellId forIndexPath:indexPath];
    [cell configWithVisitor:self.visitors[indexPath.row]];
    return cell;
}

@end
