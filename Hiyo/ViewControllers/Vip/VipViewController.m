#import "VipViewController.h"
#import "HYAPIClient.h"
#import "HYVip.h"
#import <StoreKit/StoreKit.h>
#import <Masonry/Masonry.h>

@interface HYSubscriptionPlanCell : UITableViewCell
- (void)configWithPlan:(HYSubscriptionPlan *)plan isSelected:(BOOL)selected;
@end

@implementation HYSubscriptionPlanCell
- (void)configWithPlan:(HYSubscriptionPlan *)plan isSelected:(BOOL)selected {
    self.textLabel.text = plan.name;
    self.textLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];

    NSString *desc = [NSString stringWithFormat:@"%@ • %@", plan.priceDisplay, plan.planDescription];
    self.detailTextLabel.text = desc;
    self.detailTextLabel.font = [UIFont systemFontOfSize:13];
    self.detailTextLabel.textColor = [UIColor secondaryLabelColor];

    self.accessoryType = selected ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    self.tintColor = [UIColor colorWithRed:139/255.0 green:92/255.0 blue:246/255.0 alpha:1];
}
@end

@interface VipViewController () <UITableViewDelegate, UITableViewDataSource, SKProductsRequestDelegate, SKPaymentTransactionObserver>
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UILabel *daysLeftLabel;
@property (nonatomic, strong) UIButton *subscribeBtn;
@property (nonatomic, strong) UITableView *plansTable;
@property (nonatomic, strong) UIActivityIndicatorView *loadingIndicator;
@property (nonatomic, strong) NSArray<HYSubscriptionPlan *> *plans;
@property (nonatomic, strong) HYSubscriptionPlan *selectedPlan;
@property (nonatomic, strong) HYVipStatus *vipStatus;
@property (nonatomic, assign) BOOL isSubscribing;
@end

@implementation VipViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"VIP Membership";
    self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];
    self.plans = @[];
    [self setupUI];
    [self loadData];
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
}

- (void)dealloc {
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}

#pragma mark - Setup

