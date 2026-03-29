#import "HYConversationCell.h"
#import "HYModels.h"
#import "HYColors.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/SDWebImage.h>

NSNotificationName const HYConversationCellDidTapDeleteNotification = @"HYConversationCellDidTapDeleteNotification";

static CGFloat const kAvatarSize = 52.0;

@interface HYConversationCell ()

@property (nonatomic, strong) UIView *cardView;
@property (nonatomic, strong) UIView *cardOverlay;
@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic, strong) UIView *onlineIndicator;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UIView *vipBadge;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UILabel *messageLabel;
@property (nonatomic, strong) UIView *badgeView;
@property (nonatomic, strong) UILabel *badgeLabel;
@property (nonatomic, strong) HYConversation *conversation;

@end

@implementation HYConversationCell

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
    // Card background
    self.cardView = [[UIView alloc] init];
    self.cardView.backgroundColor = LightCard;
    self.cardView.layer.cornerRadius = 14;
    self.cardView.layer.shadowColor = PurpleGradStart.CGColor;
    self.cardView.layer.shadowOffset = CGSizeMake(0, 2);
    self.cardView.layer.shadowRadius = 8;
    self.cardView.layer.shadowOpacity = 0.08;
    [self.contentView addSubview:self.cardView];

    // Unread overlay (light gradient)
    self.cardOverlay = [[UIView alloc] init];
    self.cardOverlay.backgroundColor = [UIColor colorWithRed:1.0 green:0.941 blue:0.961 alpha:0.3];
    self.cardOverlay.layer.cornerRadius = 14;
    self.cardOverlay.hidden = YES;
    [self.cardView addSubview:self.cardOverlay];

    // Avatar container
    UIView *avatarContainer = [[UIView alloc] init];
    avatarContainer.tag = 10;
    [self.cardView addSubview:avatarContainer];

    self.avatarImageView = [[UIImageView alloc] init];
    self.avatarImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.avatarImageView.clipsToBounds = YES;
    self.avatarImageView.layer.cornerRadius = 26;
    self.avatarImageView.backgroundColor = [UIColor colorWithRed:0.91 green:0.878 blue:1.0 alpha:1.0];
    [avatarContainer addSubview:self.avatarImageView];

    // Online indicator
    self.onlineIndicator = [[UIView alloc] init];
    self.onlineIndicator.backgroundColor = [UIColor whiteColor];
    self.onlineIndicator.layer.cornerRadius = 7;
    self.onlineIndicator.hidden = YES;
    [avatarContainer addSubview:self.onlineIndicator];

    UIView *greenDot = [[UIView alloc] init];
    greenDot.backgroundColor = OnlineGreenLight;
    greenDot.layer.cornerRadius = 5;
    greenDot.tag = 20;
    [self.onlineIndicator addSubview:greenDot];

    // Name
    self.nameLabel = [[UILabel alloc] init];
    self.nameLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightBold];
    self.nameLabel.textColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0];
    [self.cardView addSubview:self.nameLabel];

    // VIP badge
    self.vipBadge = [[UIView alloc] init];
    self.vipBadge.backgroundColor = VipGold;
    self.vipBadge.layer.cornerRadius = 8;
    self.vipBadge.hidden = YES;
    [self.cardView addSubview:self.vipBadge];

    UILabel *vipText = [[UILabel alloc] init];
    vipText.text = @"VIP";
    vipText.font = [UIFont systemFontOfSize:8 weight:UIFontWeightHeavy];
    vipText.textColor = [UIColor colorWithRed:0.545 green:0.412 blue:0.078 alpha:1.0];
    vipText.textAlignment = NSTextAlignmentCenter;
    [self.vipBadge addSubview:vipText];

    // Time
    self.timeLabel = [[UILabel alloc] init];
    self.timeLabel.font = [UIFont systemFontOfSize:11];
    self.timeLabel.textColor = [UIColor colorWithRed:0.667 green:0.667 blue:0.667 alpha:1.0];
    self.timeLabel.textAlignment = NSTextAlignmentRight;
    [self.cardView addSubview:self.timeLabel];

    // Message preview
    self.messageLabel = [[UILabel alloc] init];
    self.messageLabel.font = [UIFont systemFontOfSize:13];
    self.messageLabel.textColor = [UIColor colorWithRed:0.4 green:0.4 blue:0.4 alpha:1.0];
    self.messageLabel.numberOfLines = 1;
    [self.cardView addSubview:self.messageLabel];

    // Badge (unread count)
    self.badgeView = [[UIView alloc] init];
    self.badgeView.backgroundColor = PinkGradStart;
    self.badgeView.layer.cornerRadius = 9;
    self.badgeView.hidden = YES;
    [self.cardView addSubview:self.badgeView];

    self.badgeLabel = [[UILabel alloc] init];
    self.badgeLabel.font = [UIFont systemFontOfSize:10 weight:UIFontWeightBold];
    self.badgeLabel.textColor = [UIColor whiteColor];
    self.badgeLabel.textAlignment = NSTextAlignmentCenter;
    [self.badgeView addSubview:self.badgeLabel];

    [self setupConstraints];
}

