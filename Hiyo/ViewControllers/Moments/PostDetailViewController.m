#import "PostDetailViewController.h"
#import "HYAPIClient.h"
#import "HYModels.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/SDWebImage.h>
#import <MJRefresh/MJRefresh.h>

static CGFloat const kInputBarHeight = 56.0;

@interface PostDetailViewController () <UITableViewDelegate, UITableViewDataSource, UITextViewDelegate>

@property (nonatomic, assign) NSInteger postId;
@property (nonatomic, strong) HYPostDetail *postDetail;
@property (nonatomic, assign) NSInteger currentUserId;

// UI
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIView *inputContainerView;
@property (nonatomic, strong) UITextView *inputTextView;
@property (nonatomic, strong) UIButton *sendButton;
@property (nonatomic, strong) UIView *inputBar;
@property (nonatomic, strong) UIActivityIndicatorView *loadingIndicator;
@property (nonatomic, strong) UILabel *errorLabel;
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) NSLayoutConstraint *inputBottomConstraint;

// State
@property (nonatomic, assign) BOOL isSubmittingComment;

@end

@implementation PostDetailViewController

- (instancetype)initWithPostId:(NSInteger)postId {
    self = [super init];
    if (self) {
        _postId = postId;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"帖子详情";
    self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];
    [self setupUI];
    [self setupKeyboardNotifications];
    [self loadPostDetail];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Setup

- (void)setupUI {
    // Table View
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 80;
    self.tableView.backgroundColor = [UIColor systemGroupedBackgroundColor];
    [self.view addSubview:self.tableView];

    // Header view (post content)
    self.headerView = [[UIView alloc] init];
    self.headerView.backgroundColor = [UIColor systemBackgroundColor];
    [self setupHeaderView];

    // Loading
    self.loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    self.loadingIndicator.color = [UIColor systemPinkColor];
    self.loadingIndicator.hidesWhenStopped = YES;
    [self.view addSubview:self.loadingIndicator];

    // Error label
    self.errorLabel = [[UILabel alloc] init];
    self.errorLabel.font = [UIFont systemFontOfSize:15];
    self.errorLabel.textColor = [UIColor secondaryLabelColor];
    self.errorLabel.textAlignment = NSTextAlignmentCenter;
    self.errorLabel.numberOfLines = 0;
    self.errorLabel.hidden = YES;
    [self.view addSubview:self.errorLabel];

    // Input bar
    self.inputContainerView = [[UIView alloc] init];
    self.inputContainerView.backgroundColor = [UIColor systemBackgroundColor];
    [self.view addSubview:self.inputContainerView];

    UIView *inputBg = [[UIView alloc] init];
    inputBg.backgroundColor = [UIColor secondarySystemGroupedBackgroundColor];
    inputBg.layer.cornerRadius = 20;
    [self.inputContainerView addSubview:inputBg];

    self.inputTextView = [[UITextView alloc] init];
    self.inputTextView.font = [UIFont systemFontOfSize:15];
    self.inputTextView.textColor = [UIColor labelColor];
    self.inputTextView.backgroundColor = [UIColor clearColor];
    self.inputTextView.delegate = self;
    self.inputTextView.showsVerticalScrollIndicator = NO;
    self.inputTextView.textContainerInset = UIEdgeInsetsMake(8, 4, 8, 4);
    [inputBg addSubview:self.inputTextView];

    UILabel *placeholder = [[UILabel alloc] init];
    placeholder.text = @"写评论...";
    placeholder.font = [UIFont systemFontOfSize:15];
    placeholder.textColor = [UIColor placeholderTextColor];
    placeholder.tag = 100;
    [inputBg addSubview:placeholder];

    self.sendButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.sendButton setTitle:@"发送" forState:UIControlStateNormal];
    [self.sendButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.sendButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
    self.sendButton.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    self.sendButton.backgroundColor = [UIColor systemPinkColor];
    self.sendButton.layer.cornerRadius = 16;
    self.sendButton.enabled = NO;
    [self.sendButton addTarget:self action:@selector(sendCommentTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.inputContainerView addSubview:self.sendButton];

    // Separator
    UIView *separator = [[UIView alloc] init];
    separator.backgroundColor = [UIColor separatorColor];
    [self.inputContainerView addSubview:separator];

    [self setupConstraints:inputBg separator:separator placeholder:placeholder];
}

- (void)setupHeaderView {
    // Avatar
    UIImageView *avatar = [[UIImageView alloc] init];
    avatar.contentMode = UIViewContentModeScaleAspectFill;
    avatar.clipsToBounds = YES;
    avatar.layer.cornerRadius = 22;
    avatar.backgroundColor = [UIColor systemGray5Color];
    avatar.tag = 10;
    [self.headerView addSubview:avatar];

    // User name
    UILabel *nameLabel = [[UILabel alloc] init];
    nameLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    nameLabel.textColor = [UIColor labelColor];
    nameLabel.tag = 11;
    [self.headerView addSubview:nameLabel];

    // Time
    UILabel *timeLabel = [[UILabel alloc] init];
    timeLabel.font = [UIFont systemFontOfSize:12];
    timeLabel.textColor = [UIColor secondaryLabelColor];
    timeLabel.tag = 12;
    [self.headerView addSubview:timeLabel];

    // Title
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
    titleLabel.textColor = [UIColor labelColor];
    titleLabel.numberOfLines = 0;
    titleLabel.tag = 13;
    [self.headerView addSubview:titleLabel];

    // Content
    UILabel *contentLabel = [[UILabel alloc] init];
    contentLabel.font = [UIFont systemFontOfSize:15];
    contentLabel.textColor = [UIColor labelColor];
    contentLabel.numberOfLines = 0;
    contentLabel.tag = 14;
    [self.headerView addSubview:contentLabel];

    // Images container
    UIView *imagesContainer = [[UIView alloc] init];
    imagesContainer.tag = 15;
    [self.headerView addSubview:imagesContainer];

    // Like bar
    UIView *likeBar = [[UIView alloc] init];
    likeBar.tag = 16;
    [self.headerView addSubview:likeBar];

    UIButton *likeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    likeBtn.tag = 20;
    [likeBar addSubview:likeBtn];

    UILabel *likeCountLabel = [[UILabel alloc] init];
    likeCountLabel.font = [UIFont systemFontOfSize:13];
    likeCountLabel.textColor = [UIColor secondaryLabelColor];
    likeCountLabel.tag = 21;
    [likeBar addSubview:likeCountLabel];

    UIButton *deleteBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [deleteBtn setTitle:@"删除" forState:UIControlStateNormal];
    [deleteBtn setTitleColor:[UIColor systemRedColor] forState:UIControlStateNormal];
    deleteBtn.titleLabel.font = [UIFont systemFontOfSize:13];
    deleteBtn.tag = 22;
    deleteBtn.hidden = YES;
    [deleteBtn addTarget:self action:@selector(deletePostTapped) forControlEvents:UIControlEventTouchUpInside];
    [likeBar addSubview:deleteBtn];

    UIView *separator = [[UIView alloc] init];
    separator.backgroundColor = [UIColor separatorColor];
    separator.tag = 30;
    [self.headerView addSubview:separator];

    // Layout header
    [avatar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.top.equalTo(self.headerView).offset(16);
        make.width.height.equalTo(@44);
    }];

    [nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(avatar.mas_trailing).offset(10);
        make.top.equalTo(avatar).offset(2);
    }];

    [timeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(nameLabel);
        make.top.equalTo(nameLabel.mas_bottom).offset(2);
    }];

    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.equalTo(self.headerView).inset(16);
        make.top.equalTo(avatar.mas_bottom).offset(14);
    }];

    [contentLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.equalTo(titleLabel);
        make.top.equalTo(titleLabel.mas_bottom).offset(8);
    }];

    [imagesContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.equalTo(titleLabel);
        make.top.equalTo(contentLabel.mas_bottom).offset(10);
        make.height.equalTo(@0);
    }];

    [likeBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.equalTo(titleLabel);
        make.top.equalTo(imagesContainer.mas_bottom).offset(12);
        make.height.equalTo(@36);
    }];

    [likeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.centerY.equalTo(likeBar);
        make.height.equalTo(@36);
    }];

    [likeCountLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(likeBtn.mas_trailing).offset(4);
        make.centerY.equalTo(likeBar);
    }];

    [deleteBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.centerY.equalTo(likeBar);
    }];

    [separator mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.equalTo(self.headerView);
        make.top.equalTo(likeBar.mas_bottom).offset(4);
        make.height.equalTo(@1);
        make.bottom.equalTo(self.headerView);
    }];
}

