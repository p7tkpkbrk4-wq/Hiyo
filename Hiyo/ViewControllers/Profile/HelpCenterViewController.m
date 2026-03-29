#import "HelpCenterViewController.h"
#import "HYColors.h"
#import "HYRouter.h"

@interface HelpCenterViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray<NSDictionary *> *faqs;
@property (nonatomic, strong) NSMutableSet<NSNumber *> *expandedSections;

@end

@implementation HelpCenterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"帮助中心";
    [self setupNavigationBarDark];
    self.view.backgroundColor = DarkBackground;

    self.expandedSections = [NSMutableSet set];

    self.faqs = @[
        @{@"question": @"如何修改个人资料？",
          @"answer": @"进入个人主页，点击右上角编辑按钮即可修改您的个人资料。"},
        @{@"question": @"如何删除账号？",
          @"answer": @"请在设置页面联系客服申请删除账号，我们会在7个工作日内处理。"},
        @{@"question": @"为什么无法匹配到用户？",
          @"answer": @"可能是您的资料不完整或网络问题。请确保已完善个人资料并检查网络连接。"},
        @{@"question": @"如何举报用户？",
          @"answer": @"在用户个人页面，点击右上角菜单，选择「举报用户」选项。"},
        @{@"question": @"验证码无法收到怎么办？",
          @"answer": @"请检查垃圾邮件文件夹，或尝试重新发送。如持续无法收到，请联系客服。"},
        @{@"question": @"如何更改语言设置？",
          @"answer": @"进入设置 > 语言设置，选择您偏好的语言。"}
    ];

    [self setupUI];
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

    // Contact support button
    UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 80)];
    UIButton *contactBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [contactBtn setTitle:@"联系客服" forState:UIControlStateNormal];
    [contactBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    contactBtn.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    contactBtn.backgroundColor = PrimaryPink;
    contactBtn.layer.cornerRadius = 24;
    [contactBtn addTarget:self action:@selector(contactSupport) forControlEvents:UIControlEventTouchUpInside];
    [footer addSubview:contactBtn];

    contactBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [contactBtn.centerXAnchor constraintEqualToAnchor:footer.centerXAnchor],
        [contactBtn.centerYAnchor constraintEqualToAnchor:footer.centerYAnchor],
        [contactBtn.widthAnchor constraintEqualToConstant:200],
        [contactBtn.heightAnchor constraintEqualToConstant:48]
    ]];

    self.tableView.tableFooterView = footer;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.faqs.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    cell.backgroundColor = DarkCard;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    // Remove old content
    for (UIView *sub in cell.contentView.subviews) {
        [sub removeFromSuperview];
    }

    NSDictionary *faq = self.faqs[indexPath.row];
    BOOL isExpanded = [self.expandedSections containsObject:@(indexPath.row)];

    UILabel *questionLabel = [[UILabel alloc] init];
    questionLabel.text = faq[@"question"];
    questionLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    questionLabel.textColor = TextPrimary;
    questionLabel.numberOfLines = 0;
    [cell.contentView addSubview:questionLabel];

    questionLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [questionLabel.topAnchor constraintEqualToAnchor:cell.contentView.topAnchor constant:16],
        [questionLabel.leadingAnchor constraintEqualToAnchor:cell.contentView.leadingAnchor constant:16],
        [questionLabel.trailingAnchor constraintEqualToAnchor:cell.contentView.trailingAnchor constant:-40]
    ]];

    if (isExpanded) {
        UILabel *answerLabel = [[UILabel alloc] init];
        answerLabel.text = faq[@"answer"];
        answerLabel.font = [UIFont systemFontOfSize:14];
        answerLabel.textColor = TextSecondary;
        answerLabel.numberOfLines = 0;
        [cell.contentView addSubview:answerLabel];

        answerLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [NSLayoutConstraint activateConstraints:@[
            [answerLabel.topAnchor constraintEqualToAnchor:questionLabel.bottomAnchor constant:12],
            [answerLabel.leadingAnchor constraintEqualToAnchor:cell.contentView.leadingAnchor constant:16],
            [answerLabel.trailingAnchor constraintEqualToAnchor:cell.contentView.trailingAnchor constant:-16],
            [answerLabel.bottomAnchor constraintEqualToAnchor:cell.contentView.bottomAnchor constant:-16]
        ]];
    } else {
        [NSLayoutConstraint activateConstraints:@[
            [questionLabel.bottomAnchor constraintEqualToAnchor:cell.contentView.bottomAnchor constant:-16]
        ]];
    }

    UIImageView *arrow = [[UIImageView alloc] init];
    arrow.image = [UIImage systemImageNamed:isExpanded ? @"chevron.up" : @"chevron.down"];
    arrow.tintColor = TextMuted;
    arrow.contentMode = UIViewContentModeScaleAspectFit;
    [cell.contentView addSubview:arrow];
    arrow.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [arrow.trailingAnchor constraintEqualToAnchor:cell.contentView.trailingAnchor constant:-16],
        [arrow.centerYAnchor constraintEqualToAnchor:cell.contentView.centerYAnchor],
        [arrow.widthAnchor constraintEqualToConstant:16],
        [arrow.heightAnchor constraintEqualToConstant:16]
    ]];

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.expandedSections containsObject:@(indexPath.row)]) {
        [self.expandedSections removeObject:@(indexPath.row)];
    } else {
        [self.expandedSections addObject:@(indexPath.row)];
    }
    [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)contactSupport {
    [self showAlert:@"欢迎联系我们：hiyo@example.com"];
}

@end
