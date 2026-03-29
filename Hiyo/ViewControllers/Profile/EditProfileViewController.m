#import "EditProfileViewController.h"
#import "HYAPIClient.h"
#import "HYUser.h"
#import "HYPickerManager.h"
#import "HYColors.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/SDWebImage.h>
#import <PhotosUI/PhotosUI.h>
#import <objc/runtime.h>

@interface EditProfileViewController () <PHPickerViewControllerDelegate, UITextFieldDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;

// Background
@property (nonatomic, strong) UIImageView *backgroundImageView;
@property (nonatomic, strong) UIButton *changeBgButton;
@property (nonatomic, strong) NSString *pendingBgUrl;

// Avatar
@property (nonatomic, strong) UIImageView *avatarView;
@property (nonatomic, strong) UIButton *changeAvatarButton;

// Fields
@property (nonatomic, strong) UITextField *nicknameField;
@property (nonatomic, strong) UITextField *bioField;
@property (nonatomic, strong) UITextField *birthdayField;
@property (nonatomic, strong) UITextField *countryCityField;
@property (nonatomic, strong) UITextField *heightField;
@property (nonatomic, strong) UITextField *weightField;
@property (nonatomic, strong) UITextField *jobField;

// Interests
@property (nonatomic, strong) UIView *interestsContainer;
@property (nonatomic, strong) NSMutableArray<NSString *> *selectedInterests;

// Save button
@property (nonatomic, strong) UIButton *saveButton;
@property (nonatomic, strong) UIActivityIndicatorView *loadingView;

// Data
@property (nonatomic, strong) HYUser *user;
@property (nonatomic, strong) NSString *pendingAvatarUrl;
@property (nonatomic, strong) NSDate *selectedBirthday;
@property (nonatomic, copy) NSString *selectedCountry;
@property (nonatomic, copy) NSString *selectedCity;

@end

@implementation EditProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"编辑资料";
    self.view.backgroundColor = DarkBackground;
    self.selectedInterests = [NSMutableArray array];

    [self setupUI];
    [self setupConstraints];
    [self loadData];
}

