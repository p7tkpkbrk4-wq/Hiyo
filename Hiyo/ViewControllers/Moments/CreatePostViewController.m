#import "CreatePostViewController.h"
#import "HYAPIClient.h"
#import "HYModels.h"
#import "HYColors.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/SDWebImage.h>
#import <PhotosUI/PhotosUI.h>

static NSInteger const kMaxTitleLength = 20;
static NSInteger const kMaxContentLength = 250;
static NSInteger const kMaxImageCount = 6;
static CGFloat const kImageCellSize = 108.0;
static CGFloat const kImageCellSpacing = 8.0;

@interface CreatePostViewController () <UITextFieldDelegate, UITextViewDelegate, PHPickerViewControllerDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic, strong) UILabel *userNameLabel;
@property (nonatomic, strong) UITextField *titleField;
@property (nonatomic, strong) UILabel *titleCounter;
@property (nonatomic, strong) UITextView *contentTextView;
@property (nonatomic, strong) UILabel *contentPlaceholder;
@property (nonatomic, strong) UILabel *contentCounter;
@property (nonatomic, strong) UIView *imageContainerView;
@property (nonatomic, strong) UIButton *addImageButton;
@property (nonatomic, strong) NSMutableArray<UIImageView *> *imageViews;
@property (nonatomic, strong) NSMutableArray<NSData *> *imageDatas;
@property (nonatomic, strong) UIButton *publishButton;
@property (nonatomic, strong) UIActivityIndicatorView *loadingIndicator;
@property (nonatomic, strong) UILabel *errorLabel;

@end

@implementation CreatePostViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"发帖";
    self.view.backgroundColor = LightBg1;
    self.imageViews = [NSMutableArray array];
    self.imageDatas = [NSMutableArray array];
    [self setupNavigationBar];
    [self setupUI];
}

#pragma mark - Setup

