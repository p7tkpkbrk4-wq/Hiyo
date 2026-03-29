#import "GiftPanelSheetController.h"
#import "HYAPIClient.h"
#import "HYGift.h"
#import "HYBottomSheetController.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/SDWebImage.h>

static NSString * const kGiftCellId = @"GiftCell";

@interface HYGiftCell : UICollectionViewCell
@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *priceLabel;
@property (nonatomic, strong) UIView *selectedRing;
@end

@implementation HYGiftCell
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.iconView = [[UIImageView alloc] init];
        self.iconView.contentMode = UIViewContentModeScaleAspectFit;
        [self.contentView addSubview:self.iconView];

        self.nameLabel = [[UILabel alloc] init];
        self.nameLabel.font = [UIFont systemFontOfSize:11];
        self.nameLabel.textColor = [UIColor labelColor];
        self.nameLabel.textAlignment = NSTextAlignmentCenter;
        [self.contentView addSubview:self.nameLabel];

        self.priceLabel = [[UILabel alloc] init];
        self.priceLabel.font = [UIFont systemFontOfSize:10 weight:UIFontWeightMedium];
        self.priceLabel.textColor = [UIColor colorWithRed:139/255.0 green:92/255.0 blue:246/255.0 alpha:1];
        self.priceLabel.textAlignment = NSTextAlignmentCenter;
        [self.contentView addSubview:self.priceLabel];

        self.selectedRing = [[UIView alloc] init];
        self.selectedRing.layer.cornerRadius = 6;
        self.selectedRing.layer.borderWidth = 2;
        self.selectedRing.layer.borderColor = [UIColor colorWithRed:139/255.0 green:92/255.0 blue:246/255.0 alpha:1].CGColor;
        self.selectedRing.hidden = YES;
        [self.contentView addSubview:self.selectedRing];

        self.iconView.translatesAutoresizingMaskIntoConstraints = NO;
        self.nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
        self.priceLabel.translatesAutoresizingMaskIntoConstraints = NO;
        self.selectedRing.translatesAutoresizingMaskIntoConstraints = NO;

        [NSLayoutConstraint activateConstraints:@[
            [self.iconView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:4],
            [self.iconView.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor],
            [self.iconView.widthAnchor constraintEqualToConstant:48],
            [self.iconView.heightAnchor constraintEqualToConstant:48],

            [self.nameLabel.topAnchor constraintEqualToAnchor:self.iconView.bottomAnchor constant:2],
            [self.nameLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:2],
            [self.nameLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-2],

            [self.priceLabel.topAnchor constraintEqualToAnchor:self.nameLabel.bottomAnchor constant:1],
            [self.priceLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:2],
            [self.priceLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-2],

            [self.selectedRing.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:-2],
            [self.selectedRing.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:-2],
            [self.selectedRing.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:2],
            [self.selectedRing.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:2],
        ]];
    }
    return self;
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    self.contentView.alpha = highlighted ? 0.6 : 1.0;
}
@end

@interface GiftPanelSheetController () <UICollectionViewDelegate, UICollectionViewDataSource>
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UISegmentedControl *groupTabs;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UIView *bottomBar;
@property (nonatomic, strong) UILabel *balanceLabel;
@property (nonatomic, strong) UIButton *minusBtn;
@property (nonatomic, strong) UILabel *quantityLabel;
@property (nonatomic, strong) UIButton *plusBtn;
@property (nonatomic, strong) UIButton *sendBtn;
@property (nonatomic, strong) UIActivityIndicatorView *loadingIndicator;

@property (nonatomic, strong) NSArray<HYGiftGroup *> *giftGroups;
@property (nonatomic, strong) NSArray<HYGift *> *currentGifts;
@property (nonatomic, assign) NSInteger selectedGroupIndex;
@property (nonatomic, strong) HYGift *selectedGift;
@property (nonatomic, assign) NSInteger quantity;
@property (nonatomic, assign) NSInteger currentBalance;
@end

