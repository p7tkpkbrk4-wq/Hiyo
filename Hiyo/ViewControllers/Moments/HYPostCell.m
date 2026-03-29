#import "HYPostCell.h"
#import "HYModels.h"
#import "HYColors.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/SDWebImage.h>

NSNotificationName const HYPostCellDidTapLikeNotification = @"HYPostCellDidTapLikeNotification";
NSNotificationName const HYPostCellDidTapCommentNotification = @"HYPostCellDidTapCommentNotification";

static CGFloat const kImageHeight = 180.0;
static CGFloat const kAvatarSize = 44.0;
static CGFloat const kCardCornerRadius = 20.0;
static CGFloat const kAccentBarWidth = 3.0;

@interface HYPostCell ()

@property (nonatomic, strong) UIView *cardView;
@property (nonatomic, strong) CAGradientLayer *accentLayer;
@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic, strong) UIView *onlineIndicator;
@property (nonatomic, strong) UILabel *userNameLabel;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UIButton *moreButton;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *contentLabel;
@property (nonatomic, strong) UIImageView *postImageView;
@property (nonatomic, strong) UIView *actionBar;
@property (nonatomic, strong) UIButton *likeButton;
@property (nonatomic, strong) UILabel *likeCountLabel;
@property (nonatomic, strong) UIButton *commentButton;
@property (nonatomic, strong) UILabel *commentCountLabel;
@property (nonatomic, strong) UIButton *shareButton;
@property (nonatomic, strong) UIButton *bookmarkButton;
@property (nonatomic, strong) HYPost *post;

@end

