#import "MessagesViewController.h"
#import "HYAPIClient.h"
#import "HYModels.h"
#import "HYColors.h"
#import "HYConversationCell.h"
#import "HYSearchUserCell.h"
#import "HYSearchUser.h"
#import "HYWebSocketManager.h"
#import "HYLoginRequiredView.h"
#import "ChatDetailViewController.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/SDWebImage.h>
#import <MJRefresh/MJRefresh.h>

static NSString * const kConversationCellId = @"HYConversationCell";
static NSString * const kSearchUserCellId = @"HYSearchUserCell";

@interface MessagesViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UIView *segmentControl;
@property (nonatomic, strong) UIButton *recentButton;
@property (nonatomic, strong) UIButton *nearbyButton;
@property (nonatomic, strong) UIView *segmentIndicator;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIActivityIndicatorView *loadingIndicator;
@property (nonatomic, strong) UILabel *emptyLabel;
@property (nonatomic, strong) UILabel *nearbyPlaceholder;

// Search
@property (nonatomic, strong) UIView *searchOverlay;
@property (nonatomic, strong) UITextField *searchField;
@property (nonatomic, strong) UIButton *cancelButton;
@property (nonatomic, strong) UITableView *searchResultsTableView;
@property (nonatomic, strong) UILabel *searchEmptyLabel;
@property (nonatomic, strong) NSMutableArray<HYSearchUser *> *searchResults;
@property (nonatomic, assign) BOOL isSearchActive;

@property (nonatomic, strong) NSMutableArray<HYConversation *> *conversations;
@property (nonatomic, assign) NSInteger currentPage;
@property (nonatomic, assign) BOOL hasMore;
@property (nonatomic, assign) BOOL isLoading;
@property (nonatomic, assign) NSInteger currentSegment;

@property (nonatomic, strong) HYLoginRequiredView *loginRequiredView;

@end

@implementation MessagesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"消息";
    self.view.backgroundColor = LightBg1;
    self.conversations = [NSMutableArray array];
    self.searchResults = [NSMutableArray array];
    self.currentPage = 1;
    self.hasMore = YES;
    self.currentSegment = 0;
    self.isSearchActive = NO;
    [self setupNavigationBar];
    [self setupUI];
    [self setupNotifications];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if ([HYAPIClient shared].isLoggedIn) {
        [self hideLoginRequired];
        [self loadConversations:YES];
    } else {
        [self showLoginRequired];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Setup

- (void)setupNavigationBar {
    self.navigationController.navigationBar.tintColor = PinkGradStart;

    if (@available(iOS 15.0, *)) {
        UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
        [appearance configureWithOpaqueBackground];
        appearance.backgroundColor = [UIColor whiteColor];
        appearance.shadowColor = [UIColor colorWithRed:0.933 green:0.933 blue:1.0 alpha:1.0];
        appearance.titleTextAttributes = @{
            NSForegroundColorAttributeName: [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0],
            NSFontAttributeName: [UIFont systemFontOfSize:18 weight:UIFontWeightBold]
        };
        self.navigationController.navigationBar.standardAppearance = appearance;
        self.navigationController.navigationBar.scrollEdgeAppearance = appearance;
    }

    // Right: search button (purple circle with search icon)
    UIView *searchWrapper = [[UIView alloc] init];
    searchWrapper.backgroundColor = [UIColor colorWithRed:0.961 green:0.941 blue:1.0 alpha:1.0];
    searchWrapper.layer.cornerRadius = 18;

    UIButton *searchButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [searchButton setImage:[UIImage systemImageNamed:@"magnifyingglass"] forState:UIControlStateNormal];
    searchButton.tintColor = PurpleGradStart;
    searchButton.frame = CGRectMake(0, 0, 36, 36);
    [searchButton addTarget:self action:@selector(searchButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [searchWrapper addSubview:searchButton];

    [searchWrapper mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.equalTo(@36);
    }];

    UIBarButtonItem *searchItem = [[UIBarButtonItem alloc] initWithCustomView:searchWrapper];
    self.navigationItem.rightBarButtonItem = searchItem;
}

- (void)setupUI {
    [self setupSegmentControl];
    [self setupSearchOverlay];
    [self setupTableView];
    [self setupLoginRequired];
    [self setupConstraints];
}

- (void)setupSegmentControl {
    self.segmentControl = [[UIView alloc] init];
    self.segmentControl.backgroundColor = LightCard;
    self.segmentControl.layer.cornerRadius = 12;
    self.segmentControl.layer.borderWidth = 1;
    self.segmentControl.layer.borderColor = [UIColor colorWithRed:0.933 green:0.933 blue:1.0 alpha:1.0].CGColor;
    [self.view addSubview:self.segmentControl];

    self.segmentIndicator = [[UIView alloc] init];
    self.segmentIndicator.backgroundColor = PurpleGradStart;
    self.segmentIndicator.layer.cornerRadius = 8;
    [self.segmentControl addSubview:self.segmentIndicator];

    self.recentButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.recentButton setTitle:@"最近聊天" forState:UIControlStateNormal];
    self.recentButton.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
    [self.recentButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.recentButton addTarget:self action:@selector(segmentTapped:) forControlEvents:UIControlEventTouchUpInside];
    self.recentButton.tag = 0;
    [self.segmentControl addSubview:self.recentButton];

    self.nearbyButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.nearbyButton setTitle:@"附近" forState:UIControlStateNormal];
    self.nearbyButton.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    [self.nearbyButton setTitleColor:[UIColor colorWithRed:0.667 green:0.667 blue:0.667 alpha:1.0] forState:UIControlStateNormal];
    [self.nearbyButton addTarget:self action:@selector(segmentTapped:) forControlEvents:UIControlEventTouchUpInside];
    self.nearbyButton.tag = 1;
    [self.segmentControl addSubview:self.nearbyButton];
}

