#import "CompleteProfileViewController.h"
#import "HYAPIClient.h"
#import "HYColors.h"
#import "HYPickerManager.h"
#import "HYCountry.h"
#import "HYInterestCategory.h"
#import <PhotosUI/PhotosUI.h>
#import <Masonry/Masonry.h>

@interface CompleteProfileViewController () <PHPickerViewControllerDelegate, UITextViewDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIView *gradientView;

// Avatar
@property (nonatomic, strong) UIView *avatarContainer;
@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic, strong) UILabel *avatarHintLabel;
@property (nonatomic, strong) UIActivityIndicatorView *avatarLoadingIndicator;
@property (nonatomic, strong) UIImage *selectedAvatarImage;
@property (nonatomic, copy) NSString *uploadedAvatarUrl;

// Gender
@property (nonatomic, assign) NSInteger selectedGender; // 0=none, 1=male, 2=female
@property (nonatomic, strong) UIButton *maleButton;
@property (nonatomic, strong) UIButton *femaleButton;

// Fields
@property (nonatomic, strong) UITextField *birthdayField;
@property (nonatomic, strong) UITextField *countryCityField;
@property (nonatomic, strong) UITextField *heightField;
@property (nonatomic, strong) UITextField *weightField;
@property (nonatomic, strong) UITextView *signatureTextView;
@property (nonatomic, strong) UILabel *signaturePlaceholder;

// Interests
@property (nonatomic, strong) UILabel *interestCountLabel;
@property (nonatomic, strong) UIView *selectedInterestsContainer;
@property (nonatomic, strong) UIScrollView *categoryScrollView;
@property (nonatomic, strong) UIView *tagsContainer;
@property (nonatomic, strong) NSMutableArray<NSString *> *selectedInterests;
@property (nonatomic, strong) NSArray<HYInterestCategory *> *interestCategories;
@property (nonatomic, assign) NSInteger selectedCategoryIndex;

// Data
@property (nonatomic, strong) NSDate *selectedBirthday;
@property (nonatomic, copy) NSString *selectedCountry;
@property (nonatomic, copy) NSString *selectedCity;
@property (nonatomic, assign) NSInteger selectedHeight;
@property (nonatomic, assign) NSInteger selectedWeight;

// Buttons
@property (nonatomic, strong) UIButton *completeButton;
@property (nonatomic, strong) UIActivityIndicatorView *loadingIndicator;
@property (nonatomic, strong) UILabel *errorLabel;

// Loading state
@property (nonatomic, assign) BOOL isLoading;

@end

@implementation CompleteProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    self.selectedGender = 0;
    self.selectedInterests = [NSMutableArray array];
    self.selectedHeight = 170;
    self.selectedWeight = 60;
    self.selectedCategoryIndex = 0;

    [self setupUI];
    [self setupConstraints];
    [self loadData];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setupGradientIfNeeded];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self updateGradientFrames];
}

#pragma mark - UI Setup