- (void)setupNavigationBar {
    if (@available(iOS 15.0, *)) {
        UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
        [appearance configureWithOpaqueBackground];
        appearance.backgroundColor = [UIColor whiteColor];
        appearance.shadowColor = [UIColor colorWithRed:0.933 green:0.933 blue:1.0 alpha:1.0];
        appearance.titleTextAttributes = @{
            NSForegroundColorAttributeName: [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0],
            NSFontAttributeName: [UIFont systemFontOfSize:18 weight:UIFontWeightBold]
        };
        self.navigationController.navigationBar.standardAppearance = appearance;
        self.navigationController.navigationBar.scrollEdgeAppearance = appearance;
    } else {
        self.navigationController.navigationBar.backgroundColor = [UIColor whiteColor];
        self.navigationController.navigationBar.titleTextAttributes = @{
            NSForegroundColorAttributeName: [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0],
            NSFontAttributeName: [UIFont systemFontOfSize:18 weight:UIFontWeightBold]
        };
    }

    // Left: Cancel button
    UIBarButtonItem *cancelItem = [[UIBarButtonItem alloc] initWithTitle:@"取消"
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(cancelTapped)];
    cancelItem.tintColor = [UIColor colorWithRed:0.6 green:0.6 blue:0.6 alpha:1.0];
    self.navigationItem.leftBarButtonItem = cancelItem;

    // Right: Gradient Publish button
    self.publishButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.publishButton.frame = CGRectMake(0, 0, 80, 36);
    self.publishButton.layer.cornerRadius = 18;
    self.publishButton.clipsToBounds = YES;

    CAGradientLayer *publishGrad = [CAGradientLayer layer];
    publishGrad.colors = @[(id)PinkGradStart.CGColor, (id)PurpleGradStart.CGColor];
    publishGrad.startPoint = CGPointMake(0, 0.5);
    publishGrad.endPoint = CGPointMake(1, 0.5);
    publishGrad.cornerRadius = 18;
    publishGrad.frame = CGRectMake(0, 0, 80, 36);
    [self.publishButton.layer insertSublayer:publishGrad atIndex:0];

    self.publishButton.layer.shadowColor = PinkGradStart.CGColor;
    self.publishButton.layer.shadowOffset = CGSizeMake(0, 2);
    self.publishButton.layer.shadowRadius = 8;
    self.publishButton.layer.shadowOpacity = 0.25;
    self.publishButton.layer.masksToBounds = NO;

    [self.publishButton setTitle:@"发布" forState:UIControlStateNormal];
    [self.publishButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.publishButton.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    self.publishButton.enabled = NO;
    [self.publishButton addTarget:self action:@selector(publishTapped) forControlEvents:UIControlEventTouchUpInside];

    UIBarButtonItem *publishItem = [[UIBarButtonItem alloc] initWithCustomView:self.publishButton];
    self.navigationItem.rightBarButtonItem = publishItem;
}

- (void)setupUI {
    // Scroll view
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.backgroundColor = [UIColor clearColor];
    self.scrollView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    self.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    [self.view addSubview:self.scrollView];

    self.contentView = [[UIView alloc] init];
    self.contentView.backgroundColor = [UIColor clearColor];
    [self.scrollView addSubview:self.contentView];

    // User avatar with pink shadow
    UIView *avatarContainer = [[UIView alloc] init];
    [self.contentView addSubview:avatarContainer];

    UIView *avatarShadow = [[UIView alloc] init];
    avatarShadow.backgroundColor = [UIColor clearColor];
    avatarShadow.layer.shadowColor = PinkGradStart.CGColor;
    avatarShadow.layer.shadowOffset = CGSizeMake(0, 4);
    avatarShadow.layer.shadowRadius = 8;
    avatarShadow.layer.shadowOpacity = 0.3;
    [avatarContainer addSubview:avatarShadow];

    self.avatarImageView = [[UIImageView alloc] init];
    self.avatarImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.avatarImageView.clipsToBounds = YES;
    self.avatarImageView.layer.cornerRadius = 24;
    self.avatarImageView.backgroundColor = [UIColor colorWithRed:0.941 green:0.929 blue:1.0 alpha:1.0];
    self.avatarImageView.image = [UIImage systemImageNamed:@"person.circle.fill"];
    [avatarShadow addSubview:self.avatarImageView];

    self.userNameLabel = [[UILabel alloc] init];
    self.userNameLabel.text = @"用户";
    self.userNameLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightBold];
    self.userNameLabel.textColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0];
    self.userNameLabel.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:self.userNameLabel];

    [self loadCurrentUserInfo];

    // Title field
    UIView *titleContainer = [[UIView alloc] init];
    titleContainer.backgroundColor = LightCard;
    titleContainer.layer.cornerRadius = 12;
    titleContainer.layer.borderWidth = 1.5;
    titleContainer.layer.borderColor = [UIColor colorWithRed:0.933 green:0.933 blue:1.0 alpha:1.0].CGColor;
    titleContainer.layer.shadowColor = PurpleGradStart.CGColor;
    titleContainer.layer.shadowOffset = CGSizeMake(0, 3);
    titleContainer.layer.shadowRadius = 10;
    titleContainer.layer.shadowOpacity = 0.08;
    [self.contentView addSubview:titleContainer];

    self.titleField = [[UITextField alloc] init];
    self.titleField.font = [UIFont systemFontOfSize:15];
    self.titleField.textColor = [UIColor colorWithRed:0.333 green:0.333 blue:0.333 alpha:1.0];
    self.titleField.delegate = self;
    self.titleField.returnKeyType = UIReturnKeyNext;
    self.titleField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.titleField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"标题（选填，不超过20字）"
                                                                          attributes:@{
        NSForegroundColorAttributeName: [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:1.0]
    }];
    [self.titleField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    [titleContainer addSubview:self.titleField];

    self.titleCounter = [[UILabel alloc] init];
    self.titleCounter.text = @"0/20";
    self.titleCounter.font = [UIFont systemFontOfSize:12];
    self.titleCounter.textColor = [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:1.0];
    self.titleCounter.textAlignment = NSTextAlignmentRight;
    [titleContainer addSubview:self.titleCounter];

    // Content text area
    UIView *contentContainer = [[UIView alloc] init];
    contentContainer.backgroundColor = LightCard;
    contentContainer.layer.cornerRadius = 14;
    contentContainer.layer.borderWidth = 1.5;
    contentContainer.layer.borderColor = [UIColor colorWithRed:0.933 green:0.933 blue:1.0 alpha:1.0].CGColor;
    contentContainer.layer.shadowColor = PurpleGradStart.CGColor;
    contentContainer.layer.shadowOffset = CGSizeMake(0, 3);
    contentContainer.layer.shadowRadius = 10;
    contentContainer.layer.shadowOpacity = 0.08;
    [self.contentView addSubview:contentContainer];

    self.contentTextView = [[UITextView alloc] init];
    self.contentTextView.font = [UIFont systemFontOfSize:15];
    self.contentTextView.textColor = [UIColor colorWithRed:0.333 green:0.333 blue:0.333 alpha:1.0];
    self.contentTextView.backgroundColor = [UIColor clearColor];
    self.contentTextView.delegate = self;
    [contentContainer addSubview:self.contentTextView];

    self.contentPlaceholder = [[UILabel alloc] init];
    self.contentPlaceholder.text = @"分享你的想法...";
    self.contentPlaceholder.font = [UIFont systemFontOfSize:15];
    self.contentPlaceholder.textColor = [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:1.0];
    [contentContainer addSubview:self.contentPlaceholder];

    self.contentCounter = [[UILabel alloc] init];
    self.contentCounter.text = @"0/250";
    self.contentCounter.font = [UIFont systemFontOfSize:12];
    self.contentCounter.textColor = [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:1.0];
    self.contentCounter.textAlignment = NSTextAlignmentRight;
    [contentContainer addSubview:self.contentCounter];

    // Image section label
    UILabel *imageSectionLabel = [[UILabel alloc] init];
    imageSectionLabel.text = @"图片（选填，最多6张）";
    imageSectionLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
    imageSectionLabel.textColor = [UIColor colorWithRed:0.4 green:0.4 blue:0.4 alpha:1.0];
    [self.contentView addSubview:imageSectionLabel];

    // Image container
    self.imageContainerView = [[UIView alloc] init];
    self.imageContainerView.backgroundColor = [UIColor clearColor];
    [self.contentView addSubview:self.imageContainerView];

    // Add image button with dashed border
    self.addImageButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.addImageButton.backgroundColor = [UIColor colorWithRed:0.961 green:0.961 blue:0.961 alpha:1.0];
    self.addImageButton.layer.cornerRadius = 10;
    [self.addImageButton.layer addSublayer:[self dashedBorderLayer:self.addImageButton.bounds cornerRadius:10]];
    [self.addImageButton addTarget:self action:@selector(addImageTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.imageContainerView addSubview:self.addImageButton];

    // Plus circle on add button
    UIView *plusCircle = [[UIView alloc] init];
    plusCircle.backgroundColor = [UIColor whiteColor];
    plusCircle.layer.cornerRadius = 24;
    plusCircle.layer.borderWidth = 1.5;
    plusCircle.layer.borderColor = [UIColor colorWithRed:0.933 green:0.933 blue:0.933 alpha:1.0].CGColor;
    [self.addImageButton addSubview:plusCircle];

    UILabel *plusLabel = [[UILabel alloc] init];
    plusLabel.text = @"+";
    plusLabel.font = [UIFont systemFontOfSize:22 weight:UIFontWeightMedium];
    plusLabel.textColor = [UIColor colorWithRed:0.667 green:0.667 blue:0.667 alpha:1.0];
    plusLabel.textAlignment = NSTextAlignmentCenter;
    [plusCircle addSubview:plusLabel];

    // Tips banner
    UIView *tipsBanner = [[UIView alloc] init];
    tipsBanner.backgroundColor = [UIColor colorWithRed:1.0 green:0.973 blue:0.878 alpha:0.8];
    tipsBanner.layer.cornerRadius = 12;
    [self.contentView addSubview:tipsBanner];

    UIView *tipsIconCircle = [[UIView alloc] init];
    tipsIconCircle.backgroundColor = [UIColor colorWithRed:1.0 green:0.596 blue:0.0 alpha:0.2];
    tipsIconCircle.layer.cornerRadius = 12;
    [tipsBanner addSubview:tipsIconCircle];

    UILabel *tipsIcon = [[UILabel alloc] init];
    tipsIcon.text = @"!";
    tipsIcon.font = [UIFont systemFontOfSize:10 weight:UIFontWeightBold];
    tipsIcon.textColor = [UIColor colorWithRed:1.0 green:0.596 blue:0.0 alpha:1.0];
    tipsIcon.textAlignment = NSTextAlignmentCenter;
    [tipsIconCircle addSubview:tipsIcon];

    UILabel *tipsTitle = [[UILabel alloc] init];
    tipsTitle.text = @"温馨提醒";
    tipsTitle.font = [UIFont systemFontOfSize:12 weight:UIFontWeightSemibold];
    tipsTitle.textColor = [UIColor colorWithRed:1.0 green:0.596 blue:0.0 alpha:1.0];
    [tipsBanner addSubview:tipsTitle];

    UILabel *tipsText = [[UILabel alloc] init];
    tipsText.text = @"请勿发布违规内容，共同维护社区环境";
    tipsText.font = [UIFont systemFontOfSize:11];
    tipsText.textColor = [UIColor colorWithRed:0.8 green:0.533 blue:0.0 alpha:1.0];
    [tipsBanner addSubview:tipsText];

    // Error label
    self.errorLabel = [[UILabel alloc] init];
    self.errorLabel.font = [UIFont systemFontOfSize:13];
    self.errorLabel.textColor = [UIColor systemRedColor];
    self.errorLabel.textAlignment = NSTextAlignmentCenter;
    self.errorLabel.numberOfLines = 0;
    self.errorLabel.hidden = YES;
    [self.contentView addSubview:self.errorLabel];

    // Loading
    self.loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    self.loadingIndicator.hidesWhenStopped = YES;
    [self.view addSubview:self.loadingIndicator];

    [self setupConstraints:titleContainer contentContainer:contentContainer imageSectionLabel:imageSectionLabel tipsBanner:tipsBanner tipsIconCircle:tipsIconCircle tipsIcon:tipsIcon tipsTitle:tipsTitle tipsText:tipsText plusCircle:plusCircle plusLabel:plusLabel avatarContainer:avatarContainer avatarShadow:avatarShadow];
}

- (CAShapeLayer *)dashedBorderLayer:(CGRect)bounds cornerRadius:(CGFloat)radius {
    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    shapeLayer.strokeColor = [UIColor colorWithRed:0.867 green:0.867 blue:0.867 alpha:1.0].CGColor;
    shapeLayer.fillColor = [UIColor clearColor].CGColor;
    shapeLayer.lineWidth = 1.5;
    shapeLayer.lineDashPattern = @[@6, @3];
    shapeLayer.frame = bounds;
    shapeLayer.path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, bounds.size.width, bounds.size.height) cornerRadius:radius].CGPath;
    return shapeLayer;
}

