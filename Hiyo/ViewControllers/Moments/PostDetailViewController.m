#import "PostDetailViewController.h"
#import "HYAPIClient.h"
#import "HYModels.h"
#import "HYColors.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/SDWebImage.h>
#import <MJRefresh/MJRefresh.h>

static CGFloat const kInputBarHeight = 100.0;

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
    self.view.backgroundColor = LightBg1;
    [self setupNavigationBar];
    [self setupUI];
    [self setupKeyboardNotifications];
    [self loadPostDetail];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Setup

- (void)setupNavigationBar {
    if (@available(iOS 15.0, *)) {
        UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
        [appearance configureWithOpaqueBackground];
        appearance.backgroundColor = [UIColor whiteColor];
        appearance.shadowColor = [UIColor colorWithRed:0.933 green:0.933 blue:1.0 alpha:1.0]; // #EEEEFF
        appearance.titleTextAttributes = @{
            NSForegroundColorAttributeName: [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0]
        };
        self.navigationController.navigationBar.standardAppearance = appearance;
        self.navigationController.navigationBar.scrollEdgeAppearance = appearance;
    } else {
        self.navigationController.navigationBar.backgroundColor = [UIColor whiteColor];
        self.navigationController.navigationBar.shadowImage = [UIImage new];
        self.navigationController.navigationBar.titleTextAttributes = @{
            NSForegroundColorAttributeName: [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0]
        };
    }
    self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0];
}

