#import "ChatDetailViewController.h"
#import "HYAPIClient.h"
#import "HYChatMessage.h"
#import "HYModels.h"
#import "HYWebSocketManager.h"
#import "HYGift.h"
#import "GiftPanelSheetController.h"
#import "UserProfileViewController.h"
#import "WalletViewController.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/SDWebImage.h>
#import <PhotosUI/PhotosUI.h>

static NSString * const kChatBubbleCellId = @"ChatBubbleCell";
static CGFloat const kInputBarHeight = 56.0;
static CGFloat const kBubbleMaxWidth = 260.0;

@interface HYUserInfo : NSObject
@property (nonatomic, copy) NSString *userId;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *avatar;
@property (nonatomic, copy) NSString *bio;
@property (nonatomic, assign) NSInteger sex;
@property (nonatomic, assign) BOOL isOnline;
@property (nonatomic, copy) NSArray<NSString *> *photos;
@end
@implementation HYUserInfo
- (instancetype)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        _userId = [NSString stringWithFormat:@"%@", dict[@"id"] ?: @""];
        _name = dict[@"name"] ?: @"";
        _avatar = dict[@"avatar"] ?: @"";
        _bio = dict[@"bio"] ?: @"";
        _sex = [dict[@"sex"] integerValue];
        _isOnline = [dict[@"is_online"] boolValue];
        _photos = dict[@"photos"];
        if (![_photos isKindOfClass:[NSArray class]]) _photos = @[];
    }
    return self;
}
@end

@interface ChatBubbleCell : UITableViewCell
- (void)configWithMessage:(HYChatMessage *)message;
@end

@interface ChatDetailViewController () <UITableViewDelegate, UITableViewDataSource, UITextViewDelegate, PHPickerViewControllerDelegate>

@property (nonatomic, copy) NSString *partnerId;
@property (nonatomic, copy) NSString *partnerName;
@property (nonatomic, copy) NSString *partnerAvatar;

// UI
@property (nonatomic, strong) UIView *topBar;
@property (nonatomic, strong) UIImageView *topAvatarImageView;
@property (nonatomic, strong) UILabel *topNameLabel;
@property (nonatomic, strong) UILabel *topStatusLabel;
@property (nonatomic, strong) UIButton *backButton;

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIView *inputBar;
@property (nonatomic, strong) UIButton *imageButton;
@property (nonatomic, strong) UIButton *giftButton;
@property (nonatomic, strong) UITextView *inputTextView;
@property (nonatomic, strong) UILabel *inputPlaceholder;
@property (nonatomic, strong) UIButton *sendButton;

@property (nonatomic, strong) NSMutableArray<HYChatMessage *> *messages;
@property (nonatomic, strong) HYUserInfo *partnerInfo;
@property (nonatomic, strong) NSString *currentUserId;
@property (nonatomic, strong) UIActivityIndicatorView *loadingIndicator;
@property (nonatomic, strong) NSMutableArray<NSData *> *pendingImages;
@property (nonatomic, strong) UIView *profileHeader;
@property (nonatomic, assign) BOOL isLoading;

@end

@implementation ChatDetailViewController

- (instancetype)initWithPartnerId:(NSString *)partnerId
                       partnerName:(NSString *)partnerName
                     partnerAvatar:(NSString *)partnerAvatar {
    self = [super init];
    if (self) {
        _partnerId = partnerId;
        _partnerName = partnerName;
        _partnerAvatar = partnerAvatar;
        _messages = [NSMutableArray array];
        _pendingImages = [NSMutableArray array];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    self.messages = [NSMutableArray array];
    [self setupUI];
    [self setupNotifications];
    [self loadChatHistory];
    [self loadPartnerInfo];
    [self markAsRead];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.navigationController.navigationBarHidden = NO;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"HYChatPartnerDidCloseNotification" object:self.partnerId];
}

#pragma mark - Setup

- (void)setupUI {
    [self setupTopBar];
    [self setupTableView];
    [self setupInputBar];
    [self setupConstraints];
}