- (void)loadCurrentUserInfo {
    NSString *userId = [[NSUserDefaults standardUserDefaults] stringForKey:@"hiyo_user_id"];
    NSString *nickname = [[NSUserDefaults standardUserDefaults] stringForKey:@"hiyo_nickname"];
    NSString *avatar = [[NSUserDefaults standardUserDefaults] stringForKey:@"hiyo_avatar"];

    if (nickname.length > 0) {
        self.userNameLabel.text = nickname;
    }
    if (avatar.length > 0) {
        [self.avatarImageView sd_setImageWithURL:[NSURL URLWithString:avatar] placeholderImage:[UIImage systemImageNamed:@"person.circle.fill"]];
    }
}

- (void)setupConstraints:(UIView *)titleContainer
         contentContainer:(UIView *)contentContainer
       imageSectionLabel:(UILabel *)imageSectionLabel
               tipsBanner:(UIView *)tipsBanner
           tipsIconCircle:(UIView *)tipsIconCircle
                tipsIcon:(UILabel *)tipsIcon
              tipsTitle:(UILabel *)tipsTitle
               tipsText:(UILabel *)tipsText
             plusCircle:(UIView *)plusCircle
              plusLabel:(UILabel *)plusLabel
          avatarContainer:(UIView *)avatarContainer
             avatarShadow:(UIView *)avatarShadow {

    [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
        make.leading.trailing.bottom.equalTo(self.view);
    }];

    [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.scrollView);
        make.width.equalTo(self.scrollView);
    }];

    [avatarContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(20);
        make.centerX.equalTo(self.contentView);
        make.width.height.equalTo(@56);
    }];

    [avatarShadow mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(avatarContainer);
    }];

    [self.avatarImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(avatarContainer);
        make.width.height.equalTo(@48);
    }];

    [self.userNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(avatarContainer.mas_bottom).offset(12);
        make.centerX.equalTo(self.contentView);
    }];

    [titleContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.userNameLabel.mas_bottom).offset(20);
        make.leading.equalTo(self.contentView).offset(24);
        make.trailing.equalTo(self.contentView).offset(-24);
        make.height.equalTo(@48);
    }];

    [self.titleField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(titleContainer).offset(16);
        make.trailing.equalTo(titleContainer).offset(-60);
        make.centerY.equalTo(titleContainer);
    }];

    [self.titleCounter mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(titleContainer).offset(-16);
        make.centerY.equalTo(titleContainer);
    }];

    [contentContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(titleContainer.mas_bottom).offset(12);
        make.leading.trailing.equalTo(titleContainer);
        make.height.equalTo(@200);
    }];

    [self.contentTextView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(contentContainer).insets(UIEdgeInsetsMake(12, 12, 36, 12));
    }];

    [self.contentPlaceholder mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(contentContainer).offset(17);
        make.top.equalTo(contentContainer).offset(20);
    }];

    [self.contentCounter mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(contentContainer).offset(-16);
        make.bottom.equalTo(contentContainer).offset(-12);
    }];

    [imageSectionLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(contentContainer.mas_bottom).offset(20);
        make.leading.equalTo(self.contentView).offset(24);
    }];

    [self.imageContainerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(imageSectionLabel.mas_bottom).offset(12);
        make.leading.trailing.equalTo(self.contentView).inset(24);
        make.height.equalTo(@(kImageCellSize + kImageCellSpacing * 2 + 20));
    }];

    [self.addImageButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.top.equalTo(self.imageContainerView).offset(kImageCellSpacing);
        make.width.height.equalTo(@(kImageCellSize));
    }];

    [plusCircle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.addImageButton);
        make.centerY.equalTo(self.addImageButton).offset(-4);
        make.width.height.equalTo(@48);
    }];

    [plusLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(plusCircle);
    }];

    [tipsBanner mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.imageContainerView.mas_bottom).offset(24);
        make.leading.equalTo(self.contentView).offset(24);
        make.trailing.equalTo(self.contentView).offset(-24);
        make.height.equalTo(@50);
        make.bottom.equalTo(self.contentView).offset(-40);
    }];

    [tipsIconCircle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(tipsBanner).offset(12);
        make.centerY.equalTo(tipsBanner);
        make.width.height.equalTo(@24);
    }];

    [tipsIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(tipsIconCircle);
    }];

    [tipsTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(tipsIconCircle.mas_trailing).offset(8);
        make.top.equalTo(tipsBanner).offset(8);
    }];

    [tipsText mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(tipsTitle);
        make.top.equalTo(tipsTitle.mas_bottom).offset(2);
    }];

    [self.errorLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(tipsBanner.mas_bottom).offset(8);
        make.leading.trailing.equalTo(self.contentView).inset(16);
    }];

    [self.loadingIndicator mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);
    }];

    [self updateImageLayout];
}