- (void)setupUI {
    // Table View
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 80;
    self.tableView.backgroundColor = [UIColor clearColor];
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
    self.inputContainerView.backgroundColor = LightCard;
    [self.view addSubview:self.inputContainerView];

    UIView *inputBg = [[UIView alloc] init];
    inputBg.backgroundColor = [UIColor colorWithRed:0.961 green:0.961 blue:0.973 alpha:1.0];
    inputBg.layer.cornerRadius = 21;
    inputBg.layer.borderWidth = 1.5;
    inputBg.layer.borderColor = [UIColor colorWithRed:0.933 green:0.933 blue:1.0 alpha:1.0].CGColor;
    [self.inputContainerView addSubview:inputBg];

    self.inputTextView = [[UITextView alloc] init];
    self.inputTextView.font = [UIFont systemFontOfSize:15];
    self.inputTextView.textColor = [UIColor colorWithRed:0.333 green:0.333 blue:0.333 alpha:1.0];
    self.inputTextView.backgroundColor = [UIColor clearColor];
    self.inputTextView.delegate = self;
    self.inputTextView.showsVerticalScrollIndicator = NO;
    self.inputTextView.textContainerInset = UIEdgeInsetsMake(8, 4, 8, 4);
    [inputBg addSubview:self.inputTextView];

    UILabel *placeholder = [[UILabel alloc] init];
    placeholder.text = @"说点什么...";
    placeholder.font = [UIFont systemFontOfSize:15];
    placeholder.textColor = [UIColor colorWithRed:0.6 green:0.6 blue:0.6 alpha:1.0];
    placeholder.tag = 100;
    [inputBg addSubview:placeholder];

    self.sendButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.sendButton.layer.cornerRadius = 21;
    self.sendButton.clipsToBounds = YES;
    CAGradientLayer *sendGrad = [CAGradientLayer layer];
    sendGrad.colors = @[(id)PinkGradStart.CGColor, (id)PurpleGradEnd.CGColor];
    sendGrad.startPoint = CGPointMake(0, 0);
    sendGrad.endPoint = CGPointMake(1, 1);
    sendGrad.frame = CGRectMake(0, 0, 42, 42);
    [self.sendButton.layer insertSublayer:sendGrad atIndex:0];
    [self.sendButton setImage:[UIImage systemImageNamed:@"arrow.up"] forState:UIControlStateNormal];
    self.sendButton.tintColor = [UIColor whiteColor];
    self.sendButton.enabled = NO;
    [self.sendButton addTarget:self action:@selector(sendCommentTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.inputContainerView addSubview:self.sendButton];

    // Separator
    UIView *separator = [[UIView alloc] init];
    separator.backgroundColor = [UIColor colorWithRed:0.933 green:0.933 blue:1.0 alpha:1.0];
    [self.inputContainerView addSubview:separator];

    [self setupConstraints:inputBg separator:separator placeholder:placeholder];

    // Bottom action buttons
    UIView *bottomActions = [[UIView alloc] init];
    bottomActions.tag = 70;
    [self.inputContainerView addSubview:bottomActions];

    // Photo button (purple)
    UIButton *photoBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    photoBtn.backgroundColor = [UIColor colorWithRed:0.961 green:0.941 blue:1.0 alpha:1.0];
    photoBtn.layer.cornerRadius = 16;
    [photoBtn setImage:[UIImage systemImageNamed:@"photo"] forState:UIControlStateNormal];
    photoBtn.tintColor = PurpleGradStart;
    [bottomActions addSubview:photoBtn];

    // Heart button (pink)
    UIButton *heartBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    heartBtn.backgroundColor = [UIColor colorWithRed:1.0 green:0.941 blue:0.961 alpha:1.0];
    heartBtn.layer.cornerRadius = 16;
    [heartBtn setImage:[UIImage systemImageNamed:@"heart.fill"] forState:UIControlStateNormal];
    heartBtn.tintColor = PinkGradStart;
    [bottomActions addSubview:heartBtn];

    // Clock button (sky blue)
    UIButton *clockBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    clockBtn.backgroundColor = [UIColor colorWithRed:0.91 green:0.961 blue:1.0 alpha:1.0];
    clockBtn.layer.cornerRadius = 16;
    [clockBtn setImage:[UIImage systemImageNamed:@"clock"] forState:UIControlStateNormal];
    clockBtn.tintColor = [UIColor colorWithRed:0.22 green:0.741 blue:0.973 alpha:1.0];
    [bottomActions addSubview:clockBtn];

    // Alert button (warning yellow)
    UIButton *alertBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    alertBtn.backgroundColor = [UIColor colorWithRed:1.0 green:0.973 blue:0.878 alpha:1.0];
    alertBtn.layer.cornerRadius = 16;
    [alertBtn setImage:[UIImage systemImageNamed:@"exclamationmark.circle"] forState:UIControlStateNormal];
    alertBtn.tintColor = [UIColor colorWithRed:1.0 green:0.596 blue:0.0 alpha:1.0];
    [bottomActions addSubview:alertBtn];

    [bottomActions mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.inputContainerView).offset(16);
        make.bottom.equalTo(self.inputContainerView).offset(-12);
        make.height.equalTo(@32);
    }];

    [photoBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.centerY.equalTo(bottomActions);
        make.width.height.equalTo(@32);
    }];

    [heartBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(photoBtn.mas_trailing).offset(8);
        make.centerY.equalTo(bottomActions);
        make.width.height.equalTo(@32);
    }];

    [clockBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(heartBtn.mas_trailing).offset(8);
        make.centerY.equalTo(bottomActions);
        make.width.height.equalTo(@32);
    }];

    [alertBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(clockBtn.mas_trailing).offset(8);
        make.centerY.equalTo(bottomActions);
        make.width.height.equalTo(@32);
        make.trailing.lessThanOrEqualTo(bottomActions);
    }];
}