- (void)setupConstraints:(UIView *)inputBg separator:(UIView *)separator placeholder:(UILabel *)placeholder {
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.trailing.equalTo(self.view);
        make.bottom.equalTo(self.inputContainerView.mas_top);
    }];

    [self.loadingIndicator mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);
    }];

    [self.errorLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);
        make.leading.trailing.equalTo(self.view).inset(40);
    }];

    [self.inputContainerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.equalTo(self.view);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom);
        make.height.equalTo(@(kInputBarHeight + 1));
    }];

    [separator mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.trailing.equalTo(self.inputContainerView);
        make.height.equalTo(@1);
    }];

    [inputBg mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.inputContainerView).offset(12);
        make.top.equalTo(separator.mas_bottom).offset(8);
        make.bottom.equalTo(self.inputContainerView).offset(-8);
        make.trailing.equalTo(self.sendButton.mas_leading).offset(-8);
    }];

    [self.inputTextView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(inputBg);
    }];

    [placeholder mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(inputBg).offset(12);
        make.centerY.equalTo(inputBg);
    }];

    [self.sendButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(self.inputContainerView).offset(-12);
        make.centerY.equalTo(inputBg);
        make.width.equalTo(@60);
        make.height.equalTo(@32);
    }];
}

- (void)setupKeyboardNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWillShow:(NSNotification *)notification {
    CGRect keyboardFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    NSTimeInterval duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];

    [self.inputContainerView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-(keyboardFrame.size.height - self.view.safeAreaInsets.bottom));
    }];

    [UIView animateWithDuration:duration animations:^{
        [self.view layoutIfNeeded];
    }];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    NSTimeInterval duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];

    [self.inputContainerView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom);
    }];

    [UIView animateWithDuration:duration animations:^{
        [self.view layoutIfNeeded];
    }];
}