- (void)updateImageLayout {
    CGFloat imageSize = kImageCellSize;
    CGFloat spacing = kImageCellSpacing;
    NSInteger count = self.imageViews.count;

    for (NSInteger i = 0; i < count; i++) {
        NSInteger col = i % 3;
        NSInteger row = i / 3;

        UIImageView *imgView = self.imageViews[i];
        [imgView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(self.imageContainerView).offset(spacing + col * (imageSize + spacing));
            make.top.equalTo(self.imageContainerView).offset(spacing + row * (imageSize + spacing));
            make.width.height.equalTo(@(imageSize));
        }];
    }

    NSInteger nextCol = count % 3;
    NSInteger nextRow = count / 3;

    self.addImageButton.hidden = (count >= kMaxImageCount);
    [self.addImageButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.imageContainerView).offset(spacing + nextCol * (imageSize + spacing));
        make.top.equalTo(self.imageContainerView).offset(spacing + nextRow * (imageSize + spacing));
        make.width.height.equalTo(@(imageSize));
    }];

    NSInteger totalCells = count >= kMaxImageCount ? count : count + 1;
    NSInteger rows = (totalCells + 2) / 3;
    if (rows == 0) rows = 1;
    CGFloat height = spacing + rows * imageSize + (rows - 1) * spacing + spacing + 20;
    [self.imageContainerView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@(height));
    }];
}