- (void)setupUI {
    // Gradient background
    self.gradientView = [[UIView alloc] init];
    [self.view addSubview:self.gradientView];

    // Scroll view
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    [self.view addSubview:self.scrollView];

    self.contentView = [[UIView alloc] init];
    [self.scrollView addSubview:self.contentView];

    // Title
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = @"完善资料";
    titleLabel.font = [UIFont systemFontOfSize:32 weight:UIFontWeightBold];
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.tag = 100;
    [self.contentView addSubview:titleLabel];

    UILabel *subtitleLabel = [[UILabel alloc] init];
    subtitleLabel.text = @"完善资料让更多人认识你";
    subtitleLabel.font = [UIFont systemFontOfSize:16];
    subtitleLabel.textColor = [UIColor colorWithWhite:0.6 alpha:1.0];
    subtitleLabel.tag = 101;
    [self.contentView addSubview:subtitleLabel];

    // Avatar
    [self setupAvatar];

    // Gender Selection
    [self setupGenderSection];

    // Birthday
    [self setupFieldRow:@"生日" tag:200 placeholder:@"选择生日" field:&_birthdayField icon:@"calendar"];
    UITapGestureRecognizer *birthdayTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(birthdayTapped)];
    [self.contentView viewWithTag:200].userInteractionEnabled = YES;
    [[self.contentView viewWithTag:200] addGestureRecognizer:birthdayTap];

    // Country/City
    [self setupFieldRow:@"所在地" tag:201 placeholder:@"选择国家和城市" field:&_countryCityField icon:@"location.fill"];
    UITapGestureRecognizer *locationTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(countryCityTapped)];
    [self.contentView viewWithTag:201].userInteractionEnabled = YES;
    [[self.contentView viewWithTag:201] addGestureRecognizer:locationTap];

    // Height
    [self setupFieldRow:@"身高" tag:202 placeholder:@"选择身高" field:&_heightField icon:@"ruler"];
    UITapGestureRecognizer *heightTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(heightTapped)];
    [self.contentView viewWithTag:202].userInteractionEnabled = YES;
    [[self.contentView viewWithTag:202] addGestureRecognizer:heightTap];

    // Weight
    [self setupFieldRow:@"体重" tag:203 placeholder:@"选择体重" field:&_weightField icon:@"scalemass"];
    UITapGestureRecognizer *weightTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(weightTapped)];
    [self.contentView viewWithTag:203].userInteractionEnabled = YES;
    [[self.contentView viewWithTag:203] addGestureRecognizer:weightTap];

    // Signature
    [self setupSignatureSection];

    // Interests
    [self setupInterestsSection];

    // Error label
    self.errorLabel = [[UILabel alloc] init];
    self.errorLabel.font = [UIFont systemFontOfSize:14];
    self.errorLabel.textColor = [UIColor systemRedColor];
    self.errorLabel.textAlignment = NSTextAlignmentCenter;
    self.errorLabel.hidden = YES;
    self.errorLabel.numberOfLines = 0;
    self.errorLabel.tag = 300;
    [self.contentView addSubview:self.errorLabel];

    // Complete button
    self.completeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.completeButton setTitle:@"完成" forState:UIControlStateNormal];
    [self.completeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.completeButton.titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];
    self.completeButton.layer.cornerRadius = 28;
    [self.completeButton addTarget:self action:@selector(completeTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.completeButton];

    self.loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    self.loadingIndicator.color = [UIColor whiteColor];
    self.loadingIndicator.hidesWhenStopped = YES;
    [self.completeButton addSubview:self.loadingIndicator];

    // Keyboard dismiss
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    tap.cancelsTouchesInView = NO;
    [self.scrollView addGestureRecognizer:tap];
}

- (void)setupAvatar {
    self.avatarContainer = [[UIView alloc] init];
    self.avatarContainer.backgroundColor = [UIColor clearColor];
    self.avatarContainer.layer.cornerRadius = 60;
    self.avatarContainer.layer.borderWidth = 3;
    self.avatarContainer.layer.borderColor = PrimaryPink.CGColor;
    [self.contentView addSubview:self.avatarContainer];

    self.avatarImageView = [[UIImageView alloc] init];
    self.avatarImageView.image = [UIImage systemImageNamed:@"person"];
    self.avatarImageView.tintColor = [UIColor colorWithWhite:0.6 alpha:1.0];
    self.avatarImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.avatarImageView.clipsToBounds = YES;
    self.avatarImageView.layer.cornerRadius = 60;
    [self.avatarContainer addSubview:self.avatarImageView];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(avatarTapped)];
    [self.avatarContainer addGestureRecognizer:tap];
    self.avatarContainer.userInteractionEnabled = YES;

    self.avatarLoadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    self.avatarLoadingIndicator.color = [UIColor whiteColor];
    self.avatarLoadingIndicator.hidesWhenStopped = YES;
    [self.avatarContainer addSubview:self.avatarLoadingIndicator];

    self.avatarHintLabel = [[UILabel alloc] init];
    self.avatarHintLabel.text = @"点击上传头像";
    self.avatarHintLabel.font = [UIFont systemFontOfSize:12];
    self.avatarHintLabel.textColor = [UIColor colorWithWhite:0.6 alpha:1.0];
    self.avatarHintLabel.tag = 102;
    [self.contentView addSubview:self.avatarHintLabel];
}

- (void)setupGenderSection {
    UILabel *genderLabel = [[UILabel alloc] init];
    genderLabel.text = @"性别 *";
    genderLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    genderLabel.textColor = [UIColor colorWithWhite:0.7 alpha:1.0];
    genderLabel.tag = 110;
    [self.contentView addSubview:genderLabel];

    UIView *genderContainer = [[UIView alloc] init];
    genderContainer.tag = 111;
    [self.contentView addSubview:genderContainer];

    self.maleButton = [self createGenderButton:@"男  👦" tag:1];
    self.femaleButton = [self createGenderButton:@"女  👧" tag:2];
    [genderContainer addSubview:self.maleButton];
    [genderContainer addSubview:self.femaleButton];
}