- (void)setupTopBar {
    // Gradient background
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.colors = @[(id)[UIColor systemPinkColor].CGColor, (id)[UIColor systemPurpleColor].CGColor];
    gradient.startPoint = CGPointMake(0, 0);
    gradient.endPoint = CGPointMake(1, 1);

    self.topBar = [[UIView alloc] init];
    self.topBar.backgroundColor = [UIColor systemPinkColor];
    [self.view addSubview:self.topBar];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        gradient.frame = self.topBar.bounds;
        [self.topBar.layer insertSublayer:gradient atIndex:0];
    });

    // Back button
    self.backButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.backButton setImage:[UIImage systemImageNamed:@"chevron.left"] forState:UIControlStateNormal];
    self.backButton.tintColor = [UIColor whiteColor];
    [self.backButton addTarget:self action:@selector(backTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.topBar addSubview:self.backButton];

    // Avatar
    self.topAvatarImageView = [[UIImageView alloc] init];
    self.topAvatarImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.topAvatarImageView.clipsToBounds = YES;
    self.topAvatarImageView.layer.cornerRadius = 18;
    self.topAvatarImageView.layer.borderWidth = 1.5;
    self.topAvatarImageView.layer.borderColor = [UIColor whiteColor].CGColor;
    self.topAvatarImageView.backgroundColor = [UIColor systemGray5Color];
    if (self.partnerAvatar.length > 0) {
        [self.topAvatarImageView sd_setImageWithURL:[NSURL URLWithString:self.partnerAvatar]
                                 placeholderImage:[UIImage systemImageNamed:@"person.circle.fill"]];
    } else {
        self.topAvatarImageView.image = [UIImage systemImageNamed:@"person.circle.fill"];
    }
    [self.topBar addSubview:self.topAvatarImageView];

    // Name
    self.topNameLabel = [[UILabel alloc] init];
    self.topNameLabel.text = self.partnerName ?: @"";
    self.topNameLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    self.topNameLabel.textColor = [UIColor whiteColor];
    [self.topBar addSubview:self.topNameLabel];

    // Status
    self.topStatusLabel = [[UILabel alloc] init];
    self.topStatusLabel.text = @"";
    self.topStatusLabel.font = [UIFont systemFontOfSize:12];
    self.topStatusLabel.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.8];
    [self.topBar addSubview:self.topStatusLabel];
}

- (void)setupTableView {
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.backgroundColor = [UIColor systemBackgroundColor];
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    self.tableView.estimatedRowHeight = 60;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    [self.tableView registerClass:[ChatBubbleCell class] forCellReuseIdentifier:kChatBubbleCellId];
    [self.view addSubview:self.tableView];

    self.loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    self.loadingIndicator.color = [UIColor systemPinkColor];
    self.loadingIndicator.hidesWhenStopped = YES;
    [self.view addSubview:self.loadingIndicator];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    tap.cancelsTouchesInView = NO;
    [self.tableView addGestureRecognizer:tap];
}

- (void)setupInputBar {
    self.inputBar = [[UIView alloc] init];
    self.inputBar.backgroundColor = [UIColor systemBackgroundColor];
    self.inputBar.layer.borderWidth = 0.5;
    self.inputBar.layer.borderColor = [UIColor separatorColor].CGColor;
    [self.view addSubview:self.inputBar];

    // Image button
    self.imageButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.imageButton setImage:[UIImage systemImageNamed:@"photo"] forState:UIControlStateNormal];
    self.imageButton.tintColor = [UIColor systemGrayColor];
    [self.imageButton addTarget:self action:@selector(imageButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.inputBar addSubview:self.imageButton];

    // Gift button (pink gradient background)
    self.giftButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.giftButton setImage:[UIImage systemImageNamed:@"gift.fill"] forState:UIControlStateNormal];
    self.giftButton.tintColor = [UIColor whiteColor];
    self.giftButton.backgroundColor = [UIColor colorWithRed:236/255.0 green:72/255.0 blue:153/255.0 alpha:1];
    self.giftButton.layer.cornerRadius = 18;
    [self.giftButton addTarget:self action:@selector(giftButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.inputBar addSubview:self.giftButton];

    // Text input
    self.inputTextView = [[UITextView alloc] init];
    self.inputTextView.font = [UIFont systemFontOfSize:16];
    self.inputTextView.textColor = [UIColor labelColor];
    self.inputTextView.backgroundColor = [UIColor secondarySystemGroupedBackgroundColor];
    self.inputTextView.layer.cornerRadius = 18;
    self.inputTextView.textContainerInset = UIEdgeInsetsMake(8, 10, 8, 10);
    self.inputTextView.delegate = self;
    self.inputTextView.showsVerticalScrollIndicator = NO;
    [self.inputBar addSubview:self.inputTextView];

    // Placeholder
    self.inputPlaceholder = [[UILabel alloc] init];
    self.inputPlaceholder.text = @"说点什么...";
    self.inputPlaceholder.font = [UIFont systemFontOfSize:16];
    self.inputPlaceholder.textColor = [UIColor placeholderTextColor];
    [self.inputTextView addSubview:self.inputPlaceholder];

    // Send button
    self.sendButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.sendButton setImage:[UIImage systemImageNamed:@"arrow.up.circle.fill"] forState:UIControlStateNormal];
    self.sendButton.tintColor = [UIColor systemPinkColor];
    self.sendButton.enabled = NO;
    [self.sendButton addTarget:self action:@selector(sendTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.inputBar addSubview:self.sendButton];
}