#pragma mark - Actions

- (void)cancelTapped {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)addImageTapped {
    NSInteger remaining = kMaxImageCount - (NSInteger)self.imageViews.count;
    if (remaining <= 0) return;

    PHPickerConfiguration *config = [[PHPickerConfiguration alloc] init];
    config.selectionLimit = remaining;
    config.filter = [PHPickerFilter imagesFilter];

    PHPickerViewController *picker = [[PHPickerViewController alloc] initWithConfiguration:config];
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)publishTapped {
    NSString *title = [self.titleField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSString *content = [self.contentTextView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

    if (title.length == 0) {
        [self showError:@"请输入标题"];
        return;
    }
    if (content.length == 0) {
        [self showError:@"请输入内容"];
        return;
    }

    self.errorLabel.hidden = YES;
    self.publishButton.enabled = NO;
    self.navigationItem.leftBarButtonItem.enabled = NO;
    [self.loadingIndicator startAnimating];

    if (self.imageDatas.count > 0) {
        [self uploadImagesAndCreatePost:title content:content];
    } else {
        [self createPostWithTitle:title content:content imageUrl:@""];
    }
}

- (void)uploadImagesAndCreatePost:(NSString *)title content:(NSString *)content {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableArray *uploadedUrls = [NSMutableArray array];
        __block NSString *uploadError = nil;
        dispatch_group_t group = dispatch_group_create();

        for (NSInteger i = 0; i < self.imageDatas.count; i++) {
            dispatch_group_enter(group);
            NSData *data = self.imageDatas[i];
            NSString *fileName = [NSString stringWithFormat:@"post_image_%ld_%@.jpg", (long)[[NSDate date] timeIntervalSince1970], @(i)];

            [[HYAPIClient shared] uploadImageWithData:data fileName:fileName completion:^(NSDictionary *response, NSError *error) {
                if (error) {
                    uploadError = @"图片上传失败";
                } else {
                    NSDictionary *dataDict = response[@"data"];
                    if ([dataDict isKindOfClass:[NSDictionary class]]) {
                        NSString *url = dataDict[@"url"];
                        if (url) {
                            [uploadedUrls addObject:url];
                        }
                    }
                }
                dispatch_group_leave(group);
            }];
        }

        dispatch_group_wait(group, DISPATCH_TIME_FOREVER);

        dispatch_async(dispatch_get_main_queue(), ^{
            if (uploadedUrls.count == 0) {
                [self showError:@"图片上传失败"];
                [self.loadingIndicator stopAnimating];
                self.publishButton.enabled = YES;
                self.navigationItem.leftBarButtonItem.enabled = YES;
                return;
            }

            NSString *imageUrl = [uploadedUrls componentsJoinedByString:@","];
            [self createPostWithTitle:title content:content imageUrl:imageUrl];
        });
    });
}

