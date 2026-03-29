#import "MessagesViewController.h"
#import "HYAPIClient.h"
#import "HYModels.h"
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

@interface MessagesViewController () <UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate>

@property (nonatomic, strong) UIView *segmentControl;
@property (nonatomic, strong) UIButton *recentButton;
@property (nonatomic, strong) UIButton *nearbyButton;
@property (nonatomic, strong) UIView *segmentIndicator;
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) UIView *searchContainer;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UITableView *searchResultsTableView;
@property (nonatomic, strong) UIActivityIndicatorView *loadingIndicator;
@property (nonatomic, strong) UILabel *emptyLabel;
@property (nonatomic, strong) UILabel *nearbyPlaceholder;

@property (nonatomic, strong) NSMutableArray<HYConversation *> *conversations;
@property (nonatomic, strong) NSMutableArray<HYSearchUser *> *searchResults;
@property (nonatomic, assign) NSInteger currentPage;
@property (nonatomic, assign) BOOL hasMore;
@property (nonatomic, assign) BOOL isLoading;
@property (nonatomic, assign) BOOL isSearching;
@property (nonatomic, assign) NSInteger currentSegment; // 0 = recent, 1 = nearby

@property (nonatomic, strong) HYLoginRequiredView *loginRequiredView;

@end

@implementation MessagesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"消息";
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    self.conversations = [NSMutableArray array];
    self.searchResults = [NSMutableArray array];
    self.currentPage = 1;
    self.hasMore = YES;
    self.currentSegment = 0;
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

- (void)setupUI {
    [self setupSegmentControl];
    [self setupSearchBar];
    [self setupTableView];
    [self setupLoginRequired];
    [self setupConstraints];
}

- (void)setupSegmentControl {
    self.segmentControl = [[UIView alloc] init];
    self.segmentControl.backgroundColor = [UIColor secondarySystemBackgroundColor];
    [self.view addSubview:self.segmentControl];

    self.recentButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.recentButton setTitle:@"最近聊天" forState:UIControlStateNormal];
    self.recentButton.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    [self.recentButton setTitleColor:[UIColor systemPinkColor] forState:UIControlStateNormal];
    [self.recentButton addTarget:self action:@selector(segmentTapped:) forControlEvents:UIControlEventTouchUpInside];
    self.recentButton.tag = 0;
    [self.segmentControl addSubview:self.recentButton];

    self.nearbyButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.nearbyButton setTitle:@"附近" forState:UIControlStateNormal];
    self.nearbyButton.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    [self.nearbyButton setTitleColor:[UIColor secondaryLabelColor] forState:UIControlStateNormal];
    [self.nearbyButton addTarget:self action:@selector(segmentTapped:) forControlEvents:UIControlEventTouchUpInside];
    self.nearbyButton.tag = 1;
    [self.segmentControl addSubview:self.nearbyButton];

    self.segmentIndicator = [[UIView alloc] init];
    self.segmentIndicator.backgroundColor = [UIColor systemPinkColor];
    self.segmentIndicator.layer.cornerRadius = 1.5;
    [self.segmentControl addSubview:self.segmentIndicator];
}

- (void)setupSearchBar {
    self.searchContainer = [[UIView alloc] init];
    self.searchContainer.backgroundColor = [UIColor secondarySystemBackgroundColor];
    [self.view addSubview:self.searchContainer];

    self.searchBar = [[UISearchBar alloc] init];
    self.searchBar.placeholder = @"搜索用户ID或昵称";
    self.searchBar.delegate = self;
    self.searchBar.searchBarStyle = UISearchBarStyleMinimal;
    self.searchBar.backgroundColor = [UIColor clearColor];
    [self.searchContainer addSubview:self.searchBar];

    self.searchResultsTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.searchResultsTableView.delegate = self;
    self.searchResultsTableView.dataSource = self;
    self.searchResultsTableView.hidden = YES;
    self.searchResultsTableView.backgroundColor = [UIColor systemBackgroundColor];
    self.searchResultsTableView.rowHeight = 60;
    [self.searchResultsTableView registerClass:[HYSearchUserCell class] forCellReuseIdentifier:kSearchUserCellId];
    [self.view addSubview:self.searchResultsTableView];
}