- (void)setupConstraints {
    [self.topBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.trailing.equalTo(self.view);
        make.height.equalTo(@100);
    }];

    [self.backButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.topBar).offset(8);
        make.bottom.equalTo(self.topBar).offset(-12);
        make.width.height.equalTo(@44);
    }];

    [self.topAvatarImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.backButton.mas_trailing).offset(4);
        make.centerY.equalTo(self.backButton);
        make.width.height.equalTo(@36);
    }];

    [self.topNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.topAvatarImageView.mas_trailing).offset(10);
        make.top.equalTo(self.topAvatarImageView).offset(-2);
        make.trailing.lessThanOrEqualTo(self.topBar).offset(-60);
    }];

    [self.topStatusLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.topNameLabel);
        make.top.equalTo(self.topNameLabel.mas_bottom).offset(1);
    }];

    [self.inputBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.equalTo(self.view);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom);
        make.height.greaterThanOrEqualTo(@(kInputBarHeight));
    }];

    [self.imageButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.inputBar).offset(8);
        make.centerY.equalTo(self.inputBar);
        make.width.height.equalTo(@36);
    }];

    [self.giftButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.imageButton.mas_trailing).offset(4);
        make.centerY.equalTo(self.inputBar);
        make.width.height.equalTo(@36);
    }];

    [self.sendButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(self.inputBar).offset(-8);
        make.centerY.equalTo(self.inputBar);
        make.width.height.equalTo(@36);
    }];

    [self.inputTextView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.giftButton.mas_trailing).offset(8);
        make.trailing.equalTo(self.sendButton.mas_leading).offset(-8);
        make.top.equalTo(self.inputBar).offset(8);
        make.bottom.equalTo(self.inputBar).offset(-8);
        make.height.greaterThanOrEqualTo(@36);
        make.height.lessThanOrEqualTo(@120);
    }];

    [self.inputPlaceholder mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.inputTextView).offset(14);
        make.centerY.equalTo(self.inputTextView);
    }];

    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.topBar.mas_bottom);
        make.leading.trailing.equalTo(self.view);
        make.bottom.equalTo(self.inputBar.mas_top);
    }];

    [self.loadingIndicator mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.tableView);
    }];
}

#pragma mark - Notifications

- (void)setupNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleWebSocketMessage:)
                                                 name:HYWebSocketMessageReceivedNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleGiftNotification:)
                                                 name:HYWebSocketGiftNotificationReceivedNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)handleWebSocketMessage:(NSNotification *)notification {
    HYChatMessage *msg = notification.object;
    if (![msg isKindOfClass:[HYChatMessage class]]) return;

    // Only handle messages from current partner
    BOOL isFromPartner = [msg.senderId isEqualToString:self.partnerId];
    BOOL isToMe = [msg.receiverId isEqualToString:self.partnerId]; // sent by me

    if (isFromPartner) {
        msg.isFromMe = NO;
        [self.messages addObject:msg];
        [self.tableView reloadData];
        [self scrollToBottomAnimated:YES];
        [self markAsRead];
    } else if (isToMe) {
        // Update pending message with real data
        msg.isFromMe = YES;
        msg.sendStatus = HYMessageSendStatusSuccess;
        // Find and replace pending message by content match
        for (NSInteger i = 0; i < self.messages.count; i++) {
            HYChatMessage *existing = self.messages[i];
            if (existing.sendStatus == HYMessageSendStatusSending &&
                [existing.content isEqualToString:msg.content]) {
                [self.messages replaceObjectAtIndex:i withObject:msg];
                [self.tableView reloadData];
                [self scrollToBottomAnimated:YES];
                return;
            }
        }
    }
}

- (void)handleGiftNotification:(NSNotification *)notification {
    NSDictionary *payload = notification.object;
    if (![payload isKindOfClass:[NSDictionary class]]) return;

    NSString *senderId = [NSString stringWithFormat:@"%@", payload[@"sender_id"] ?: @""];
    if (![senderId isEqualToString:self.partnerId]) return;

    NSString *iconUrl = payload[@"gift_icon_url"] ?: @"";
    NSString *giftName = payload[@"gift_name"] ?: @"";
    NSInteger quantity = [payload[@"quantity"] integerValue];
    NSString *effectUrl = payload[@"effect_url"] ?: @"";

    HYGiftBubble *bubble = [[HYGiftBubble alloc] init];
    bubble.iconUrl = iconUrl;
    bubble.name = giftName;
    bubble.quantity = quantity;
    bubble.effectUrl = effectUrl;

    HYChatMessage *msg = [[HYChatMessage alloc] init];
    msg.msgId = [NSString stringWithFormat:@"ws_%@", [[NSUUID UUID] UUIDString]];
    msg.content = @"";
    msg.type = @"gift";
    msg.giftIconUrl = iconUrl;
    msg.giftName = giftName;
    msg.giftQuantity = quantity;
    msg.giftEffectUrl = effectUrl;
    msg.senderId = senderId;
    msg.receiverId = @"";
    msg.timestamp = payload[@"created_at"] ?: @"";
    msg.isFromMe = NO;
    msg.sendStatus = HYMessageSendStatusSuccess;

    [self.messages addObject:msg];
    [self.tableView reloadData];
    [self scrollToBottomAnimated:YES];
    [self markAsRead];

    // Play effect
    if (effectUrl.length > 0) {
        [self playGiftEffect:effectUrl];
    }
}