- (void)setupSearchOverlay {
    // Search overlay - appears above segment control when active
    self.searchOverlay = [[UIView alloc] init];
    self.searchOverlay.backgroundColor = [UIColor colorWithRed:0.961 green:0.941 blue:1.0 alpha:1.0];
    self.searchOverlay.hidden = YES;
    [self.view addSubview:self.searchOverlay];

    // Search text field (rounded, filled style)
    self.searchField = [[UITextField alloc] init];
    self.searchField.placeholder = @"搜索用户ID/昵称";
    self.searchField.font = [UIFont systemFontOfSize:15];
    self.searchField.textColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0];
    self.searchField.backgroundColor = LightCard;
    self.searchField.layer.cornerRadius = 28;
    self.searchField.layer.borderWidth = 1;
    self.searchField.layer.borderColor = [UIColor colorWithRed:0.933 green:0.933 blue:1.0 alpha:1.0].CGColor;
    self.searchField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 16, 1)];
    self.searchField.leftViewMode = UITextFieldViewModeAlways;
    self.searchField.rightView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 16, 1)];
    self.searchField.rightViewMode = UITextFieldViewModeAlways;
    self.searchField.returnKeyType = UIReturnKeySearch;
    self.searchField.delegate = (id)self;
    self.searchField.clearButtonMode = UITextFieldViewModeWhileEditing;
    [self.searchField addTarget:self action:@selector(searchTextChanged:) forControlEvents:UIControlEventEditingChanged];
    [self.searchOverlay addSubview:self.searchField];

    // Cancel button
    self.cancelButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.cancelButton setTitle:@"取消" forState:UIControlStateNormal];
    self.cancelButton.titleLabel.font = [UIFont systemFontOfSize:15];
    [self.cancelButton setTitleColor:[UIColor colorWithRed:0.4 green:0.4 blue:0.4 alpha:1.0] forState:UIControlStateNormal];
    [self.cancelButton addTarget:self action:@selector(cancelSearch) forControlEvents:UIControlEventTouchUpInside];
    [self.searchOverlay addSubview:self.cancelButton];

    // Search results table
    self.searchResultsTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.searchResultsTableView.delegate = self;
    self.searchResultsTableView.dataSource = self;
    self.searchResultsTableView.hidden = YES;
    self.searchResultsTableView.backgroundColor = [UIColor clearColor];
    self.searchResultsTableView.rowHeight = 60;
    self.searchResultsTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.searchResultsTableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    [self.searchResultsTableView registerClass:[HYSearchUserCell class] forCellReuseIdentifier:kSearchUserCellId];
    [self.view addSubview:self.searchResultsTableView];

    self.searchEmptyLabel = [[UILabel alloc] init];
    self.searchEmptyLabel.text = @"暂无搜索结果";
    self.searchEmptyLabel.font = [UIFont systemFontOfSize:15];
    self.searchEmptyLabel.textColor = [UIColor colorWithRed:0.6 green:0.6 blue:0.6 alpha:1.0];
    self.searchEmptyLabel.textAlignment = NSTextAlignmentCenter;
    self.searchEmptyLabel.hidden = YES;
    [self.searchResultsTableView addSubview:self.searchEmptyLabel];
}