- (void)setupUI {
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    [self.view addSubview:self.scrollView];

    self.contentView = [[UIView alloc] init];
    [self.scrollView addSubview:self.contentView];

    // Background image (tag 50)
    self.backgroundImageView = [[UIImageView alloc] init];
    self.backgroundImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.backgroundImageView.clipsToBounds = YES;
    self.backgroundImageView.backgroundColor = [UIColor colorWithRed:0.12 green:0.1 blue:0.2 alpha:1.0];
    self.backgroundImageView.tag = 50;
    [self.contentView addSubview:self.backgroundImageView];

    // Change background button
    self.changeBgButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.changeBgButton setImage:[UIImage systemImageNamed:@"camera.fill"] forState:UIControlStateNormal];
    self.changeBgButton.tintColor = [UIColor whiteColor];
    self.changeBgButton.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
    self.changeBgButton.layer.cornerRadius = 16;
    [self.changeBgButton addTarget:self action:@selector(changeBackgroundTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.changeBgButton];

    // Avatar section
    self.avatarView = [[UIImageView alloc] init];
    self.avatarView.backgroundColor = [UIColor colorWithRed:0.15 green:0.15 blue:0.25 alpha:1.0];
    self.avatarView.contentMode = UIViewContentModeScaleAspectFill;
    self.avatarView.layer.cornerRadius = 45;
    self.avatarView.clipsToBounds = YES;
    self.avatarView.userInteractionEnabled = YES;
    [self.contentView addSubview:self.avatarView];

    UITapGestureRecognizer *avatarTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(changeAvatarTapped)];
    [self.avatarView addGestureRecognizer:avatarTap];

    self.changeAvatarButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.changeAvatarButton setTitle:@"更换头像" forState:UIControlStateNormal];
    [self.changeAvatarButton setTitleColor:[UIColor systemPinkColor] forState:UIControlStateNormal];
    self.changeAvatarButton.titleLabel.font = [UIFont systemFontOfSize:14];
    [self.contentView addSubview:self.changeAvatarButton];

    // Nickname
    UIView *nicknameRow = [self createFieldRow:@"昵称" placeholder:@"请输入昵称" field:&_nicknameField editable:YES icon:nil];
    nicknameRow.tag = 100;
    [self.contentView addSubview:nicknameRow];

    // Bio
    UIView *bioRow = [self createFieldRow:@"个性签名" placeholder:@"请输入个性签名" field:&_bioField editable:YES icon:nil];
    bioRow.tag = 101;
    [self.contentView addSubview:bioRow];

    // Birthday (read-only, picker)
    UIView *birthdayRow = [self createFieldRow:@"生日" placeholder:@"选择生日" field:&_birthdayField editable:NO icon:@"calendar"];
    birthdayRow.tag = 102;
    [self.contentView addSubview:birthdayRow];
    [self addTapGestureToRow:birthdayRow action:@selector(birthdayTapped)];

    // Country/City (read-only, picker)
    UIView *countryCityRow = [self createFieldRow:@"所在地" placeholder:@"选择国家城市" field:&_countryCityField editable:NO icon:@"location.fill"];
    countryCityRow.tag = 103;
    [self.contentView addSubview:countryCityRow];
    [self addTapGestureToRow:countryCityRow action:@selector(countryCityTapped)];

    // Height (read-only, picker)
    UIView *heightRow = [self createFieldRow:@"身高" placeholder:@"选择身高" field:&_heightField editable:NO icon:@"ruler"];
    heightRow.tag = 104;
    [self.contentView addSubview:heightRow];
    [self addTapGestureToRow:heightRow action:@selector(heightTapped)];

    // Weight (read-only, picker)
    UIView *weightRow = [self createFieldRow:@"体重" placeholder:@"选择体重" field:&_weightField editable:NO icon:@"scalemass"];
    weightRow.tag = 105;
    [self.contentView addSubview:weightRow];
    [self addTapGestureToRow:weightRow action:@selector(weightTapped)];

    // Job
    UIView *jobRow = [self createFieldRow:@"职业" placeholder:@"请输入职业" field:&_jobField editable:YES icon:nil];
    jobRow.tag = 106;
    [self.contentView addSubview:jobRow];

    // Interests
    UILabel *interestsLabel = [[UILabel alloc] init];
    interestsLabel.text = @"兴趣爱好";
    interestsLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    interestsLabel.textColor = [UIColor systemGrayColor];
    interestsLabel.tag = 200;
    interestsLabel.userInteractionEnabled = YES;
    [self.contentView addSubview:interestsLabel];

    self.interestsContainer = [[UIView alloc] init];
    self.interestsContainer.tag = 201;
    [self.contentView addSubview:self.interestsContainer];

    UILabel *interestsHint = [[UILabel alloc] init];
    interestsHint.text = @"点击添加兴趣爱好（4-10个）";
    interestsHint.font = [UIFont systemFontOfSize:13];
    interestsHint.textColor = TextMuted;
    interestsHint.tag = 202;
    [self.interestsContainer addSubview:interestsHint];
    [interestsHint mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.interestsContainer);
    }];

    UITapGestureRecognizer *interestsTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(interestsTapped)];
    [interestsLabel addGestureRecognizer:interestsTap];

    [self setupInterestTags];

    // Save button
    self.saveButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.saveButton setTitle:@"保存" forState:UIControlStateNormal];
    [self.saveButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.saveButton.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    self.saveButton.backgroundColor = [UIColor systemPinkColor];
    self.saveButton.layer.cornerRadius = 24;
    [self.saveButton addTarget:self action:@selector(saveTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.saveButton];

    self.loadingView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    self.loadingView.color = [UIColor whiteColor];
    self.loadingView.hidesWhenStopped = YES;
    [self.saveButton addSubview:self.loadingView];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    tap.cancelsTouchesInView = NO;
    [self.scrollView addGestureRecognizer:tap];
}

- (UIView *)createFieldRow:(NSString *)labelText placeholder:(NSString *)placeholder field:(UITextField * __strong *)field editable:(BOOL)editable icon:(NSString *)iconName {
    UIView *row = [[UIView alloc] init];
    row.backgroundColor = [UIColor colorWithRed:0.11 green:0.11 blue:0.18 alpha:1.0];
    row.layer.cornerRadius = 12;

    UITextField *textField = [[UITextField alloc] init];
    textField.placeholder = placeholder;
    textField.font = [UIFont systemFontOfSize:15];
    textField.textColor = editable ? [UIColor whiteColor] : TextSecondary;
    textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:placeholder attributes:@{NSForegroundColorAttributeName: TextMuted}];
    textField.textAlignment = NSTextAlignmentRight;
    textField.returnKeyType = UIReturnKeyDone;
    textField.delegate = self;
    textField.keyboardAppearance = UIKeyboardAppearanceDark;
    textField.enabled = editable;
    if (field) *field = textField;

    if (iconName) {
        UIImageView *icon = [[UIImageView alloc] init];
        icon.image = [UIImage systemImageNamed:iconName];
        icon.tintColor = TextMuted;
        icon.contentMode = UIViewContentModeScaleAspectFit;
        [row addSubview:icon];

        UILabel *label = [[UILabel alloc] init];
        label.text = labelText;
        label.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
        label.textColor = TextSecondary;
        [row addSubview:label];

        [row addSubview:textField];

        [icon mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(row).offset(16);
            make.centerY.equalTo(row);
            make.width.height.equalTo(@20);
        }];
        [label mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(icon.mas_right).offset(8);
            make.centerY.equalTo(row);
            make.width.equalTo(@60);
        }];
        [textField mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(label.mas_right).offset(8);
            make.right.equalTo(row).offset(-16);
            make.centerY.equalTo(row);
        }];
    } else {
        UILabel *label = [[UILabel alloc] init];
        label.text = labelText;
        label.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
        label.textColor = TextSecondary;
        [row addSubview:label];

        [row addSubview:textField];

        [label mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(row).offset(16);
            make.centerY.equalTo(row);
            make.width.equalTo(@80);
        }];
        [textField mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(label.mas_right).offset(12);
            make.right.equalTo(row).offset(-16);
            make.centerY.equalTo(row);
        }];
    }

    return row;
}