- (UIButton *)createGenderButton:(NSString *)title tag:(NSInteger)tag {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setTitle:title forState:UIControlStateNormal];
    [btn setTitleColor:TextPrimary forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    btn.backgroundColor = [UIColor clearColor];
    btn.layer.cornerRadius = 16;
    btn.layer.borderWidth = 1;
    btn.layer.borderColor = BorderLight.CGColor;
    btn.tag = tag;
    [btn addTarget:self action:@selector(genderButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    return btn;
}

- (void)setupFieldRow:(NSString *)label tag:(NSInteger)tag placeholder:(NSString *)placeholder field:(UITextField * __strong *)field icon:(NSString *)iconName {
    UIView *row = [[UIView alloc] init];
    row.tag = tag;
    row.backgroundColor = [UIColor whiteColor];
    row.layer.cornerRadius = 16;
    [self.contentView addSubview:row];

    UIImageView *icon = [[UIImageView alloc] init];
    icon.image = [UIImage systemImageNamed:iconName];
    icon.tintColor = [UIColor colorWithWhite:0.5 alpha:1.0];
    icon.contentMode = UIViewContentModeScaleAspectFit;
    [row addSubview:icon];

    UILabel *labelView = [[UILabel alloc] init];
    labelView.text = label;
    labelView.font = [UIFont systemFontOfSize:15];
    labelView.textColor = [UIColor colorWithWhite:0.3 alpha:1.0];
    [row addSubview:labelView];

    UITextField *textField = [[UITextField alloc] init];
    textField.placeholder = placeholder;
    textField.font = [UIFont systemFontOfSize:15];
    textField.textColor = [UIColor colorWithWhite:0.15 alpha:1.0];
    textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:placeholder attributes:@{NSForegroundColorAttributeName: [UIColor colorWithWhite:0.6 alpha:1.0]}];
    textField.textAlignment = NSTextAlignmentRight;
    textField.returnKeyType = UIReturnKeyDone;
    textField.keyboardAppearance = UIKeyboardAppearanceLight;
    textField.enabled = NO;
    [row addSubview:textField];
    if (field) *field = textField;

    icon.translatesAutoresizingMaskIntoConstraints = NO;
    labelView.translatesAutoresizingMaskIntoConstraints = NO;
    textField.translatesAutoresizingMaskIntoConstraints = NO;

    [NSLayoutConstraint activateConstraints:@[
        [icon.leadingAnchor constraintEqualToAnchor:row.leadingAnchor constant:16],
        [icon.centerYAnchor constraintEqualToAnchor:row.centerYAnchor],
        [icon.widthAnchor constraintEqualToConstant:20],
        [icon.heightAnchor constraintEqualToConstant:20],

        [labelView.leadingAnchor constraintEqualToAnchor:icon.trailingAnchor constant:8],
        [labelView.centerYAnchor constraintEqualToAnchor:row.centerYAnchor],

        [textField.trailingAnchor constraintEqualToAnchor:row.trailingAnchor constant:-16],
        [textField.centerYAnchor constraintEqualToAnchor:row.centerYAnchor],
        [textField.leadingAnchor constraintEqualToAnchor:labelView.trailingAnchor constant:8]
    ]];
}

- (void)setupSignatureSection {
    UILabel *sigLabel = [[UILabel alloc] init];
    sigLabel.text = @"个性签名 *";
    sigLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    sigLabel.textColor = [UIColor colorWithWhite:0.7 alpha:1.0];
    sigLabel.tag = 120;
    [self.contentView addSubview:sigLabel];

    UIView *sigContainer = [[UIView alloc] init];
    sigContainer.backgroundColor = [UIColor whiteColor];
    sigContainer.layer.cornerRadius = 16;
    sigContainer.tag = 121;
    [self.contentView addSubview:sigContainer];

    self.signatureTextView = [[UITextView alloc] init];
    self.signatureTextView.font = [UIFont systemFontOfSize:15];
    self.signatureTextView.textColor = [UIColor colorWithWhite:0.15 alpha:1.0];
    self.signatureTextView.backgroundColor = [UIColor clearColor];
    self.signatureTextView.delegate = self;
    self.signatureTextView.keyboardAppearance = UIKeyboardAppearanceLight;
    [sigContainer addSubview:self.signatureTextView];

    self.signaturePlaceholder = [[UILabel alloc] init];
    self.signaturePlaceholder.text = @"用一句话介绍自己...";
    self.signaturePlaceholder.font = [UIFont systemFontOfSize:15];
    self.signaturePlaceholder.textColor = [UIColor colorWithWhite:0.6 alpha:1.0];
    [sigContainer addSubview:self.signaturePlaceholder];

    UILabel *charCountLabel = [[UILabel alloc] init];
    charCountLabel.text = @"0/100";
    charCountLabel.font = [UIFont systemFontOfSize:12];
    charCountLabel.textColor = [UIColor colorWithWhite:0.5 alpha:1.0];
    charCountLabel.tag = 122;
    [sigContainer addSubview:charCountLabel];

    self.signatureTextView.translatesAutoresizingMaskIntoConstraints = NO;
    self.signaturePlaceholder.translatesAutoresizingMaskIntoConstraints = NO;
    charCountLabel.translatesAutoresizingMaskIntoConstraints = NO;

    [NSLayoutConstraint activateConstraints:@[
        [self.signatureTextView.topAnchor constraintEqualToAnchor:sigContainer.topAnchor constant:12],
        [self.signatureTextView.leadingAnchor constraintEqualToAnchor:sigContainer.leadingAnchor constant:16],
        [self.signatureTextView.trailingAnchor constraintEqualToAnchor:sigContainer.trailingAnchor constant:-16],
        [self.signatureTextView.heightAnchor constraintEqualToConstant:100],

        [self.signaturePlaceholder.topAnchor constraintEqualToAnchor:sigContainer.topAnchor constant:18],
        [self.signaturePlaceholder.leadingAnchor constraintEqualToAnchor:sigContainer.leadingAnchor constant:20],

        [charCountLabel.topAnchor constraintEqualToAnchor:self.signatureTextView.bottomAnchor constant:4],
        [charCountLabel.trailingAnchor constraintEqualToAnchor:sigContainer.trailingAnchor constant:-16],
        [charCountLabel.bottomAnchor constraintEqualToAnchor:sigContainer.bottomAnchor constant:-8]
    ]];
}

- (void)setupInterestsSection {
    self.interestCountLabel = [[UILabel alloc] init];
    self.interestCountLabel.text = @"兴趣爱好 * (0/10，至少4个)";
    self.interestCountLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    self.interestCountLabel.textColor = [UIColor colorWithWhite:0.7 alpha:1.0];
    self.interestCountLabel.tag = 130;
    [self.contentView addSubview:self.interestCountLabel];

    // Selected interests container
    self.selectedInterestsContainer = [[UIView alloc] init];
    self.selectedInterestsContainer.backgroundColor = DarkCardElevated;
    self.selectedInterestsContainer.layer.cornerRadius = 12;
    self.selectedInterestsContainer.layer.borderWidth = 1;
    self.selectedInterestsContainer.layer.borderColor = BorderLight.CGColor;
    self.selectedInterestsContainer.tag = 131;
    [self.contentView addSubview:self.selectedInterestsContainer];

    // Tap to edit interests
    UITapGestureRecognizer *interestsTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(interestsTapped)];
    [self.selectedInterestsContainer addGestureRecognizer:interestsTap];
    self.selectedInterestsContainer.userInteractionEnabled = YES;

    UILabel *tapHint = [[UILabel alloc] init];
    tapHint.text = @"点击选择兴趣爱好";
    tapHint.font = [UIFont systemFontOfSize:14];
    tapHint.textColor = TextMuted;
    tapHint.tag = 132;
    [self.selectedInterestsContainer addSubview:tapHint];

    tapHint.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [tapHint.centerXAnchor constraintEqualToAnchor:self.selectedInterestsContainer.centerXAnchor],
        [tapHint.centerYAnchor constraintEqualToAnchor:self.selectedInterestsContainer.centerYAnchor]
    ]];
}