- (void)setupTableView {
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.rowHeight = 76;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    [self.tableView registerClass:[HYConversationCell class] forCellReuseIdentifier:kConversationCellId];
    [self.view addSubview:self.tableView];

    self.tableView.mj_header = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(pullToRefresh)];
    self.tableView.mj_footer = [MJRefreshAutoNormalFooter footerWithRefreshingTarget:self refreshingAction:@selector(loadMoreData)];

    self.loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    self.loadingIndicator.color = PinkGradStart;
    self.loadingIndicator.hidesWhenStopped = YES;
    [self.view addSubview:self.loadingIndicator];

    self.emptyLabel = [[UILabel alloc] init];
    self.emptyLabel.text = @"暂无消息";
    self.emptyLabel.font = [UIFont systemFontOfSize:15];
    self.emptyLabel.textColor = [UIColor colorWithRed:0.6 green:0.6 blue:0.6 alpha:1.0];
    self.emptyLabel.textAlignment = NSTextAlignmentCenter;
    self.emptyLabel.hidden = YES;
    [self.tableView addSubview:self.emptyLabel];

    self.nearbyPlaceholder = [[UILabel alloc] init];
    self.nearbyPlaceholder.text = @"功能开发中";
    self.nearbyPlaceholder.font = [UIFont systemFontOfSize:15];
    self.nearbyPlaceholder.textColor = [UIColor colorWithRed:0.6 green:0.6 blue:0.6 alpha:1.0];
    self.nearbyPlaceholder.textAlignment = NSTextAlignmentCenter;
    self.nearbyPlaceholder.hidden = YES;
    [self.tableView addSubview:self.nearbyPlaceholder];
}

- (void)setupLoginRequired {
    self.loginRequiredView = [[HYLoginRequiredView alloc] init];
    self.loginRequiredView.tipText = @"登录后可以看到消息";
    self.loginRequiredView.backgroundColor = LightBg1;
    [self.loginRequiredView setLoginButtonTitle:@"去登录"];
    __weak typeof(self) weakSelf = self;
    self.loginRequiredView.onLoginTapped = ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"HYNeedLoginNotification" object:nil];
    };
    self.loginRequiredView.hidden = YES;
    [self.view addSubview:self.loginRequiredView];

    [self.loginRequiredView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
}

- (void)setupConstraints {
    [self.searchOverlay mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(8);
        make.leading.trailing.equalTo(self.view);
        make.height.equalTo(@72);
    }];

    [self.cancelButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(self.searchOverlay).offset(-16);
        make.centerY.equalTo(self.searchOverlay);
    }];

    [self.searchField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.searchOverlay).offset(16);
        make.trailing.equalTo(self.cancelButton.mas_leading).offset(-8);
        make.centerY.equalTo(self.searchOverlay);
        make.height.equalTo(@52);
    }];

    [self.segmentControl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(8);
        make.leading.equalTo(self.view).offset(16);
        make.trailing.equalTo(self.view).offset(-16);
        make.height.equalTo(@38);
    }];

    [self.recentButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.segmentControl).offset(4);
        make.centerY.equalTo(self.segmentControl);
        make.width.equalTo(@190);
    }];

    [self.nearbyButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.recentButton.mas_trailing);
        make.centerY.equalTo(self.segmentControl);
        make.width.equalTo(@190);
    }];

    [self.segmentIndicator mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.segmentControl).offset(4);
        make.top.equalTo(self.segmentControl).offset(4);
        make.bottom.equalTo(self.segmentControl).offset(-4);
        make.width.equalTo(@190);
    }];

    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.segmentControl.mas_bottom).offset(8);
        make.leading.trailing.bottom.equalTo(self.view);
    }];

    [self.loadingIndicator mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.tableView);
    }];

    [self.emptyLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.tableView);
    }];

    [self.nearbyPlaceholder mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.tableView);
    }];

    [self.searchResultsTableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.segmentControl.mas_bottom).offset(8);
        make.leading.trailing.bottom.equalTo(self.view);
    }];

    [self.searchEmptyLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.searchResultsTableView);
    }];
}

