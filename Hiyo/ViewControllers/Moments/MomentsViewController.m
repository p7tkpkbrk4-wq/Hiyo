#import "MomentsViewController.h"
#import "HYAPIClient.h"
#import "HYModels.h"
#import "HYPostCell.h"
#import "HYLoginRequiredView.h"
#import "CreatePostViewController.h"
#import "PostDetailViewController.h"
#import "NotificationsViewController.h"
#import "UserProfileViewController.h"
#import "HYColors.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/SDWebImage.h>
#import <MJRefresh/MJRefresh.h>

static NSString * const kPostCellIdentifier = @"HYPostCell";

@interface MomentsViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray<HYPost *> *posts;
@property (nonatomic, strong) UIButton *createPostButton;
@property (nonatomic, strong) UIActivityIndicatorView *loadingIndicator;
@property (nonatomic, strong) UILabel *emptyLabel;
@property (nonatomic, assign) NSInteger currentPage;
@property (nonatomic, assign) BOOL hasMore;
@property (nonatomic, assign) BOOL isLoading;
@property (nonatomic, strong) HYLoginRequiredView *loginRequiredView;

// Notification badge
@property (nonatomic, strong) UIButton *notificationButton;
@property (nonatomic, strong) UILabel *badgeLabel;

@end

@implementation MomentsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"动态广场";
    self.view.backgroundColor = LightBg1;
    self.posts = [NSMutableArray array];
    self.currentPage = 1;
    self.hasMore = YES;
    [self setupNavigationBar];
    [self setupUI];
    [self setupNotifications];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if ([HYAPIClient shared].isLoggedIn) {
        [self hideLoginRequired];
        if (self.posts.count == 0) {
            [self loadData:YES];
        } else {
            [self loadData:NO]; // Refresh to check for new posts
        }
        [self checkUnreadCount];
    } else {
        [self showLoginRequired];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Setup

- (void)setupNavigationBar {
    self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
    self.navigationController.navigationBar.tintColor = PinkGradStart;
    self.navigationController.navigationBar.titleTextAttributes = @{
        NSForegroundColorAttributeName: [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0],
        NSFontAttributeName: [UIFont systemFontOfSize:18 weight:UIFontWeightBlack]
    };
    if (@available(iOS 15.0, *)) {
        UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
        [appearance configureWithOpaqueBackground];
        appearance.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.9];
        appearance.titleTextAttributes = @{
            NSForegroundColorAttributeName: [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0],
            NSFontAttributeName: [UIFont systemFontOfSize:18 weight:UIFontWeightBlack]
        };
        appearance.shadowColor = [UIColor colorWithRed:0.933 green:0.933 blue:1.0 alpha:1.0];
        self.navigationController.navigationBar.standardAppearance = appearance;
        self.navigationController.navigationBar.scrollEdgeAppearance = appearance;
    }

    // Right: notification bell with pink circle background
    UIView *bellWrapper = [[UIView alloc] init];
    bellWrapper.backgroundColor = [UIColor colorWithRed:1.0 green:0.94 blue:0.96 alpha:1.0];
    bellWrapper.layer.cornerRadius = 18;

    self.notificationButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.notificationButton setImage:[UIImage systemImageNamed:@"bell"] forState:UIControlStateNormal];
    self.notificationButton.tintColor = PinkGradStart;
    self.notificationButton.frame = CGRectMake(0, 0, 36, 36);
    [self.notificationButton addTarget:self action:@selector(notificationButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [bellWrapper addSubview:self.notificationButton];

    // Badge
    self.badgeLabel = [[UILabel alloc] init];
    self.badgeLabel.backgroundColor = PinkGradStart;
    self.badgeLabel.textColor = [UIColor whiteColor];
    self.badgeLabel.font = [UIFont systemFontOfSize:9 weight:UIFontWeightBold];
    self.badgeLabel.textAlignment = NSTextAlignmentCenter;
    self.badgeLabel.layer.cornerRadius = 8;
    self.badgeLabel.clipsToBounds = YES;
    self.badgeLabel.hidden = YES;
    [bellWrapper addSubview:self.badgeLabel];

    [self.badgeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(bellWrapper).offset(-2);
        make.trailing.equalTo(bellWrapper).offset(2);
        make.width.height.equalTo(@16);
    }];

    [bellWrapper mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.equalTo(@36);
    }];

    UIBarButtonItem *notificationItem = [[UIBarButtonItem alloc] initWithCustomView:bellWrapper];
    self.navigationItem.rightBarButtonItem = notificationItem;
}