- (void)addTapGestureToRow:(UIView *)row action:(SEL)selector {
    UITapGestureRecognizer *t = [[UITapGestureRecognizer alloc] initWithTarget:self action:selector];
    [row addGestureRecognizer:t];
    row.userInteractionEnabled = YES;
}

- (void)setupInterestTags {
    // Replaced by updateInterestsDisplay
}

- (void)interestTagTapped:(UIButton *)sender {
    // Replaced by interestsTapped
}

- (void)setupConstraints {
    [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];

    [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.scrollView);
        make.width.equalTo(self.scrollView);
    }];

    UIView *bgImageView = [self.contentView viewWithTag:50];
    UIView *row100 = [self.contentView viewWithTag:100];
    UIView *row101 = [self.contentView viewWithTag:101];
    UIView *row102 = [self.contentView viewWithTag:102];
    UIView *row103 = [self.contentView viewWithTag:103];
    UIView *row104 = [self.contentView viewWithTag:104];
    UIView *row105 = [self.contentView viewWithTag:105];
    UIView *row106 = [self.contentView viewWithTag:106];
    UILabel *interestsLabel = [self.contentView viewWithTag:200];
    UIView *interestsContainer = [self.contentView viewWithTag:201];

    [bgImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.contentView);
        make.height.equalTo(@200);
    }];

    [self.changeBgButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(16);
        make.right.equalTo(self.contentView).offset(-16);
        make.width.height.equalTo(@32);
    }];

    [self.avatarView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.contentView);
        make.centerY.equalTo(bgImageView.mas_bottom);
        make.width.height.equalTo(@90);
    }];

    [self.changeAvatarButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.avatarView.mas_bottom).offset(8);
        make.centerX.equalTo(self.contentView);
    }];

    [row100 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.changeAvatarButton.mas_bottom).offset(24);
        make.left.equalTo(self.contentView).offset(16);
        make.right.equalTo(self.contentView).offset(-16);
        make.height.equalTo(@52);
    }];

    [row101 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(row100.mas_bottom).offset(12);
        make.left.right.height.equalTo(row100);
    }];

    [row102 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(row101.mas_bottom).offset(12);
        make.left.right.height.equalTo(row100);
    }];

    [row103 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(row102.mas_bottom).offset(12);
        make.left.right.height.equalTo(row100);
    }];

    [row104 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(row103.mas_bottom).offset(12);
        make.left.right.height.equalTo(row100);
    }];

    [row105 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(row104.mas_bottom).offset(12);
        make.left.right.height.equalTo(row100);
    }];

    [row106 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(row105.mas_bottom).offset(12);
        make.left.right.height.equalTo(row100);
    }];

    [interestsLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(row106.mas_bottom).offset(24);
        make.left.equalTo(self.contentView).offset(16);
    }];

    [interestsContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(interestsLabel.mas_bottom).offset(12);
        make.left.equalTo(self.contentView).offset(16);
        make.right.equalTo(self.contentView).offset(-16);
        make.height.equalTo(@60);
    }];

    [self.saveButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(interestsContainer.mas_bottom).offset(32);
        make.left.equalTo(self.contentView).offset(40);
        make.right.equalTo(self.contentView).offset(-40);
        make.height.equalTo(@48);
        make.bottom.equalTo(self.contentView).offset(-40);
    }];

    [self.loadingView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.saveButton);
    }];
}