#pragma mark - Notifications

- (void)setupNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleUnauthorized)
                                                 name:HYAPIClientUnauthorizedNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleChatRead:)
                                                 name:@"HYChatReadNotification"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleWebSocketMessage:)
                                                 name:HYWebSocketMessageReceivedNotification
                                               object:nil];
}

- (void)handleUnauthorized {
    [self showLoginRequired];
}

- (void)handleChatRead:(NSNotification *)notification {
    [self loadConversations:YES];
}

- (void)handleWebSocketMessage:(NSNotification *)notification {
    [self loadConversations:YES];
}

#pragma mark - Search

- (void)searchButtonTapped {
    self.isSearchActive = YES;
    self.searchOverlay.hidden = NO;
    self.segmentControl.hidden = YES;
    self.tableView.hidden = YES;
    self.searchResultsTableView.hidden = YES;
    self.nearbyPlaceholder.hidden = YES;
    [self.searchField becomeFirstResponder];
}

- (void)cancelSearch {
    self.isSearchActive = NO;
    self.searchOverlay.hidden = YES;
    self.segmentControl.hidden = NO;
    self.searchField.text = @"";
    [self.searchField resignFirstResponder];
    [self.searchResults removeAllObjects];
    [self.searchResultsTableView reloadData];
    self.searchResultsTableView.hidden = YES;

    if (self.currentSegment == 0) {
        self.tableView.hidden = NO;
    } else {
        self.nearbyPlaceholder.hidden = NO;
    }
}

- (void)searchTextChanged:(UITextField *)textField {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(doSearch) object:nil];
    [self performSelector:@selector(doSearch) withObject:nil afterDelay:0.5];
}

- (void)doSearch {
    NSString *keyword = self.searchField.text;
    if (keyword.length == 0) {
        [self.searchResults removeAllObjects];
        [self.searchResultsTableView reloadData];
        self.searchResultsTableView.hidden = YES;
        self.searchEmptyLabel.hidden = YES;
        return;
    }

    [[HYAPIClient shared] searchUsersWithKeyword:keyword completion:^(NSDictionary *response, NSError *error) {
        if (error) return;

        id data = response[@"data"];
        NSArray *usersData = nil;
        if ([data isKindOfClass:[NSDictionary class]]) {
            usersData = data[@"users"];
        } else if ([data isKindOfClass:[NSArray class]]) {
            usersData = data;
        }
        if (![usersData isKindOfClass:[NSArray class]]) {
            usersData = @[];
        }

        [self.searchResults removeAllObjects];
        for (NSDictionary *dict in usersData) {
            HYSearchUser *user = [[HYSearchUser alloc] initWithDictionary:dict];
            [self.searchResults addObject:user];
        }

        self.searchResultsTableView.hidden = NO;
        [self.searchResultsTableView reloadData];
        self.searchEmptyLabel.hidden = (self.searchResults.count > 0);
    }];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    [self doSearch];
    return YES;
}

#pragma mark - Segment

- (void)segmentTapped:(UIButton *)sender {
    if (sender.tag == self.currentSegment) return;
    self.currentSegment = sender.tag;

    [UIView animateWithDuration:0.25 animations:^{
        if (sender.tag == 0) {
            [self.recentButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [self.nearbyButton setTitleColor:[UIColor colorWithRed:0.667 green:0.667 blue:0.667 alpha:1.0] forState:UIControlStateNormal];
            [self.segmentIndicator mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.leading.equalTo(self.segmentControl).offset(4);
                make.top.equalTo(self.segmentControl).offset(4);
                make.bottom.equalTo(self.segmentControl).offset(-4);
                make.width.equalTo(@190);
            }];
            self.tableView.hidden = NO;
            self.nearbyPlaceholder.hidden = YES;
        } else {
            [self.nearbyButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [self.recentButton setTitleColor:[UIColor colorWithRed:0.667 green:0.667 blue:0.667 alpha:1.0] forState:UIControlStateNormal];
            [self.segmentIndicator mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.leading.equalTo(self.recentButton.mas_trailing);
                make.top.equalTo(self.segmentControl).offset(4);
                make.bottom.equalTo(self.segmentControl).offset(-4);
                make.width.equalTo(@190);
            }];
            self.tableView.hidden = YES;
            self.nearbyPlaceholder.hidden = NO;
        }
        [self.view layoutIfNeeded];
    }];
}