- (void)setupTableView {
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.rowHeight = 80;
    self.tableView.backgroundColor = [UIColor systemBackgroundColor];
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 84, 0, 0);
    [self.tableView registerClass:[HYConversationCell class] forCellReuseIdentifier:kConversationCellId];
    [self.view addSubview:self.tableView];

    self.tableView.mj_header = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(pullToRefresh)];
    self.tableView.mj_footer = [MJRefreshAutoNormalFooter footerWithRefreshingTarget:self refreshingAction:@selector(loadMoreData)];

    self.loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    self.loadingIndicator.color = [UIColor systemPinkColor];
    self.loadingIndicator.hidesWhenStopped = YES;
    [self.view addSubview:self.loadingIndicator];

    self.emptyLabel = [[UILabel alloc] init];
    self.emptyLabel.text = @"暂无消息";
    self.emptyLabel.font = [UIFont systemFontOfSize:15];
    self.emptyLabel.textColor = [UIColor secondaryLabelColor];
    self.emptyLabel.textAlignment = NSTextAlignmentCenter;
    self.emptyLabel.hidden = YES;
    [self.tableView addSubview:self.emptyLabel];

    self.nearbyPlaceholder = [[UILabel alloc] init];
    self.nearbyPlaceholder.text = @"功能开发中";
    self.nearbyPlaceholder.font = [UIFont systemFontOfSize:15];
    self.nearbyPlaceholder.textColor = [UIColor secondaryLabelColor];
    self.nearbyPlaceholder.textAlignment = NSTextAlignmentCenter;
    self.nearbyPlaceholder.hidden = YES;
    [self.tableView addSubview:self.nearbyPlaceholder];
}

- (void)setupLoginRequired {
    self.loginRequiredView = [[HYLoginRequiredView alloc] init];
    self.loginRequiredView.tipText = @"登录后可以看到消息";
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
    [self.segmentControl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
        make.leading.trailing.equalTo(self.view);
        make.height.equalTo(@44);
    }];

    [self.recentButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.segmentControl).offset(60);
        make.centerY.equalTo(self.segmentControl);
    }];

    [self.nearbyButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.recentButton.mas_trailing).offset(40);
        make.centerY.equalTo(self.segmentControl);
    }];

    [self.segmentIndicator mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.recentButton);
        make.bottom.equalTo(self.segmentControl).offset(-4);
        make.width.equalTo(@40);
        make.height.equalTo(@3);
    }];

    [self.searchContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.segmentControl.mas_bottom);
        make.leading.trailing.equalTo(self.view);
        make.height.equalTo(@50);
    }];

    [self.searchBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.searchContainer).insets(UIEdgeInsetsMake(4, 8, 4, 8));
    }];

    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.searchContainer.mas_bottom);
        make.leading.trailing.bottom.equalTo(self.view);
    }];

    [self.searchResultsTableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.searchContainer.mas_bottom);
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

#pragma mark - Segment

- (void)segmentTapped:(UIButton *)sender {
    if (sender.tag == self.currentSegment) return;
    self.currentSegment = sender.tag;

    [UIView animateWithDuration:0.25 animations:^{
        if (sender.tag == 0) {
            [self.recentButton setTitleColor:[UIColor systemPinkColor] forState:UIControlStateNormal];
            [self.nearbyButton setTitleColor:[UIColor secondaryLabelColor] forState:UIControlStateNormal];
            [self.segmentIndicator mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.centerX.equalTo(self.recentButton);
                make.bottom.equalTo(self.segmentControl).offset(-4);
                make.width.equalTo(@40);
                make.height.equalTo(@3);
            }];
            self.tableView.hidden = NO;
            self.nearbyPlaceholder.hidden = YES;
            self.searchContainer.hidden = NO;
            self.searchResultsTableView.hidden = YES;
        } else {
            [self.nearbyButton setTitleColor:[UIColor systemPinkColor] forState:UIControlStateNormal];
            [self.recentButton setTitleColor:[UIColor secondaryLabelColor] forState:UIControlStateNormal];
            [self.segmentIndicator mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.centerX.equalTo(self.nearbyButton);
                make.bottom.equalTo(self.segmentControl).offset(-4);
                make.width.equalTo(@40);
                make.height.equalTo(@3);
            }];
            self.tableView.hidden = YES;
            self.nearbyPlaceholder.hidden = NO;
            self.searchContainer.hidden = YES;
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

- (void)searchUsers:(NSString *)keyword {
    if (keyword.length == 0) {
        [self.searchResults removeAllObjects];
        self.searchResultsTableView.hidden = YES;
        self.tableView.hidden = NO;
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
        self.tableView.hidden = YES;
        [self.searchResultsTableView reloadData];
    }];
}

#pragma mark - UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if (self.currentSegment != 0) return;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(doSearch) object:nil];
    [self performSelector:@selector(doSearch) withObject:nil afterDelay:0.5];
}

- (void)doSearch {
    [self searchUsers:self.searchBar.text];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
    [self searchUsers:searchBar.text];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    searchBar.text = @"";
    [searchBar resignFirstResponder];
    self.searchResultsTableView.hidden = YES;
    self.tableView.hidden = NO;
    [self.searchResults removeAllObjects];
    [self.searchResultsTableView reloadData];
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
    cell.conversationIndex = indexPath.row;
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
    self.searchContainer.hidden = YES;
    self.tableView.hidden = YES;
}

- (void)hideLoginRequired {
    self.loginRequiredView.hidden = YES;
    self.segmentControl.hidden = NO;
    self.searchContainer.hidden = NO;
    self.tableView.hidden = NO;
}

@end