- (void)dismissKeyboard {
    [self.view endEditing:YES];
}

- (void)loadData {
    __weak typeof(self) weakSelf = self;
    [[HYAPIClient shared] getUserInfoWithId:@"me" completion:^(NSDictionary *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) return;
            if (error) return;

            NSDictionary *data = response[@"data"];
            if (![data isKindOfClass:[NSDictionary class]]) return;

            strongSelf.user = [[HYUser alloc] initWithDictionary:data];
            [strongSelf updateUI];
        });
    }];
}

- (void)updateUI {
    if (!self.user) return;

    if (self.user.avatar.length > 0) {
        [self.avatarView sd_setImageWithURL:[NSURL URLWithString:self.user.avatar]];
    }
    if (self.user.backgroundImage.length > 0) {
        [self.backgroundImageView sd_setImageWithURL:[NSURL URLWithString:self.user.backgroundImage]];
    } else if (self.user.avatar.length > 0) {
        [self.backgroundImageView sd_setImageWithURL:[NSURL URLWithString:self.user.avatar]];
    }

    self.nicknameField.text = self.user.name;
    self.bioField.text = self.user.bio;

    if (self.user.birthDay.length > 0) {
        self.birthdayField.text = self.user.birthDay;
        NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
        fmt.dateFormat = @"yyyy-MM-dd";
        self.selectedBirthday = [fmt dateFromString:self.user.birthDay];
    }

    if (self.user.currentAddress.length > 0) {
        self.countryCityField.text = self.user.currentAddress;
        NSArray *parts = [self.user.currentAddress componentsSeparatedByString:@" · "];
        if (parts.count >= 2) {
            self.selectedCountry = parts[0];
            self.selectedCity = parts[1];
        }
    }

    if (self.user.height > 0) {
        self.heightField.text = [NSString stringWithFormat:@"%ldcm", (long)self.user.height];
    }
    if (self.user.weight > 0) {
        self.weightField.text = [NSString stringWithFormat:@"%ldkg", (long)self.user.weight];
    }
    self.jobField.text = self.user.job;

    [self.selectedInterests removeAllObjects];
    [self.selectedInterests addObjectsFromArray:self.user.interests ?: @[]];
    [self updateInterestsDisplay];
}

- (void)updateInterestsDisplay {
    UIView *interestsContainer = [self.contentView viewWithTag:201];
    UILabel *hint = [interestsContainer viewWithTag:202];

    for (UIView *sub in interestsContainer.subviews) {
        if (sub.tag != 202) {
            [sub removeFromSuperview];
        }
    }

    if (self.selectedInterests.count == 0) {
        hint.hidden = NO;
    } else {
        hint.hidden = YES;
        CGFloat x = 8, y = 8;
        CGFloat maxWidth = self.view.bounds.size.width - 32;
        CGFloat rowHeight = 32;

        for (NSString *tag in self.selectedInterests) {
            CGSize size = [tag sizeWithAttributes:@{NSFontAttributeName: [UIFont systemFontOfSize:12]}];
            CGFloat btnWidth = size.width + 24;
            if (x + btnWidth > maxWidth) {
                x = 8;
                y += rowHeight + 6;
            }
            UIButton *chip = [UIButton buttonWithType:UIButtonTypeCustom];
            [chip setTitle:[NSString stringWithFormat:@"%@ ×", tag] forState:UIControlStateNormal];
            [chip setTitleColor:PrimaryPink forState:UIControlStateNormal];
            chip.titleLabel.font = [UIFont systemFontOfSize:12];
            chip.backgroundColor = [PrimaryPink colorWithAlphaComponent:0.15];
            chip.layer.cornerRadius = 16;
            chip.contentEdgeInsets = UIEdgeInsetsMake(6, 12, 6, 12);
            chip.frame = CGRectMake(x, y, btnWidth, rowHeight);
            [interestsContainer addSubview:chip];
            x += btnWidth + 6;
        }
    }
}