- (void)setupConstraints {
    self.gradientView.translatesAutoresizingMaskIntoConstraints = NO;
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
    self.completeButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.loadingIndicator.translatesAutoresizingMaskIntoConstraints = NO;
    self.avatarContainer.translatesAutoresizingMaskIntoConstraints = NO;
    self.avatarImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.avatarLoadingIndicator.translatesAutoresizingMaskIntoConstraints = NO;

    UILabel *titleLabel = [self.contentView viewWithTag:100];
    UILabel *subtitleLabel = [self.contentView viewWithTag:101];
    UILabel *avatarHint = [self.contentView viewWithTag:102];
    UILabel *genderLabel = [self.contentView viewWithTag:110];
    UIView *genderContainer = [self.contentView viewWithTag:111];
    UILabel *sigLabel = [self.contentView viewWithTag:120];
    UIView *sigContainer = [self.contentView viewWithTag:121];
    self.interestCountLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.selectedInterestsContainer.translatesAutoresizingMaskIntoConstraints = NO;
    UILabel *errorLabel = [self.contentView viewWithTag:300];

    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    avatarHint.translatesAutoresizingMaskIntoConstraints = NO;
    genderLabel.translatesAutoresizingMaskIntoConstraints = NO;
    genderContainer.translatesAutoresizingMaskIntoConstraints = NO;
    sigLabel.translatesAutoresizingMaskIntoConstraints = NO;
    sigContainer.translatesAutoresizingMaskIntoConstraints = NO;
    errorLabel.translatesAutoresizingMaskIntoConstraints = NO;

    UIView *row200 = [self.contentView viewWithTag:200];
    UIView *row201 = [self.contentView viewWithTag:201];
    UIView *row202 = [self.contentView viewWithTag:202];
    UIView *row203 = [self.contentView viewWithTag:203];
    UILabel *charCount = [self.contentView viewWithTag:122];

    [self layoutRows:@[row200, row201, row202, row203]];

    self.maleButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.femaleButton.translatesAutoresizingMaskIntoConstraints = NO;

    [NSLayoutConstraint activateConstraints:@[
        [self.gradientView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.gradientView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.gradientView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.gradientView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

        [self.scrollView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [self.scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.scrollView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

        [self.contentView.topAnchor constraintEqualToAnchor:self.scrollView.topAnchor],
        [self.contentView.leadingAnchor constraintEqualToAnchor:self.scrollView.leadingAnchor],
        [self.contentView.trailingAnchor constraintEqualToAnchor:self.scrollView.trailingAnchor],
        [self.contentView.bottomAnchor constraintEqualToAnchor:self.scrollView.bottomAnchor],
        [self.contentView.widthAnchor constraintEqualToAnchor:self.scrollView.widthAnchor],

        [titleLabel.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:24],
        [titleLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:24],

        [subtitleLabel.topAnchor constraintEqualToAnchor:titleLabel.bottomAnchor constant:4],
        [subtitleLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:24],

        [self.avatarContainer.topAnchor constraintEqualToAnchor:subtitleLabel.bottomAnchor constant:32],
        [self.avatarContainer.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor],
        [self.avatarContainer.widthAnchor constraintEqualToConstant:120],
        [self.avatarContainer.heightAnchor constraintEqualToConstant:120],

        [self.avatarImageView.centerXAnchor constraintEqualToAnchor:self.avatarContainer.centerXAnchor],
        [self.avatarImageView.centerYAnchor constraintEqualToAnchor:self.avatarContainer.centerYAnchor],
        [self.avatarImageView.widthAnchor constraintEqualToConstant:60],
        [self.avatarImageView.heightAnchor constraintEqualToConstant:60],

        [self.avatarLoadingIndicator.centerXAnchor constraintEqualToAnchor:self.avatarContainer.centerXAnchor],
        [self.avatarLoadingIndicator.centerYAnchor constraintEqualToAnchor:self.avatarContainer.centerYAnchor],

        [avatarHint.topAnchor constraintEqualToAnchor:self.avatarContainer.bottomAnchor constant:8],
        [avatarHint.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor],

        [genderLabel.topAnchor constraintEqualToAnchor:avatarHint.bottomAnchor constant:32],
        [genderLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:24],

        [genderContainer.topAnchor constraintEqualToAnchor:genderLabel.bottomAnchor constant:12],
        [genderContainer.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:24],
        [genderContainer.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-24],
        [genderContainer.heightAnchor constraintEqualToConstant:56],

        [self.maleButton.leadingAnchor constraintEqualToAnchor:genderContainer.leadingAnchor],
        [self.maleButton.topAnchor constraintEqualToAnchor:genderContainer.topAnchor],
        [self.maleButton.bottomAnchor constraintEqualToAnchor:genderContainer.bottomAnchor],
        [self.maleButton.widthAnchor constraintEqualToAnchor:genderContainer.widthAnchor multiplier:0.5 constant:-4],

        [self.femaleButton.trailingAnchor constraintEqualToAnchor:genderContainer.trailingAnchor],
        [self.femaleButton.topAnchor constraintEqualToAnchor:genderContainer.topAnchor],
        [self.femaleButton.bottomAnchor constraintEqualToAnchor:genderContainer.bottomAnchor],
        [self.femaleButton.widthAnchor constraintEqualToAnchor:genderContainer.widthAnchor multiplier:0.5 constant:-4],

        [sigLabel.topAnchor constraintEqualToAnchor:genderContainer.bottomAnchor constant:24],
        [sigLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:24],

        [sigContainer.topAnchor constraintEqualToAnchor:sigLabel.bottomAnchor constant:12],
        [sigContainer.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:24],
        [sigContainer.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-24],
        [sigContainer.heightAnchor constraintEqualToConstant:160],

        [self.interestCountLabel.topAnchor constraintEqualToAnchor:sigContainer.bottomAnchor constant:24],
        [self.interestCountLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:24],

        [self.selectedInterestsContainer.topAnchor constraintEqualToAnchor:self.interestCountLabel.bottomAnchor constant:12],
        [self.selectedInterestsContainer.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:24],
        [self.selectedInterestsContainer.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-24],
        [self.selectedInterestsContainer.heightAnchor constraintEqualToConstant:60],

        [errorLabel.topAnchor constraintEqualToAnchor:self.selectedInterestsContainer.bottomAnchor constant:12],
        [errorLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:24],
        [errorLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-24],

        [self.completeButton.topAnchor constraintEqualToAnchor:errorLabel.bottomAnchor constant:16],
        [self.completeButton.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:24],
        [self.completeButton.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-24],
        [self.completeButton.heightAnchor constraintEqualToConstant:56],
        [self.completeButton.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-40],

        [self.loadingIndicator.centerXAnchor constraintEqualToAnchor:self.completeButton.centerXAnchor],
        [self.loadingIndicator.centerYAnchor constraintEqualToAnchor:self.completeButton.centerYAnchor]
    ]];
}

- (void)layoutRows:(NSArray<UIView *> *)rows {
    UIView *prev = [self.contentView viewWithTag:102]; // avatarHint

    for (NSInteger i = 0; i < rows.count; i++) {
        UIView *row = rows[i];
        row.translatesAutoresizingMaskIntoConstraints = NO;
        [NSLayoutConstraint activateConstraints:@[
            [row.topAnchor constraintEqualToAnchor:prev.bottomAnchor constant:12],
            [row.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:24],
            [row.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-24],
            [row.heightAnchor constraintEqualToConstant:50]
        ]];
        prev = row;
    }
}

#pragma mark - Gradient

- (void)setupGradientIfNeeded {
    for (CALayer *layer in self.gradientView.layer.sublayers) {
        if ([layer isKindOfClass:[CAGradientLayer class]]) return;
    }

    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = self.view.bounds;
    gradient.colors = @[
        (id)[UIColor colorWithRed:139/255.0 green:92/255.0 blue:246/255.0 alpha:1].CGColor,
        (id)[UIColor colorWithRed:236/255.0 green:72/255.0 blue:153/255.0 alpha:1].CGColor
    ];
    gradient.startPoint = CGPointMake(0, 0);
    gradient.endPoint = CGPointMake(1, 1);
    [self.gradientView.layer insertSublayer:gradient atIndex:0];

    CAGradientLayer *buttonGradient = [CAGradientLayer layer];
    buttonGradient.colors = @[
        (id)PrimaryPink.CGColor,
        (id)PrimaryPurple.CGColor
    ];
    buttonGradient.startPoint = CGPointMake(0, 0);
    buttonGradient.endPoint = CGPointMake(1, 1);
    buttonGradient.cornerRadius = 28;
    [self.completeButton.layer insertSublayer:buttonGradient atIndex:0];
}

- (void)updateGradientFrames {
    self.gradientView.frame = self.view.bounds;
    for (CALayer *layer in self.gradientView.layer.sublayers) {
        if ([layer isKindOfClass:[CAGradientLayer class]]) {
            layer.frame = self.view.bounds;
        }
    }
    for (CALayer *layer in self.completeButton.layer.sublayers) {
        if ([layer isKindOfClass:[CAGradientLayer class]]) {
            layer.frame = self.completeButton.bounds;
        }
    }
}

#pragma mark - Data Loading

- (void)loadData {
    [[HYAPIClient shared] getInterestsWithCompletion:^(NSDictionary *response, NSError *error) {
        if (!error) {
            NSArray *data = response[@"data"];
            if ([data isKindOfClass:[NSArray class]]) {
                NSMutableArray *cats = [NSMutableArray array];
                for (NSDictionary *dict in data) {
                    [cats addObject:[[HYInterestCategory alloc] initWithDictionary:dict]];
                }
                self.interestCategories = cats;
            }
        }
        if (self.interestCategories.count == 0) {
            self.interestCategories = @[
                [[HYInterestCategory alloc] initWithDictionary:@{@"name": @"娱乐", @"tags": @[@"音乐", @"电影", @"游戏", @"阅读", @"电竞"]}],
                [[HYInterestCategory alloc] initWithDictionary:@{@"name": @"运动", @"tags": @[@"健身", @"跑步", @"游泳", @"篮球", @"足球"]}],
                [[HYInterestCategory alloc] initWithDictionary:@{@"name": @"生活", @"tags": @[@"美食", @"旅行", @"摄影", @"时尚", @"宠物"]}],
                [[HYInterestCategory alloc] initWithDictionary:@{@"name": @"艺术", @"tags": @[@"绘画", @"舞蹈", @"书法", @"手工", @"设计"]}]
            ];
        }
    }];
}

#pragma mark - Avatar

- (void)avatarTapped {
    [self.view endEditing:YES];
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

    [self.avatarLoadingIndicator startAnimating];
    self.avatarHintLabel.hidden = YES;

    PHPickerResult *result = results.firstObject;
    if ([result.itemProvider canLoadObjectOfClass:[UIImage class]]) {
        [result.itemProvider loadObjectOfClass:[UIImage class] completionHandler:^(id<NSItemProviderReading> object, NSError *error) {
            if (![object isKindOfClass:[UIImage class]]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.avatarLoadingIndicator stopAnimating];
                    self.avatarHintLabel.hidden = NO;
                });
                return;
            }
            UIImage *image = (UIImage *)object;
            dispatch_async(dispatch_get_main_queue(), ^{
                self.selectedAvatarImage = image;
                self.avatarImageView.image = image;
                self.avatarImageView.contentMode = UIViewContentModeScaleAspectFill;
                [self.avatarLoadingIndicator stopAnimating];
                [self uploadAvatarImage:image];
            });
        }];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.avatarLoadingIndicator stopAnimating];
            self.avatarHintLabel.hidden = NO;
        });
    }
}

