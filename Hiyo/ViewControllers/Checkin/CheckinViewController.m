#import "CheckinViewController.h"
#import "HYAPIClient.h"
#import "HYVip.h"
#import <Masonry/Masonry.h>

@interface CheckinViewController ()
@property (nonatomic, strong) UIView *weekRow;
@property (nonatomic, strong) NSArray<UIView *> *dayViews;
@property (nonatomic, strong) UIButton *checkinBtn;
@property (nonatomic, strong) UILabel *rewardLabel;
@property (nonatomic, strong) HYCheckinStatus *status;
@property (nonatomic, strong) HYCheckinResult *result;
@end

@implementation CheckinViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Daily Checkin";
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    [self setupUI];
    [self loadStatus];
}

#pragma mark - Setup

- (void)setupUI {
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = @"7-Day Check-in Plan";
    titleLabel.font = [UIFont systemFontOfSize:22 weight:UIFontWeightBold];
    titleLabel.textColor = [UIColor labelColor];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:titleLabel];

    self.weekRow = [[UIView alloc] init];
    self.weekRow.backgroundColor = [UIColor systemGray6Color];
    self.weekRow.layer.cornerRadius = 16;
    [self.view addSubview:self.weekRow];

    NSMutableArray *views = [NSMutableArray array];
    NSArray *dayLabels = @[@"D1", @"D2", @"D3", @"D4", @"D5", @"D6", @"D7"];
    for (int i = 0; i < 7; i++) {
        UIView *dayView = [[UIView alloc] init];
        dayView.backgroundColor = [UIColor systemGray5Color];
        dayView.layer.cornerRadius = 20;
        [self.weekRow addSubview:dayView];
        [views addObject:dayView];

        UILabel *dayLabel = [[UILabel alloc] init];
        dayLabel.text = dayLabels[i];
        dayLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightMedium];
        dayLabel.textColor = [UIColor secondaryLabelColor];
        dayLabel.textAlignment = NSTextAlignmentCenter;
        [dayView addSubview:dayLabel];
        dayLabel.tag = 100;
    }
    self.dayViews = views;

    self.rewardLabel = [[UILabel alloc] init];
    self.rewardLabel.text = @"Check in daily to earn coins!";
    self.rewardLabel.font = [UIFont systemFontOfSize:15];
    self.rewardLabel.textColor = [UIColor secondaryLabelColor];
    self.rewardLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.rewardLabel];

    self.checkinBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.checkinBtn setTitle:@"Check In Today" forState:UIControlStateNormal];
    [self.checkinBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.checkinBtn.backgroundColor = [UIColor colorWithRed:139/255.0 green:92/255.0 blue:246/255.0 alpha:1];
    self.checkinBtn.layer.cornerRadius = 25;
    self.checkinBtn.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    [self.checkinBtn addTarget:self action:@selector(checkinTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.checkinBtn];

    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.weekRow.translatesAutoresizingMaskIntoConstraints = NO;
    self.rewardLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.checkinBtn.translatesAutoresizingMaskIntoConstraints = NO;

    [NSLayoutConstraint activateConstraints:@[
        [titleLabel.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:32],
        [titleLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],

        [self.weekRow.topAnchor constraintEqualToAnchor:titleLabel.bottomAnchor constant:32],
        [self.weekRow.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        [self.weekRow.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],
        [self.weekRow.heightAnchor constraintEqualToConstant:80],

        [self.rewardLabel.topAnchor constraintEqualToAnchor:self.weekRow.bottomAnchor constant:24],
        [self.rewardLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],

        [self.checkinBtn.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        [self.checkinBtn.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],
        [self.checkinBtn.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-32],
        [self.checkinBtn.heightAnchor constraintEqualToConstant:50],
    ]];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat w = (self.weekRow.bounds.size.width - 48) / 7;
    for (int i = 0; i < 7; i++) {
        UIView *dayView = self.dayViews[i];
        dayView.frame = CGRectMake(24 + i * (w + 0), 20, w, 40);
        UILabel *label = [dayView viewWithTag:100];
        label.frame = dayView.bounds;
    }
}

- (void)loadStatus {
    [[HYAPIClient shared] getCheckinStatusWithCompletion:^(NSDictionary *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!error && response) {
                NSDictionary *data = response[@"data"];
                if ([data isKindOfClass:[NSDictionary class]]) {
                    self.status = [[HYCheckinStatus alloc] initWithDictionary:data];
                    [self updateUI];
                }
            }
        });
    }];
}

- (void)updateUI {
    for (int i = 0; i < 7; i++) {
        UIView *dayView = self.dayViews[i];
        BOOL checked = [self.status.checkedDays containsObject:@(i + 1)];
        BOOL isToday = (i + 1) == self.status.currentDay;

        if (checked) {
            dayView.backgroundColor = [UIColor colorWithRed:139/255.0 green:92/255.0 blue:246/255.0 alpha:1];
            UILabel *label = [dayView viewWithTag:100];
            label.textColor = [UIColor whiteColor];
        } else if (isToday) {
            dayView.backgroundColor = [UIColor colorWithRed:236/255.0 green:72/255.0 blue:153/255.0 alpha:1];
            UILabel *label = [dayView viewWithTag:100];
            label.textColor = [UIColor whiteColor];
        } else {
            dayView.backgroundColor = [UIColor systemGray5Color];
            UILabel *label = [dayView viewWithTag:100];
            label.textColor = [UIColor secondaryLabelColor];
        }
    }

    if (self.status.todayChecked) {
        [self.checkinBtn setTitle:@"Checked In Today" forState:UIControlStateNormal];
        self.checkinBtn.backgroundColor = [UIColor systemGray4Color];
        self.checkinBtn.enabled = NO;
        self.rewardLabel.text = [NSString stringWithFormat:@"You earned %ld coins today!", (long)self.status.todayReward];
    } else {
        self.rewardLabel.text = [NSString stringWithFormat:@"Today's reward: %ld coins", (long)self.status.todayReward];
    }
}

- (void)checkinTapped {
    self.checkinBtn.enabled = NO;
    [self.checkinBtn setTitle:@"Checking in..." forState:UIControlStateNormal];

    [[HYAPIClient shared] performCheckinWithCompletion:^(NSDictionary *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!error && response) {
                NSDictionary *data = response[@"data"];
                if ([data isKindOfClass:[NSDictionary class]]) {
                    self.result = [[HYCheckinResult alloc] initWithDictionary:data];
                    [self showSuccessAlert];
                    [self loadStatus];
                    if (self.onCheckinComplete) {
                        self.onCheckinComplete(self.result.coinsEarned, self.result.newBalance);
                    }
                }
            } else {
                self.checkinBtn.enabled = YES;
                [self.checkinBtn setTitle:@"Check In Today" forState:UIControlStateNormal];
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
                [self presentViewController:alert animated:YES completion:nil];
            }
        });
    }];
}

- (void)showSuccessAlert {
    NSString *msg = [NSString stringWithFormat:@"You earned %ld coins!\nNew balance: %ld", (long)self.result.coinsEarned, (long)self.result.newBalance];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Check-in Complete!" message:msg preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self.navigationController popViewControllerAnimated:YES];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
