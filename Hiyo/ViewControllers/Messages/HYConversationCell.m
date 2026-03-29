#import "HYConversationCell.h"
#import "HYModels.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/SDWebImage.h>

NSNotificationName const HYConversationCellDidTapDeleteNotification = @"HYConversationCellDidTapDeleteNotification";

static CGFloat const kAvatarSize = 56.0;

@interface HYConversationCell ()

@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *messageLabel;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UIView *badgeView;
@property (nonatomic, strong) UILabel *badgeLabel;
@property (nonatomic, strong) HYConversation *conversation;

@end

@implementation HYConversationCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleDefault;
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    // Avatar
    self.avatarImageView = [[UIImageView alloc] init];
    self.avatarImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.avatarImageView.clipsToBounds = YES;
    self.avatarImageView.layer.cornerRadius = kAvatarSize / 2;
    self.avatarImageView.backgroundColor = [UIColor systemGray5Color];
    [self.contentView addSubview:self.avatarImageView];

    // Name
    self.nameLabel = [[UILabel alloc] init];
    self.nameLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    self.nameLabel.textColor = [UIColor labelColor];
    [self.contentView addSubview:self.nameLabel];

    // Message preview
    self.messageLabel = [[UILabel alloc] init];
    self.messageLabel.font = [UIFont systemFontOfSize:14];
    self.messageLabel.textColor = [UIColor secondaryLabelColor];
    self.messageLabel.numberOfLines = 1;
    [self.contentView addSubview:self.messageLabel];

    // Time
    self.timeLabel = [[UILabel alloc] init];
    self.timeLabel.font = [UIFont systemFontOfSize:12];
    self.timeLabel.textColor = [UIColor tertiaryLabelColor];
    self.timeLabel.textAlignment = NSTextAlignmentRight;
    [self.contentView addSubview:self.timeLabel];

    // Badge
    self.badgeView = [[UIView alloc] init];
    self.badgeView.backgroundColor = [UIColor systemPinkColor];
    self.badgeView.layer.cornerRadius = 10;
    self.badgeView.hidden = YES;
    [self.contentView addSubview:self.badgeView];

    self.badgeLabel = [[UILabel alloc] init];
    self.badgeLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightBold];
    self.badgeLabel.textColor = [UIColor whiteColor];
    self.badgeLabel.textAlignment = NSTextAlignmentCenter;
    [self.badgeView addSubview:self.badgeLabel];

    self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    [self setupConstraints];
}

- (void)setupConstraints {
    [self.avatarImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.contentView).offset(16);
        make.centerY.equalTo(self.contentView);
        make.width.height.equalTo(@(kAvatarSize));
    }];

    [self.timeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(self.contentView).offset(-8);
        make.top.equalTo(self.contentView).offset(14);
        make.width.lessThanOrEqualTo(@80);
    }];

    [self.nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.avatarImageView.mas_trailing).offset(12);
        make.trailing.lessThanOrEqualTo(self.timeLabel.mas_leading).offset(-8);
        make.top.equalTo(self.contentView).offset(14);
    }];

    [self.badgeView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(self.contentView).offset(-8);
        make.bottom.equalTo(self.contentView).offset(-14);
        make.height.equalTo(@20);
        make.width.greaterThanOrEqualTo(@20);
    }];

    [self.badgeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.badgeView).insets(UIEdgeInsetsMake(0, 6, 0, 6));
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
        self.avatarImageView.tintColor = [UIColor systemGrayColor];
    }

    self.nameLabel.text = conversation.partnerName.length > 0 ? conversation.partnerName : @"未知用户";

    NSString *msgPreview = conversation.lastMessage;
    if ([conversation.lastMessageType isEqualToString:@"image"]) {
        msgPreview = @"📷 图片";
    }
    self.messageLabel.text = msgPreview ?: @"";

    self.timeLabel.text = [self formatTime:conversation.lastTime];

    if (conversation.unreadCount > 0) {
        self.badgeView.hidden = NO;
        if (conversation.unreadCount > 99) {
            self.badgeLabel.text = @"99+";
        } else {
            self.badgeLabel.text = [NSString stringWithFormat:@"%ld", (long)conversation.unreadCount];
        }
        self.messageLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
        self.messageLabel.textColor = [UIColor labelColor];
    } else {
        self.badgeView.hidden = YES;
        self.messageLabel.font = [UIFont systemFontOfSize:14];
        self.messageLabel.textColor = [UIColor secondaryLabelColor];
    }
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
        if (delta < 86400) {
            NSDateFormatter *tf = [[NSDateFormatter alloc] init];
            tf.dateFormat = @"HH:mm";
            return [tf stringFromDate:date];
        }
        if (delta < 604800) {
            NSDateFormatter *tf = [[NSDateFormatter alloc] init];
            tf.dateFormat = @"MM/dd";
            return [tf stringFromDate:date];
        }
        return timeString;
    }
    return timeString;
}

@end