@implementation HYPostCell

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
    // Card container
    self.cardView = [[UIView alloc] init];
    self.cardView.backgroundColor = LightCard;
    self.cardView.layer.cornerRadius = kCardCornerRadius;
    self.cardView.layer.shadowColor = [UIColor colorWithRed:0.545 green:0.373 blue:0.98 alpha:1.0].CGColor;
    self.cardView.layer.shadowOffset = CGSizeMake(0, 3);
    self.cardView.layer.shadowRadius = 10;
    self.cardView.layer.shadowOpacity = 0.1;
    self.cardView.clipsToBounds = NO;
    [self.contentView addSubview:self.cardView];

    // Left accent bar (gradient)
    self.accentLayer = [CAGradientLayer layer];
    self.accentLayer.colors = @[
        (id)PinkGradStart.CGColor,
        (id)PurpleGradEnd.CGColor
    ];
    self.accentLayer.startPoint = CGPointMake(0, 0);
    self.accentLayer.endPoint = CGPointMake(0, 1);
    self.accentLayer.cornerRadius = kAccentBarWidth / 2;
    [self.cardView.layer addSublayer:self.accentLayer];

    // Avatar
    self.avatarImageView = [[UIImageView alloc] init];
    self.avatarImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.avatarImageView.clipsToBounds = YES;
    self.avatarImageView.layer.cornerRadius = kAvatarSize / 2;
    self.avatarImageView.backgroundColor = [UIColor colorWithRed:0.91 green:0.863 blue:1.0 alpha:1.0];
    self.avatarImageView.userInteractionEnabled = YES;
    [self.cardView addSubview:self.avatarImageView];

    UITapGestureRecognizer *avatarTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(avatarTapped)];
    [self.avatarImageView addGestureRecognizer:avatarTap];

    // Online indicator
    self.onlineIndicator = [[UIView alloc] init];
    self.onlineIndicator.backgroundColor = [UIColor whiteColor];
    self.onlineIndicator.layer.cornerRadius = 6;
    [self.cardView addSubview:self.onlineIndicator];

    UIView *greenDot = [[UIView alloc] init];
    greenDot.backgroundColor = OnlineGreenLight;
    greenDot.layer.cornerRadius = 4.5;
    greenDot.tag = 100;
    [self.onlineIndicator addSubview:greenDot];

    // User name
    self.userNameLabel = [[UILabel alloc] init];
    self.userNameLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightBold];
    self.userNameLabel.textColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0];
    self.userNameLabel.userInteractionEnabled = YES;
    [self.cardView addSubview:self.userNameLabel];

    UITapGestureRecognizer *nameTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(avatarTapped)];
    [self.userNameLabel addGestureRecognizer:nameTap];

    // Time label
    self.timeLabel = [[UILabel alloc] init];
    self.timeLabel.font = [UIFont systemFontOfSize:11];
    self.timeLabel.textColor = [UIColor colorWithRed:0.6 green:0.6 blue:0.6 alpha:1.0];
    [self.cardView addSubview:self.timeLabel];

    // More button (3 dots)
    self.moreButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.moreButton setImage:[UIImage systemImageNamed:@"ellipsis"] forState:UIControlStateNormal];
    self.moreButton.tintColor = [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:1.0];
    [self.cardView addSubview:self.moreButton];

    // Title
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightBold];
    self.titleLabel.textColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0];
    self.titleLabel.numberOfLines = 2;
    [self.cardView addSubview:self.titleLabel];

    // Content
    self.contentLabel = [[UILabel alloc] init];
    self.contentLabel.font = [UIFont systemFontOfSize:13];
    self.contentLabel.textColor = [UIColor colorWithRed:0.4 green:0.4 blue:0.4 alpha:1.0];
    self.contentLabel.numberOfLines = 3;
    [self.cardView addSubview:self.contentLabel];

    // Post image
    self.postImageView = [[UIImageView alloc] init];
    self.postImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.postImageView.clipsToBounds = YES;
    self.postImageView.layer.cornerRadius = 10;
    self.postImageView.backgroundColor = [UIColor colorWithRed:0.941 green:0.929 blue:1.0 alpha:1.0];
    [self.cardView addSubview:self.postImageView];

    // Action bar
    self.actionBar = [[UIView alloc] init];
    [self.cardView addSubview:self.actionBar];

    // Like button with count
    self.likeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.likeButton setImage:[UIImage systemImageNamed:@"heart"] forState:UIControlStateNormal];
    self.likeButton.tintColor = [UIColor colorWithRed:1.0 green:0.42 blue:0.616 alpha:1.0];
    [self.likeButton addTarget:self action:@selector(likeButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.actionBar addSubview:self.likeButton];

    self.likeCountLabel = [[UILabel alloc] init];
    self.likeCountLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightSemibold];
    self.likeCountLabel.textColor = [UIColor colorWithRed:1.0 green:0.42 blue:0.616 alpha:1.0];
    [self.actionBar addSubview:self.likeCountLabel];

    // Comment button with count
    self.commentButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.commentButton setImage:[UIImage systemImageNamed:@"bubble.right"] forState:UIControlStateNormal];
    self.commentButton.tintColor = [UIColor colorWithRed:0.6 green:0.6 blue:0.6 alpha:1.0];
    [self.commentButton addTarget:self action:@selector(commentButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.actionBar addSubview:self.commentButton];

    self.commentCountLabel = [[UILabel alloc] init];
    self.commentCountLabel.font = [UIFont systemFontOfSize:12];
    self.commentCountLabel.textColor = [UIColor colorWithRed:0.6 green:0.6 blue:0.6 alpha:1.0];
    [self.actionBar addSubview:self.commentCountLabel];

    // Share button
    self.shareButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.shareButton setImage:[UIImage systemImageNamed:@"square.and.arrow.up"] forState:UIControlStateNormal];
    self.shareButton.tintColor = [UIColor colorWithRed:0.6 green:0.6 blue:0.6 alpha:1.0];
    [self.actionBar addSubview:self.shareButton];

    // Bookmark button
    self.bookmarkButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.bookmarkButton setImage:[UIImage systemImageNamed:@"bookmark"] forState:UIControlStateNormal];
    self.bookmarkButton.tintColor = [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:1.0];
    self.bookmarkButton.backgroundColor = [UIColor colorWithRed:0.96 green:0.94 blue:1.0 alpha:1.0];
    self.bookmarkButton.layer.cornerRadius = 14;
    self.bookmarkButton.layer.borderWidth = 1;
    self.bookmarkButton.layer.borderColor = [UIColor colorWithRed:0.91 green:0.878 blue:1.0 alpha:1.0].CGColor;
    [self.actionBar addSubview:self.bookmarkButton];

    [self setupConstraints];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    // Position accent bar on left side of card
    self.accentLayer.frame = CGRectMake(0, 0, kAccentBarWidth, self.cardView.bounds.size.height);
}

