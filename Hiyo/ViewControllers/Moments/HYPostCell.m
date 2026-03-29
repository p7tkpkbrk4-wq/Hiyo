#import "HYPostCell.h"
#import "HYModels.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/SDWebImage.h>

NSNotificationName const HYPostCellDidTapLikeNotification = @"HYPostCellDidTapLikeNotification";
NSNotificationName const HYPostCellDidTapCommentNotification = @"HYPostCellDidTapCommentNotification";

static CGFloat const kImageHeight = 200.0;
static CGFloat const kAvatarSize = 44.0;

@interface HYPostCell ()

@property (nonatomic, strong) UIView *cardView;
@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic, strong) UILabel *userNameLabel;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *contentLabel;
@property (nonatomic, strong) UIImageView *postImageView;
@property (nonatomic, strong) UIButton *likeButton;
@property (nonatomic, strong) UIButton *commentButton;
@property (nonatomic, strong) UIView *actionBar;
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
    self.cardView.backgroundColor = [UIColor systemBackgroundColor];
    self.cardView.layer.cornerRadius = 12;
    self.cardView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.cardView.layer.shadowOffset = CGSizeMake(0, 2);
    self.cardView.layer.shadowRadius = 4;
    self.cardView.layer.shadowOpacity = 0.08;
    [self.contentView addSubview:self.cardView];

    // Avatar
    self.avatarImageView = [[UIImageView alloc] init];
    self.avatarImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.avatarImageView.clipsToBounds = YES;
    self.avatarImageView.layer.cornerRadius = kAvatarSize / 2;
    self.avatarImageView.backgroundColor = [UIColor systemGray5Color];
    self.avatarImageView.userInteractionEnabled = YES;
    [self.cardView addSubview:self.avatarImageView];

    UITapGestureRecognizer *avatarTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(avatarTapped)];
    [self.avatarImageView addGestureRecognizer:avatarTap];

    // User name
    self.userNameLabel = [[UILabel alloc] init];
    self.userNameLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    self.userNameLabel.textColor = [UIColor labelColor];
    self.userNameLabel.userInteractionEnabled = YES;
    [self.cardView addSubview:self.userNameLabel];

    UITapGestureRecognizer *nameTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(avatarTapped)];
    [self.userNameLabel addGestureRecognizer:nameTap];

    // Time label
    self.timeLabel = [[UILabel alloc] init];
    self.timeLabel.font = [UIFont systemFontOfSize:12];
    self.timeLabel.textColor = [UIColor secondaryLabelColor];
    [self.cardView addSubview:self.timeLabel];

    // Title
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightBold];
    self.titleLabel.textColor = [UIColor labelColor];
    self.titleLabel.numberOfLines = 2;
    [self.cardView addSubview:self.titleLabel];

    // Content
    self.contentLabel = [[UILabel alloc] init];
    self.contentLabel.font = [UIFont systemFontOfSize:14];
    self.contentLabel.textColor = [UIColor secondaryLabelColor];
    self.contentLabel.numberOfLines = 4;
    [self.cardView addSubview:self.contentLabel];

    // Post image
    self.postImageView = [[UIImageView alloc] init];
    self.postImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.postImageView.clipsToBounds = YES;
    self.postImageView.layer.cornerRadius = 8;
    self.postImageView.backgroundColor = [UIColor systemGray5Color];
    [self.cardView addSubview:self.postImageView];

    // Action bar
    self.actionBar = [[UIView alloc] init];
    [self.cardView addSubview:self.actionBar];

    // Like button
    self.likeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.likeButton setImage:[UIImage systemImageNamed:@"heart"] forState:UIControlStateNormal];
    self.likeButton.tintColor = [UIColor systemGrayColor];
    self.likeButton.titleLabel.font = [UIFont systemFontOfSize:13];
    [self.likeButton setTitleColor:[UIColor secondaryLabelColor] forState:UIControlStateNormal];
    [self.likeButton addTarget:self action:@selector(likeButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.actionBar addSubview:self.likeButton];

    // Comment button
    self.commentButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.commentButton setImage:[UIImage systemImageNamed:@"bubble.right"] forState:UIControlStateNormal];
    self.commentButton.tintColor = [UIColor systemGrayColor];
    self.commentButton.titleLabel.font = [UIFont systemFontOfSize:13];
    [self.commentButton setTitleColor:[UIColor secondaryLabelColor] forState:UIControlStateNormal];
    [self.commentButton addTarget:self action:@selector(commentButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.actionBar addSubview:self.commentButton];

    [self setupConstraints];
}

- (void)setupConstraints {
    [self.cardView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.contentView).insets(UIEdgeInsetsMake(8, 16, 8, 16));
    }];

    [self.avatarImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.top.equalTo(self.cardView).offset(16);
        make.width.height.equalTo(@(kAvatarSize));
    }];

    [self.userNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.avatarImageView.mas_trailing).offset(10);
        make.top.equalTo(self.avatarImageView).offset(2);
        make.trailing.lessThanOrEqualTo(self.cardView).offset(-16);
    }];

    [self.timeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.userNameLabel);
        make.top.equalTo(self.userNameLabel.mas_bottom).offset(2);
    }];

    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.cardView).offset(16);
        make.trailing.equalTo(self.cardView).offset(-16);
        make.top.equalTo(self.avatarImageView.mas_bottom).offset(12);
    }];

    [self.contentLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.equalTo(self.titleLabel);
        make.top.equalTo(self.titleLabel.mas_bottom).offset(6);
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
        make.height.equalTo(@32);
    }];

    [self.commentButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.likeButton.mas_trailing).offset(20);
        make.centerY.equalTo(self.actionBar);
        make.height.equalTo(@32);
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
    } else {
        self.postImageView.hidden = YES;
        self.postImageView.image = nil;
        [self.postImageView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.leading.trailing.equalTo(self.titleLabel);
            make.top.equalTo(self.contentLabel.mas_bottom);
            make.height.equalTo(@0);
        }];
    }

    // Like button
    NSString *likeIcon = post.isLiked ? @"heart.fill" : @"heart";
    UIColor *likeColor = post.isLiked ? [UIColor systemPinkColor] : [UIColor systemGrayColor];
    [self.likeButton setImage:[UIImage systemImageNamed:likeIcon] forState:UIControlStateNormal];
    self.likeButton.tintColor = likeColor;
    [self.likeButton setTitle:[NSString stringWithFormat:@" %ld", (long)post.likesCount] forState:UIControlStateNormal];
    [self.likeButton setTitleColor:likeColor forState:UIControlStateNormal];

    // Comment button
    [self.commentButton setTitle:[NSString stringWithFormat:@" %ld", (long)post.commentsCount] forState:UIControlStateNormal];
}

- (void)updateLikeState:(BOOL)isLiked likesCount:(NSInteger)count {
    // Update self.post to keep state consistent
    self.post.isLiked = isLiked;
    self.post.likesCount = count;

    NSString *likeIcon = isLiked ? @"heart.fill" : @"heart";
    UIColor *likeColor = isLiked ? [UIColor systemPinkColor] : [UIColor systemGrayColor];
    [self.likeButton setImage:[UIImage systemImageNamed:likeIcon] forState:UIControlStateNormal];
    self.tintColor = likeColor;
    [self.likeButton setTitle:[NSString stringWithFormat:@" %ld", (long)count] forState:UIControlStateNormal];
    [self.likeButton setTitleColor:likeColor forState:UIControlStateNormal];
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