- (void)setupUI {
    // Login required view
    self.loginRequiredView = [[HYLoginRequiredView alloc] init];
    self.loginRequiredView.tipText = @"登录后可以看到动态";
    self.loginRequiredView.backgroundColor = LightBg1;
    [self.loginRequiredView setLoginButtonTitle:@"去登录"];
    __weak typeof(self) weakSelf = self;
    self.loginRequiredView.onLoginTapped = ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"HYNeedLoginNotification" object:nil];
    };
    self.loginRequiredView.hidden = YES;
    [self.view addSubview:self.loginRequiredView];

    // Table View
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.contentInset = UIEdgeInsetsMake(8, 0, 100, 0);
    [self.tableView registerClass:[HYPostCell class] forCellReuseIdentifier:kPostCellIdentifier];
    [self.view addSubview:self.tableView];

    // MJRefresh header
    MJRefreshNormalHeader *header = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(pullToRefresh)];
    header.stateLabel.hidden = YES;
    header.lastUpdatedTimeLabel.hidden = YES;
    [header setTitle:@"" forState:MJRefreshStateIdle];
    [header setTitle:@"" forState:MJRefreshStatePulling];
    [header setTitle:@"" forState:MJRefreshStateRefreshing];
    header.arrowView.hidden = YES;
    self.tableView.mj_header = header;
    self.tableView.mj_footer = [MJRefreshAutoNormalFooter footerWithRefreshingTarget:self refreshingAction:@selector(loadMoreData)];
    self.tableView.mj_footer.hidden = YES;

    // Empty label
    self.emptyLabel = [[UILabel alloc] init];
    self.emptyLabel.text = @"暂无动态\n快来发布第一条动态吧";
    self.emptyLabel.font = [UIFont systemFontOfSize:15];
    self.emptyLabel.textColor = [UIColor colorWithRed:0.6 green:0.6 blue:0.6 alpha:1.0];
    self.emptyLabel.textAlignment = NSTextAlignmentCenter;
    self.emptyLabel.numberOfLines = 0;
    self.emptyLabel.hidden = YES;
    [self.view addSubview:self.emptyLabel];

    // Loading indicator
    self.loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    self.loadingIndicator.color = PinkGradStart;
    self.loadingIndicator.hidesWhenStopped = YES;
    [self.view addSubview:self.loadingIndicator];

    // Create Post FAB - pink gradient (horizontal)
    self.createPostButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.createPostButton.frame = CGRectMake(0, 0, 60, 60);

    CAGradientLayer *fabGrad = [CAGradientLayer layer];
    fabGrad.colors = @[(id)PinkGradStart.CGColor, (id)PinkGradEnd.CGColor];
    fabGrad.startPoint = CGPointMake(0, 0.5);
    fabGrad.endPoint = CGPointMake(1, 0.5);
    fabGrad.cornerRadius = 30;
    fabGrad.frame = self.createPostButton.bounds;
    [self.createPostButton.layer insertSublayer:fabGrad atIndex:0];

    self.createPostButton.layer.shadowColor = PinkGradStart.CGColor;
    self.createPostButton.layer.shadowOffset = CGSizeMake(0, 4);
    self.createPostButton.layer.shadowRadius = 10;
    self.createPostButton.layer.shadowOpacity = 0.4;

    [self.createPostButton setTitle:@"+" forState:UIControlStateNormal];
    [self.createPostButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.createPostButton.titleLabel.font = [UIFont systemFontOfSize:28 weight:UIFontWeightMedium];
    [self.createPostButton addTarget:self action:@selector(createPostTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.createPostButton];

    [self setupConstraints];
}

- (void)setupConstraints {
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];

    [self.loadingIndicator mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);
    }];

    [self.createPostButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(self.view).offset(-20);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-20);
        make.width.height.equalTo(@60);
    }];

    [self.loginRequiredView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];

    [self.emptyLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);
        make.leading.trailing.equalTo(self.view).inset(40);
    }];
}

- (void)setupNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleUnauthorized)
                                                 name:HYAPIClientUnauthorizedNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handlePostCreated:)
                                                 name:@"HYPostCreatedNotification"
                                               object:nil];
}

#pragma mark - Data Loading

