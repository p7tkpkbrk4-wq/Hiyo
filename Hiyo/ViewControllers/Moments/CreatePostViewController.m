#import "CreatePostViewController.h"
#import "HYAPIClient.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/SDWebImage.h>
#import <PhotosUI/PhotosUI.h>

static NSInteger const kMaxTitleLength = 20;
static NSInteger const kMaxContentLength = 250;
static NSInteger const kMaxImageCount = 6;

@interface CreatePostViewController () <UITextFieldDelegate, UITextViewDelegate, PHPickerViewControllerDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UITextField *titleField;
@property (nonatomic, strong) UILabel *titleCounter;
@property (nonatomic, strong) UITextView *contentTextView;
@property (nonatomic, strong) UILabel *placeholderLabel;
@property (nonatomic, strong) UILabel *contentCounter;
@property (nonatomic, strong) UIView *imageContainerView;
@property (nonatomic, strong) UIButton *addImageButton;
@property (nonatomic, strong) NSMutableArray<UIImageView *> *imageViews;
@property (nonatomic, strong) NSMutableArray<NSData *> *imageDatas;
@property (nonatomic, strong) UIBarButtonItem *publishButton;
@property (nonatomic, strong) UIActivityIndicatorView *loadingIndicator;
@property (nonatomic, strong) UILabel *errorLabel;

@end

@implementation CreatePostViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"发布动态";
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    self.imageViews = [NSMutableArray array];
    self.imageDatas = [NSMutableArray array];
    [self setupUI];
    [self setupNavigationBar];
}

#pragma mark - Setup

- (void)setupNavigationBar {
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"取消"
                                                                              style:UIBarButtonItemStylePlain
                                                                             target:self
                                                                             action:@selector(cancelTapped)];

    self.publishButton = [[UIBarButtonItem alloc] initWithTitle:@"发布"
                                                          style:UIBarButtonItemStyleDone
                                                         target:self
                                                         action:@selector(publishTapped)];
    self.publishButton.enabled = NO;
    self.navigationItem.rightBarButtonItem = self.publishButton;
}

