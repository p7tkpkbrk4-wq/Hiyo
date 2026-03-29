#import "FavoritesViewController.h"
#import "HYAPIClient.h"
#import "HYUser.h"
#import "UserProfileViewController.h"
#import "ChatDetailViewController.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/SDWebImage.h>
#import <MJRefresh/MJRefresh.h>

static NSString *const kFavoriteCellId = @"FavoriteCell";

@interface HYFavoriteCell : UITableViewCell

@property (nonatomic, strong) UIImageView *avatarView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *bioLabel;
@property (nonatomic, strong) UIButton *chatButton;
@property (nonatomic, strong) UIButton *profileButton;

@end

@implementation HYFavoriteCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:0.11 green:0.11 blue:0.18 alpha:1.0];
        self.selectionStyle = UITableViewCellSelectionStyleNone;

        self.avatarView = [[UIImageView alloc] init];
        self.avatarView.contentMode = UIViewContentModeScaleAspectFill;
        self.avatarView.layer.cornerRadius = 30;
        self.avatarView.clipsToBounds = YES;
        self.avatarView.backgroundColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.3 alpha:1.0];
        [self.contentView addSubview:self.avatarView];

        self.nameLabel = [[UILabel alloc] init];
        self.nameLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
        self.nameLabel.textColor = [UIColor whiteColor];
        [self.contentView addSubview:self.nameLabel];

        self.bioLabel = [[UILabel alloc] init];
        self.bioLabel.font = [UIFont systemFontOfSize:13];
        self.bioLabel.textColor = [UIColor colorWithRed:0.6 green:0.6 blue:0.7 alpha:1.0];
        self.bioLabel.numberOfLines = 1;
        [self.contentView addSubview:self.bioLabel];

        self.chatButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [self.chatButton setImage:[UIImage systemImageNamed:@"bubble.left.fill"] forState:UIControlStateNormal];
        self.chatButton.tintColor = [UIColor whiteColor];
        self.chatButton.backgroundColor = [UIColor systemPinkColor];
        self.chatButton.layer.cornerRadius = 18;
        [self.contentView addSubview:self.chatButton];

        self.profileButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [self.profileButton setImage:[UIImage systemImageNamed:@"person.fill"] forState:UIControlStateNormal];
        self.profileButton.tintColor = [UIColor colorWithRed:0.77 green:0.31 blue:0.886 alpha:1.0];
        self.profileButton.backgroundColor = [UIColor colorWithRed:0.77 green:0.31 blue:0.886 alpha:0.15];
        self.profileButton.layer.cornerRadius = 18;
        [self.contentView addSubview:self.profileButton];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.avatarView.frame = CGRectMake(16, (self.contentView.bounds.size.height - 60) / 2, 60, 60);
    self.nameLabel.frame = CGRectMake(88, self.avatarView.frame.origin.y + 8, 120, 22);
    self.bioLabel.frame = CGRectMake(88, CGRectGetMaxY(self.nameLabel.frame) + 4, self.contentView.bounds.size.width - 200, 18);
    self.profileButton.frame = CGRectMake(self.contentView.bounds.size.width - 70, (self.contentView.bounds.size.height - 36) / 2, 36, 36);
    self.chatButton.frame = CGRectMake(self.contentView.bounds.size.width - 120, (self.contentView.bounds.size.height - 36) / 2, 36, 36);
}

@end

@interface FavoritesViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray<HYUser *> *favorites;
@property (nonatomic, assign) BOOL isLoading;
@property (nonatomic, assign) NSInteger currentPage;
@property (nonatomic, assign) BOOL hasMore;
@property (nonatomic, strong) UILabel *emptyLabel;

@end

@implementation FavoritesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"我的收藏";
    self.view.backgroundColor = [UIColor colorWithRed:0.04 green:0.04 blue:0.08 alpha:1.0];

    self.favorites = [NSMutableArray array];
    self.currentPage = 1;
    self.hasMore = YES;

    [self setupUI];
    [self loadData];
}

