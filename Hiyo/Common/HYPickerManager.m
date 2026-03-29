#import "HYPickerManager.h"
#import "HYCountry.h"
#import "HYInterestCategory.h"
#import "HYAPIClient.h"

@interface HYSinglePickerSheet : UIViewController
@property (nonatomic, copy) void (^onConfirm)(NSInteger value);
@property (nonatomic, assign) NSInteger currentValue;
@property (nonatomic, assign) NSInteger minValue;
@property (nonatomic, assign) NSInteger maxValue;
@property (nonatomic, copy) NSString *unit;
@property (nonatomic, strong) UILabel *valueLabel;
@property (nonatomic, strong) UISlider *slider;
@end

@implementation HYSinglePickerSheet

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = DarkCard;

    self.view.translatesAutoresizingMaskIntoConstraints = NO;

    self.valueLabel = [[UILabel alloc] init];
    self.valueLabel.text = [NSString stringWithFormat:@"%ld%@", (long)self.currentValue, self.unit];
    self.valueLabel.font = [UIFont systemFontOfSize:48 weight:UIFontWeightBold];
    self.valueLabel.textColor = TextPrimary;
    self.valueLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.valueLabel];

    self.slider = [[UISlider alloc] init];
    self.slider.minimumValue = self.minValue;
    self.slider.maximumValue = self.maxValue;
    self.slider.value = self.currentValue;
    self.slider.minimumTrackTintColor = PrimaryPink;
    self.slider.maximumTrackTintColor = DarkLighter;
    self.slider.thumbTintColor = PrimaryPink;
    [self.slider addTarget:self action:@selector(sliderChanged:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:self.slider];

    UIButton *confirmButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [confirmButton setTitle:@"确定" forState:UIControlStateNormal];
    [confirmButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    confirmButton.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    confirmButton.backgroundColor = PrimaryPink;
    confirmButton.layer.cornerRadius = 24;
    [confirmButton addTarget:self action:@selector(confirmTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:confirmButton];

    self.valueLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.slider.translatesAutoresizingMaskIntoConstraints = NO;
    confirmButton.translatesAutoresizingMaskIntoConstraints = NO;

    [NSLayoutConstraint activateConstraints:@[
        [self.valueLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.valueLabel.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:40],

        [self.slider.topAnchor constraintEqualToAnchor:self.valueLabel.bottomAnchor constant:32],
        [self.slider.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:24],
        [self.slider.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-24],

        [confirmButton.topAnchor constraintEqualToAnchor:self.slider.bottomAnchor constant:40],
        [confirmButton.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:24],
        [confirmButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-24],
        [confirmButton.heightAnchor constraintEqualToConstant:48],
        [confirmButton.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-40]
    ]];
}

- (void)sliderChanged:(UISlider *)slider {
    NSInteger val = (NSInteger)roundf(slider.value);
    self.valueLabel.text = [NSString stringWithFormat:@"%ld%@", (long)val, self.unit];
    self.currentValue = val;
}

- (void)confirmTapped {
    if (self.onConfirm) {
        self.onConfirm(self.currentValue);
    }
    [self dismiss];
}

- (void)dismiss {
    UIViewController *presenter = self.presentingViewController;
    [self dismissViewControllerAnimated:YES completion:^{
        // handled by HYPickerManager
    }];
}

- (CGSize)preferredContentSize {
    return CGSizeMake(UIScreen.mainScreen.bounds.size.width, 350);
}

@end

@interface HYDatePickerSheet : UIViewController
@property (nonatomic, copy) void (^onConfirm)(NSDate *date);
@property (nonatomic, strong) NSDate *currentDate;
@property (nonatomic, strong) UIDatePicker *datePicker;
@end

@implementation HYDatePickerSheet

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = DarkCard;

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = @"选择日期";
    titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    titleLabel.textColor = TextPrimary;
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:titleLabel];

    self.datePicker = [[UIDatePicker alloc] init];
    self.datePicker.datePickerMode = UIDatePickerModeDate;
    self.datePicker.preferredDatePickerStyle = UIDatePickerStyleWheels;
    self.datePicker.date = self.currentDate ?: [NSDate date];
    self.datePicker.minimumDate = [NSDate dateWithTimeIntervalSinceNow:-80 * 365 * 24 * 60 * 60];
    self.datePicker.maximumDate = [NSDate date];
    self.datePicker.backgroundColor = DarkCard;
    if (@available(iOS 13.0, *)) {
        self.datePicker.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
    }
    [self.view addSubview:self.datePicker];

    UIButton *confirmButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [confirmButton setTitle:@"确定" forState:UIControlStateNormal];
    [confirmButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    confirmButton.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    confirmButton.backgroundColor = PrimaryPink;
    confirmButton.layer.cornerRadius = 24;
    [confirmButton addTarget:self action:@selector(confirmTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:confirmButton];

    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.datePicker.translatesAutoresizingMaskIntoConstraints = NO;
    confirmButton.translatesAutoresizingMaskIntoConstraints = NO;

    [NSLayoutConstraint activateConstraints:@[
        [titleLabel.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:20],
        [titleLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],

        [self.datePicker.topAnchor constraintEqualToAnchor:titleLabel.bottomAnchor constant:8],
        [self.datePicker.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.datePicker.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],

        [confirmButton.topAnchor constraintEqualToAnchor:self.datePicker.bottomAnchor constant:16],
        [confirmButton.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:24],
        [confirmButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-24],
        [confirmButton.heightAnchor constraintEqualToConstant:48],
        [confirmButton.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-24]
    ]];
}

- (void)confirmTapped {
    if (self.onConfirm) {
        self.onConfirm(self.datePicker.date);
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (CGSize)preferredContentSize {
    return CGSizeMake(UIScreen.mainScreen.bounds.size.width, 400);
}

@end

@interface HYCountryPickerSheet : UIViewController <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate>
@property (nonatomic, copy) void (^onSelect)(HYCountry *country);
@property (nonatomic, strong) NSArray<HYCountry *> *countries;
@property (nonatomic, strong) NSArray<HYCountry *> *filteredCountries;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UISearchBar *searchBar;
@end

@implementation HYCountryPickerSheet

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = DarkCard;
    self.filteredCountries = self.countries;

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = @"选择国家";
    titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    titleLabel.textColor = TextPrimary;
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:titleLabel];

    self.searchBar = [[UISearchBar alloc] init];
    self.searchBar.placeholder = @"搜索国家";
    self.searchBar.searchBarStyle = UISearchBarStyleMinimal;
    self.searchBar.delegate = self;
    self.searchBar.barTintColor = DarkCard;
    if (@available(iOS 13.0, *)) {
        self.searchBar.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
    }
    [self.view addSubview:self.searchBar];

    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.backgroundColor = DarkCard;
    self.tableView.separatorColor = DarkLighter;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
    [self.view addSubview:self.tableView];

    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.searchBar.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;

    [NSLayoutConstraint activateConstraints:@[
        [titleLabel.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:20],
        [titleLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],

        [self.searchBar.topAnchor constraintEqualToAnchor:titleLabel.bottomAnchor constant:8],
        [self.searchBar.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.searchBar.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],

        [self.tableView.topAnchor constraintEqualToAnchor:self.searchBar.bottomAnchor constant:8],
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.filteredCountries.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    HYCountry *country = self.filteredCountries[indexPath.row];
    cell.textLabel.text = country.name;
    cell.textLabel.textColor = TextPrimary;
    cell.backgroundColor = DarkCard;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.onSelect) {
        self.onSelect(self.filteredCountries[indexPath.row]);
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if (searchText.length == 0) {
        self.filteredCountries = self.countries;
    } else {
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"name CONTAINS[cd] %@", searchText];
        self.filteredCountries = [self.countries filteredArrayUsingPredicate:pred];
    }
    [self.tableView reloadData];
}

- (CGSize)preferredContentSize {
    return CGSizeMake(UIScreen.mainScreen.bounds.size.width, 450);
}

@end

@interface HYCitiesPickerSheet : UIViewController <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, copy) void (^onSelect)(NSString *city);
@property (nonatomic, copy) NSString *countryName;
@property (nonatomic, strong) NSArray<NSString *> *cities;
@property (nonatomic, strong) UITableView *tableView;
@end

@implementation HYCitiesPickerSheet

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = DarkCard;

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = [NSString stringWithFormat:@"%@ - 选择城市", self.countryName];
    titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    titleLabel.textColor = TextPrimary;
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:titleLabel];

    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.backgroundColor = DarkCard;
    self.tableView.separatorColor = DarkLighter;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
    [self.view addSubview:self.tableView];

    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;

    [NSLayoutConstraint activateConstraints:@[
        [titleLabel.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:20],
        [titleLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],

        [self.tableView.topAnchor constraintEqualToAnchor:titleLabel.bottomAnchor constant:16],
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.cities.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    cell.textLabel.text = self.cities[indexPath.row];
    cell.textLabel.textColor = TextPrimary;
    cell.backgroundColor = DarkCard;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.onSelect) {
        self.onSelect(self.cities[indexPath.row]);
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (CGSize)preferredContentSize {
    return CGSizeMake(UIScreen.mainScreen.bounds.size.width, 400);
}

@end

@interface HYInterestsPickerSheet : UIViewController
@property (nonatomic, copy) void (^onConfirm)(NSArray<NSString *> *interests);
@property (nonatomic, strong) NSMutableArray<NSString *> *selectedInterests;
@property (nonatomic, strong) NSArray<HYInterestCategory *> *categories;
@property (nonatomic, assign) NSInteger selectedCategoryIndex;
@property (nonatomic, strong) UIScrollView *categoryScrollView;
@property (nonatomic, strong) UIView *selectedContainer;
@property (nonatomic, strong) UIView *tagsContainer;
@property (nonatomic, strong) UIButton *confirmButton;
@property (nonatomic, strong) UILabel *countLabel;
@end

@implementation HYInterestsPickerSheet

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = DarkCard;
    self.selectedInterests = [NSMutableArray array];
    self.selectedCategoryIndex = 0;

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = @"选择兴趣爱好";
    titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    titleLabel.textColor = TextPrimary;
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:titleLabel];

    self.countLabel = [[UILabel alloc] init];
    self.countLabel.font = [UIFont systemFontOfSize:13];
    self.countLabel.textColor = TextSecondary;
    self.countLabel.textAlignment = NSTextAlignmentCenter;
    [self updateCountLabel];
    [self.view addSubview:self.countLabel];

    self.selectedContainer = [[UIView alloc] init];
    self.selectedContainer.backgroundColor = DarkCardElevated;
    self.selectedContainer.layer.cornerRadius = 12;
    self.selectedContainer.layer.borderWidth = 1;
    self.selectedContainer.layer.borderColor = BorderLight.CGColor;
    [self.view addSubview:self.selectedContainer];

    self.categoryScrollView = [[UIScrollView alloc] init];
    self.categoryScrollView.showsHorizontalScrollIndicator = NO;
    [self.view addSubview:self.categoryScrollView];

    self.tagsContainer = [[UIView alloc] init];
    [self.view addSubview:self.tagsContainer];

    self.confirmButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.confirmButton setTitle:@"确定" forState:UIControlStateNormal];
    [self.confirmButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.confirmButton.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    self.confirmButton.backgroundColor = PrimaryPink;
    self.confirmButton.layer.cornerRadius = 24;
    [self.confirmButton addTarget:self action:@selector(confirmTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.confirmButton];

    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.countLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.selectedContainer.translatesAutoresizingMaskIntoConstraints = NO;
    self.categoryScrollView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tagsContainer.translatesAutoresizingMaskIntoConstraints = NO;
    self.confirmButton.translatesAutoresizingMaskIntoConstraints = NO;

    [NSLayoutConstraint activateConstraints:@[
        [titleLabel.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:20],
        [titleLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],

        [self.countLabel.topAnchor constraintEqualToAnchor:titleLabel.bottomAnchor constant:4],
        [self.countLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],

        [self.selectedContainer.topAnchor constraintEqualToAnchor:self.countLabel.bottomAnchor constant:12],
        [self.selectedContainer.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        [self.selectedContainer.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],
        [self.selectedContainer.heightAnchor constraintEqualToConstant:50],

        [self.categoryScrollView.topAnchor constraintEqualToAnchor:self.selectedContainer.bottomAnchor constant:16],
        [self.categoryScrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.categoryScrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.categoryScrollView.heightAnchor constraintEqualToConstant:40],

        [self.tagsContainer.topAnchor constraintEqualToAnchor:self.categoryScrollView.bottomAnchor constant:12],
        [self.tagsContainer.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        [self.tagsContainer.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],
        [self.tagsContainer.heightAnchor constraintGreaterThanOrEqualToConstant:120],

        [self.confirmButton.topAnchor constraintEqualToAnchor:self.tagsContainer.bottomAnchor constant:16],
        [self.confirmButton.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:24],
        [self.confirmButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-24],
        [self.confirmButton.heightAnchor constraintEqualToConstant:48],
        [self.confirmButton.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-24]
    ]];

    [self setupCategories];
    [self setupTags];
}

- (void)updateCountLabel {
    NSInteger count = self.selectedInterests.count;
    self.countLabel.text = [NSString stringWithFormat:@"已选择 %ld/10 个（至少4个）", (long)count];
    self.confirmButton.enabled = count >= 4 && count <= 10;
    self.confirmButton.alpha = (count >= 4 && count <= 10) ? 1.0 : 0.5;
}

- (void)setupCategories {
    for (UIView *subview in self.categoryScrollView.subviews) {
        [subview removeFromSuperview];
    }

    CGFloat x = 16;
    for (NSInteger i = 0; i < self.categories.count; i++) {
        HYInterestCategory *cat = self.categories[i];
        BOOL selected = (i == self.selectedCategoryIndex);
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        [btn setTitle:cat.name forState:UIControlStateNormal];
        [btn setTitleColor:selected ? [UIColor whiteColor] : TextSecondary forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
        btn.backgroundColor = selected ? PrimaryPurple : DarkCardElevated;
        btn.layer.cornerRadius = 20;
        btn.contentEdgeInsets = UIEdgeInsetsMake(8, 20, 8, 20);
        btn.tag = i;
        [btn addTarget:self action:@selector(categoryTapped:) forControlEvents:UIControlEventTouchUpInside];
        btn.frame = CGRectMake(x, 0, [cat.name sizeWithAttributes:@{NSFontAttributeName: btn.titleLabel.font}].width + 40, 40);
        [self.categoryScrollView addSubview:btn];
        x += btn.frame.size.width + 8;
    }
    self.categoryScrollView.contentSize = CGSizeMake(x, 40);
}

- (void)setupTags {
    for (UIView *subview in self.tagsContainer.subviews) {
        [subview removeFromSuperview];
    }

    if (self.categories.count == 0) return;

    NSArray<NSString *> *tags = self.categories[self.selectedCategoryIndex].tags;
    CGFloat width = UIScreen.mainScreen.bounds.size.width - 32;
    CGFloat x = 0, y = 0, rowHeight = 36;

    for (NSInteger i = 0; i < tags.count; i++) {
        NSString *tag = tags[i];
        BOOL isSelected = [self.selectedInterests containsObject:tag];

        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        [btn setTitle:tag forState:UIControlStateNormal];
        [btn setTitleColor:isSelected ? [UIColor whiteColor] : TextSecondary forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont systemFontOfSize:13];
        btn.layer.cornerRadius = 18;
        btn.layer.borderWidth = 1;
        btn.layer.borderColor = isSelected ? PrimaryPink.CGColor : BorderLight.CGColor;
        btn.backgroundColor = isSelected ? [PrimaryPink colorWithAlphaComponent:0.2] : [UIColor clearColor];
        btn.contentEdgeInsets = UIEdgeInsetsMake(8, 16, 8, 16);
        btn.tag = i;
        [btn addTarget:self action:@selector(tagTapped:) forControlEvents:UIControlEventTouchUpInside];

        CGSize size = [tag sizeWithAttributes:@{NSFontAttributeName: btn.titleLabel.font}];
        CGFloat btnWidth = size.width + 32;

        if (x + btnWidth > width) {
            x = 0;
            y += rowHeight + 8;
        }
        btn.frame = CGRectMake(x, y, btnWidth, rowHeight);
        [self.tagsContainer addSubview:btn];
        x += btnWidth + 8;
    }
}

- (void)categoryTapped:(UIButton *)sender {
    self.selectedCategoryIndex = sender.tag;
    [self setupCategories];
    [self setupTags];
}

- (void)tagTapped:(UIButton *)sender {
    if (self.categories.count == 0) return;
    NSString *tag = self.categories[self.selectedCategoryIndex].tags[sender.tag];

    if ([self.selectedInterests containsObject:tag]) {
        [self.selectedInterests removeObject:tag];
    } else if (self.selectedInterests.count < 10) {
        [self.selectedInterests addObject:tag];
    }

    [self setupTags];
    [self setupSelectedContainer];
    [self updateCountLabel];
}

- (void)setupSelectedContainer {
    for (UIView *subview in self.selectedContainer.subviews) {
        [subview removeFromSuperview];
    }

    CGFloat x = 8;
    for (NSString *tag in self.selectedInterests) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        [btn setTitle:[NSString stringWithFormat:@"%@ ×", tag] forState:UIControlStateNormal];
        [btn setTitleColor:PrimaryPink forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont systemFontOfSize:12];
        btn.backgroundColor = [PrimaryPink colorWithAlphaComponent:0.15];
        btn.layer.cornerRadius = 12;
        btn.contentEdgeInsets = UIEdgeInsetsMake(4, 10, 4, 10);
        CGSize size = [[NSString stringWithFormat:@"%@ ×", tag] sizeWithAttributes:@{NSFontAttributeName: btn.titleLabel.font}];
        btn.frame = CGRectMake(x, (50 - size.height - 8) / 2, size.width + 20, size.height + 8);
        x += btn.frame.size.width + 6;
    }
}

- (void)confirmTapped {
    if (self.onConfirm && self.selectedInterests.count >= 4 && self.selectedInterests.count <= 10) {
        self.onConfirm([self.selectedInterests copy]);
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (CGSize)preferredContentSize {
    return CGSizeMake(UIScreen.mainScreen.bounds.size.width, 500);
}

@end

@implementation HYPickerManager

+ (instancetype)shared {
    static HYPickerManager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[HYPickerManager alloc] init];
    });
    return instance;
}

+ (void)showBirthdayPickerWithCurrentDate:(NSDate *)date completion:(HYDatePickerCompletion)completion {
    HYDatePickerSheet *sheet = [[HYDatePickerSheet alloc] init];
    sheet.currentDate = date;
    sheet.onConfirm = completion;
    HYBottomSheetController *bottomSheet = [[HYBottomSheetController alloc] initWithContentViewController:sheet];
    [bottomSheet show];
}

+ (void)showCountryCityPickerWithCountry:(NSString *)country city:(NSString *)city completion:(HYCountryCityCompletion)completion {
    __block NSString *selectedCountryName;
    __block NSArray<HYCountry *> *allCountries;

    [[HYAPIClient shared] getLocationsWithCompletion:^(NSDictionary *response, NSError *error) {
        if (error) return;

        NSArray *list = response[@"data"];
        if (![list isKindOfClass:[NSArray class]]) return;

        NSMutableArray *countries = [NSMutableArray array];
        for (NSDictionary *dict in list) {
            [countries addObject:[[HYCountry alloc] initWithDictionary:dict]];
        }
        allCountries = countries;

        HYCountryPickerSheet *countrySheet = [[HYCountryPickerSheet alloc] init];
        countrySheet.countries = countries;
        HYBottomSheetController *countryBottom = [[HYBottomSheetController alloc] initWithContentViewController:countrySheet];

        countrySheet.onSelect = ^(HYCountry *country) {
            selectedCountryName = country.name;

            HYCitiesPickerSheet *citySheet = [[HYCitiesPickerSheet alloc] init];
            citySheet.countryName = country.name;
            citySheet.cities = country.cities;
            HYBottomSheetController *cityBottom = [[HYBottomSheetController alloc] initWithContentViewController:citySheet];

            citySheet.onSelect = ^(NSString *cityName) {
                if (completion) {
                    completion(selectedCountryName, cityName);
                }
            };
            [cityBottom show];
        };
        [countryBottom show];
    }];
}

+ (void)showHeightPickerWithValue:(NSInteger)value completion:(HYValueCompletion)completion {
    HYSinglePickerSheet *sheet = [[HYSinglePickerSheet alloc] init];
    sheet.currentValue = value > 0 ? value : 170;
    sheet.minValue = 100;
    sheet.maxValue = 220;
    sheet.unit = @"cm";
    sheet.onConfirm = completion;

    UIViewController *topVC = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (topVC.presentedViewController) {
        topVC = topVC.presentedViewController;
    }
    [topVC presentViewController:sheet animated:YES completion:nil];
}

+ (void)showWeightPickerWithValue:(NSInteger)value completion:(HYValueCompletion)completion {
    HYSinglePickerSheet *sheet = [[HYSinglePickerSheet alloc] init];
    sheet.currentValue = value > 0 ? value : 60;
    sheet.minValue = 30;
    sheet.maxValue = 150;
    sheet.unit = @"kg";
    sheet.onConfirm = completion;

    UIViewController *topVC = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (topVC.presentedViewController) {
        topVC = topVC.presentedViewController;
    }
    [topVC presentViewController:sheet animated:YES completion:nil];
}

+ (void)showInterestsPickerWithSelected:(NSArray<NSString *> *)selected completion:(HYInterestsCompletion)completion {
    [[HYAPIClient shared] getInterestsWithCompletion:^(NSDictionary *response, NSError *error) {
        NSMutableArray *categories = [NSMutableArray array];
        if (!error) {
            NSArray *data = response[@"data"];
            if ([data isKindOfClass:[NSArray class]]) {
                for (NSDictionary *dict in data) {
                    [categories addObject:[[HYInterestCategory alloc] initWithDictionary:dict]];
                }
            }
        }

        if (categories.count == 0) {
            NSArray *defaults = @[
                [[HYInterestCategory alloc] initWithDictionary:@{@"name": @"娱乐", @"tags": @[@"音乐", @"电影", @"游戏", @"阅读", @"电竞"]}],
                [[HYInterestCategory alloc] initWithDictionary:@{@"name": @"运动", @"tags": @[@"健身", @"跑步", @"游泳", @"篮球", @"足球"]}],
                [[HYInterestCategory alloc] initWithDictionary:@{@"name": @"生活", @"tags": @[@"美食", @"旅行", @"摄影", @"时尚", @"宠物"]}],
                [[HYInterestCategory alloc] initWithDictionary:@{@"name": @"艺术", @"tags": @[@"绘画", @"舞蹈", @"书法", @"手工", @"设计"]}],
            ];
            categories = [defaults mutableCopy];
        }

        HYInterestsPickerSheet *sheet = [[HYInterestsPickerSheet alloc] init];
        sheet.categories = categories;
        [sheet.selectedInterests addObjectsFromArray:selected ?: @[]];
        sheet.onConfirm = completion;
        HYBottomSheetController *bottomSheet = [[HYBottomSheetController alloc] initWithContentViewController:sheet];
        [bottomSheet show];
    }];
}

@end
