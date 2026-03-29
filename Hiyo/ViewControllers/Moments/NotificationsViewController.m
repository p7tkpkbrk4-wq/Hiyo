#import "NotificationsViewController.h"
#import "HYAPIClient.h"
#import "HYModels.h"
#import "PostDetailViewController.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/SDWebImage.h>
#import <MJRefresh/MJRefresh.h>

static NSString * const kNotificationCellIdentifier = @"NotificationCell";

@interface NotificationsViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray<HYNotification *> *notifications;
@property (nonatomic, strong) UIActivityIndicatorView *loadingIndicator;
@property (nonatomic, strong) UILabel *emptyLabel;
@property (nonatomic, assign) NSInteger currentPage;
@property (nonatomic, assign) BOOL hasMore;
@property (nonatomic, assign) BOOL isLoading;

@end

@implementation NotificationsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"消息通知";
    self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];
    self.notifications = [NSMutableArray array];
    self.currentPage = 1;
    self.hasMore = YES;
    [self setupUI];
    [self loadNotifications:YES];
    [self markAsRead];
}

#pragma mark - Setup

- (void)setupUI {
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.rowHeight = 70;
    self.tableView.backgroundColor = [UIColor systemGroupedBackgroundColor];
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 76, 0, 0);
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kNotificationCellIdentifier];
    [self.view addSubview:self.tableView];

    self.tableView.mj_header = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(pullToRefresh)];
    self.tableView.mj_footer = [MJRefreshAutoNormalFooter footerWithRefreshingTarget:self refreshingAction:@selector(loadMoreData)];

    self.loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    self.loadingIndicator.color = [UIColor systemPinkColor];
    self.loadingIndicator.hidesWhenStopped = YES;
    [self.view addSubview:self.loadingIndicator];

    self.emptyLabel = [[UILabel alloc] init];
    self.emptyLabel.text = @"暂无通知";
    self.emptyLabel.font = [UIFont systemFontOfSize:15];
    self.emptyLabel.textColor = [UIColor secondaryLabelColor];
    self.emptyLabel.textAlignment = NSTextAlignmentCenter;
    self.emptyLabel.hidden = YES;
    [self.view addSubview:self.emptyLabel];

    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];

    [self.loadingIndicator mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);
    }];

    [self.emptyLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);
    }];
}

#pragma mark - Data Loading

- (void)loadNotifications:(BOOL)refresh {
    if (self.isLoading) return;
    self.isLoading = YES;

    if (refresh) {
        self.currentPage = 1;
        [self.loadingIndicator startAnimating];
    }

    [[HYAPIClient shared] getNotificationsWithPage:self.currentPage pageSize:20 completion:^(NSDictionary *response, NSError *error) {
        self.isLoading = NO;
        [self.loadingIndicator stopAnimating];
        [self.tableView.mj_header endRefreshing];
        [self.tableView.mj_footer endRefreshing];

        if (error) {
            NSLog(@"Failed to load notifications: %@", error.localizedDescription);
            return;
        }

        id data = response[@"data"];
        NSArray *notificationsData = nil;
        if ([data isKindOfClass:[NSDictionary class]]) {
            notificationsData = data[@"notifications"];
        } else if ([data isKindOfClass:[NSArray class]]) {
            notificationsData = data;
        }
        if (![notificationsData isKindOfClass:[NSArray class]]) {
            notificationsData = @[];
        }

        if (refresh) {
            [self.notifications removeAllObjects];
        }
        for (NSDictionary *dict in notificationsData) {
            HYNotification *notification = [[HYNotification alloc] initWithDictionary:dict];
            [self.notifications addObject:notification];
        }

        self.hasMore = (notificationsData.count == 20);
        if (!self.hasMore) {
            [self.tableView.mj_footer endRefreshingWithNoMoreData];
        }

        [self.tableView reloadData];
        self.emptyLabel.hidden = (self.notifications.count > 0);
    }];
}

- (void)pullToRefresh {
    self.currentPage = 1;
    self.hasMore = YES;
    [self loadNotifications:YES];
}