- (void)uploadAvatarImage:(UIImage *)image {
    NSData *imageData = UIImageJPEGRepresentation(image, 0.8);
    if (!imageData) return;

    [self.avatarLoadingIndicator startAnimating];
    self.avatarHintLabel.text = @"上传中...";

    __weak typeof(self) weakSelf = self;
    [[HYAPIClient shared] uploadAvatarImage:imageData completion:^(NSString *imageUrl, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) return;

            [strongSelf.avatarLoadingIndicator stopAnimating];

            if (error) {
                strongSelf.avatarHintLabel.text = @"上传失败，点击重试";
                strongSelf.avatarHintLabel.hidden = NO;
            } else {
                strongSelf.uploadedAvatarUrl = imageUrl;
                strongSelf.avatarHintLabel.text = @"点击更换头像";
                strongSelf.avatarHintLabel.hidden = NO;
            }
        });
    }];
}

#pragma mark - Gender

- (void)genderButtonTapped:(UIButton *)sender {
    self.selectedGender = sender.tag;

    BOOL maleSelected = (self.selectedGender == 1);
    BOOL femaleSelected = (self.selectedGender == 2);

    self.maleButton.backgroundColor = maleSelected ? [PrimaryPink colorWithAlphaComponent:0.2] : [UIColor clearColor];
    self.maleButton.layer.borderColor = maleSelected ? PrimaryPink.CGColor : BorderLight.CGColor;

    self.femaleButton.backgroundColor = femaleSelected ? [PrimaryPink colorWithAlphaComponent:0.2] : [UIColor clearColor];
    self.femaleButton.layer.borderColor = femaleSelected ? PrimaryPink.CGColor : BorderLight.CGColor;

    // Update default height/weight based on gender
    if (maleSelected) {
        self.selectedHeight = 170;
        self.selectedWeight = 65;
        self.heightField.text = @"170cm";
        self.weightField.text = @"65kg";
    } else if (femaleSelected) {
        self.selectedHeight = 160;
        self.selectedWeight = 50;
        self.heightField.text = @"160cm";
        self.weightField.text = @"50kg";
    }
}