#pragma mark - Data Loading

- (void)loadPostDetail {
    [self.loadingIndicator startAnimating];
    self.tableView.hidden = YES;
    self.errorLabel.hidden = YES;

    [[HYAPIClient shared] getPostDetailWithId:self.postId completion:^(NSDictionary *response, NSError *error) {
        [self.loadingIndicator stopAnimating];

        if (error) {
            self.errorLabel.text = [NSString stringWithFormat:@"加载失败: %@", error.localizedDescription];
            self.errorLabel.hidden = NO;
            return;
        }

        NSDictionary *data = response[@"data"];
        if (![data isKindOfClass:[NSDictionary class]]) {
            self.errorLabel.text = @"数据格式错误";
            self.errorLabel.hidden = NO;
            return;
        }

        self.postDetail = [[HYPostDetail alloc] initWithDictionary:data];
        self.tableView.hidden = NO;
        [self updateHeaderUI];
        [self.tableView reloadData];
    }];
}

- (void)updateHeaderUI {
    if (!self.postDetail) return;

    UIImageView *avatar = [self.headerView viewWithTag:10];
    UILabel *nameLabel = [self.headerView viewWithTag:11];
    UILabel *timeLabel = [self.headerView viewWithTag:12];
    UILabel *titleLabel = [self.headerView viewWithTag:13];
    UILabel *contentLabel = [self.headerView viewWithTag:14];
    UIView *imagesContainer = [self.headerView viewWithTag:15];
    UIButton *likeBtn = [self.headerView viewWithTag:20];
    UILabel *likeCountLabel = [self.headerView viewWithTag:21];
    UIButton *deleteBtn = [self.headerView viewWithTag:22];

    HYPostAuthor *author = self.postDetail.author;
    [avatar sd_setImageWithURL:[NSURL URLWithString:author.avatar] placeholderImage:[UIImage systemImageNamed:@"person.circle.fill"]];
    nameLabel.text = author.userName;
    timeLabel.text = [self formatTime:self.postDetail.createdAt];
    titleLabel.text = self.postDetail.title;
    contentLabel.text = self.postDetail.content;

    // Like button
    NSString *likeIcon = self.postDetail.isLiked ? @"heart.fill" : @"heart";
    UIColor *likeColor = self.postDetail.isLiked ? [UIColor systemPinkColor] : [UIColor systemGrayColor];
    [likeBtn setImage:[UIImage systemImageNamed:likeIcon] forState:UIControlStateNormal];
    likeBtn.tintColor = likeColor;
    [likeBtn setTitle:[NSString stringWithFormat:@" %ld", (long)self.postDetail.likesCount] forState:UIControlStateNormal];
    [likeBtn setTitleColor:likeColor forState:UIControlStateNormal];
    likeCountLabel.text = [NSString stringWithFormat:@"%ld 人点赞", (long)self.postDetail.likesCount];
    [likeBtn removeTarget:self action:NULL forControlEvents:UIControlEventAllEvents];
    [likeBtn addTarget:self action:@selector(likeTapped) forControlEvents:UIControlEventTouchUpInside];

    // Check if current user is the author
    NSString *userIdStr = [[NSUserDefaults standardUserDefaults] stringForKey:@"hiyo_user_id"];
    NSInteger currentUserId = [userIdStr integerValue];
    deleteBtn.hidden = (author.userId != currentUserId);

    // Layout images
    [self layoutImagesInContainer:imagesContainer];

    // Set header table
    [self.headerView setNeedsLayout];
    [self.headerView layoutIfNeeded];
    CGFloat height = [self.headerView systemLayoutSizeFittingSize:CGSizeMake(self.view.bounds.size.width, UILayoutFittingCompressedSize.height)].height;
    self.headerView.frame = CGRectMake(0, 0, self.view.bounds.size.width, height);
    self.tableView.tableHeaderView = self.headerView;
}