- (void)loadData:(BOOL)refresh {
    if (self.isLoading) return;
    self.isLoading = YES;

    if (refresh) {
        self.currentPage = 1;
        [self.loadingIndicator startAnimating];
    }

    [[HYAPIClient shared] getPostsWithPage:self.currentPage pageSize:10 completion:^(NSDictionary *response, NSError *error) {
        self.isLoading = NO;
        [self.loadingIndicator stopAnimating];
        [self.tableView.mj_header endRefreshing];
        [self.tableView.mj_footer endRefreshing];

        if (error) {
            NSLog(@"Failed to load posts: %@", error.localizedDescription);
            if (self.posts.count == 0) {
                [self showError:error.localizedDescription];
            }
            return;
        }

        NSDictionary *dataDict = response[@"data"];
        NSArray *data = @[];
        if ([dataDict isKindOfClass:[NSDictionary class]]) {
            data = dataDict[@"posts"];
            if (![data isKindOfClass:[NSArray class]]) {
                data = @[];
            }
        }

        if (refresh) {
            [self.posts removeAllObjects];
        }
        for (NSDictionary *dict in data) {
            HYPost *post = [[HYPost alloc] initWithDictionary:dict];
            [self.posts addObject:post];
        }

        NSDictionary *pagination = dataDict[@"pagination"];
        NSInteger pageSize = [pagination[@"page_size"] integerValue];
        self.hasMore = (data.count == pageSize && data.count > 0);
        if (!self.hasMore) {
            [self.tableView.mj_footer endRefreshingWithNoMoreData];
        }

        [self.tableView reloadData];
        self.emptyLabel.hidden = (self.posts.count > 0);
    }];
}

- (void)pullToRefresh {
    self.currentPage = 1;
    self.hasMore = YES;
    [self loadData:YES];
}

- (void)loadMoreData {
    if (self.isLoading || !self.hasMore) {
        [self.tableView.mj_footer endRefreshing];
        return;
    }

    // 提前2张卡片加载更多
    NSInteger threshold = self.posts.count > 2 ? self.posts.count - 2 : 0;
    if (self.tableView.contentOffset.y < 0) {
        [self.tableView.mj_footer endRefreshing];
        return;
    }

    self.currentPage++;
    self.isLoading = YES;

    [[HYAPIClient shared] getPostsWithPage:self.currentPage pageSize:10 completion:^(NSDictionary *response, NSError *error) {
        self.isLoading = NO;

        if (error) {
            self.currentPage--;
            [self.tableView.mj_footer endRefreshing];
            return;
        }

        NSDictionary *dataDict = response[@"data"];
        NSArray *data = @[];
        if ([dataDict isKindOfClass:[NSDictionary class]]) {
            data = dataDict[@"posts"];
            if (![data isKindOfClass:[NSArray class]]) {
                data = @[];
            }
        }

        for (NSDictionary *dict in data) {
            HYPost *post = [[HYPost alloc] initWithDictionary:dict];
            [self.posts addObject:post];
        }

        NSDictionary *pagination = dataDict[@"pagination"];
        NSInteger pageSize = [pagination[@"page_size"] integerValue];
        self.hasMore = (data.count == pageSize && data.count > 0);
        if (!self.hasMore) {
            [self.tableView.mj_footer endRefreshingWithNoMoreData];
        } else {
            [self.tableView.mj_footer endRefreshing];
        }

        [self.tableView reloadData];
    }];
}

- (void)checkUnreadCount {
    [[HYAPIClient shared] getUnreadCountWithCompletion:^(NSDictionary *response, NSError *error) {
        if (error) return;
        NSInteger count = 0;
        NSDictionary *data = response[@"data"];
        if ([data isKindOfClass:[NSDictionary class]]) {
            count = [data[@"count"] integerValue];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            self.badgeLabel.hidden = (count == 0);
            if (count > 99) {
                self.badgeLabel.text = @"99+";
            } else if (count > 0) {
                self.badgeLabel.text = [NSString stringWithFormat:@"%ld", (long)count];
            }
        });
    }];
}

- (void)showError:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"加载失败" message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"重试" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self loadData:YES];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Login

- (void)showLoginRequired {
    self.loginRequiredView.hidden = NO;
    self.tableView.hidden = YES;
    self.createPostButton.hidden = YES;
}

- (void)hideLoginRequired {
    self.loginRequiredView.hidden = YES;
    self.tableView.hidden = NO;
    self.createPostButton.hidden = NO;
}