@implementation GiftPanelSheetController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.quantity = 1;
    self.selectedGroupIndex = 0;
    self.giftGroups = @[];
    self.currentGifts = @[];
    [self setupUI];
    [self loadData];
}

#pragma mark - Setup

- (void)setupUI {
    self.view.backgroundColor = [UIColor clearColor];

    self.containerView = [[UIView alloc] init];
    self.containerView.backgroundColor = [UIColor systemBackgroundColor];
    self.containerView.layer.cornerRadius = 20;
    self.containerView.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    [self.view addSubview:self.containerView];

    // Drag indicator
    UIView *dragIndicator = [[UIView alloc] init];
    dragIndicator.backgroundColor = [UIColor systemGray4Color];
    dragIndicator.layer.cornerRadius = 2;
    [self.containerView addSubview:dragIndicator];

    // Header
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = @"Send Gift";
    titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
    titleLabel.textColor = [UIColor labelColor];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.containerView addSubview:titleLabel];

    // Close button
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [closeBtn setImage:[UIImage systemImageNamed:@"xmark"] forState:UIControlStateNormal];
    closeBtn.tintColor = [UIColor systemGrayColor];
    [closeBtn addTarget:self action:@selector(closeTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.containerView addSubview:closeBtn];

    // Balance
    self.balanceLabel = [[UILabel alloc] init];
    self.balanceLabel.text = @"Balance: 0";
    self.balanceLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    self.balanceLabel.textColor = [UIColor secondaryLabelColor];
    self.balanceLabel.textAlignment = NSTextAlignmentCenter;
    [self.containerView addSubview:self.balanceLabel];

    // Group tabs (scrollable)
    self.groupTabs = [[UISegmentedControl alloc] initWithItems:@[@"All", @"Popular", @"Special"]];
    self.groupTabs.selectedSegmentIndex = 0;
    [self.groupTabs addTarget:self action:@selector(groupTabChanged:) forControlEvents:UIControlEventValueChanged];
    [self.containerView addSubview:self.groupTabs];

    // Collection view for gifts
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    CGFloat cellW = (([UIScreen mainScreen].bounds.size.width - 48) / 4);
    layout.itemSize = CGSizeMake(cellW, 80);
    layout.minimumInteritemSpacing = 8;
    layout.minimumLineSpacing = 8;
    layout.sectionInset = UIEdgeInsetsMake(8, 8, 8, 8);

    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    self.collectionView.backgroundColor = [UIColor systemBackgroundColor];
    [self.collectionView registerClass:[HYGiftCell class] forCellWithReuseIdentifier:kGiftCellId];
    [self.containerView addSubview:self.collectionView];

    // Bottom bar
    self.bottomBar = [[UIView alloc] init];
    self.bottomBar.backgroundColor = [UIColor systemBackgroundColor];
    self.bottomBar.layer.borderWidth = 0.5;
    self.bottomBar.layer.borderColor = [UIColor separatorColor].CGColor;
    [self.containerView addSubview:self.bottomBar];

    self.minusBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.minusBtn setTitle:@"-" forState:UIControlStateNormal];
    self.minusBtn.titleLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightMedium];
    self.minusBtn.tintColor = [UIColor systemGrayColor];
    [self.minusBtn addTarget:self action:@selector(minusTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomBar addSubview:self.minusBtn];

    self.quantityLabel = [[UILabel alloc] init];
    self.quantityLabel.text = @"1";
    self.quantityLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    self.quantityLabel.textColor = [UIColor labelColor];
    self.quantityLabel.textAlignment = NSTextAlignmentCenter;
    [self.bottomBar addSubview:self.quantityLabel];

    self.plusBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.plusBtn setTitle:@"+" forState:UIControlStateNormal];
    self.plusBtn.titleLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightMedium];
    self.plusBtn.tintColor = [UIColor colorWithRed:139/255.0 green:92/255.0 blue:246/255.0 alpha:1];
    [self.plusBtn addTarget:self action:@selector(plusTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomBar addSubview:self.plusBtn];

    self.sendBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.sendBtn setTitle:@"Send to TA" forState:UIControlStateNormal];
    [self.sendBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.sendBtn.backgroundColor = [UIColor colorWithRed:139/255.0 green:92/255.0 blue:246/255.0 alpha:1];
    self.sendBtn.layer.cornerRadius = 20;
    self.sendBtn.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    self.sendBtn.enabled = NO;
    self.sendBtn.alpha = 0.5;
    [self.sendBtn addTarget:self action:@selector(sendTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomBar addSubview:self.sendBtn];

    self.loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    self.loadingIndicator.hidesWhenStopped = YES;
    [self.bottomBar addSubview:self.loadingIndicator];

    // Layout
    self.containerView.translatesAutoresizingMaskIntoConstraints = NO;
    dragIndicator.translatesAutoresizingMaskIntoConstraints = NO;
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.balanceLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.groupTabs.translatesAutoresizingMaskIntoConstraints = NO;
    self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    self.bottomBar.translatesAutoresizingMaskIntoConstraints = NO;
    self.minusBtn.translatesAutoresizingMaskIntoConstraints = NO;
    self.quantityLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.plusBtn.translatesAutoresizingMaskIntoConstraints = NO;
    self.sendBtn.translatesAutoresizingMaskIntoConstraints = NO;
    self.loadingIndicator.translatesAutoresizingMaskIntoConstraints = NO;

    closeBtn.translatesAutoresizingMaskIntoConstraints = NO;

    [NSLayoutConstraint activateConstraints:@[
        [self.containerView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.containerView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.containerView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [self.containerView.heightAnchor constraintEqualToConstant:420],

        [dragIndicator.topAnchor constraintEqualToAnchor:self.containerView.topAnchor constant:8],
        [dragIndicator.centerXAnchor constraintEqualToAnchor:self.containerView.centerXAnchor],
        [dragIndicator.widthAnchor constraintEqualToConstant:40],
        [dragIndicator.heightAnchor constraintEqualToConstant:4],

        [titleLabel.topAnchor constraintEqualToAnchor:dragIndicator.bottomAnchor constant:8],
        [titleLabel.centerXAnchor constraintEqualToAnchor:self.containerView.centerXAnchor],

        [closeBtn.trailingAnchor constraintEqualToAnchor:self.containerView.trailingAnchor constant:-16],
        [closeBtn.centerYAnchor constraintEqualToAnchor:titleLabel.centerYAnchor],
        [closeBtn.widthAnchor constraintEqualToConstant:32],
        [closeBtn.heightAnchor constraintEqualToConstant:32],

        [self.balanceLabel.topAnchor constraintEqualToAnchor:titleLabel.bottomAnchor constant:4],
        [self.balanceLabel.centerXAnchor constraintEqualToAnchor:self.containerView.centerXAnchor],

        [self.groupTabs.topAnchor constraintEqualToAnchor:self.balanceLabel.bottomAnchor constant:8],
        [self.groupTabs.leadingAnchor constraintEqualToAnchor:self.containerView.leadingAnchor constant:16],
        [self.groupTabs.trailingAnchor constraintEqualToAnchor:self.containerView.trailingAnchor constant:-16],

        [self.collectionView.topAnchor constraintEqualToAnchor:self.groupTabs.bottomAnchor constant:8],
        [self.collectionView.leadingAnchor constraintEqualToAnchor:self.containerView.leadingAnchor],
        [self.collectionView.trailingAnchor constraintEqualToAnchor:self.containerView.trailingAnchor],
        [self.collectionView.bottomAnchor constraintEqualToAnchor:self.bottomBar.topAnchor],

        [self.bottomBar.leadingAnchor constraintEqualToAnchor:self.containerView.leadingAnchor],
        [self.bottomBar.trailingAnchor constraintEqualToAnchor:self.containerView.trailingAnchor],
        [self.bottomBar.bottomAnchor constraintEqualToAnchor:self.containerView.bottomAnchor],
        [self.bottomBar.heightAnchor constraintEqualToConstant:70],

        [self.minusBtn.leadingAnchor constraintEqualToAnchor:self.bottomBar.leadingAnchor constant:16],
        [self.minusBtn.centerYAnchor constraintEqualToAnchor:self.bottomBar.centerYAnchor constant:-10],
        [self.minusBtn.widthAnchor constraintEqualToConstant:36],

        [self.quantityLabel.leadingAnchor constraintEqualToAnchor:self.minusBtn.trailingAnchor constant:8],
        [self.quantityLabel.centerYAnchor constraintEqualToAnchor:self.bottomBar.centerYAnchor constant:-10],
        [self.quantityLabel.widthAnchor constraintEqualToConstant:40],

        [self.plusBtn.leadingAnchor constraintEqualToAnchor:self.quantityLabel.trailingAnchor constant:8],
        [self.plusBtn.centerYAnchor constraintEqualToAnchor:self.bottomBar.centerYAnchor constant:-10],
        [self.plusBtn.widthAnchor constraintEqualToConstant:36],

        [self.sendBtn.trailingAnchor constraintEqualToAnchor:self.bottomBar.trailingAnchor constant:-16],
        [self.sendBtn.centerYAnchor constraintEqualToAnchor:self.bottomBar.centerYAnchor constant:-10],
        [self.sendBtn.widthAnchor constraintEqualToConstant:120],
        [self.sendBtn.heightAnchor constraintEqualToConstant:40],

        [self.loadingIndicator.centerXAnchor constraintEqualToAnchor:self.sendBtn.centerXAnchor],
        [self.loadingIndicator.centerYAnchor constraintEqualToAnchor:self.sendBtn.centerYAnchor],
    ]];
}

#pragma mark - Data

- (void)loadData {
    dispatch_group_t group = dispatch_group_create();
    __block NSDictionary *giftsResponse = nil;
    __block NSDictionary *balanceResponse = nil;

    dispatch_group_enter(group);
    [[HYAPIClient shared] getGiftsWithCompletion:^(NSDictionary *response, NSError *error) {
        giftsResponse = response;
        dispatch_group_leave(group);
    }];

    dispatch_group_enter(group);
    [[HYAPIClient shared] getWalletBalanceWithCompletion:^(NSDictionary *response, NSError *error) {
        balanceResponse = response;
        dispatch_group_leave(group);
    }];

    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        if (giftsResponse && !giftsResponse[@"error"]) {
            NSArray *data = giftsResponse[@"data"];
            if ([data isKindOfClass:[NSArray class]]) {
                NSMutableArray *groups = [NSMutableArray array];
                for (NSDictionary *g in data) {
                    [groups addObject:[[HYGiftGroup alloc] initWithDictionary:g]];
                }
                self.giftGroups = groups;
                [self updateGroupTabs];
                if (self.giftGroups.count > 0) {
                    self.currentGifts = self.giftGroups[0].gifts;
                }
                [self.collectionView reloadData];
            }
        }

        if (balanceResponse && !balanceResponse[@"error"]) {
            NSDictionary *data = balanceResponse[@"data"];
            if ([data isKindOfClass:[NSDictionary class]]) {
                self.currentBalance = [data[@"balance"] integerValue];
                self.balanceLabel.text = [NSString stringWithFormat:@"Balance: %ld", (long)self.currentBalance];
            }
        }
    });
}