- (void)loadMoreData {
    if (self.isLoading || !self.hasMore) {
        [self.tableView.mj_footer endRefreshing];
        return;
    }

    self.currentPage++;
    self.isLoading = YES;

    [[HYAPIClient shared] getNotificationsWithPage:self.currentPage pageSize:20 completion:^(NSDictionary *response, NSError *error) {
        self.isLoading = NO;

        if (error) {
            self.currentPage--;
            [self.tableView.mj_footer endRefreshing];
            return;
        }

        id data = response[@"data"];
        NSArray *notificationsData = nil;
        if ([data isKindOfClass:[NSDictionary class]]) {
            notificationsData = data[@"notifications"];
        } else if ([data isKindOfClass:[NSArray class]]) {
            notificationsData = data;
        }
        if (![notificationsData isKindOfClass:[NSArray class]]) {
            notificationsData = @[];
        }

        for (NSDictionary *dict in notificationsData) {
            HYNotification *notification = [[HYNotification alloc] initWithDictionary:dict];
            [self.notifications addObject:notification];
        }

        self.hasMore = (notificationsData.count == 20);
        if (!self.hasMore) {
            [self.tableView.mj_footer endRefreshingWithNoMoreData];
        } else {
            [self.tableView.mj_footer endRefreshing];
        }

        [self.tableView reloadData];
    }];
}

- (void)markAsRead {
    [[HYAPIClient shared] markNotificationsReadWithCompletion:^(NSDictionary *response, NSError *error) {
        if (!error) {
            // Post notification to update badge
            [[NSNotificationCenter defaultCenter] postNotificationName:@"HYNotificationsReadNotification" object:nil];
        }
    }];
}

- (NSString *)actionTextForType:(NSString *)type {
    if ([type isEqualToString:@"post_like"]) {
        return @"赞了你的动态";
    } else if ([type isEqualToString:@"post_comment"]) {
        return @"评论了你的动态";
    } else if ([type isEqualToString:@"follow"]) {
        return @"关注了你";
    }
    return @"与你互动了";
}

- (NSString *)formatTime:(NSString *)timeString {
    if (!timeString || timeString.length == 0) return @"";
    static NSDateFormatter *inputFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        inputFormatter = [[NSDateFormatter alloc] init];
        inputFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSSZ";
        inputFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    });

    NSDate *date = [inputFormatter dateFromString:timeString];
    if (!date) {
        inputFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss";
        date = [inputFormatter dateFromString:timeString];
    }
    if (date) {
        NSTimeInterval delta = [[NSDate date] timeIntervalSinceDate:date];
        if (delta < 60) return @"刚刚";
        if (delta < 3600) return [NSString stringWithFormat:@"%.0f分钟前", delta/60];
        if (delta < 86400) return [NSString stringWithFormat:@"%.0f小时前", delta/3600];
        if (delta < 604800) return [NSString stringWithFormat:@"%.0f天前", delta/86400];
        return timeString;
    }
    return timeString;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.notifications.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kNotificationCellIdentifier forIndexPath:indexPath];

    HYNotification *notification = self.notifications[indexPath.row];

    // Configure cell
    cell.imageView.contentMode = UIViewContentModeScaleAspectFill;
    cell.imageView.clipsToBounds = YES;
    cell.imageView.layer.cornerRadius = 24;
    if (notification.actorAvatar.length > 0) {
        [cell.imageView sd_setImageWithURL:[NSURL URLWithString:notification.actorAvatar] placeholderImage:[UIImage systemImageNamed:@"person.circle.fill"]];
    } else {
        cell.imageView.image = [UIImage systemImageNamed:@"person.circle.fill"];
    }

    NSMutableString *text = [NSMutableString string];
    [text appendFormat:@"%@ ", notification.actorName];
    [text appendString:[self actionTextForType:notification.type]];

    NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithString:text];
    [attr addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:15 weight:UIFontWeightSemibold] range:NSMakeRange(0, notification.actorName.length)];
    [attr addAttribute:NSForegroundColorAttributeName value:[UIColor labelColor] range:NSMakeRange(0, notification.actorName.length)];

    NSRange actionRange = NSMakeRange(notification.actorName.length, text.length - notification.actorName.length);
    [attr addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:15] range:actionRange];
    [attr addAttribute:NSForegroundColorAttributeName value:[UIColor secondaryLabelColor] range:actionRange];

    cell.textLabel.attributedText = attr;
    cell.detailTextLabel.text = [self formatTime:notification.createdAt];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;

    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    HYNotification *notification = self.notifications[indexPath.row];
    if (notification.postId > 0) {
        PostDetailViewController *vc = [[PostDetailViewController alloc] initWithPostId:notification.postId];
        [self.navigationController pushViewController:vc animated:YES];
    }
}

@end