- (void)setupUI {
    // VIP status header
    UIView *headerCard = [[UIView alloc] init];
    headerCard.backgroundColor = [UIColor colorWithRed:139/255.0 green:92/255.0 blue:246/255.0 alpha:1];
    headerCard.layer.cornerRadius = 16;
    [self.view addSubview:headerCard];

    UIImageView *vipIcon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"crown.fill"]];
    vipIcon.tintColor = [UIColor whiteColor];
    vipIcon.contentMode = UIViewContentModeScaleAspectFit;
    [headerCard addSubview:vipIcon];

    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.text = @"Not a VIP member";
    self.statusLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightBold];
    self.statusLabel.textColor = [UIColor whiteColor];
    [headerCard addSubview:self.statusLabel];

    self.daysLeftLabel = [[UILabel alloc] init];
    self.daysLeftLabel.text = @"Unlock all premium features";
    self.daysLeftLabel.font = [UIFont systemFontOfSize:14];
    self.daysLeftLabel.textColor = [UIColor colorWithWhite:1 alpha:0.8];
    [headerCard addSubview:self.daysLeftLabel];

    // Plans table
    UILabel *plansTitle = [[UILabel alloc] init];
    plansTitle.text = @"Choose a Plan";
    plansTitle.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    plansTitle.textColor = [UIColor labelColor];
    [self.view addSubview:plansTitle];

    self.plansTable = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.plansTable.delegate = self;
    self.plansTable.dataSource = self;
    self.plansTable.rowHeight = 70;
    self.plansTable.backgroundColor = [UIColor systemGroupedBackgroundColor];
    self.plansTable.layer.cornerRadius = 12;
    self.plansTable.clipsToBounds = YES;
    [self.plansTable registerClass:[HYSubscriptionPlanCell class] forCellReuseIdentifier:@"PlanCell"];
    [self.view addSubview:self.plansTable];

    self.subscribeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.subscribeBtn setTitle:@"Subscribe" forState:UIControlStateNormal];
    [self.subscribeBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.subscribeBtn.backgroundColor = [UIColor colorWithRed:139/255.0 green:92/255.0 blue:246/255.0 alpha:1];
    self.subscribeBtn.layer.cornerRadius = 25;
    self.subscribeBtn.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    self.subscribeBtn.enabled = NO;
    self.subscribeBtn.alpha = 0.5;
    [self.subscribeBtn addTarget:self action:@selector(subscribeTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.subscribeBtn];

    self.loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    self.loadingIndicator.color = [UIColor systemPurpleColor];
    self.loadingIndicator.hidesWhenStopped = YES;
    [self.view addSubview:self.loadingIndicator];

    // Layout
    headerCard.translatesAutoresizingMaskIntoConstraints = NO;
    vipIcon.translatesAutoresizingMaskIntoConstraints = NO;
    self.statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.daysLeftLabel.translatesAutoresizingMaskIntoConstraints = NO;
    plansTitle.translatesAutoresizingMaskIntoConstraints = NO;
    self.plansTable.translatesAutoresizingMaskIntoConstraints = NO;
    self.subscribeBtn.translatesAutoresizingMaskIntoConstraints = NO;
    self.loadingIndicator.translatesAutoresizingMaskIntoConstraints = NO;

    [NSLayoutConstraint activateConstraints:@[
        [headerCard.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:16],
        [headerCard.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        [headerCard.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],
        [headerCard.heightAnchor constraintEqualToConstant:100],

        [vipIcon.leadingAnchor constraintEqualToAnchor:headerCard.leadingAnchor constant:20],
        [vipIcon.centerYAnchor constraintEqualToAnchor:headerCard.centerYAnchor],
        [vipIcon.widthAnchor constraintEqualToConstant:40],
        [vipIcon.heightAnchor constraintEqualToConstant:40],

        [self.statusLabel.leadingAnchor constraintEqualToAnchor:vipIcon.trailingAnchor constant:12],
        [self.statusLabel.topAnchor constraintEqualToAnchor:headerCard.topAnchor constant:28],

        [self.daysLeftLabel.leadingAnchor constraintEqualToAnchor:self.statusLabel.leadingAnchor],
        [self.daysLeftLabel.topAnchor constraintEqualToAnchor:self.statusLabel.bottomAnchor constant:4],

        [plansTitle.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        [plansTitle.topAnchor constraintEqualToAnchor:headerCard.bottomAnchor constant:24],

        [self.plansTable.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        [self.plansTable.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],
        [self.plansTable.topAnchor constraintEqualToAnchor:plansTitle.bottomAnchor constant:8],
        [self.plansTable.heightAnchor constraintEqualToConstant:210],

        [self.subscribeBtn.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        [self.subscribeBtn.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],
        [self.subscribeBtn.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-16],
        [self.subscribeBtn.heightAnchor constraintEqualToConstant:50],

        [self.loadingIndicator.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.loadingIndicator.centerYAnchor constraintEqualToAnchor:self.plansTable.centerYAnchor],
    ]];
}

- (void)loadData {
    [self.loadingIndicator startAnimating];

    dispatch_group_t group = dispatch_group_create();
    __block NSDictionary *plansResponse = nil;
    __block NSDictionary *statusResponse = nil;

    dispatch_group_enter(group);
    [[HYAPIClient shared] getSubscriptionPlansWithCompletion:^(NSDictionary *response, NSError *error) {
        plansResponse = response;
        dispatch_group_leave(group);
    }];

    dispatch_group_enter(group);
    [[HYAPIClient shared] getVipStatusWithCompletion:^(NSDictionary *response, NSError *error) {
        statusResponse = response;
        dispatch_group_leave(group);
    }];

    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        [self.loadingIndicator stopAnimating];

        if (plansResponse && !plansResponse[@"error"]) {
            NSArray *data = plansResponse[@"data"][@"plans"];
            if ([data isKindOfClass:[NSArray class]]) {
                NSMutableArray *arr = [NSMutableArray array];
                for (NSDictionary *p in data) {
                    [arr addObject:[[HYSubscriptionPlan alloc] initWithDictionary:p]];
                }
                self.plans = arr;
                [self.plansTable reloadData];
            }
        }

        if (statusResponse && !statusResponse[@"error"]) {
            NSDictionary *data = statusResponse[@"data"];
            if ([data isKindOfClass:[NSDictionary class]]) {
                self.vipStatus = [[HYVipStatus alloc] initWithDictionary:data];
                [self updateStatusUI];
            }
        }
    });
}

- (void)updateStatusUI {
    if (self.vipStatus.isVip) {
        self.statusLabel.text = [NSString stringWithFormat:@"%@ VIP", self.vipStatus.planName ?: @"Premium"];
        self.daysLeftLabel.text = [NSString stringWithFormat:@"%ld days remaining", (long)self.vipStatus.daysLeft];
    } else {
        self.statusLabel.text = @"Not a VIP member";
        self.daysLeftLabel.text = @"Unlock all premium features";
    }
}

#pragma mark - Actions

- (void)subscribeTapped {
    if (!self.selectedPlan || self.isSubscribing) return;
    if (![SKPaymentQueue canMakePayments]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Unavailable" message:@"In-app purchases are not available." preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }

    self.isSubscribing = YES;
    self.subscribeBtn.enabled = NO;
    [self.subscribeBtn setTitle:@"Processing..." forState:UIControlStateNormal];
    [self.loadingIndicator startAnimating];

    [[HYAPIClient shared] verifySubscriptionWithPlanId:self.selectedPlan.planId purchaseToken:@"temp_token" completion:^(NSDictionary *response, NSError *error) {
        // Server-side flow: verify after StoreKit confirmation
        SKProductsRequest *req = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithObject:self.selectedPlan.platformProductId]];
        req.delegate = self;
        [req start];
    }];
}

- (void)finishSubscribeWithError:(NSError *)error {
    self.isSubscribing = NO;
    [self.loadingIndicator stopAnimating];
    self.subscribeBtn.enabled = YES;
    self.subscribeBtn.alpha = 0.5;
    [self.subscribeBtn setTitle:@"Subscribe" forState:UIControlStateNormal];
    if (error) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

#pragma mark - SKProductsRequestDelegate

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    SKProduct *product = response.products.firstObject;
    if (!product) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self finishSubscribeWithError:[NSError errorWithDomain:@"HYError" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Product not found"}]];
        });
        return;
    }
    SKPayment *payment = [SKPayment paymentWithProduct:product];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
}