- (void)updateGroupTabs {
    NSMutableArray *titles = [NSMutableArray array];
    for (HYGiftGroup *group in self.giftGroups) {
        [titles addObject:group.groupName];
    }
    if (titles.count > 0) {
        [self.groupTabs removeAllSegments];
        for (NSInteger i = 0; i < titles.count; i++) {
            [self.groupTabs insertSegmentWithTitle:titles[i] atIndex:i animated:NO];
        }
        self.groupTabs.selectedSegmentIndex = 0;
    }
}

#pragma mark - Actions

- (void)closeTapped {
    if (self.onDismiss) {
        self.onDismiss();
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)groupTabChanged:(UISegmentedControl *)sender {
    if (sender.selectedSegmentIndex < self.giftGroups.count) {
        self.currentGifts = self.giftGroups[sender.selectedSegmentIndex].gifts;
        [self.collectionView reloadData];
    }
}

- (void)minusTapped {
    if (self.quantity > 1) {
        self.quantity--;
        self.quantityLabel.text = [NSString stringWithFormat:@"%ld", (long)self.quantity];
        [self updateSendButton];
    }
}

- (void)plusTapped {
    if (self.quantity < 99) {
        self.quantity++;
        self.quantityLabel.text = [NSString stringWithFormat:@"%ld", (long)self.quantity];
        [self updateSendButton];
    }
}

- (void)updateSendButton {
    if (self.selectedGift) {
        NSInteger totalCost = self.selectedGift.price * self.quantity;
        self.sendBtn.enabled = (totalCost <= self.currentBalance);
        self.sendBtn.alpha = self.sendBtn.enabled ? 1.0 : 0.5;
        NSString *title = [NSString stringWithFormat:@"Send (%ld)", (long)totalCost];
        [self.sendBtn setTitle:title forState:UIControlStateNormal];
    }
}

- (void)sendTapped {
    if (!self.selectedGift || self.selectedGift.price * self.quantity > self.currentBalance) {
        if (self.onInsufficientBalance) {
            self.onInsufficientBalance();
        }
        return;
    }

    self.sendBtn.enabled = NO;
    [self.sendBtn setTitle:@"" forState:UIControlStateNormal];
    [self.loadingIndicator startAnimating];

    [[HYAPIClient shared] sendGiftToReceiverId:self.receiverId giftId:self.selectedGift.giftId quantity:self.quantity completion:^(NSDictionary *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.loadingIndicator stopAnimating];
            [self.sendBtn setTitle:@"Send to TA" forState:UIControlStateNormal];

            if (error) {
                NSString *msg = error.localizedDescription;
                // Check for insufficient balance error
                if ([msg containsString:@"40003"] || [msg containsString:@"balance"]) {
                    if (self.onInsufficientBalance) {
                        self.onInsufficientBalance();
                    }
                }
                self.sendBtn.enabled = YES;
                [self updateSendButton];
                return;
            }

            // Create gift bubble
            HYGiftBubble *bubble = [[HYGiftBubble alloc] init];
            bubble.iconUrl = self.selectedGift.iconUrl;
            bubble.name = self.selectedGift.name;
            bubble.quantity = self.quantity;
            bubble.effectUrl = self.selectedGift.effectUrl;

            if (self.onGiftSent) {
                self.onGiftSent(bubble, YES);
            }
            if (self.onDismiss) {
                self.onDismiss();
            } else {
                [self dismissViewControllerAnimated:YES completion:nil];
            }
        });
    }];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.currentGifts.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    HYGiftCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kGiftCellId forIndexPath:indexPath];
    HYGift *gift = self.currentGifts[indexPath.item];
    [cell.iconView sd_setImageWithURL:[NSURL URLWithString:gift.iconUrl] placeholderImage:[UIImage systemImageNamed:@"gift"]];
    cell.nameLabel.text = gift.name;
    cell.priceLabel.text = [NSString stringWithFormat:@"%ld", (long)gift.price];
    cell.selectedRing.hidden = (self.selectedGift != gift);
    return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    self.selectedGift = self.currentGifts[indexPath.item];
    [collectionView reloadData];
    [self updateSendButton];
}

@end