#pragma mark - Data Loading

- (void)loadConversations:(BOOL)refresh {
    if (self.isLoading) return;
    self.isLoading = YES;

    if (refresh) {
        self.currentPage = 1;
        [self.loadingIndicator startAnimating];
    }

    [[HYAPIClient shared] getConversationsWithLimit:20 offset:0 completion:^(NSDictionary *response, NSError *error) {
        self.isLoading = NO;
        [self.loadingIndicator stopAnimating];
        [self.tableView.mj_header endRefreshing];
        [self.tableView.mj_footer endRefreshing];

        if (error) {
            NSLog(@"Failed to load conversations: %@", error.localizedDescription);
            return;
        }

        id data = response[@"data"];
        NSArray *convsData = nil;
        if ([data isKindOfClass:[NSArray class]]) {
            convsData = data;
        } else if ([data isKindOfClass:[NSDictionary class]]) {
            convsData = data[@"conversations"];
        }
        if (![convsData isKindOfClass:[NSArray class]]) {
            convsData = @[];
        }

        [self.conversations removeAllObjects];
        for (NSDictionary *dict in convsData) {
            HYConversation *conv = [[HYConversation alloc] initWithDictionary:dict];
            [self.conversations addObject:conv];
        }

        self.hasMore = (convsData.count == 20);
        if (!self.hasMore) {
            [self.tableView.mj_footer endRefreshingWithNoMoreData];
        }

        [self.tableView reloadData];
        self.emptyLabel.hidden = (self.conversations.count > 0);
    }];
}

- (void)pullToRefresh {
    self.currentPage = 1;
    self.hasMore = YES;
    [self loadConversations:YES];
}

- (void)loadMoreData {
    if (self.isLoading || !self.hasMore) {
        [self.tableView.mj_footer endRefreshing];
        return;
    }
    self.currentPage++;
    [self loadConversations:NO];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.searchResultsTableView) {
        return self.searchResults.count;
    }
    return self.conversations.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.searchResultsTableView) {
        HYSearchUserCell *cell = [tableView dequeueReusableCellWithIdentifier:kSearchUserCellId forIndexPath:indexPath];
        HYSearchUser *user = self.searchResults[indexPath.row];
        [cell configWithSearchUser:user];
        return cell;
    }

    HYConversationCell *cell = [tableView dequeueReusableCellWithIdentifier:kConversationCellId forIndexPath:indexPath];
    HYConversation *conv = self.conversations[indexPath.row];
    [cell configWithConversation:conv];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return (tableView != self.searchResultsTableView);
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete && tableView == self.tableView) {
        [self.conversations removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (tableView == self.searchResultsTableView) {
        HYSearchUser *user = self.searchResults[indexPath.row];
        NSString *uid = user.userId.length > 0 ? user.userId : user.uid;
        ChatDetailViewController *vc = [[ChatDetailViewController alloc] initWithPartnerId:uid partnerName:user.name partnerAvatar:user.avatarUrl];
        [self.navigationController pushViewController:vc animated:YES];
    } else {
        HYConversation *conv = self.conversations[indexPath.row];
        ChatDetailViewController *vc = [[ChatDetailViewController alloc] initWithPartnerId:conv.partnerId partnerName:conv.partnerName partnerAvatar:conv.partnerAvatar];
        [self.navigationController pushViewController:vc animated:YES];
    }
}

#pragma mark - Login

- (void)showLoginRequired {
    self.loginRequiredView.hidden = NO;
    self.segmentControl.hidden = YES;
    self.searchOverlay.hidden = YES;
    self.tableView.hidden = YES;
}

- (void)hideLoginRequired {
    self.loginRequiredView.hidden = YES;
    self.segmentControl.hidden = NO;
    self.tableView.hidden = NO;
}

@end