- (void)setupHeaderView {
    // Card background
    self.headerView.backgroundColor = LightCard;

    // Avatar container
    UIView *avatarContainer = [[UIView alloc] init];
    avatarContainer.tag = 50;
    [self.headerView addSubview:avatarContainer];

    // Avatar shadow container
    UIView *avatarShadow = [[UIView alloc] init];
    avatarShadow.backgroundColor = [UIColor clearColor];
    avatarShadow.layer.shadowColor = PinkGradStart.CGColor;
    avatarShadow.layer.shadowOffset = CGSizeMake(0, 4);
    avatarShadow.layer.shadowRadius = 8;
    avatarShadow.layer.shadowOpacity = 0.3;
    [avatarContainer addSubview:avatarShadow];

    UIImageView *avatar = [[UIImageView alloc] init];
    avatar.contentMode = UIViewContentModeScaleAspectFill;
    avatar.clipsToBounds = YES;
    avatar.layer.cornerRadius = 28;
    avatar.backgroundColor = [UIColor colorWithRed:0.941 green:0.929 blue:1.0 alpha:1.0];
    avatar.tag = 10;
    [avatarShadow addSubview:avatar];

    // Online indicator
    UIView *onlineIndicator = [[UIView alloc] init];
    onlineIndicator.backgroundColor = [UIColor whiteColor];
    onlineIndicator.layer.cornerRadius = 9;
    onlineIndicator.tag = 51;
    [avatarContainer addSubview:onlineIndicator];

    UIView *greenDot = [[UIView alloc] init];
    greenDot.backgroundColor = OnlineGreenLight;
    greenDot.layer.cornerRadius = 6;
    greenDot.tag = 52;
    [onlineIndicator addSubview:greenDot];

    // User name
    UILabel *nameLabel = [[UILabel alloc] init];
    nameLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightBold];
    nameLabel.textColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0];
    nameLabel.tag = 11;
    [self.headerView addSubview:nameLabel];

    // Follow button
    UIButton *followBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [followBtn setTitle:@"+关注" forState:UIControlStateNormal];
    followBtn.titleLabel.font = [UIFont systemFontOfSize:12];
    [followBtn setTitleColor:PinkGradStart forState:UIControlStateNormal];
    followBtn.tag = 53;
    [self.headerView addSubview:followBtn];

    // Time
    UILabel *timeLabel = [[UILabel alloc] init];
    timeLabel.font = [UIFont systemFontOfSize:12];
    timeLabel.textColor = [UIColor colorWithRed:0.6 green:0.6 blue:0.6 alpha:1.0];
    timeLabel.tag = 12;
    [self.headerView addSubview:timeLabel];

    // Title
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
    titleLabel.textColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0];
    titleLabel.numberOfLines = 0;
    titleLabel.tag = 13;
    [self.headerView addSubview:titleLabel];

    // Content
    UILabel *contentLabel = [[UILabel alloc] init];
    contentLabel.font = [UIFont systemFontOfSize:14];
    contentLabel.textColor = [UIColor colorWithRed:0.333 green:0.333 blue:0.333 alpha:1.0];
    contentLabel.numberOfLines = 0;
    contentLabel.tag = 14;
    [self.headerView addSubview:contentLabel];

    // Images container
    UIView *imagesContainer = [[UIView alloc] init];
    imagesContainer.tag = 15;
    [self.headerView addSubview:imagesContainer];

    // Action bar
    UIView *actionBar = [[UIView alloc] init];
    actionBar.tag = 16;
    [self.headerView addSubview:actionBar];

    // Like button with pink circle bg
    UIView *likeCircle = [[UIView alloc] init];
    likeCircle.backgroundColor = [UIColor colorWithRed:1.0 green:0.941 blue:0.961 alpha:1.0];
    likeCircle.layer.cornerRadius = 18;
    likeCircle.tag = 60;
    [actionBar addSubview:likeCircle];

    UIButton *likeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    likeBtn.tag = 20;
    [likeCircle addSubview:likeBtn];

    UILabel *likeCountLabel = [[UILabel alloc] init];
    likeCountLabel.font = [UIFont systemFontOfSize:13];
    likeCountLabel.textColor = [UIColor colorWithRed:0.6 green:0.6 blue:0.6 alpha:1.0];
    likeCountLabel.tag = 21;
    [actionBar addSubview:likeCountLabel];

    // Comment button with purple circle bg
    UIView *commentCircle = [[UIView alloc] init];
    commentCircle.backgroundColor = [UIColor colorWithRed:0.941 green:0.91 blue:1.0 alpha:1.0];
    commentCircle.layer.cornerRadius = 18;
    commentCircle.tag = 61;
    [actionBar addSubview:commentCircle];

    UIButton *commentBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [commentBtn setImage:[UIImage systemImageNamed:@"bubble.right"] forState:UIControlStateNormal];
    commentBtn.tintColor = PurpleGradStart;
    commentBtn.tag = 62;
    [commentCircle addSubview:commentBtn];

    // Share button with blue circle bg
    UIView *shareCircle = [[UIView alloc] init];
    shareCircle.backgroundColor = [UIColor colorWithRed:0.91 green:0.961 blue:1.0 alpha:1.0];
    shareCircle.layer.cornerRadius = 18;
    shareCircle.tag = 63;
    [actionBar addSubview:shareCircle];

    UIButton *shareBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [shareBtn setImage:[UIImage systemImageNamed:@"square.and.arrow.up"] forState:UIControlStateNormal];
    shareBtn.tintColor = [UIColor colorWithRed:0.22 green:0.741 blue:0.973 alpha:1.0];
    shareBtn.tag = 64;
    [shareCircle addSubview:shareBtn];

    UIButton *deleteBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [deleteBtn setTitle:@"删除" forState:UIControlStateNormal];
    [deleteBtn setTitleColor:[UIColor systemRedColor] forState:UIControlStateNormal];
    deleteBtn.titleLabel.font = [UIFont systemFontOfSize:13];
    deleteBtn.tag = 22;
    deleteBtn.hidden = YES;
    [deleteBtn addTarget:self action:@selector(deletePostTapped) forControlEvents:UIControlEventTouchUpInside];
    [actionBar addSubview:deleteBtn];

    UIView *separator = [[UIView alloc] init];
    separator.backgroundColor = [UIColor colorWithRed:0.941 green:0.941 blue:0.961 alpha:1.0];
    separator.tag = 30;
    [self.headerView addSubview:separator];

    // Layout header
    [avatarContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.top.equalTo(self.headerView).offset(24);
        make.width.height.equalTo(@56);
    }];

    [avatarShadow mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(avatarContainer);
    }];

    [avatar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(avatarContainer);
    }];

    [onlineIndicator mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.equalTo(@18);
        make.trailing.bottom.equalTo(avatarContainer);
    }];

    [greenDot mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(onlineIndicator);
        make.width.height.equalTo(@12);
    }];

    [nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(avatarContainer.mas_trailing).offset(12);
        make.top.equalTo(avatarContainer).offset(4);
    }];

    [followBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(self.headerView).offset(-24);
        make.centerY.equalTo(nameLabel);
    }];

    [timeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(nameLabel);
        make.top.equalTo(nameLabel.mas_bottom).offset(2);
    }];

    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.equalTo(self.headerView).inset(24);
        make.top.equalTo(avatarContainer.mas_bottom).offset(14);
    }];

    [contentLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.equalTo(titleLabel);
        make.top.equalTo(titleLabel.mas_bottom).offset(6);
    }];

    [imagesContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.equalTo(titleLabel);
        make.top.equalTo(contentLabel.mas_bottom).offset(10);
        make.height.equalTo(@0);
    }];

    [actionBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.equalTo(titleLabel);
        make.top.equalTo(imagesContainer.mas_bottom).offset(14);
        make.height.equalTo(@36);
    }];

    [likeCircle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.centerY.equalTo(actionBar);
        make.width.height.equalTo(@36);
    }];

    [likeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(likeCircle);
        make.width.height.equalTo(@20);
    }];

    [likeCountLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(likeCircle.mas_trailing).offset(4);
        make.centerY.equalTo(actionBar);
    }];

    [commentCircle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(likeCountLabel.mas_trailing).offset(20);
        make.centerY.equalTo(actionBar);
        make.width.height.equalTo(@36);
    }];

    [commentBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(commentCircle);
        make.width.height.equalTo(@20);
    }];

    [shareCircle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(commentCircle.mas_trailing).offset(20);
        make.centerY.equalTo(actionBar);
        make.width.height.equalTo(@36);
    }];

    [shareBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(shareCircle);
        make.width.height.equalTo(@20);
    }];

    [deleteBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.centerY.equalTo(actionBar);
    }];

    [separator mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.equalTo(self.headerView);
        make.top.equalTo(actionBar.mas_bottom).offset(4);
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
        make.trailing.equalTo(self.inputContainerView).offset(-16);
        make.centerY.equalTo(inputBg);
        make.width.height.equalTo(@42);
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
    UIButton *commentBtn = [self.headerView viewWithTag:62];
    UIButton *shareBtn = [self.headerView viewWithTag:64];

    HYPostAuthor *author = self.postDetail.author;
    [avatar sd_setImageWithURL:[NSURL URLWithString:author.avatar] placeholderImage:[UIImage systemImageNamed:@"person.circle.fill"]];
    nameLabel.text = author.userName ?: @"匿名用户";
    timeLabel.text = [NSString stringWithFormat:@"在线 · %@", [self formatTime:self.postDetail.createdAt]];
    titleLabel.text = self.postDetail.title;
    contentLabel.text = self.postDetail.content;

    // Like button
    NSString *likeIcon = self.postDetail.isLiked ? @"heart.fill" : @"heart";
    UIColor *likeColor = self.postDetail.isLiked ? PinkGradStart : [UIColor colorWithRed:0.6 green:0.6 blue:0.6 alpha:1.0];
    [likeBtn setImage:[UIImage systemImageNamed:likeIcon] forState:UIControlStateNormal];
    likeBtn.tintColor = likeColor;
    [likeBtn setTitle:[NSString stringWithFormat:@" %ld", (long)self.postDetail.likesCount] forState:UIControlStateNormal];
    [likeBtn setTitleColor:likeColor forState:UIControlStateNormal];
    likeBtn.titleLabel.font = [UIFont systemFontOfSize:13];
    likeCountLabel.text = [NSString stringWithFormat:@"%ld", (long)self.postDetail.likesCount];
    [likeBtn removeTarget:self action:NULL forControlEvents:UIControlEventAllEvents];
    [likeBtn addTarget:self action:@selector(likeTapped) forControlEvents:UIControlEventTouchUpInside];

    // Comment count
    [commentBtn removeTarget:self action:NULL forControlEvents:UIControlEventAllEvents];
    [commentBtn addTarget:self action:@selector(commentButtonTapped) forControlEvents:UIControlEventTouchUpInside];

    // Share
    [shareBtn removeTarget:self action:NULL forControlEvents:UIControlEventAllEvents];
    [shareBtn addTarget:self action:@selector(shareTapped) forControlEvents:UIControlEventTouchUpInside];

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

- (void)commentButtonTapped {
    [self.inputTextView becomeFirstResponder];
}

- (void)shareTapped {
    NSString *textToShare = [NSString stringWithFormat:@"%@ - 来自Hiyo", self.postDetail.title ?: @""];
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[textToShare] applicationActivities:nil];
    [self presentViewController:activityVC animated:YES completion:nil];
}

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