- (void)playGiftEffect:(NSString *)effectUrl {
    // Full-screen gift effect overlay (simplified: just show a toast)
    UIView *overlay = [[UIView alloc] initWithFrame:self.view.bounds];
    overlay.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.3];
    overlay.alpha = 0;
    [self.view addSubview:overlay];

    UIImageView *effectView = [[UIImageView alloc] init];
    effectView.contentMode = UIViewContentModeScaleAspectFit;
    [effectView sd_setImageWithURL:[NSURL URLWithString:effectUrl] placeholderImage:nil];
    effectView.frame = CGRectMake(0, 0, 200, 200);
    effectView.center = self.view.center;
    [overlay addSubview:effectView];

    [UIView animateWithDuration:0.3 animations:^{
        overlay.alpha = 1;
    } completion:^(BOOL finished) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.3 animations:^{
                overlay.alpha = 0;
            } completion:^(BOOL finished) {
                [overlay removeFromSuperview];
            }];
        });
    }];
}

- (void)keyboardWillShow:(NSNotification *)notification {
    CGRect keyboardFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    NSTimeInterval duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];

    [self.inputBar mas_updateConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view).offset(-keyboardFrame.size.height);
    }];

    [UIView animateWithDuration:duration animations:^{
        [self.view layoutIfNeeded];
    }];
    [self scrollToBottomAnimated:YES];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    NSTimeInterval duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];

    [self.inputBar mas_updateConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom);
    }];

    [UIView animateWithDuration:duration animations:^{
        [self.view layoutIfNeeded];
    }];
}

#pragma mark - Data Loading

- (void)loadChatHistory {
    if (self.isLoading) return;
    self.isLoading = YES;
    [self.loadingIndicator startAnimating];

    [[HYAPIClient shared] getChatHistoryWithPartnerId:self.partnerId limit:50 offset:0 completion:^(NSDictionary *response, NSError *error) {
        self.isLoading = NO;
        [self.loadingIndicator stopAnimating];

        if (error) {
            NSLog(@"Failed to load chat history: %@", error.localizedDescription);
            return;
        }

        id data = response[@"data"];
        if ([data isKindOfClass:[NSDictionary class]]) {
            NSArray *messagesData = data[@"messages"];
            if ([messagesData isKindOfClass:[NSArray class]]) {
                [self.messages removeAllObjects];
                for (NSDictionary *dict in messagesData) {
                    HYChatMessage *msg = [[HYChatMessage alloc] initWithDictionary:dict];
                    msg.isFromMe = [msg.senderId isEqualToString:self.partnerId] ? NO : YES;
                    [self.messages addObject:msg];
                }
                [self.tableView reloadData];
                [self scrollToBottomAnimated:NO];
            }
        }
    }];
}

- (void)loadPartnerInfo {
    [[HYAPIClient shared] getUserInfoWithId:self.partnerId completion:^(NSDictionary *response, NSError *error) {
        if (error) return;

        NSDictionary *data = response[@"data"];
        if ([data isKindOfClass:[NSDictionary class]]) {
            self.partnerInfo = [[HYUserInfo alloc] initWithDictionary:data];
            [self updateTopBarWithInfo];
            [self buildProfileHeader];
            [self.tableView reloadData];
        }
    }];
}

- (void)updateTopBarWithInfo {
    if (!self.partnerInfo) return;
    self.topNameLabel.text = self.partnerInfo.name;
    self.topStatusLabel.text = self.partnerInfo.isOnline ? @"在线" : @"离线";
    if (self.partnerInfo.avatar.length > 0) {
        [self.topAvatarImageView sd_setImageWithURL:[NSURL URLWithString:self.partnerInfo.avatar]];
    }
}

