#import "PrivacySettingsViewController.h"
#import "HYColors.h"
#import "HYAPIClient.h"

@interface PrivacySettingsViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray<NSDictionary *> *settings;
@property (nonatomic, strong) NSMutableArray<NSNumber *> *enabledStates;

@end

@implementation PrivacySettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"隐私设置";
    [self setupNavigationBarDark];
    self.view.backgroundColor = DarkBackground;

    self.settings = @[
        @{@"title": @"隐藏在线状态", @"icon": @"eye.slash.fill", @"key": @"hide_online"},
        @{@"title": @"隐藏距离", @"icon": @"location.slash.fill", @"key": @"hide_distance"},
        @{@"title": @"隐藏最后登录时间", @"icon": @"clock.fill", @"key": @"hide_last_seen"}
    ];

    self.enabledStates = [NSMutableArray arrayWithArray:@[@NO, @NO, @NO]];
    [self loadSettings];
    [self setupUI];
}

- (void)loadSettings {
    NSDictionary *saved = [[NSUserDefaults standardUserDefaults] objectForKey:@"HYPrivacySettings"];
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
    [[NSUserDefaults standardUserDefaults] setObject:dict forKey:@"HYPrivacySettings"];
    [[NSUserDefaults standardUserDefaults] synchronize];

    [[HYAPIClient shared] updatePrivacySettings:dict completion:^(NSDictionary *response, NSError *error) {
        // Silently save locally
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