- (void)setupUI {
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.separatorColor = [[UIColor whiteColor] colorWithAlphaComponent:0.05];
    [self.tableView registerClass:[HYFavoriteCell class] forCellReuseIdentifier:kFavoriteCellId];
    [self.view addSubview:self.tableView];

    self.tableView.mj_header = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
        self.currentPage = 1;
        self.hasMore = YES;
        [self loadData];
    }];

    self.tableView.mj_footer = [MJRefreshAutoNormalFooter footerWithRefreshingBlock:^{
        if (self.hasMore) {
            [self loadData];
        } else {
            [self.tableView.mj_footer endRefreshingWithNoMoreData];
        }
    }];

    self.emptyLabel = [[UILabel alloc] init];
    self.emptyLabel.text = @"暂无收藏";
    self.emptyLabel.font = [UIFont systemFontOfSize:16];
    self.emptyLabel.textColor = [UIColor systemGrayColor];
    self.emptyLabel.textAlignment = NSTextAlignmentCenter;
    self.emptyLabel.hidden = YES;
    [self.view addSubview:self.emptyLabel];

    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];

    [self.emptyLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);
    }];
}

- (void)loadData {
    if (self.isLoading) return;
    self.isLoading = YES;

    __weak typeof(self) weakSelf = self;
    [[HYAPIClient shared] getFavoritesWithPage:self.currentPage pageSize:20 completion:^(NSDictionary *response, NSError *error) {
        weakSelf.isLoading = NO;
        [weakSelf.tableView.mj_header endRefreshing];
        [weakSelf.tableView.mj_footer endRefreshing];

        if (error) {
            NSLog(@"Load favorites error: %@", error.localizedDescription);
            return;
        }

        NSArray *data = nil;
        id responseData = response[@"data"];
        if ([responseData isKindOfClass:[NSArray class]]) {
            data = responseData;
        } else if ([responseData isKindOfClass:[NSDictionary class]]) {
            data = responseData[@"list"] ?: responseData[@"users"] ?: responseData[@"favorites"];
        }

        if (![data isKindOfClass:[NSArray class]]) data = @[];

        if (weakSelf.currentPage == 1) {
            [weakSelf.favorites removeAllObjects];
        }

        for (NSDictionary *dict in data) {
            if ([dict isKindOfClass:[NSDictionary class]]) {
                [weakSelf.favorites addObject:[[HYUser alloc] initWithDictionary:dict]];
            }
        }

        if ((NSInteger)data.count < 20) {
            weakSelf.hasMore = NO;
        } else {
            weakSelf.currentPage++;
        }

        weakSelf.emptyLabel.hidden = weakSelf.favorites.count > 0;
        [weakSelf.tableView reloadData];
    }];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.favorites.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    HYFavoriteCell *cell = [tableView dequeueReusableCellWithIdentifier:kFavoriteCellId forIndexPath:indexPath];

    HYUser *user = self.favorites[indexPath.row];
    cell.nameLabel.text = user.name;
    cell.bioLabel.text = user.bio.length > 0 ? user.bio : @"这个人很懒，什么都没写";
    if (user.avatar.length > 0) {
        [cell.avatarView sd_setImageWithURL:[NSURL URLWithString:user.avatar] placeholderImage:[UIImage systemImageNamed:@"person.circle.fill"]];
    } else {
        cell.avatarView.image = [UIImage systemImageNamed:@"person.circle.fill"];
        cell.avatarView.tintColor = [UIColor systemGrayColor];
    }

    cell.chatButton.tag = indexPath.row;
    cell.profileButton.tag = indexPath.row;
    [cell.chatButton addTarget:self action:@selector(chatTapped:) forControlEvents:UIControlEventTouchUpInside];
    [cell.profileButton addTarget:self action:@selector(profileTapped:) forControlEvents:UIControlEventTouchUpInside];

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 84;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    HYUser *user = self.favorites[indexPath.row];
    UserProfileViewController *vc = [[UserProfileViewController alloc] initWithUserId:[NSString stringWithFormat:@"%ld", (long)user.userId]];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)chatTapped:(UIButton *)sender {
    HYUser *user = self.favorites[sender.tag];
    ChatDetailViewController *vc = [[ChatDetailViewController alloc] initWithPartnerId:[NSString stringWithFormat:@"%ld", (long)user.userId] partnerName:user.name partnerAvatar:user.avatar];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)profileTapped:(UIButton *)sender {
    HYUser *user = self.favorites[sender.tag];
    UserProfileViewController *vc = [[UserProfileViewController alloc] initWithUserId:[NSString stringWithFormat:@"%ld", (long)user.userId]];
    [self.navigationController pushViewController:vc animated:YES];
}

@end