- (void)createPostWithTitle:(NSString *)title content:(NSString *)content imageUrl:(NSString *)imageUrl {
    [[HYAPIClient shared] createPostWithTitle:title content:content imageUrl:imageUrl completion:^(NSDictionary *response, NSError *error) {
        [self.loadingIndicator stopAnimating];
        self.publishButton.enabled = YES;
        self.navigationItem.leftBarButtonItem.enabled = YES;

        if (error) {
            [self showError:error.localizedDescription];
            return;
        }

        [[NSNotificationCenter defaultCenter] postNotificationName:@"HYPostCreatedNotification" object:nil];
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
}

- (void)showError:(NSString *)message {
    self.errorLabel.text = message;
    self.errorLabel.hidden = NO;
}

- (void)removeImageAtIndex:(NSInteger)index {
    if (index < 0 || index >= (NSInteger)self.imageViews.count) return;

    UIImageView *imgView = self.imageViews[index];
    [imgView removeFromSuperview];
    [self.imageViews removeObjectAtIndex:index];
    [self.imageDatas removeObjectAtIndex:index];

    [self updateImageLayout];
}

- (UIImage *)resizeImage:(UIImage *)image maxDimension:(CGFloat)maxDimension {
    CGFloat width = image.size.width;
    CGFloat height = image.size.height;

    if (width <= maxDimension && height <= maxDimension) {
        return image;
    }

    CGFloat ratio = width / height;
    CGFloat newWidth, newHeight;
    if (width > height) {
        newWidth = maxDimension;
        newHeight = maxDimension / ratio;
    } else {
        newHeight = maxDimension;
        newWidth = maxDimension * ratio;
    }

    CGSize newSize = CGSizeMake(newWidth, newHeight);
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 1.0);
    [image drawInRect:CGRectMake(0, 0, newWidth, newHeight)];
    UIImage *resized = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return resized;
}

- (void)deleteImageTapped:(UIButton *)sender {
    [self removeImageAtIndex:sender.tag];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *newText = [textField.text stringByReplacingCharactersInRange:range withString:string];
    return newText.length <= kMaxTitleLength;
}

- (void)textFieldDidChange:(UITextField *)textField {
    self.titleCounter.text = [NSString stringWithFormat:@"%ld/%ld", (long)textField.text.length, (long)kMaxTitleLength];
    [self updatePublishButton];
}

#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView {
    self.contentPlaceholder.hidden = (textView.text.length > 0);
    self.contentCounter.text = [NSString stringWithFormat:@"%ld/%ld", (long)textView.text.length, (long)kMaxContentLength];
    [self updatePublishButton];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    NSString *newText = [textView.text stringByReplacingCharactersInRange:range withString:text];
    return newText.length <= kMaxContentLength;
}