#pragma mark - Field Actions

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
    __weak typeof(self) weakSelf = self;
    [HYPickerManager showHeightPickerWithValue:self.selectedHeight completion:^(NSInteger value) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        strongSelf.selectedHeight = value;
        strongSelf.heightField.text = [NSString stringWithFormat:@"%ldcm", (long)value];
    }];
}

- (void)weightTapped {
    [self.view endEditing:YES];
    __weak typeof(self) weakSelf = self;
    [HYPickerManager showWeightPickerWithValue:self.selectedWeight completion:^(NSInteger value) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        strongSelf.selectedWeight = value;
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

- (void)updateInterestsDisplay {
    self.interestCountLabel.text = [NSString stringWithFormat:@"兴趣爱好 * (%ld/10，至少4个)", (long)self.selectedInterests.count];

    // Clear container
    for (UIView *sub in self.selectedInterestsContainer.subviews) {
        [sub removeFromSuperview];
    }

    if (self.selectedInterests.count == 0) {
        UILabel *hint = [[UILabel alloc] init];
        hint.text = @"点击选择兴趣爱好";
        hint.font = [UIFont systemFontOfSize:14];
        hint.textColor = TextMuted;
        hint.translatesAutoresizingMaskIntoConstraints = NO;
        [self.selectedInterestsContainer addSubview:hint];
        [NSLayoutConstraint activateConstraints:@[
            [hint.centerXAnchor constraintEqualToAnchor:self.selectedInterestsContainer.centerXAnchor],
            [hint.centerYAnchor constraintEqualToAnchor:self.selectedInterestsContainer.centerYAnchor]
        ]];
    } else {
        CGFloat x = 8, y = 8;
        CGFloat maxWidth = self.view.bounds.size.width - 48;
        CGFloat rowHeight = 32;

        for (NSString *tag in self.selectedInterests) {
            CGSize size = [tag sizeWithAttributes:@{NSFontAttributeName: [UIFont systemFontOfSize:13]}];
            CGFloat btnWidth = size.width + 24;

            if (x + btnWidth > maxWidth) {
                x = 8;
                y += rowHeight + 8;
            }

            UIButton *chip = [UIButton buttonWithType:UIButtonTypeCustom];
            [chip setTitle:[NSString stringWithFormat:@"%@ ×", tag] forState:UIControlStateNormal];
            [chip setTitleColor:PrimaryPink forState:UIControlStateNormal];
            chip.titleLabel.font = [UIFont systemFontOfSize:12];
            chip.backgroundColor = [PrimaryPink colorWithAlphaComponent:0.15];
            chip.layer.cornerRadius = 16;
            chip.contentEdgeInsets = UIEdgeInsetsMake(6, 12, 6, 12);
            chip.frame = CGRectMake(x, y, btnWidth, rowHeight);
            [self.selectedInterestsContainer addSubview:chip];

            x += btnWidth + 6;
        }
    }
}

#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView {
    NSString *text = textView.text;
    if (text.length > 100) {
        textView.text = [text substringToIndex:100];
    }

    UILabel *charCount = [self.contentView viewWithTag:122];
    charCount.text = [NSString stringWithFormat:@"%ld/100", (long)textView.text.length];

    self.signaturePlaceholder.hidden = textView.text.length > 0;
}

#pragma mark - Complete

- (void)completeTapped {
    [self.view endEditing:YES];
    self.errorLabel.hidden = YES;

    NSString *error = [self validateForm];
    if (error) {
        self.errorLabel.text = error;
        self.errorLabel.hidden = NO;
        return;
    }

    [self setLoading:YES];

    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    fmt.dateFormat = @"yyyy-MM-dd";
    NSString *birthdayString = [fmt stringFromDate:self.selectedBirthday];

    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"avatar_url"] = self.uploadedAvatarUrl ?: @"";
    params[@"sex"] = @(self.selectedGender);
    params[@"birth_day"] = birthdayString;
    params[@"current_address"] = [NSString stringWithFormat:@"%@ · %@", self.selectedCountry ?: @"", self.selectedCity ?: @""];
    params[@"height"] = @(self.selectedHeight);
    params[@"weight"] = @(self.selectedWeight);
    params[@"signature"] = self.signatureTextView.text ?: @"";
    params[@"interests"] = self.selectedInterests;

    __weak typeof(self) weakSelf = self;
    [[HYAPIClient shared] completeProfileWithData:params completion:^(NSDictionary *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) return;

            [strongSelf setLoading:NO];

            if (error) {
                strongSelf.errorLabel.text = error.localizedDescription;
                strongSelf.errorLabel.hidden = NO;
                return;
            }

            if (strongSelf.onComplete) {
                strongSelf.onComplete();
            }
        });
    }];
}