- (void)changeAvatarTapped {
    PHPickerConfiguration *config = [[PHPickerConfiguration alloc] init];
    config.selectionLimit = 1;
    config.filter = [PHPickerFilter imagesFilter];

    PHPickerViewController *picker = [[PHPickerViewController alloc] initWithConfiguration:config];
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:nil];
}

#pragma mark - PHPickerViewControllerDelegate

- (void)picker:(PHPickerViewController *)picker didFinishPicking:(NSArray<PHPickerResult *> *)results {
    [picker dismissViewControllerAnimated:YES completion:nil];
    if (results.count == 0) return;

    BOOL isBackgroundPicker = [objc_getAssociatedObject(self, "backgroundPicker") boolValue];
    objc_setAssociatedObject(self, "backgroundPicker", nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    PHPickerResult *result = results.firstObject;
    if ([result.itemProvider canLoadObjectOfClass:[UIImage class]]) {
        [result.itemProvider loadObjectOfClass:[UIImage class] completionHandler:^(id<NSItemProviderReading> object, NSError *error) {
            if (![object isKindOfClass:[UIImage class]]) return;
            UIImage *image = (UIImage *)object;
            dispatch_async(dispatch_get_main_queue(), ^{
                if (isBackgroundPicker) {
                    self.backgroundImageView.image = image;
                    [self uploadBackgroundImage:image];
                } else {
                    self.avatarView.image = image;
                    [self uploadAvatarImage:image];
                }
            });
        }];
    }
}

- (void)uploadBackgroundImage:(UIImage *)image {
    NSData *imageData = UIImageJPEGRepresentation(image, 0.8);
    if (!imageData) return;

    [[HYAPIClient shared] uploadBackgroundImage:imageData completion:^(NSString *imageUrl, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!error && imageUrl) {
                self.pendingBgUrl = imageUrl;
            }
        });
    }];
}

- (void)uploadAvatarImage:(UIImage *)image {
    NSData *imageData = UIImageJPEGRepresentation(image, 0.8);
    if (!imageData) return;

    [self.changeAvatarButton setTitle:@"上传中..." forState:UIControlStateNormal];
    self.changeAvatarButton.enabled = NO;

    __weak typeof(self) weakSelf = self;
    [[HYAPIClient shared] uploadAvatarImage:imageData completion:^(NSString *imageUrl, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) return;

            [strongSelf.changeAvatarButton setTitle:@"更换头像" forState:UIControlStateNormal];
            strongSelf.changeAvatarButton.enabled = YES;

            if (error) {
                [strongSelf showAlert:@"头像上传失败，请重试"];
            } else {
                strongSelf.pendingAvatarUrl = imageUrl;
            }
        });
    }];
}

- (void)changeBackgroundTapped {
    PHPickerConfiguration *config = [[PHPickerConfiguration alloc] init];
    config.selectionLimit = 1;
    config.filter = [PHPickerFilter imagesFilter];
    PHPickerViewController *picker = [[PHPickerViewController alloc] initWithConfiguration:config];
    picker.delegate = (id<PHPickerViewControllerDelegate>)self;
    [self presentViewController:picker animated:YES completion:nil];

    objc_setAssociatedObject(self, "backgroundPicker", @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)birthdayTapped {
    [self.view endEditing:YES];
    __weak typeof(self) weakSelf = self;
    [HYPickerManager showBirthdayPickerWithCurrentDate:self.selectedBirthday completion:^(NSDate *date) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        strongSelf.selectedBirthday = date;
        NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
        fmt.dateFormat = @"yyyy-MM-dd";
        strongSelf.birthdayField.text = [fmt stringFromDate:date];
    }];
}