- (void)setupUI {
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.backgroundColor = [UIColor systemBackgroundColor];
    self.scrollView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    [self.view addSubview:self.scrollView];

    self.contentView = [[UIView alloc] init];
    [self.scrollView addSubview:self.contentView];

    // Title container
    UIView *titleContainer = [[UIView alloc] init];
    titleContainer.backgroundColor = [UIColor secondarySystemGroupedBackgroundColor];
    titleContainer.layer.cornerRadius = 10;
    [self.contentView addSubview:titleContainer];

    self.titleField = [[UITextField alloc] init];
    self.titleField.placeholder = @"标题 (必填)";
    self.titleField.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    self.titleField.delegate = self;
    self.titleField.returnKeyType = UIReturnKeyNext;
    self.titleField.clearButtonMode = UITextFieldViewModeWhileEditing;
    [self.titleField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    [titleContainer addSubview:self.titleField];

    self.titleCounter = [[UILabel alloc] init];
    self.titleCounter.text = @"0/20";
    self.titleCounter.font = [UIFont systemFontOfSize:12];
    self.titleCounter.textColor = [UIColor tertiaryLabelColor];
    [titleContainer addSubview:self.titleCounter];

    // Content container
    UIView *contentContainer = [[UIView alloc] init];
    contentContainer.backgroundColor = [UIColor secondarySystemGroupedBackgroundColor];
    contentContainer.layer.cornerRadius = 10;
    [self.contentView addSubview:contentContainer];

    self.contentTextView = [[UITextView alloc] init];
    self.contentTextView.font = [UIFont systemFontOfSize:15];
    self.contentTextView.textColor = [UIColor labelColor];
    self.contentTextView.backgroundColor = [UIColor clearColor];
    self.contentTextView.delegate = self;
    [contentContainer addSubview:self.contentTextView];

    self.placeholderLabel = [[UILabel alloc] init];
    self.placeholderLabel.text = @"说点什么吧... (必填)";
    self.placeholderLabel.font = [UIFont systemFontOfSize:15];
    self.placeholderLabel.textColor = [UIColor placeholderTextColor];
    [contentContainer addSubview:self.placeholderLabel];

    self.contentCounter = [[UILabel alloc] init];
    self.contentCounter.text = @"0/250";
    self.contentCounter.font = [UIFont systemFontOfSize:12];
    self.contentCounter.textColor = [UIColor tertiaryLabelColor];
    [contentContainer addSubview:self.contentCounter];

    // Image section
    UILabel *imageSectionLabel = [[UILabel alloc] init];
    imageSectionLabel.text = @"添加图片 (可选，最多6张)";
    imageSectionLabel.font = [UIFont systemFontOfSize:14];
    imageSectionLabel.textColor = [UIColor secondaryLabelColor];
    [self.contentView addSubview:imageSectionLabel];

    self.imageContainerView = [[UIView alloc] init];
    [self.contentView addSubview:self.imageContainerView];

    // Add image button
    self.addImageButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.addImageButton setImage:[UIImage systemImageNamed:@"plus"] forState:UIControlStateNormal];
    self.addImageButton.tintColor = [UIColor systemGrayColor];
    self.addImageButton.backgroundColor = [UIColor tertiarySystemGroupedBackgroundColor];
    self.addImageButton.layer.cornerRadius = 8;
    self.addImageButton.layer.borderWidth = 1;
    self.addImageButton.layer.borderColor = [UIColor systemGray4Color].CGColor;
    [self.addImageButton addTarget:self action:@selector(addImageTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.imageContainerView addSubview:self.addImageButton];

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

    [self setupConstraints:titleContainer contentContainer:contentContainer imageSectionLabel:imageSectionLabel];
}

- (void)setupConstraints:(UIView *)titleContainer
         contentContainer:(UIView *)contentContainer
       imageSectionLabel:(UILabel *)imageSectionLabel {

    [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];

    [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.scrollView);
        make.width.equalTo(self.scrollView);
    }];

    [titleContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(16);
        make.leading.trailing.equalTo(self.contentView).inset(16);
        make.height.equalTo(@50);
    }];

    [self.titleField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(titleContainer).offset(12);
        make.trailing.equalTo(titleContainer).offset(-50);
        make.centerY.equalTo(titleContainer);
    }];

    [self.titleCounter mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(titleContainer).offset(-12);
        make.centerY.equalTo(titleContainer);
    }];

    [contentContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(titleContainer.mas_bottom).offset(12);
        make.leading.trailing.equalTo(titleContainer);
        make.height.equalTo(@150);
    }];

    [self.contentTextView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(contentContainer).insets(UIEdgeInsetsMake(8, 8, 8, 8));
    }];

    [self.placeholderLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(contentContainer).offset(13);
        make.top.equalTo(contentContainer).offset(16);
    }];

    [self.contentCounter mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.bottom.equalTo(contentContainer).offset(-8);
    }];

    [imageSectionLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(contentContainer.mas_bottom).offset(20);
        make.leading.equalTo(self.contentView).offset(16);
    }];

    [self.imageContainerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(imageSectionLabel.mas_bottom).offset(10);
        make.leading.trailing.equalTo(self.contentView).inset(16);
        make.height.equalTo(@110);
        make.bottom.equalTo(self.contentView).offset(-40);
    }];

    CGFloat imageSize = 90;
    [self.addImageButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.top.equalTo(self.imageContainerView);
        make.width.height.equalTo(@(imageSize));
    }];
    [self updateImageLayout];

    [self.errorLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.imageContainerView.mas_bottom).offset(8);
        make.leading.trailing.equalTo(self.contentView).inset(16);
    }];

    [self.loadingIndicator mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);
    }];
}

- (void)updateImageLayout {
    CGFloat imageSize = 90;
    CGFloat spacing = 10;
    NSInteger count = self.imageViews.count;

    for (NSInteger i = 0; i < count; i++) {
        NSInteger col = (i + 1) % 3;
        if (col == 0) col = 3;
        NSInteger row = (i + 1) / 3;
        if ((i + 1) % 3 == 0) row--;
        row++;

        UIImageView *imgView = self.imageViews[i];
        [imgView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(self.imageContainerView).offset((col - 1) * (imageSize + spacing));
            make.top.equalTo(self.imageContainerView).offset((row - 1) * (imageSize + spacing));
            make.width.height.equalTo(@(imageSize));
        }];
    }

    // Update add button position
    NSInteger nextCol = (count + 1) % 3;
    if (nextCol == 0) nextCol = 3;
    NSInteger nextRow = (count + 1) / 3;
    if ((count + 1) % 3 == 0) nextRow--;
    nextRow++;

    self.addImageButton.hidden = (count >= kMaxImageCount);
    [self.addImageButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.imageContainerView).offset((nextCol - 1) * (imageSize + spacing));
        make.top.equalTo(self.imageContainerView).offset((nextRow - 1) * (imageSize + spacing));
        make.width.height.equalTo(@(imageSize));
    }];

    // Update container height
    NSInteger rows = (count + 1 + 2) / 3;
    if (count == 0) rows = 1;
    CGFloat height = rows * imageSize + (rows - 1) * spacing + 10;
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
    self.placeholderLabel.hidden = (textView.text.length > 0);
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
                        imgView.layer.cornerRadius = 8;
                        imgView.image = resizedImage ?: image;
                        imgView.userInteractionEnabled = YES;
                        imgView.tag = self.imageViews.count;
                        [self.imageContainerView insertSubview:imgView belowSubview:self.addImageButton];
                        [self.imageViews addObject:imgView];

                        // Add delete button
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