- (void)setupConstraints {
    [self.cardView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.contentView).insets(UIEdgeInsetsMake(8, 16, 8, 16));
    }];

    [self.avatarImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.cardView).offset(20);
        make.top.equalTo(self.cardView).offset(20);
        make.width.height.equalTo(@(kAvatarSize));
    }];

    [self.onlineIndicator mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.equalTo(@12);
        make.trailing.bottom.equalTo(self.avatarImageView);
    }];

    [self.userNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.avatarImageView.mas_trailing).offset(10);
        make.top.equalTo(self.avatarImageView).offset(2);
    }];

    [self.timeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.userNameLabel);
        make.top.equalTo(self.userNameLabel.mas_bottom).offset(2);
    }];

    [self.moreButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(self.cardView).offset(-16);
        make.centerY.equalTo(self.avatarImageView);
        make.width.height.equalTo(@20);
    }];

    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.cardView).offset(20);
        make.trailing.equalTo(self.cardView).offset(-20);
        make.top.equalTo(self.avatarImageView.mas_bottom).offset(12);
    }];

    [self.contentLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.equalTo(self.titleLabel);
        make.top.equalTo(self.titleLabel.mas_bottom).offset(4);
    }];

    [self.postImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.equalTo(self.titleLabel);
        make.top.equalTo(self.contentLabel.mas_bottom).offset(10);
        make.height.equalTo(@(kImageHeight));
    }];

    [self.actionBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.equalTo(self.titleLabel);
        make.top.equalTo(self.postImageView.mas_bottom).offset(12);
        make.bottom.equalTo(self.cardView).offset(-16);
        make.height.equalTo(@32);
    }];

    [self.likeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.centerY.equalTo(self.actionBar);
        make.width.height.equalTo(@20);
    }];

    [self.likeCountLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.likeButton.mas_trailing).offset(4);
        make.centerY.equalTo(self.actionBar);
    }];

    [self.commentButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.likeCountLabel.mas_trailing).offset(16);
        make.centerY.equalTo(self.actionBar);
        make.width.height.equalTo(@20);
    }];

    [self.commentCountLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.commentButton.mas_trailing).offset(4);
        make.centerY.equalTo(self.actionBar);
    }];

    [self.shareButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.commentCountLabel.mas_trailing).offset(16);
        make.centerY.equalTo(self.actionBar);
        make.width.height.equalTo(@20);
    }];

    [self.bookmarkButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(self.actionBar);
        make.centerY.equalTo(self.actionBar);
        make.width.height.equalTo(@28);
    }];
}

