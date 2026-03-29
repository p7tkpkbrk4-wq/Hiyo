#import "HYSearchUserCell.h"
#import "HYSearchUser.h"
#import "HYColors.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/SDWebImage.h>

static CGFloat const kAvatarSize = 44.0;

@interface HYSearchUserCell ()

@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *signatureLabel;

@end

@implementation HYSearchUserCell

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
    self.avatarImageView = [[UIImageView alloc] init];
    self.avatarImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.avatarImageView.clipsToBounds = YES;
    self.avatarImageView.layer.cornerRadius = kAvatarSize / 2;
    self.avatarImageView.backgroundColor = [UIColor colorWithRed:0.91 green:0.878 blue:1.0 alpha:1.0];
    [self.contentView addSubview:self.avatarImageView];

    self.nameLabel = [[UILabel alloc] init];
    self.nameLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    self.nameLabel.textColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0];
    [self.contentView addSubview:self.nameLabel];

    self.signatureLabel = [[UILabel alloc] init];
    self.signatureLabel.font = [UIFont systemFontOfSize:13];
    self.signatureLabel.textColor = [UIColor colorWithRed:0.6 green:0.6 blue:0.6 alpha:1.0];
    self.signatureLabel.numberOfLines = 1;
    [self.contentView addSubview:self.signatureLabel];

    [self setupConstraints];
}

- (void)setupConstraints {
    [self.avatarImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.contentView).offset(16);
        make.centerY.equalTo(self.contentView);
        make.width.height.equalTo(@(kAvatarSize));
    }];

    [self.nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.avatarImageView.mas_trailing).offset(12);
        make.trailing.equalTo(self.contentView).offset(-16);
        make.top.equalTo(self.contentView).offset(10);
    }];

    [self.signatureLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.equalTo(self.nameLabel);
        make.top.equalTo(self.nameLabel.mas_bottom).offset(2);
    }];
}

- (void)configWithSearchUser:(HYSearchUser *)user {
    if (user.avatarUrl.length > 0) {
        [self.avatarImageView sd_setImageWithURL:[NSURL URLWithString:user.avatarUrl]
                                placeholderImage:[UIImage systemImageNamed:@"person.circle.fill"]];
    } else {
        self.avatarImageView.image = [UIImage systemImageNamed:@"person.circle.fill"];
        self.avatarImageView.tintColor = [UIColor colorWithRed:0.878 green:0.867 blue:1.0 alpha:1.0];
    }

    self.nameLabel.text = user.name.length > 0 ? user.name : @"未知用户";
    self.signatureLabel.text = user.signature.length > 0 ? user.signature : @"";
}

@end