- (NSString *)validateForm {
    if (!self.uploadedAvatarUrl || self.uploadedAvatarUrl.length == 0) {
        return @"请上传头像";
    }
    if (self.selectedGender == 0) {
        return @"请选择性别";
    }
    if (!self.selectedBirthday) {
        return @"请选择生日";
    }
    if (!self.selectedCountry || !self.selectedCity) {
        return @"请选择国家和城市";
    }
    if (self.signatureTextView.text.length == 0) {
        return @"请输入个性签名";
    }
    if (self.selectedInterests.count < 4) {
        return @"请至少选择4个兴趣爱好";
    }
    if (self.selectedInterests.count > 10) {
        return @"最多选择10个兴趣爱好";
    }
    return nil;
}

- (void)setLoading:(BOOL)loading {
    self.isLoading = loading;
    self.completeButton.enabled = !loading;
    self.avatarContainer.userInteractionEnabled = !loading;

    if (loading) {
        [self.completeButton setTitle:@"" forState:UIControlStateNormal];
        [self.loadingIndicator startAnimating];
    } else {
        [self.completeButton setTitle:@"完成" forState:UIControlStateNormal];
        [self.loadingIndicator stopAnimating];
    }
}

- (void)dismissKeyboard {
    [self.view endEditing:YES];
}

@end