- (void)configWithPost:(HYPost *)post {
    self.post = post;

    // Avatar
    if (post.userAvatar.length > 0) {
        [self.avatarImageView sd_setImageWithURL:[NSURL URLWithString:post.userAvatar] placeholderImage:[UIImage systemImageNamed:@"person.circle.fill"]];
    } else {
        self.avatarImageView.image = [UIImage systemImageNamed:@"person.circle.fill"];
    }

    // Online indicator (always show for demo)
    UIView *greenDot = [self.onlineIndicator viewWithTag:100];
    greenDot.frame = CGRectMake(2, 2, 8, 8);
    self.onlineIndicator.hidden = NO;

    self.userNameLabel.text = post.userName.length > 0 ? post.userName : @"匿名用户";
    self.timeLabel.text = [self formatTime:post.createdAt];
    self.titleLabel.text = post.title;
    self.contentLabel.text = post.content;

    // Post image
    if (post.firstImage.length > 0) {
        self.postImageView.hidden = NO;
        self.postImageView.image = nil;
        [self.postImageView sd_setImageWithURL:[NSURL URLWithString:post.firstImage] placeholderImage:nil];
        [self.postImageView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.leading.trailing.equalTo(self.titleLabel);
            make.top.equalTo(self.contentLabel.mas_bottom).offset(10);
            make.height.equalTo(@(kImageHeight));
        }];
        [self.actionBar mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.leading.trailing.equalTo(self.titleLabel);
            make.top.equalTo(self.postImageView.mas_bottom).offset(12);
            make.bottom.equalTo(self.cardView).offset(-16);
            make.height.equalTo(@32);
        }];
    } else {
        self.postImageView.hidden = YES;
        self.postImageView.image = nil;
        [self.postImageView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.leading.trailing.equalTo(self.titleLabel);
            make.top.equalTo(self.contentLabel.mas_bottom);
            make.height.equalTo(@0);
        }];
        [self.actionBar mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.leading.trailing.equalTo(self.titleLabel);
            make.top.equalTo(self.contentLabel.mas_bottom).offset(12);
            make.bottom.equalTo(self.cardView).offset(-16);
            make.height.equalTo(@32);
        }];
    }

    // Like button
    NSString *likeIcon = post.isLiked ? @"heart.fill" : @"heart";
    UIColor *likeColor = post.isLiked ? PinkGradStart : [UIColor colorWithRed:0.6 green:0.6 blue:0.6 alpha:1.0];
    [self.likeButton setImage:[UIImage systemImageNamed:likeIcon] forState:UIControlStateNormal];
    self.likeButton.tintColor = likeColor;
    self.likeCountLabel.text = [NSString stringWithFormat:@"%ld", (long)post.likesCount];
    self.likeCountLabel.textColor = likeColor;

    // Comment button
    [self.commentButton setImage:nil forState:UIControlStateNormal];
    self.commentCountLabel.text = [NSString stringWithFormat:@"%ld", (long)post.commentsCount];
}

- (void)updateLikeState:(BOOL)isLiked likesCount:(NSInteger)count {
    self.post.isLiked = isLiked;
    self.post.likesCount = count;

    NSString *likeIcon = isLiked ? @"heart.fill" : @"heart";
    UIColor *likeColor = isLiked ? PinkGradStart : [UIColor colorWithRed:0.6 green:0.6 blue:0.6 alpha:1.0];
    [self.likeButton setImage:[UIImage systemImageNamed:likeIcon] forState:UIControlStateNormal];
    self.likeButton.tintColor = likeColor;
    self.likeCountLabel.text = [NSString stringWithFormat:@"%ld", (long)count];
    self.likeCountLabel.textColor = likeColor;
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
        // Try alternate format
        inputFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss";
        date = [inputFormatter dateFromString:timeString];
    }

    if (date) {
        NSTimeInterval delta = [[NSDate date] timeIntervalSinceDate:date];
        if (delta < 60) {
            return @"刚刚";
        } else if (delta < 3600) {
            return [NSString stringWithFormat:@"%.0f分钟前", delta / 60];
        } else if (delta < 86400) {
            return [NSString stringWithFormat:@"%.0f小时前", delta / 3600];
        } else if (delta < 604800) {
            return [NSString stringWithFormat:@"%.0f天前", delta / 86400];
        } else {
            return [outputFormatter stringFromDate:date];
        }
    }
    return timeString;
}

#pragma mark - Actions

- (void)likeButtonTapped {
    if (self.onLikeTapped) {
        self.onLikeTapped(self.post);
    }
}

- (void)avatarTapped {
    if (self.onAvatarTapped) {
        self.onAvatarTapped(self.post);
    }
}

- (void)commentButtonTapped {
    if (self.onCommentTapped) {
        self.onCommentTapped(self.post);
    }
}

@end