- (void)buildProfileHeader {
    if (!self.partnerInfo) return;

    self.profileHeader = [[UIView alloc] init];
    self.profileHeader.backgroundColor = [UIColor secondarySystemBackgroundColor];
    self.profileHeader.frame = CGRectMake(0, 0, self.view.bounds.size.width, 120);

    UIImageView *avatar = [[UIImageView alloc] init];
    avatar.contentMode = UIViewContentModeScaleAspectFill;
    avatar.clipsToBounds = YES;
    avatar.layer.cornerRadius = 28;
    avatar.backgroundColor = [UIColor systemGray5Color];
    if (self.partnerInfo.avatar.length > 0) {
        [avatar sd_setImageWithURL:[NSURL URLWithString:self.partnerInfo.avatar]
                 placeholderImage:[UIImage systemImageNamed:@"person.circle.fill"]];
    }
    [self.profileHeader addSubview:avatar];

    UILabel *nameLabel = [[UILabel alloc] init];
    nameLabel.text = self.partnerInfo.name;
    nameLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    nameLabel.textColor = [UIColor labelColor];
    [self.profileHeader addSubview:nameLabel];

    NSString *statusText = self.partnerInfo.isOnline ? @"🟢 在线" : @"⚫ 离线";
    UILabel *statusLabel = [[UILabel alloc] init];
    statusLabel.text = statusText;
    statusLabel.font = [UIFont systemFontOfSize:13];
    statusLabel.textColor = [UIColor secondaryLabelColor];
    [self.profileHeader addSubview:statusLabel];

    UILabel *bioLabel = [[UILabel alloc] init];
    bioLabel.text = self.partnerInfo.bio;
    bioLabel.font = [UIFont systemFontOfSize:14];
    bioLabel.textColor = [UIColor secondaryLabelColor];
    bioLabel.numberOfLines = 2;
    [self.profileHeader addSubview:bioLabel];

    [avatar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.profileHeader).offset(16);
        make.top.equalTo(self.profileHeader).offset(12);
        make.width.height.equalTo(@56);
    }];

    [nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(avatar.mas_trailing).offset(12);
        make.top.equalTo(avatar).offset(4);
    }];

    [statusLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(nameLabel);
        make.top.equalTo(nameLabel.mas_bottom).offset(2);
    }];

    [bioLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(avatar);
        make.trailing.equalTo(self.profileHeader).offset(-16);
        make.top.equalTo(avatar.mas_bottom).offset(10);
    }];

    [self.tableView setTableHeaderView:self.profileHeader];

    UITapGestureRecognizer *headerTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(profileHeaderTapped)];
    [self.profileHeader addGestureRecognizer:headerTap];
}

- (void)profileHeaderTapped {
    UserProfileViewController *vc = [[UserProfileViewController alloc] initWithUserId:self.partnerId];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)markAsRead {
    [[HYAPIClient shared] markChatReadWithPartnerId:self.partnerId chatType:1 completion:^(NSDictionary *response, NSError *error) {
        // Post notification to update badge
        [[NSNotificationCenter defaultCenter] postNotificationName:@"HYChatReadNotification" object:self.partnerId];
    }];
}

#pragma mark - Actions

- (void)backTapped {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)dismissKeyboard {
    [self.view endEditing:YES];
}

- (void)imageButtonTapped {
    PHPickerConfiguration *config = [[PHPickerConfiguration alloc] init];
    config.selectionLimit = 1;
    config.filter = [PHPickerFilter imagesFilter];

    PHPickerViewController *picker = [[PHPickerViewController alloc] initWithConfiguration:config];
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)giftButtonTapped {
    GiftPanelSheetController *sheet = [[GiftPanelSheetController alloc] init];
    sheet.receiverId = [self.partnerId integerValue];
    sheet.modalPresentationStyle = UIModalPresentationOverFullScreen;
    sheet.modalTransitionStyle = UIModalTransitionStyleCoverVertical;

    __weak typeof(self) weakSelf = self;
    sheet.onGiftSent = ^(HYGiftBubble *bubble, BOOL isFromMe) {
        [weakSelf handleGiftSent:bubble];
    };
    sheet.onDismiss = ^{
        [weakSelf dismissViewControllerAnimated:YES completion:nil];
    };
    sheet.onInsufficientBalance = ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Insufficient Balance" message:@"You don't have enough coins. Would you like to recharge?" preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Recharge" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            WalletViewController *wallet = [[WalletViewController alloc] init];
            [weakSelf.navigationController pushViewController:wallet animated:YES];
        }]];
        [weakSelf presentViewController:alert animated:YES completion:nil];
    };

    [self presentViewController:sheet animated:YES completion:nil];
}