- (void)countryCityTapped {
    [self.view endEditing:YES];
    __weak typeof(self) weakSelf = self;
    [HYPickerManager showCountryCityPickerWithCountry:self.selectedCountry ?: @"" city:self.selectedCity ?: @"" completion:^(NSString *country, NSString *city) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        strongSelf.selectedCountry = country;
        strongSelf.selectedCity = city;
        strongSelf.countryCityField.text = [NSString stringWithFormat:@"%@ · %@", country, city];
    }];
}

- (void)heightTapped {
    [self.view endEditing:YES];
    NSInteger current = 0;
    if (self.heightField.text.length > 0) {
        NSString *num = [self.heightField.text stringByReplacingOccurrencesOfString:@"cm" withString:@""];
        current = [num integerValue];
    }
    __weak typeof(self) weakSelf = self;
    [HYPickerManager showHeightPickerWithValue:current > 0 ? current : 170 completion:^(NSInteger value) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        strongSelf.heightField.text = [NSString stringWithFormat:@"%ldcm", (long)value];
    }];
}

- (void)weightTapped {
    [self.view endEditing:YES];
    NSInteger current = 0;
    if (self.weightField.text.length > 0) {
        NSString *num = [self.weightField.text stringByReplacingOccurrencesOfString:@"kg" withString:@""];
        current = [num integerValue];
    }
    __weak typeof(self) weakSelf = self;
    [HYPickerManager showWeightPickerWithValue:current > 0 ? current : 60 completion:^(NSInteger value) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        strongSelf.weightField.text = [NSString stringWithFormat:@"%ldkg", (long)value];
    }];
}

- (void)interestsTapped {
    [self.view endEditing:YES];
    __weak typeof(self) weakSelf = self;
    [HYPickerManager showInterestsPickerWithSelected:self.selectedInterests completion:^(NSArray<NSString *> *interests) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        [strongSelf.selectedInterests removeAllObjects];
        [strongSelf.selectedInterests addObjectsFromArray:interests];
        [strongSelf updateInterestsDisplay];
    }];
}

- (void)saveTapped {
    NSString *nickname = [self.nicknameField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (nickname.length == 0) {
        [self showAlert:@"请输入昵称"];
        return;
    }

    [self.loadingView startAnimating];
    [self.saveButton setTitle:@"" forState:UIControlStateNormal];
    self.saveButton.enabled = NO;

    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"name"] = nickname;
    params[@"bio"] = self.bioField.text ?: @"";
    if (self.selectedBirthday) {
        NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
        fmt.dateFormat = @"yyyy-MM-dd";
        params[@"birth_day"] = [fmt stringFromDate:self.selectedBirthday];
    }
    if (self.selectedCountry && self.selectedCity) {
        params[@"current_address"] = [NSString stringWithFormat:@"%@ · %@", self.selectedCountry, self.selectedCity];
    }
    if (self.heightField.text.length > 0) {
        NSString *num = [self.heightField.text stringByReplacingOccurrencesOfString:@"cm" withString:@""];
        params[@"height"] = @([num integerValue]);
    }
    if (self.weightField.text.length > 0) {
        NSString *num = [self.weightField.text stringByReplacingOccurrencesOfString:@"kg" withString:@""];
        params[@"weight"] = @([num integerValue]);
    }
    params[@"job"] = self.jobField.text ?: @"";
    params[@"interests"] = self.selectedInterests;
    if (self.pendingAvatarUrl) {
        params[@"avatar_url"] = self.pendingAvatarUrl;
    }
    if (self.pendingBgUrl) {
        params[@"background_image_url"] = self.pendingBgUrl;
    }

    __weak typeof(self) weakSelf = self;
    [[HYAPIClient shared] updateProfileWithData:params completion:^(NSDictionary *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) return;

            [strongSelf.loadingView stopAnimating];
            [strongSelf.saveButton setTitle:@"保存" forState:UIControlStateNormal];
            strongSelf.saveButton.enabled = YES;

            if (error) {
                [strongSelf showAlert:@"保存失败，请重试"];
                return;
            }

            [[NSNotificationCenter defaultCenter] postNotificationName:@"HYProfileDidUpdateNotification" object:nil];
            [strongSelf.navigationController popViewControllerAnimated:YES];
        });
    }];
}

- (void)showAlert:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

@end
