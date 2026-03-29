#import "HYBottomSheetController.h"
#import "HYColors.h"

@interface HYBottomSheetController () <UIViewControllerTransitioningDelegate, UIAdaptivePresentationControllerDelegate>

@property (nonatomic, strong) UIViewController *contentVC;
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UIView *overlayView;
@property (nonatomic, strong) UIPanGestureRecognizer *panGesture;
@property (nonatomic, assign) CGFloat startY;
@property (nonatomic, assign) BOOL isPresented;

@end

@implementation HYBottomSheetController

- (instancetype)initWithContentViewController:(UIViewController *)contentVC {
    self = [super init];
    if (self) {
        _contentVC = contentVC;
        _cornerRadius = 20;
        _maxHeight = UIScreen.mainScreen.bounds.size.height * 0.75;
        self.modalPresentationStyle = UIModalPresentationCustom;
        self.transitioningDelegate = self;
        self.presentationController.delegate = self;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    [self setupOverlay];
    [self setupContainer];
    [self setupPanGesture];
}

- (void)setupOverlay {
    self.overlayView = [[UIView alloc] init];
    self.overlayView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    self.overlayView.alpha = 0;
    [self.view addSubview:self.overlayView];
    self.overlayView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [self.overlayView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.overlayView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.overlayView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.overlayView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(overlayTapped)];
    [self.overlayView addGestureRecognizer:tap];
}

- (void)setupContainer {
    self.containerView = [[UIView alloc] init];
    self.containerView.backgroundColor = DarkCard;
    self.containerView.layer.cornerRadius = self.cornerRadius;
    self.containerView.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    self.containerView.clipsToBounds = YES;
    [self.view addSubview:self.containerView];
    self.containerView.translatesAutoresizingMaskIntoConstraints = NO;

    [self addChildViewController:self.contentVC];
    [self.containerView addSubview:self.contentVC.view];
    self.contentVC.view.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [self.contentVC.view.topAnchor constraintEqualToAnchor:self.containerView.topAnchor],
        [self.contentVC.view.leadingAnchor constraintEqualToAnchor:self.containerView.leadingAnchor],
        [self.contentVC.view.trailingAnchor constraintEqualToAnchor:self.containerView.trailingAnchor],
        [self.contentVC.view.bottomAnchor constraintEqualToAnchor:self.containerView.bottomAnchor]
    ]];
    [self.contentVC didMoveToParentViewController:self];

    CGFloat height = MIN(self.contentVC.preferredContentSize.height, self.maxHeight);
    if (self.contentVC.preferredContentSize.height == 0) {
        height = self.maxHeight;
    }

    [NSLayoutConstraint activateConstraints:@[
        [self.containerView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.containerView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.containerView.topAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [self.containerView.heightAnchor constraintEqualToConstant:height]
    ]];
}

- (void)setupPanGesture {
    self.panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [self.containerView addGestureRecognizer:self.panGesture];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (!self.isPresented) {
        [self animateIn];
        self.isPresented = YES;
    }
}

- (void)animateIn {
    [self.view layoutIfNeeded];
    CGFloat height = self.containerView.bounds.size.height;

    for (NSLayoutConstraint *c in self.view.constraints) {
        if (c.firstItem == self.containerView && c.firstAttribute == NSLayoutAttributeTop) {
            c.constant = self.view.bounds.size.height - height;
            break;
        }
    }

    [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.85 initialSpringVelocity:0 options:0 animations:^{
        self.overlayView.alpha = 1;
        [self.view layoutIfNeeded];
    } completion:nil];
}

- (void)overlayTapped {
    [self dismiss];
}

- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    CGPoint translation = [gesture translationInView:self.view];

    if (gesture.state == UIGestureRecognizerStateBegan) {
        self.startY = self.containerView.frame.origin.y;
    } else if (gesture.state == UIGestureRecognizerStateChanged) {
        CGFloat newY = self.startY + translation.y;
        newY = MAX(newY, self.view.bounds.size.height - self.maxHeight);
        newY = MIN(newY, self.view.bounds.size.height);

        for (NSLayoutConstraint *c in self.view.constraints) {
            if (c.firstItem == self.containerView && c.firstAttribute == NSLayoutAttributeTop) {
                c.constant = newY;
                break;
            }
        }

        CGFloat progress = (newY - (self.view.bounds.size.height - self.containerView.bounds.size.height)) / (self.containerView.bounds.size.height);
        self.overlayView.alpha = 1 - progress * 0.5;
    } else if (gesture.state == UIGestureRecognizerStateEnded) {
        CGPoint velocity = [gesture velocityInView:self.view];
        CGFloat currentY = self.containerView.frame.origin.y;
        CGFloat threshold = self.view.bounds.size.height * 0.3;

        if (velocity.y > 500 || currentY > self.view.bounds.size.height - 100) {
            [self dismiss];
        } else {
            [self animateBack];
        }
    }
}

- (void)animateBack {
    for (NSLayoutConstraint *c in self.view.constraints) {
        if (c.firstItem == self.containerView && c.firstAttribute == NSLayoutAttributeTop) {
            c.constant = self.view.bounds.size.height - self.containerView.bounds.size.height;
            break;
        }
    }
    [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.85 initialSpringVelocity:0 options:0 animations:^{
        self.overlayView.alpha = 1;
        [self.view layoutIfNeeded];
    } completion:nil];
}

- (void)dismiss {
    CGFloat height = self.containerView.bounds.size.height;
    for (NSLayoutConstraint *c in self.view.constraints) {
        if (c.firstItem == self.containerView && c.firstAttribute == NSLayoutAttributeTop) {
            c.constant = self.view.bounds.size.height + height;
            break;
        }
    }

    [UIView animateWithDuration:0.3 animations:^{
        self.overlayView.alpha = 0;
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        if (self.onDismiss) {
            self.onDismiss();
        }
        [self dismissViewControllerAnimated:NO completion:nil];
    }];
}

#pragma mark - UIViewControllerTransitioningDelegate

- (UIPresentationController *)presentationControllerForPresentedViewController:(UIViewController *)presented presentingViewController:(UIViewController *)presenting sourceViewController:(UIViewController *)source {
    return [[UIPresentationController alloc] initWithPresentedViewController:presented presentingViewController:presenting];
}

@end
