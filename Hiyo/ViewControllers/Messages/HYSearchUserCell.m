#import "HYSearchUserCell.h"
#import "HYSearchUser.h"
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
        self.selectionStyle = UITableViewCellSelectionStyleDefault;
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.avatarImageView = [[UIImageView alloc] init];
    self.avatarImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.avatarImageView.clipsToBounds = YES;
    self.avatarImageView.layer.cornerRadius = kAvatarSize / 2;
    self.avatarImageView.backgroundColor = [UIColor systemGray5Color];
    [self.contentView addSubview:self.avatarImageView];

    self.nameLabel = [[UILabel alloc] init];
    self.nameLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    self.nameLabel.textColor = [UIColor labelColor];
    [self.contentView addSubview:self.nameLabel];

    self.signatureLabel = [[UILabel alloc] init];
    self.signatureLabel.font = [UIFont systemFontOfSize:13];
    self.signatureLabel.textColor = [UIColor secondaryLabelColor];
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
        self.avatarImageView.tintColor = [UIColor systemGrayColor];
    }

    self.nameLabel.text = user.name.length > 0 ? user.name : @"未知用户";
    self.signatureLabel.text = user.signature.length > 0 ? user.signature : @"";
}

@end
