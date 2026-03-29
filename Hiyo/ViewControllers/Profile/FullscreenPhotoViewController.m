#import "FullscreenPhotoViewController.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/SDWebImage.h>

@interface FullscreenPhotoViewController () <UIScrollViewDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIPageControl *pageControl;
@property (nonatomic, strong) NSArray<NSString *> *photoUrls;
@property (nonatomic, assign) NSInteger currentIndex;

@end

@implementation FullscreenPhotoViewController

- (instancetype)initWithPhotoUrls:(NSArray<NSString *> *)urls startIndex:(NSInteger)index {
    self = [super init];
    if (self) {
        _photoUrls = urls;
        _currentIndex = index;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    [self setupUI];
    [self setupConstraints];
    [self loadImages];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self scrollToIndex:self.currentIndex animated:NO];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)setupUI {
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.pagingEnabled = YES;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.delegate = self;
    self.scrollView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:self.scrollView];

    self.pageControl = [[UIPageControl alloc] init];
    self.pageControl.numberOfPages = self.photoUrls.count;
    self.pageControl.currentPage = self.currentIndex;
    self.pageControl.pageIndicatorTintColor = [[UIColor whiteColor] colorWithAlphaComponent:0.5];
    self.pageControl.currentPageIndicatorTintColor = [UIColor systemPinkColor];
    [self.view addSubview:self.pageControl];

    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
    doubleTap.numberOfTapsRequired = 2;
    [self.scrollView addGestureRecognizer:doubleTap];

    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap)];
    singleTap.numberOfTapsRequired = 1;
    [singleTap requireGestureRecognizerToFail:doubleTap];
    [self.view addGestureRecognizer:singleTap];

    UISwipeGestureRecognizer *swipeDown = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(dismissFullscreen)];
    swipeDown.direction = UISwipeGestureRecognizerDirectionDown;
    [self.view addGestureRecognizer:swipeDown];
}

- (void)setupConstraints {
    [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];

    [self.pageControl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-20);
    }];
}

- (void)loadImages {
    for (NSInteger i = 0; i < self.photoUrls.count; i++) {
        UIScrollView *zoomView = [[UIScrollView alloc] init];
        zoomView.minimumZoomScale = 1.0;
        zoomView.maximumZoomScale = 3.0;
        zoomView.showsHorizontalScrollIndicator = NO;
        zoomView.showsVerticalScrollIndicator = NO;
        zoomView.delegate = self;
        zoomView.tag = 1000 + i;
        [self.scrollView addSubview:zoomView];

        UIImageView *imageView = [[UIImageView alloc] init];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView.clipsToBounds = YES;
        imageView.tag = 2000 + i;
        [zoomView addSubview:imageView];

        NSString *url = self.photoUrls[i];
        [imageView sd_setImageWithURL:[NSURL URLWithString:url]
                     placeholderImage:nil
                              options:SDWebImageRetryFailed];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self layoutPages];
}

- (void)layoutPages {
    CGFloat width = self.view.bounds.size.width;
    CGFloat height = self.view.bounds.size.height;

    for (NSInteger i = 0; i < self.photoUrls.count; i++) {
        UIScrollView *zoomView = [self.scrollView viewWithTag:1000 + i];
        zoomView.frame = CGRectMake(i * width, 0, width, height);

        UIImageView *imageView = [zoomView viewWithTag:2000 + i];
        imageView.frame = zoomView.bounds;
    }

    self.scrollView.contentSize = CGSizeMake(width * self.photoUrls.count, height);
}

- (void)viewDidUpdate_CalledByRotate {
    [self layoutPages];
    [self scrollToIndex:self.pageControl.currentPage animated:NO];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self layoutPages];
        [self scrollToIndex:self.pageControl.currentPage animated:NO];
    } completion:nil];
}

- (void)scrollToIndex:(NSInteger)index animated:(BOOL)animated {
    if (index < 0 || index >= self.photoUrls.count) return;
    CGFloat width = self.view.bounds.size.width;
    [self.scrollView setContentOffset:CGPointMake(index * width, 0) animated:animated];
}

- (void)handleDoubleTap:(UITapGestureRecognizer *)gesture {
    CGPoint point = [gesture locationInView:gesture.view];
    UIScrollView *zoomView = (UIScrollView *)gesture.view;

    if (zoomView.zoomScale > 1.0) {
        [zoomView setZoomScale:1.0 animated:YES];
    } else {
        CGFloat newScale = 2.5;
        CGSize size = zoomView.bounds.size;
        CGRect zoomRect = CGRectMake(point.x - (size.width / newScale) / 2,
                                     point.y - (size.height / newScale) / 2,
                                     size.width / newScale,
                                     size.height / newScale);
        [zoomView zoomToRect:zoomRect animated:YES];
    }
}

- (void)handleSingleTap {
    [self dismissFullscreen];
}

- (void)dismissFullscreen {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    if ([scrollView isEqual:self.scrollView]) return nil;
    return [scrollView viewWithTag:scrollView.tag + 1000];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (![scrollView isEqual:self.scrollView]) return;
    CGFloat width = self.view.bounds.size.width;
    if (width <= 0) return;
    NSInteger page = (NSInteger)((scrollView.contentOffset.x / width) + 0.5);
    if (page >= 0 && page < self.photoUrls.count) {
        self.pageControl.currentPage = page;
    }
}

@end