- (void)handleGiftSent:(HYGiftBubble *)bubble {
    // Build gift extra JSON
    NSDictionary *extraDict = @{
        @"icon_url": bubble.iconUrl ?: @"",
        @"name": bubble.name ?: @"",
        @"quantity": @(bubble.quantity),
        @"effect_url": bubble.effectUrl ?: @""
    };
    NSData *extraData = [NSJSONSerialization dataWithJSONObject:extraDict options:0 error:nil];
    NSString *extra = [[NSString alloc] initWithData:extraData encoding:NSUTF8StringEncoding];

    // Create gift message
    HYChatMessage *msg = [[HYChatMessage alloc] init];
    msg.msgId = [NSString stringWithFormat:@"local_%@", [[NSUUID UUID] UUIDString]];
    msg.content = @"";
    msg.type = @"gift";
    msg.giftIconUrl = bubble.iconUrl;
    msg.giftName = bubble.name;
    msg.giftQuantity = bubble.quantity;
    msg.giftEffectUrl = bubble.effectUrl;
    msg.senderId = @"";
    msg.receiverId = self.partnerId;
    msg.timestamp = [HYChatMessage isoTimestamp];
    msg.isFromMe = YES;
    msg.sendStatus = HYMessageSendStatusSending;

    [self.messages addObject:msg];
    [self.tableView reloadData];
    [self scrollToBottomAnimated:YES];

    // Send via WebSocket
    [[HYWebSocketManager shared] sendMessageWithContent:@"" type:@"gift" extra:extra receiverId:self.partnerId];

    msg.sendStatus = HYMessageSendStatusSuccess;
    [self.tableView reloadData];

    // Play effect if available
    if (bubble.effectUrl.length > 0) {
        [self playGiftEffect:bubble.effectUrl];
    }
}

- (void)sendTapped {
    NSString *content = [self.inputTextView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (content.length == 0 && self.pendingImages.count == 0) return;

    if (self.pendingImages.count > 0) {
        [self uploadAndSendImageMessage];
    } else {
        [self sendTextMessage:content];
    }
}

- (void)sendTextMessage:(NSString *)content {
    NSString *trimmed = [content stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (trimmed.length == 0) return;

    self.inputTextView.text = @"";
    self.inputPlaceholder.hidden = NO;
    self.sendButton.enabled = NO;

    // Optimistic: create pending message
    HYChatMessage *pending = [HYChatMessage pendingMessageWithContent:trimmed type:HYMessageTypeText receiverId:self.partnerId localImagePath:nil];
    pending.isFromMe = YES;
    [self.messages addObject:pending];
    [self.tableView reloadData];
    [self scrollToBottomAnimated:YES];

    [[HYAPIClient shared] sendMessageToPartnerId:self.partnerId content:trimmed type:@"text" extra:@"" completion:^(NSDictionary *response, NSError *error) {
        if (error) {
            pending.sendStatus = HYMessageSendStatusFailed;
            [self.tableView reloadData];
        }
    }];
}

- (void)uploadAndSendImageMessage {
    if (self.pendingImages.count == 0) return;

    NSData *imageData = self.pendingImages.firstObject;
    [self.pendingImages removeObjectAtIndex:0];

    // Create pending message
    HYChatMessage *pending = [HYChatMessage pendingMessageWithContent:@"" type:HYMessageTypeImage receiverId:self.partnerId localImagePath:@"local_image"];
    pending.isFromMe = YES;
    [self.messages addObject:pending];
    [self.tableView reloadData];
    [self scrollToBottomAnimated:YES];

    NSString *fileName = [NSString stringWithFormat:@"chat_%@_%@.jpg", self.partnerId, @([[NSDate date] timeIntervalSince1970])];

    [[HYAPIClient shared] uploadImageWithData:imageData fileName:fileName completion:^(NSDictionary *response, NSError *error) {
        if (error) {
            pending.sendStatus = HYMessageSendStatusFailed;
            [self.tableView reloadData];
            return;
        }

        NSDictionary *data = response[@"data"];
        NSString *imageUrl = data[@"url"];
        if (!imageUrl) {
            pending.sendStatus = HYMessageSendStatusFailed;
            [self.tableView reloadData];
            return;
        }

        [[HYAPIClient shared] sendMessageToPartnerId:self.partnerId content:imageUrl type:@"image" extra:@"" completion:^(NSDictionary *response, NSError *error) {
            if (error) {
                pending.sendStatus = HYMessageSendStatusFailed;
            }
            [self.tableView reloadData];
        }];
    }];
}

- (void)scrollToBottomAnimated:(BOOL)animated {
    if (self.messages.count == 0) return;
    NSIndexPath *lastIndex = [NSIndexPath indexPathForRow:self.messages.count - 1 inSection:0];
    [self.tableView scrollToRowAtIndexPath:lastIndex atScrollPosition:UITableViewScrollPositionBottom animated:animated];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.messages.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ChatBubbleCell *cell = [tableView dequeueReusableCellWithIdentifier:kChatBubbleCellId forIndexPath:indexPath];
    HYChatMessage *msg = self.messages[indexPath.row];
    [cell configWithMessage:msg];
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self dismissKeyboard];
}

#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView {
    self.inputPlaceholder.hidden = (textView.text.length > 0);
    self.sendButton.enabled = (textView.text.length > 0 || self.pendingImages.count > 0);
}

#pragma mark - PHPickerViewControllerDelegate