- (void)handleUnauthorized {
    [self showLoginRequired];
}

#pragma mark - Actions

- (void)createPostTapped {
    if (![HYAPIClient shared].isLoggedIn) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"HYNeedLoginNotification" object:nil];
        return;
    }
    CreatePostViewController *vc = [[CreatePostViewController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)notificationButtonTapped {
    if (![HYAPIClient shared].isLoggedIn) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"HYNeedLoginNotification" object:nil];
        return;
    }
    NotificationsViewController *vc = [[NotificationsViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)handlePostCreated:(NSNotification *)notification {
    [self loadData:YES];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.posts.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    HYPostCell *cell = [tableView dequeueReusableCellWithIdentifier:kPostCellIdentifier forIndexPath:indexPath];
    HYPost *post = self.posts[indexPath.row];
    [cell configWithPost:post];

    __weak typeof(self) weakSelf = self;
    cell.onLikeTapped = ^(HYPost *likedPost) {
        [weakSelf toggleLikeForPost:likedPost atIndex:indexPath.row];
    };
    cell.onCommentTapped = ^(HYPost *commentedPost) {
        [weakSelf showPostDetail:commentedPost];
    };
    cell.onAvatarTapped = ^(HYPost *tappedPost) {
        NSString *uid = [NSString stringWithFormat:@"%ld", (long)tappedPost.userId];
        UserProfileViewController *vc = [[UserProfileViewController alloc] initWithUserId:uid];
        [weakSelf.navigationController pushViewController:vc animated:YES];
    };

    return cell;
}

- (void)toggleLikeForPost:(HYPost *)post atIndex:(NSInteger)index {
    NSInteger postId = post.postId;
    BOOL currentLike = post.isLiked;

    // Optimistic update
    HYPost *targetPost = self.posts[index];
    targetPost.isLiked = !currentLike;
    targetPost.likesCount = currentLike ? targetPost.likesCount - 1 : targetPost.likesCount + 1;

    // Update cell
    HYPostCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
    [cell updateLikeState:targetPost.isLiked likesCount:targetPost.likesCount];

    __weak typeof(self) weakSelf = self;
    [[HYAPIClient shared] likePostWithId:postId completion:^(NSDictionary *response, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        if (error) {
            // Revert on error
            targetPost.isLiked = currentLike;
            targetPost.likesCount = currentLike ? targetPost.likesCount + 1 : targetPost.likesCount - 1;
            dispatch_async(dispatch_get_main_queue(), ^{
                HYPostCell *cell = [strongSelf.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
                [cell updateLikeState:currentLike likesCount:targetPost.likesCount];
            });
        } else {
            // Update with server response
            NSDictionary *data = response[@"data"];
            if ([data isKindOfClass:[NSDictionary class]]) {
                BOOL isLiked = [data[@"is_liked"] boolValue];
                NSInteger likesCount = [data[@"likes_count"] integerValue];
                targetPost.isLiked = isLiked;
                targetPost.likesCount = likesCount;
                dispatch_async(dispatch_get_main_queue(), ^{
                    HYPostCell *cell = [strongSelf.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
                    [cell updateLikeState:isLiked likesCount:likesCount];
                });
            }
        }
    }];
}

- (void)showPostDetail:(HYPost *)post {
    PostDetailViewController *vc = [[PostDetailViewController alloc] initWithPostId:post.postId];
    vc.onPostDeleted = ^{
        NSInteger index = [self.posts indexOfObject:post];
        if (index != NSNotFound) {
            [self.posts removeObjectAtIndex:index];
            [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    };
    vc.onPostUpdated = ^(HYPost *updatedPost) {
        NSInteger index = [self.posts indexOfObjectPassingTest:^BOOL(HYPost *p, NSUInteger idx, BOOL *stop) {
            return p.postId == updatedPost.postId;
        }];
        if (index != NSNotFound) {
            self.posts[index] = updatedPost;
            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
        }
    };
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    HYPost *post = self.posts[indexPath.row];
    [self showPostDetail:post];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    // Check if we need to load more when approaching end
    CGFloat offsetY = scrollView.contentOffset.y;
    CGFloat contentHeight = scrollView.contentSize.height;
    CGFloat screenHeight = scrollView.frame.size.height;

    if (offsetY > contentHeight - screenHeight - 200 && !self.isLoading && self.hasMore) {
        [self loadMoreData];
    }
}

@end
