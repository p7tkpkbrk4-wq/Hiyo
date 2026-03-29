#import "LanguageSettingsViewController.h"
#import "HYColors.h"
#import "HYNotificationConstants.h"

static NSString * const kLanguageKey = @"HYLanguagePreference";

@interface LanguageSettingsViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray<NSDictionary *> *options;
@property (nonatomic, assign) NSInteger selectedIndex;

@end

@implementation LanguageSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"语言";
    [self setupNavigationBarDark];
    self.view.backgroundColor = DarkBackground;

    self.options = @[
        @{@"title": @"跟随系统", @"value": @"system"},
        @{@"title": @"繁體中文", @"value": @"zh-Hant"},
        @{@"title": @"简体中文", @"value": @"zh-Hans"},
        @{@"title": @"English", @"value": @"en"}
    ];

    NSString *saved = [[NSUserDefaults standardUserDefaults] stringForKey:kLanguageKey] ?: @"system";
    self.selectedIndex = [self indexForValue:saved];
    if (self.selectedIndex == NSNotFound) self.selectedIndex = 0;

    [self setupUI];
}

- (NSInteger)indexForValue:(NSString *)value {
    for (NSInteger i = 0; i < self.options.count; i++) {
        if ([self.options[i][@"value"] isEqualToString:value]) {
            return i;
        }
    }
    return NSNotFound;
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
    return self.options.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    cell.backgroundColor = DarkCard;
    cell.textLabel.text = self.options[indexPath.row][@"title"];
    cell.textLabel.textColor = TextPrimary;
    cell.textLabel.font = [UIFont systemFontOfSize:16];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    if (indexPath.row == self.selectedIndex) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        cell.tintColor = PrimaryPink;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.selectedIndex = indexPath.row;
    NSString *value = self.options[indexPath.row][@"value"];
    [[NSUserDefaults standardUserDefaults] setObject:value forKey:kLanguageKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [tableView reloadData];
    [[NSNotificationCenter defaultCenter] postNotificationName:HYLanguageDidChangeNotification object:value];
    [self showToast:@"语言已切换"];
}

@end