- (void)picker:(PHPickerViewController *)picker didFinishPicking:(NSArray<PHPickerResult *> *)results {
    [picker dismissViewControllerAnimated:YES completion:nil];
    if (results.count == 0) return;

    PHPickerResult *result = results.firstObject;
    [result.itemProvider loadObjectOfClass:[UIImage class] completionHandler:^(id<NSItemProviderReading> object, NSError *error) {
        if (!object || ![object isKindOfClass:[UIImage class]]) return;
        UIImage *image = (UIImage *)object;
        CGFloat maxDim = 1080;
        CGFloat ratio = image.size.width / image.size.height;
        CGFloat w = maxDim, h = maxDim;
        if (image.size.width > image.size.height) {
            w = maxDim;
            h = maxDim / ratio;
        } else {
            h = maxDim;
            w = maxDim * ratio;
        }
        CGSize size = CGSizeMake(w, h);
        UIGraphicsBeginImageContextWithOptions(size, NO, 1.0);
        [image drawInRect:CGRectMake(0, 0, w, h)];
        UIImage *resized = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        NSData *data = UIImageJPEGRepresentation(resized ?: image, 0.8);
        if (!data) return;

        dispatch_async(dispatch_get_main_queue(), ^{
            [self.pendingImages addObject:data];
            self.sendButton.enabled = YES;
        });
    }];
}

@end

#pragma mark - ChatBubbleCell

@interface ChatBubbleCell ()
@property (nonatomic, strong) UIView *bubbleView;
@property (nonatomic, strong) UILabel *contentLabel;
@property (nonatomic, strong) UIImageView *contentImageView;
@property (nonatomic, strong) UIImageView *giftIconView;
@property (nonatomic, strong) UILabel *giftNameLabel;
@property (nonatomic, strong) UILabel *giftQuantityLabel;
@property (nonatomic, strong) UIActivityIndicatorView *loadingIndicator;
@property (nonatomic, strong) UIButton *retryButton;
@property (nonatomic, strong) HYChatMessage *message;
@end

@implementation ChatBubbleCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.bubbleView = [[UIView alloc] init];
    self.bubbleView.layer.cornerRadius = 16;
    [self.contentView addSubview:self.bubbleView];

    self.contentLabel = [[UILabel alloc] init];
    self.contentLabel.font = [UIFont systemFontOfSize:16];
    self.contentLabel.numberOfLines = 0;
    [self.bubbleView addSubview:self.contentLabel];

    self.contentImageView = [[UIImageView alloc] init];
    self.contentImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.contentImageView.clipsToBounds = YES;
    self.contentImageView.layer.cornerRadius = 12;
    self.contentImageView.hidden = YES;
    self.contentImageView.userInteractionEnabled = YES;
    [self.bubbleView addSubview:self.contentImageView];

    self.giftIconView = [[UIImageView alloc] init];
    self.giftIconView.contentMode = UIViewContentModeScaleAspectFit;
    self.giftIconView.hidden = YES;
    [self.bubbleView addSubview:self.giftIconView];

    self.giftNameLabel = [[UILabel alloc] init];
    self.giftNameLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    self.giftNameLabel.textAlignment = NSTextAlignmentCenter;
    self.giftNameLabel.hidden = YES;
    [self.bubbleView addSubview:self.giftNameLabel];

    self.giftQuantityLabel = [[UILabel alloc] init];
    self.giftQuantityLabel.font = [UIFont systemFontOfSize:11];
    self.giftQuantityLabel.textAlignment = NSTextAlignmentCenter;
    self.giftQuantityLabel.hidden = YES;
    [self.bubbleView addSubview:self.giftQuantityLabel];

    self.loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    self.loadingIndicator.hidesWhenStopped = YES;
    [self.bubbleView addSubview:self.loadingIndicator];

    self.retryButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.retryButton setTitle:@"重试" forState:UIControlStateNormal];
    self.retryButton.titleLabel.font = [UIFont systemFontOfSize:12];
    self.retryButton.tintColor = [UIColor systemRedColor];
    self.retryButton.hidden = YES;
    [self.bubbleView addSubview:self.retryButton];
}