- (void)layoutImagesInContainer:(UIView *)container {
    // Remove existing image views
    for (UIView *subview in container.subviews) {
        [subview removeFromSuperview];
    }

    NSString *imageUrl = self.postDetail.imageUrl;
    if (imageUrl.length == 0) return;

    NSArray *urls = [imageUrl componentsSeparatedByString:@","];
    if (urls.count == 0) return;

    CGFloat imageWidth = (self.view.bounds.size.width - 32 - 10) / 2;
    CGFloat imageHeight = 160;
    NSInteger maxRows = urls.count > 1 ? 2 : 1;
    CGFloat totalHeight = maxRows * imageHeight + (maxRows - 1) * 8;

    [container mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@(totalHeight));
    }];

    for (NSInteger i = 0; i < urls.count && i < 4; i++) {
        UIImageView *imgView = [[UIImageView alloc] init];
        imgView.contentMode = UIViewContentModeScaleAspectFill;
        imgView.clipsToBounds = YES;
        imgView.layer.cornerRadius = 8;
        imgView.backgroundColor = [UIColor systemGray5Color];
        [imgView sd_setImageWithURL:[NSURL URLWithString:urls[i]]];
        [container addSubview:imgView];

        NSInteger col = i % 2;
        NSInteger row = i / 2;
        [imgView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(container).offset(col * (imageWidth + 10));
            make.top.equalTo(container).offset(row * (imageHeight + 8));
            make.width.equalTo(@(imageWidth));
            make.height.equalTo(@(imageHeight));
        }];
    }
}

- (NSString *)formatTime:(NSString *)timeString {
    if (!timeString || timeString.length == 0) return @"";
    static NSDateFormatter *inputFormatter = nil;
    static NSDateFormatter *outputFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        inputFormatter = [[NSDateFormatter alloc] init];
        inputFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSSZ";
        inputFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        outputFormatter = [[NSDateFormatter alloc] init];
        outputFormatter.dateFormat = @"MM-dd HH:mm";
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
        return [outputFormatter stringFromDate:date];
    }
    return timeString;
}

#pragma mark - Actions

- (void)likeTapped {
    BOOL currentLike = self.postDetail.isLiked;
    self.postDetail.isLiked = !currentLike;
    self.postDetail.likesCount = currentLike ? self.postDetail.likesCount - 1 : self.postDetail.likesCount + 1;
    [self updateHeaderUI];

    [[HYAPIClient shared] likePostWithId:self.postId completion:^(NSDictionary *response, NSError *error) {
        if (!error) {
            NSDictionary *data = response[@"data"];
            if ([data isKindOfClass:[NSDictionary class]]) {
                self.postDetail.isLiked = [data[@"is_liked"] boolValue];
                self.postDetail.likesCount = [data[@"likes_count"] integerValue];
                [self updateHeaderUI];
            }
        } else {
            // Revert
            self.postDetail.isLiked = currentLike;
            self.postDetail.likesCount = currentLike ? self.postDetail.likesCount + 1 : self.postDetail.likesCount - 1;
            [self updateHeaderUI];
        }
    }];
}