- (void)replyToComment:(UIButton *)sender {
    NSInteger index = sender.tag - 200;
    if (index >= 0 && index < (NSInteger)self.postDetail.comments.count) {
        HYPostComment *comment = self.postDetail.comments[index];
        self.inputTextView.text = [NSString stringWithFormat:@"回复 %@: ", comment.userName ?: @""];
        UILabel *placeholder = [self.inputTextView.superview viewWithTag:100];
        placeholder.hidden = YES;
        self.sendButton.enabled = YES;
        [self.inputTextView becomeFirstResponder];
    }
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

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (!self.postDetail || self.postDetail.comments.count == 0) return nil;

    UIView *header = [[UIView alloc] init];
    header.backgroundColor = [UIColor clearColor];

    UIView *line = [[UIView alloc] init];
    line.backgroundColor = [UIColor colorWithRed:0.941 green:0.941 blue:0.961 alpha:1.0];
    [header addSubview:line];

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = [NSString stringWithFormat:@"评论 %ld", (long)self.postDetail.comments.count];
    titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
    titleLabel.textColor = [UIColor colorWithRed:0.4 green:0.4 blue:0.4 alpha:1.0];
    [header addSubview:titleLabel];

    [line mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.bottom.equalTo(header);
        make.height.equalTo(@1);
    }];

    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(header).offset(24);
        make.bottom.equalTo(line.mas_top).offset(-8);
    }];

    [header mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@45);
    }];

    return header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (!self.postDetail || self.postDetail.comments.count == 0) return 0;
    return 45;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"CommentCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.backgroundColor = [UIColor clearColor];
        cell.contentView.backgroundColor = [UIColor clearColor];

        UIView *container = [[UIView alloc] init];
        container.tag = 100;
        [cell.contentView addSubview:container];

        UIImageView *avatar = [[UIImageView alloc] init];
        avatar.contentMode = UIViewContentModeScaleAspectFill;
        avatar.clipsToBounds = YES;
        avatar.layer.cornerRadius = 20;
        avatar.backgroundColor = [UIColor colorWithRed:0.91 green:0.878 blue:1.0 alpha:1.0];
        avatar.tag = 101;
        [container addSubview:avatar];

        UILabel *nameLabel = [[UILabel alloc] init];
        nameLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightBold];
        nameLabel.textColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0];
        nameLabel.tag = 102;
        [container addSubview:nameLabel];

        UILabel *contentLabel = [[UILabel alloc] init];
        contentLabel.font = [UIFont systemFontOfSize:13];
        contentLabel.textColor = [UIColor colorWithRed:0.333 green:0.333 blue:0.333 alpha:1.0];
        contentLabel.numberOfLines = 0;
        contentLabel.tag = 103;
        [container addSubview:contentLabel];

        UILabel *timeLabel = [[UILabel alloc] init];
        timeLabel.font = [UIFont systemFontOfSize:11];
        timeLabel.textColor = [UIColor colorWithRed:0.6 green:0.6 blue:0.6 alpha:1.0];
        timeLabel.tag = 104;
        [container addSubview:timeLabel];

        UIButton *replyBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        [replyBtn setTitle:@"回复" forState:UIControlStateNormal];
        replyBtn.titleLabel.font = [UIFont systemFontOfSize:12];
        [replyBtn setTitleColor:PinkGradStart forState:UIControlStateNormal];
        replyBtn.tag = 105;
        [container addSubview:replyBtn];

        [container mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(cell.contentView).insets(UIEdgeInsetsMake(8, 24, 8, 24));
        }];

        [avatar mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.top.equalTo(container);
            make.width.height.equalTo(@40);
        }];

        [nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(avatar.mas_trailing).offset(10);
            make.top.equalTo(avatar).offset(2);
            make.trailing.lessThanOrEqualTo(replyBtn.mas_leading).offset(-4);
        }];

        [contentLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(nameLabel);
            make.top.equalTo(nameLabel.mas_bottom).offset(3);
            make.trailing.equalTo(container);
        }];

        [timeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(nameLabel);
            make.top.equalTo(contentLabel.mas_bottom).offset(3);
            make.bottom.equalTo(container);
        }];

        [replyBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.trailing.equalTo(container);
            make.centerY.equalTo(timeLabel);
        }];
    }

    HYPostComment *comment = self.postDetail.comments[indexPath.row];

    UIView *container = [cell.contentView viewWithTag:100];
    UIImageView *avatar = [container viewWithTag:101];
    UILabel *nameLabel = [container viewWithTag:102];
    UILabel *contentLabel = [container viewWithTag:103];
    UILabel *timeLabel = [container viewWithTag:104];
    UIButton *replyBtn = [container viewWithTag:105];

    [avatar sd_setImageWithURL:[NSURL URLWithString:comment.userAvatar] placeholderImage:[UIImage systemImageNamed:@"person.circle.fill"]];
    nameLabel.text = comment.userName ?: @"匿名用户";
    contentLabel.text = comment.content;
    timeLabel.text = [self formatTime:comment.createdAt];
    replyBtn.tag = 200 + indexPath.row;

    [replyBtn removeTarget:self action:NULL forControlEvents:UIControlEventAllEvents];
    [replyBtn addTarget:self action:@selector(replyToComment:) forControlEvents:UIControlEventTouchUpInside];

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