- (void)configWithMessage:(HYChatMessage *)message {
    self.message = message;

    [self.bubbleView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self.bubbleView addSubview:self.contentLabel];
    [self.bubbleView addSubview:self.contentImageView];
    [self.bubbleView addSubview:self.giftIconView];
    [self.bubbleView addSubview:self.giftNameLabel];
    [self.bubbleView addSubview:self.giftQuantityLabel];
    [self.bubbleView addSubview:self.loadingIndicator];
    [self.bubbleView addSubview:self.retryButton];

    if (message.isFromMe) {
        self.bubbleView.backgroundColor = [UIColor colorWithRed:1.0 green:0.4 blue:0.6 alpha:1.0];
        self.contentLabel.textColor = [UIColor whiteColor];
    } else {
        self.bubbleView.backgroundColor = [UIColor secondarySystemBackgroundColor];
        self.contentLabel.textColor = [UIColor labelColor];
    }

    if ([message.type isEqualToString:@"image"]) {
        self.contentLabel.hidden = YES;
        self.contentImageView.hidden = NO;
        self.giftIconView.hidden = YES;
        self.giftNameLabel.hidden = YES;
        self.giftQuantityLabel.hidden = YES;

        if (message.sendStatus == HYMessageSendStatusSending) {
            self.contentImageView.image = nil;
            self.contentImageView.backgroundColor = [UIColor systemGray5Color];
            [self.loadingIndicator startAnimating];
        } else {
            [self.loadingIndicator stopAnimating];
            if (message.content.length > 0) {
                [self.contentImageView sd_setImageWithURL:[NSURL URLWithString:message.content]
                                        placeholderImage:nil];
            }
        }

        [self.contentImageView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.bubbleView).insets(UIEdgeInsetsMake(4, 4, 4, 4));
            make.width.height.equalTo(@150);
        }];
    } else if ([message.type isEqualToString:@"gift"]) {
        // Gift bubble: icon + name + quantity
        self.contentLabel.hidden = YES;
        self.contentImageView.hidden = YES;
        [self.loadingIndicator stopAnimating];

        self.giftIconView.hidden = NO;
        self.giftNameLabel.hidden = NO;
        self.giftQuantityLabel.hidden = NO;

        if (message.isFromMe) {
            self.giftNameLabel.textColor = [UIColor whiteColor];
            self.giftQuantityLabel.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.8];
        } else {
            self.giftNameLabel.textColor = [UIColor labelColor];
            self.giftQuantityLabel.textColor = [UIColor secondaryLabelColor];
        }

        if (message.giftIconUrl.length > 0) {
            [self.giftIconView sd_setImageWithURL:[NSURL URLWithString:message.giftIconUrl]
                                 placeholderImage:[UIImage systemImageNamed:@"gift.fill"]];
        } else {
            self.giftIconView.image = [UIImage systemImageNamed:@"gift.fill"];
            self.giftIconView.tintColor = message.isFromMe ? [UIColor whiteColor] : [UIColor colorWithRed:236/255.0 green:72/255.0 blue:153/255.0 alpha:1];
        }
        self.giftNameLabel.text = message.giftName.length > 0 ? message.giftName : @"Gift";
        if (message.giftQuantity > 1) {
            self.giftQuantityLabel.text = [NSString stringWithFormat:@"x%ld", (long)message.giftQuantity];
        } else {
            self.giftQuantityLabel.text = @"";
        }

        self.giftIconView.translatesAutoresizingMaskIntoConstraints = NO;
        self.giftNameLabel.translatesAutoresizingMaskIntoConstraints = NO;
        self.giftQuantityLabel.translatesAutoresizingMaskIntoConstraints = NO;

        [self.giftIconView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.bubbleView);
            make.top.equalTo(self.bubbleView).offset(12);
            make.width.height.equalTo(@40);
        }];
        [self.giftNameLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.bubbleView);
            make.top.equalTo(self.giftIconView.mas_bottom).offset(4);
            make.leading.trailing.equalTo(self.bubbleView).inset(8);
        }];
        [self.giftQuantityLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.bubbleView);
            make.top.equalTo(self.giftNameLabel.mas_bottom).offset(2);
            make.bottom.equalTo(self.bubbleView).offset(-12);
        }];
    } else {
        self.contentLabel.hidden = NO;
        self.contentImageView.hidden = YES;
        self.giftIconView.hidden = YES;
        self.giftNameLabel.hidden = YES;
        self.giftQuantityLabel.hidden = YES;
        [self.loadingIndicator stopAnimating];

        self.contentLabel.text = message.content;
        [self.contentLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.bubbleView).insets(UIEdgeInsetsMake(8, 12, 8, 12));
            make.width.lessThanOrEqualTo(@(kBubbleMaxWidth));
        }];
    }

    [self.retryButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(self.bubbleView.mas_leading).offset(-4);
        make.centerY.equalTo(self.bubbleView);
    }];
    self.retryButton.hidden = (message.sendStatus != HYMessageSendStatusFailed);

    [self layoutConstraintsForMessage:message];
}

- (void)layoutConstraintsForMessage:(HYChatMessage *)message {
    [self.bubbleView mas_remakeConstraints:^(MASConstraintMaker *make) {
        if (message.isFromMe) {
            make.trailing.equalTo(self.contentView).offset(-16);
        } else {
            make.leading.equalTo(self.contentView).offset(16);
        }
        make.top.equalTo(self.contentView).offset(4);
        make.bottom.equalTo(self.contentView).offset(-4);
    }];

    if (message.isFromMe) {
        [self.bubbleView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.trailing.equalTo(self.contentView).offset(-16);
        }];
    } else {
        [self.bubbleView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(self.contentView).offset(16);
        }];
    }
}

@end