- (void)updatePublishButton {
    BOOL hasTitle = self.titleField.text.length > 0;
    BOOL hasContent = self.contentTextView.text.length > 0;
    self.publishButton.enabled = hasTitle && hasContent;
}

#pragma mark - PHPickerViewControllerDelegate

- (void)picker:(PHPickerViewController *)picker didFinishPicking:(NSArray<PHPickerResult *> *)results {
    [picker dismissViewControllerAnimated:YES completion:nil];

    if (results.count == 0) return;

    dispatch_group_t group = dispatch_group_create();

    for (PHPickerResult *result in results) {
        if (self.imageViews.count >= kMaxImageCount) break;

        dispatch_group_enter(group);
        [result.itemProvider loadObjectOfClass:[UIImage class] completionHandler:^(id<NSItemProviderReading> object, NSError *error) {
            if (object && [object isKindOfClass:[UIImage class]]) {
                UIImage *image = (UIImage *)object;
                UIImage *resizedImage = [self resizeImage:image maxDimension:1080];
                NSData *imageData = UIImageJPEGRepresentation(resizedImage ?: image, 0.8);

                dispatch_async(dispatch_get_main_queue(), ^{
                    if (imageData) {
                        [self.imageDatas addObject:imageData];

                        UIImageView *imgView = [[UIImageView alloc] init];
                        imgView.contentMode = UIViewContentModeScaleAspectFill;
                        imgView.clipsToBounds = YES;
                        imgView.layer.cornerRadius = 10;
                        imgView.image = resizedImage ?: image;
                        imgView.userInteractionEnabled = YES;
                        imgView.tag = self.imageViews.count;
                        imgView.layer.borderWidth = 1;
                        imgView.layer.borderColor = [UIColor colorWithRed:0.933 green:0.933 blue:1.0 alpha:1.0].CGColor;
                        [self.imageContainerView insertSubview:imgView belowSubview:self.addImageButton];
                        [self.imageViews addObject:imgView];

                        UIButton *deleteBtn = [UIButton buttonWithType:UIButtonTypeSystem];
                        [deleteBtn setImage:[UIImage systemImageNamed:@"xmark.circle.fill"] forState:UIControlStateNormal];
                        deleteBtn.tintColor = [UIColor whiteColor];
                        deleteBtn.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
                        deleteBtn.layer.cornerRadius = 10;
                        deleteBtn.tag = self.imageViews.count - 1;
                        [deleteBtn addTarget:self action:@selector(deleteImageTapped:) forControlEvents:UIControlEventTouchUpInside];
                        [imgView addSubview:deleteBtn];

                        [deleteBtn mas_makeConstraints:^(MASConstraintMaker *make) {
                            make.top.trailing.equalTo(imgView).insets(UIEdgeInsetsMake(4, 0, 0, 4));
                            make.width.height.equalTo(@20);
                        }];
                    }
                    dispatch_group_leave(group);
                });
            } else {
                dispatch_group_leave(group);
            }
        }];
    }

    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        [self updateImageLayout];
    });
}

@end