- (void)deletePostTapped {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"删除动态" message:@"确定要删除这条动态吗？" preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"删除" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [[HYAPIClient shared] deletePostWithId:self.postId completion:^(NSDictionary *response, NSError *error) {
            if (error) {
                NSLog(@"Delete error: %@", error.localizedDescription);
                return;
            }
            if (self.onPostDeleted) self.onPostDeleted();
            [self.navigationController popViewControllerAnimated:YES];
        }];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)sendCommentTapped {
    NSString *content = [self.inputTextView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (content.length == 0 || self.isSubmittingComment) return;

    self.isSubmittingComment = YES;
    self.sendButton.enabled = NO;

    [[HYAPIClient shared] createCommentWithPostId:self.postId content:content completion:^(NSDictionary *response, NSError *error) {
        self.isSubmittingComment = NO;
        self.sendButton.enabled = YES;

        if (error) {
            NSLog(@"Comment error: %@", error.localizedDescription);
            return;
        }

        self.inputTextView.text = @"";
        UILabel *placeholder = [self.inputTextView.superview viewWithTag:100];
        placeholder.hidden = YES;
        [self.view endEditing:YES];

        // Reload to get updated comments
        [self loadPostDetail];
    }];
}

- (void)deleteComment:(HYPostComment *)comment {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"删除评论" message:@"确定要删除这条评论吗？" preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"删除" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [[HYAPIClient shared] deleteCommentWithId:comment.commentId completion:^(NSDictionary *response, NSError *error) {
            if (error) {
                NSLog(@"Delete comment error: %@", error.localizedDescription);
                return;
            }
            [self loadPostDetail];
        }];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.postDetail ? self.postDetail.comments.count : 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (!self.postDetail || self.postDetail.comments.count == 0) return nil;
    return [NSString stringWithFormat:@"评论 (%ld)", (long)self.postDetail.comments.count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"CommentCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }

    HYPostComment *comment = self.postDetail.comments[indexPath.row];

    // Build cell content
    NSMutableString *text = [NSMutableString string];
    [text appendFormat:@"%@ ", comment.userName];
    [text appendString:comment.content];

    NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithString:text];
    [attr addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:14 weight:UIFontWeightSemibold] range:NSMakeRange(0, comment.userName.length)];
    [attr addAttribute:NSForegroundColorAttributeName value:[UIColor labelColor] range:NSMakeRange(0, comment.userName.length)];
    [attr addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:14] range:NSMakeRange(comment.userName.length, text.length - comment.userName.length)];
    [attr addAttribute:NSForegroundColorAttributeName value:[UIColor secondaryLabelColor] range:NSMakeRange(comment.userName.length, text.length - comment.userName.length)];

    cell.textLabel.attributedText = attr;
    cell.detailTextLabel.text = [self formatTime:comment.createdAt];

    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (BOOL)tableView:(UITableView *)tableView canPerformAction:(SEL)action withSender:(id)sender {
    return (action == @selector(copy:));
}

- (void)tableView:(UITableView *)tableView performAction:(SEL)action withSender:(id)sender {
    // Copy handled via UIContextMenuInteraction below
}

- (UIContextMenuConfiguration *)tableView:(UITableView *)tableView contextMenuConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath point:(CGPoint)point API_AVAILABLE(ios(13.0)) {
    HYPostComment *comment = self.postDetail.comments[indexPath.row];
    NSString *userIdStr = [[NSUserDefaults standardUserDefaults] stringForKey:@"hiyo_user_id"];
    NSInteger currentUserId = [userIdStr integerValue];
    BOOL isOwner = (comment.userId == currentUserId);

    return [UIContextMenuConfiguration configurationWithIdentifier:nil previewProvider:nil actionProvider:^UIMenu * _Nullable(NSArray<UIMenuElement *> * _Nonnull suggestedActions) {
        UIAction *copyAction = [UIAction actionWithTitle:@"复制" image:[UIImage systemImageNamed:@"doc.on.doc"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            [UIPasteboard generalPasteboard].string = comment.content;
        }];

        NSMutableArray *actions = [NSMutableArray arrayWithObject:copyAction];
        if (isOwner) {
            UIAction *deleteAction = [UIAction actionWithTitle:@"删除" image:[UIImage systemImageNamed:@"trash"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                [self deleteComment:comment];
            }];
            deleteAction.attributes = UIMenuElementAttributesDestructive;
            [actions addObject:deleteAction];
        }

        return [UIMenu menuWithTitle:@"" children:actions];
    }];
}

#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView {
    UILabel *placeholder = [textView.superview viewWithTag:100];
    placeholder.hidden = (textView.text.length > 0);
    self.sendButton.enabled = (textView.text.length > 0 && !self.isSubmittingComment);
}

@end
