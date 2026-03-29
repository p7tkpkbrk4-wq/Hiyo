#import "NotificationSettingsViewController.h"
#import "HYColors.h"
#import "HYAPIClient.h"

@interface NotificationSettingsViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray<NSDictionary *> *settings;
@property (nonatomic, strong) NSMutableArray<NSNumber *> *enabledStates;

@end

@implementation NotificationSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"消息通知";
    [self setupNavigationBarDark];
    self.view.backgroundColor = DarkBackground;

    self.settings = @[
        @{@"title": @"新消息通知", @"icon": @"message.fill", @"key": @"message"},
        @{@"title": @"匹配通知", @"icon": @"heart.fill", @"key": @"match"},
        @{@"title": @"关注通知", @"icon": @"person.badge.plus.fill", @"key": @"follow"},
        @{@"title": @"系统通知", @"icon": @"bell.fill", @"key": @"system"}
    ];

    self.enabledStates = [NSMutableArray arrayWithArray:@[@YES, @YES, @YES, @YES]];
    [self loadSettings];
    [self setupUI];
}

- (void)loadSettings {
    NSDictionary *saved = [[NSUserDefaults standardUserDefaults] objectForKey:@"HYNotificationSettings"];
    if (saved) {
        for (NSInteger i = 0; i < self.settings.count; i++) {
            NSString *key = self.settings[i][@"key"];
            if (saved[key]) {
                self.enabledStates[i] = saved[key];
            }
        }
    }
}

- (void)saveSettings {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    for (NSInteger i = 0; i < self.settings.count; i++) {
        dict[self.settings[i][@"key"]] = self.enabledStates[i];
    }
    [[NSUserDefaults standardUserDefaults] setObject:dict forKey:@"HYNotificationSettings"];
    [[NSUserDefaults standardUserDefaults] synchronize];

    [[HYAPIClient shared] updateNotificationSettings:dict completion:^(NSDictionary *response, NSError *error) {
        // Silently save locally even if API fails
    }];
}

- (void)setupUI {
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleInsetGrouped];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.backgroundColor = DarkBackground;
    self.tableView.separatorColor = DarkLighter;
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

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.settings.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    cell.backgroundColor = DarkCard;
    cell.textLabel.text = self.settings[indexPath.row][@"title"];
    cell.textLabel.textColor = TextPrimary;
    cell.textLabel.font = [UIFont systemFontOfSize:16];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    UISwitch *sw = [[UISwitch alloc] init];
    sw.onTintColor = PrimaryPink;
    sw.tag = indexPath.row;
    sw.on = [self.enabledStates[indexPath.row] boolValue];
    [sw addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
    cell.accessoryView = sw;

    return cell;
}

- (void)switchChanged:(UISwitch *)sw {
    self.enabledStates[sw.tag] = @(sw.on);
    [self saveSettings];
}

@end