- (void)setupConstraints {
    UIView *avatarContainer = [self.cardView viewWithTag:10];
    UIView *greenDot = [self.onlineIndicator viewWithTag:20];
    UIView *vipText = [self.vipBadge.subviews firstObject];

    [self.cardView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(4);
        make.bottom.equalTo(self.contentView).offset(-4);
        make.leading.equalTo(self.contentView).offset(16);
        make.trailing.equalTo(self.contentView).offset(-16);
    }];

    [self.cardOverlay mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.cardView);
    }];

    [avatarContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.cardView).offset(16);
        make.centerY.equalTo(self.cardView);
        make.width.height.equalTo(@(kAvatarSize));
    }];

    [self.avatarImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(avatarContainer);
        make.width.height.equalTo(@52);
    }];

    [self.onlineIndicator mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.equalTo(@14);
        make.trailing.bottom.equalTo(avatarContainer);
    }];

    [greenDot mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.onlineIndicator);
        make.width.height.equalTo(@10);
    }];

    [self.nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(avatarContainer.mas_trailing).offset(12);
        make.top.equalTo(self.cardView).offset(16);
    }];

    [self.vipBadge mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.nameLabel.mas_trailing).offset(6);
        make.centerY.equalTo(self.nameLabel);
        make.width.equalTo(@38);
        make.height.equalTo(@16);
    }];

    [vipText mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.vipBadge);
    }];

    [self.timeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(self.cardView).offset(-16);
        make.centerY.equalTo(self.nameLabel);
    }];

    [self.badgeView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(self.cardView).offset(-16);
        make.bottom.equalTo(self.cardView).offset(-16);
        make.width.height.equalTo(@18);
    }];

    [self.badgeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.badgeView);
    }];

    [self.messageLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.nameLabel);
        make.trailing.lessThanOrEqualTo(self.badgeView.mas_leading).offset(-8);
        make.top.equalTo(self.nameLabel.mas_bottom).offset(4);
    }];
}

- (void)configWithConversation:(HYConversation *)conversation {
    self.conversation = conversation;

    if (conversation.partnerAvatar.length > 0) {
        [self.avatarImageView sd_setImageWithURL:[NSURL URLWithString:conversation.partnerAvatar]
                                placeholderImage:[UIImage systemImageNamed:@"person.circle.fill"]];
    } else {
        self.avatarImageView.image = [UIImage systemImageNamed:@"person.circle.fill"];
        self.avatarImageView.tintColor = [UIColor colorWithRed:0.878 green:0.867 blue:1.0 alpha:1.0];
    }

    self.nameLabel.text = conversation.partnerName.length > 0 ? conversation.partnerName : @"未知用户";
    self.timeLabel.text = [self formatTime:conversation.lastTime];

    // Last message preview
    NSString *msgPreview = conversation.lastMessage;
    if ([conversation.lastMessageType isEqualToString:@"image"]) {
        msgPreview = @"[图片]";
    }
    self.messageLabel.text = msgPreview ?: @"";

    // Unread
    BOOL hasUnread = conversation.unreadCount > 0;
    self.cardOverlay.hidden = !hasUnread;
    self.badgeView.hidden = !hasUnread;
    if (hasUnread) {
        if (conversation.unreadCount > 99) {
            self.badgeLabel.text = @"99+";
        } else {
            self.badgeLabel.text = [NSString stringWithFormat:@"%ld", (long)conversation.unreadCount];
        }
        self.messageLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
        self.messageLabel.textColor = PinkGradStart;
    } else {
        self.messageLabel.font = [UIFont systemFontOfSize:13];
        self.messageLabel.textColor = [UIColor colorWithRed:0.6 green:0.6 blue:0.6 alpha:1.0];
    }

    // Online indicator - always show for demo
    self.onlineIndicator.hidden = NO;

    // VIP badge - always hidden (no isVip on HYConversation)
    self.vipBadge.hidden = YES;
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

@end