#pragma mark - SKPaymentTransactionObserver

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions {
    for (SKPaymentTransaction *tx in transactions) {
        if (tx.transactionState == SKPaymentTransactionStatePurchased) {
            [[HYAPIClient shared] verifySubscriptionWithPlanId:self.selectedPlan.planId purchaseToken:@"" completion:^(NSDictionary *response, NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[SKPaymentQueue defaultQueue] finishTransaction:tx];
                    if (!error) {
                        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Success" message:@"VIP subscription activated!" preferredStyle:UIAlertControllerStyleAlert];
                        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                            [self loadData];
                        }]];
                        [self presentViewController:alert animated:YES completion:nil];
                    }
                    [self finishSubscribeWithError:error];
                });
            }];
        } else if (tx.transactionState == SKPaymentTransactionStateFailed) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[SKPaymentQueue defaultQueue] finishTransaction:tx];
                [self finishSubscribeWithError:tx.error];
            });
        }
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.plans.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    HYSubscriptionPlanCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PlanCell" forIndexPath:indexPath];
    HYSubscriptionPlan *plan = self.plans[indexPath.row];
    [cell configWithPlan:plan isSelected:(self.selectedPlan == plan)];
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    self.selectedPlan = self.plans[indexPath.row];
    self.subscribeBtn.enabled = YES;
    self.subscribeBtn.alpha = 1.0;
    [tableView reloadData];
}

@end
