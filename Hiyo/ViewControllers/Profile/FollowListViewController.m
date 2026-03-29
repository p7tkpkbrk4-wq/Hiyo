#import "FollowListViewController.h"
#import "HYAPIClient.h"
#import "HYFollowUser.h"
#import "UserProfileViewController.h"
#import "HYLoginRequiredView.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/SDWebImage.h>
#import <MJRefresh/MJRefresh.h>

static NSString *const kFollowCellId = @"FollowCell";

@interface FollowUserCell : UITableViewCell

@property (nonatomic, strong) UIImageView *avatarView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *signatureLabel;
@property (nonatomic, strong) UIButton *followButton;

@end

@implementation FollowUserCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:0.11 green:0.11 blue:0.18 alpha:1.0];
        self.selectionStyle = UITableViewCellSelectionStyleNone;

        self.avatarView = [[UIImageView alloc] init];
        self.avatarView.contentMode = UIViewContentModeScaleAspectFill;
        self.avatarView.layer.cornerRadius = 25;
        self.avatarView.clipsToBounds = YES;
        self.avatarView.backgroundColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.3 alpha:1.0];
        [self.contentView addSubview:self.avatarView];

        self.nameLabel = [[UILabel alloc] init];
        self.nameLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
        self.nameLabel.textColor = [UIColor whiteColor];
        [self.contentView addSubview:self.nameLabel];

        self.signatureLabel = [[UILabel alloc] init];
        self.signatureLabel.font = [UIFont systemFontOfSize:13];
        self.signatureLabel.textColor = [UIColor systemGrayColor];
        self.signatureLabel.numberOfLines = 1;
        [self.contentView addSubview:self.signatureLabel];

        self.followButton = [UIButton buttonWithType:UIButtonTypeSystem];
        self.followButton.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
        self.followButton.layer.cornerRadius = 14;
        self.followButton.layer.borderWidth = 1;
        [self.contentView addSubview:self.followButton];
    }
    return self;
}

- (void)configureWithUser:(HYFollowUser *)user isLoggedIn:(BOOL)loggedIn {
    self.nameLabel.text = user.name;
    self.signatureLabel.text = user.signature ?: @"";
    if (user.avatarUrl.length > 0) {
        [self.avatarView sd_setImageWithURL:[NSURL URLWithString:user.avatarUrl]];
    } else {
        self.avatarView.image = [UIImage systemImageNamed:@"person.circle.fill"];
        self.avatarView.tintColor = [UIColor systemGrayColor];
    }

    if (!loggedIn) {
        [self.followButton setTitle:@"关注" forState:UIControlStateNormal];
        [self.followButton setTitleColor:[UIColor systemGrayColor] forState:UIControlStateNormal];
        self.followButton.layer.borderColor = [UIColor systemGrayColor].CGColor;
        self.followButton.backgroundColor = [UIColor clearColor];
    } else if (user.isFollowing) {
        [self.followButton setTitle:@"已关注" forState:UIControlStateNormal];
        [self.followButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        self.followButton.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.3].CGColor;
        self.followButton.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.1];
    } else {
        [self.followButton setTitle:@"关注" forState:UIControlStateNormal];
        [self.followButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        self.followButton.layer.borderColor = [UIColor systemPinkColor].CGColor;
        self.followButton.backgroundColor = [UIColor systemPinkColor];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];

    self.avatarView.frame = CGRectMake(16, (self.contentView.bounds.size.height - 50) / 2, 50, 50);
    self.nameLabel.frame = CGRectMake(78, self.avatarView.frame.origin.y, 120, 22);
    self.signatureLabel.frame = CGRectMake(78, CGRectGetMaxY(self.nameLabel.frame) + 2, self.contentView.bounds.size.width - 160, 18);

    CGSize btnSize = CGSizeMake(60, 28);
    self.followButton.frame = CGRectMake(self.contentView.bounds.size.width - 16 - btnSize.width,
                                        (self.contentView.bounds.size.height - btnSize.height) / 2,
                                        btnSize.width, btnSize.height);
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.avatarView.image = nil;
    self.nameLabel.text = nil;
    self.signatureLabel.text = nil;
}

@end

@interface FollowListViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, copy) NSString *userId;
@property (nonatomic, assign) HYFollowListType listType;
@property (nonatomic, copy) NSString *userName;

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray<HYFollowUser *> *users;
@property (nonatomic, copy) NSString *lastId;
@property (nonatomic, assign) BOOL hasMore;
@property (nonatomic, assign) BOOL isLoading;
@property (nonatomic, strong) HYLoginRequiredView *loginRequiredView;
@property (nonatomic, strong) UIActivityIndicatorView *footerLoading;

@end

@implementation FollowListViewController

- (instancetype)initWithUserId:(NSString *)userId type:(HYFollowListType)type userName:(NSString *)userName {
    self = [super init];
    if (self) {
        _userId = userId;
        _listType = type;
        _userName = userName;
        _users = [NSMutableArray array];
        _hasMore = YES;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithRed:0.04 green:0.04 blue:0.08 alpha:1.0];
    self.title = self.userName ?: (self.listType == HYFollowListTypeFollowers ? @"粉丝" : @"关注");
    [self setupUI];
    [self setupConstraints];
    [self loadData];
}

- (void)setupUI {
    if (![[HYAPIClient shared] isLoggedIn]) {
        self.loginRequiredView = [[HYLoginRequiredView alloc] init];
        self.loginRequiredView.tipText = @"登录后可以查看";
        [self.loginRequiredView setLoginButtonTitle:@"去登录"];
        __weak typeof(self) weakSelf = self;
        self.loginRequiredView.onLoginTapped = ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:@"HYNeedLoginNotification" object:nil];
        };
        [self.view addSubview:self.loginRequiredView];
    } else {
        self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        self.tableView.delegate = self;
        self.tableView.dataSource = self;
        self.tableView.backgroundColor = [UIColor clearColor];
        self.tableView.separatorColor = [[UIColor whiteColor] colorWithAlphaComponent:0.05];
        [self.tableView registerClass:[FollowUserCell class] forCellReuseIdentifier:kFollowCellId];
        [self.view addSubview:self.tableView];

        self.tableView.mj_header = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
            [self refreshData];
        }];

        self.footerLoading = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
        self.footerLoading.color = [UIColor systemGrayColor];
        self.footerLoading.frame = CGRectMake(0, 0, self.view.bounds.size.width, 44);
        self.tableView.tableFooterView = self.footerLoading;
    }
}

- (void)setupConstraints {
    if (![[HYAPIClient shared] isLoggedIn]) {
        [self.loginRequiredView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.view);
        }];
    } else {
        [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.view);
        }];
    }
}

- (void)refreshData {
    self.lastId = nil;
    self.hasMore = YES;
    [self loadData];
}

- (void)loadData {
    if (self.isLoading || !self.hasMore) return;
    self.isLoading = YES;

    __weak typeof(self) weakSelf = self;

    void (^done)(NSArray<HYFollowUser *> *, NSError *) = ^(NSArray<HYFollowUser *> *users, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) return;

            strongSelf.isLoading = NO;
            [strongSelf.tableView.mj_header endRefreshing];
            [strongSelf.footerLoading stopAnimating];

            if (error) {
                NSLog(@"Load follow list error: %@", error.localizedDescription);
                return;
            }

            if (strongSelf.lastId == nil) {
                [strongSelf.users removeAllObjects];
            }
            [strongSelf.users addObjectsFromArray:users];

            if (users.count < 20) {
                strongSelf.hasMore = NO;
            } else if (users.count > 0) {
                strongSelf.lastId = [NSString stringWithFormat:@"%@", @(((HYFollowUser *)users.lastObject).followId)];
            }

            [strongSelf.tableView reloadData];
        });
    };

    NSInteger lastIdVal = self.lastId ? [self.lastId integerValue] : 0;
    if (self.listType == HYFollowListTypeFollowers) {
        [[HYAPIClient shared] getFollowersWithUserId:self.userId limit:20 lastId:lastIdVal completion:^(NSDictionary *response, NSError *error) {
            NSMutableArray *arr = [NSMutableArray array];
            id data = response[@"data"];
            if ([data isKindOfClass:[NSArray class]]) {
                for (NSDictionary *dict in data) {
                    if ([dict isKindOfClass:[NSDictionary class]]) {
                        [arr addObject:[[HYFollowUser alloc] initWithDictionary:dict]];
                    }
                }
            }
            done(arr, error);
        }];
    } else {
        [[HYAPIClient shared] getFollowingsWithUserId:self.userId limit:20 lastId:lastIdVal completion:^(NSDictionary *response, NSError *error) {
            NSMutableArray *arr = [NSMutableArray array];
            id data = response[@"data"];
            if ([data isKindOfClass:[NSArray class]]) {
                for (NSDictionary *dict in data) {
                    if ([dict isKindOfClass:[NSDictionary class]]) {
                        [arr addObject:[[HYFollowUser alloc] initWithDictionary:dict]];
                    }
                }
            }
            done(arr, error);
        }];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.users.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    FollowUserCell *cell = [tableView dequeueReusableCellWithIdentifier:kFollowCellId forIndexPath:indexPath];
    HYFollowUser *user = self.users[indexPath.row];
    [cell configureWithUser:user isLoggedIn:[[HYAPIClient shared] isLoggedIn]];

    cell.followButton.tag = indexPath.row;
    [cell.followButton addTarget:self action:@selector(followButtonTapped:) forControlEvents:UIControlEventTouchUpInside];

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 70;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    HYFollowUser *user = self.users[indexPath.row];
    UserProfileViewController *vc = [[UserProfileViewController alloc] initWithUserId:user.userId];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == self.users.count - 1 && self.hasMore && !self.isLoading) {
        [self.footerLoading startAnimating];
        [self loadData];
    }
}

- (void)followButtonTapped:(UIButton *)sender {
    if (![[HYAPIClient shared] isLoggedIn]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"HYNeedLoginNotification" object:nil];
        return;
    }

    NSInteger row = sender.tag;
    if (row >= self.users.count) return;
    HYFollowUser *user = self.users[row];

    BOOL willFollow = !user.isFollowing;
    user.isFollowing = willFollow;

    FollowUserCell *cell = (FollowUserCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];
    [cell configureWithUser:user isLoggedIn:YES];

    __weak typeof(self) weakSelf = self;
    void (^completion)(NSDictionary *, NSError *) = ^(NSDictionary *response, NSError *error) {
        if (error) {
            user.isFollowing = !willFollow;
            dispatch_async(dispatch_get_main_queue(), ^{
                FollowUserCell *cell = (FollowUserCell *)[weakSelf.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];
                [cell configureWithUser:user isLoggedIn:YES];
            });
        }
    };

    if (willFollow) {
        [[HYAPIClient shared] followUserWithId:user.userId completion:completion];
    } else {
        [[HYAPIClient shared] unfollowUserWithId:user.userId completion:completion];
    }
}

@end
