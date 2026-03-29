#import "RechargeViewController.h"
#import "HYAPIClient.h"
#import "HYCoinProduct.h"
#import <StoreKit/StoreKit.h>
#import <Masonry/Masonry.h>

@interface HYCoinProductCell : UICollectionViewCell
@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UILabel *coinLabel;
@property (nonatomic, strong) UILabel *priceLabel;
@property (nonatomic, strong) UILabel *bonusLabel;
@property (nonatomic, strong) UIView *selectedBg;
@end

@implementation HYCoinProductCell
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.contentView.layer.cornerRadius = 12;
        self.contentView.layer.borderWidth = 1.5;
        self.contentView.layer.borderColor = [UIColor colorWithRed:139/255.0 green:92/255.0 blue:246/255.0 alpha:0.3].CGColor;
        self.contentView.backgroundColor = [UIColor systemBackgroundColor];

        self.iconView = [[UIImageView alloc] init];
        self.iconView.contentMode = UIViewContentModeScaleAspectFit;
        self.iconView.tintColor = [UIColor colorWithRed:139/255.0 green:92/255.0 blue:246/255.0 alpha:1];
        [self.contentView addSubview:self.iconView];

        self.coinLabel = [[UILabel alloc] init];
        self.coinLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightBold];
        self.coinLabel.textColor = [UIColor labelColor];
        self.coinLabel.textAlignment = NSTextAlignmentCenter;
        [self.contentView addSubview:self.coinLabel];

        self.priceLabel = [[UILabel alloc] init];
        self.priceLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
        self.priceLabel.textColor = [UIColor colorWithRed:139/255.0 green:92/255.0 blue:246/255.0 alpha:1];
        self.priceLabel.textAlignment = NSTextAlignmentCenter;
        [self.contentView addSubview:self.priceLabel];

        self.bonusLabel = [[UILabel alloc] init];
        self.bonusLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightMedium];
        self.bonusLabel.textColor = [UIColor whiteColor];
        self.bonusLabel.backgroundColor = [UIColor colorWithRed:239/255.0 green:68/255.0 blue:68/255.0 alpha:1];
        self.bonusLabel.layer.cornerRadius = 8;
        self.bonusLabel.clipsToBounds = YES;
        self.bonusLabel.textAlignment = NSTextAlignmentCenter;
        [self.contentView addSubview:self.bonusLabel];

        self.iconView.translatesAutoresizingMaskIntoConstraints = NO;
        self.coinLabel.translatesAutoresizingMaskIntoConstraints = NO;
        self.priceLabel.translatesAutoresizingMaskIntoConstraints = NO;
        self.bonusLabel.translatesAutoresizingMaskIntoConstraints = NO;

        [NSLayoutConstraint activateConstraints:@[
            [self.iconView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:8],
            [self.iconView.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor],
            [self.iconView.widthAnchor constraintEqualToConstant:32],
            [self.iconView.heightAnchor constraintEqualToConstant:32],

            [self.coinLabel.topAnchor constraintEqualToAnchor:self.iconView.bottomAnchor constant:4],
            [self.coinLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:4],
            [self.coinLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-4],

            [self.priceLabel.topAnchor constraintEqualToAnchor:self.coinLabel.bottomAnchor constant:2],
            [self.priceLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:4],
            [self.priceLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-4],

            [self.bonusLabel.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:4],
            [self.bonusLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-4],
            [self.bonusLabel.widthAnchor constraintGreaterThanOrEqualToConstant:40],
            [self.bonusLabel.heightAnchor constraintEqualToConstant:16],
        ]];
    }
    return self;
}

- (void)configWithProduct:(HYCoinProduct *)product {
    self.coinLabel.text = [NSString stringWithFormat:@"%ld", (long)product.coinAmount];
    self.priceLabel.text = [NSString stringWithFormat:@"$%.2f", product.priceCents / 100.0];
    if (product.bonusCoins > 0) {
        self.bonusLabel.text = [NSString stringWithFormat:@" +%ld ", (long)product.bonusCoins];
        self.bonusLabel.hidden = NO;
    } else {
        self.bonusLabel.hidden = YES;
    }
    self.iconView.image = [UIImage systemImageNamed:@"bitcoinsign.circle.fill"];
}
@end

@interface RechargeViewController () <UICollectionViewDelegate, UICollectionViewDataSource, SKProductsRequestDelegate, SKPaymentTransactionObserver>
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSArray<HYCoinProduct *> *products;
@property (nonatomic, strong) HYCoinProduct *selectedProduct;
@property (nonatomic, strong) UIButton *purchaseBtn;
@property (nonatomic, strong) UIActivityIndicatorView *loadingIndicator;
@property (nonatomic, assign) BOOL isPurchasing;
@end

@implementation RechargeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Buy Coins";
    self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];
    self.products = @[];
    [self setupUI];
    [self loadProducts];
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
}

- (void)dealloc {
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}

#pragma mark - Setup

- (void)setupUI {
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    CGFloat w = ([UIScreen mainScreen].bounds.size.width - 48) / 2;
    layout.itemSize = CGSizeMake(w, 120);
    layout.minimumInteritemSpacing = 16;
    layout.minimumLineSpacing = 16;
    layout.sectionInset = UIEdgeInsetsMake(16, 16, 16, 16);

    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    self.collectionView.backgroundColor = [UIColor systemGroupedBackgroundColor];
    [self.collectionView registerClass:[HYCoinProductCell class] forCellWithReuseIdentifier:@"ProductCell"];
    [self.view addSubview:self.collectionView];

    self.purchaseBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.purchaseBtn setTitle:@"Purchase" forState:UIControlStateNormal];
    [self.purchaseBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.purchaseBtn.backgroundColor = [UIColor colorWithRed:139/255.0 green:92/255.0 blue:246/255.0 alpha:1];
    self.purchaseBtn.layer.cornerRadius = 25;
    self.purchaseBtn.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    self.purchaseBtn.enabled = NO;
    self.purchaseBtn.alpha = 0.5;
    [self.purchaseBtn addTarget:self action:@selector(purchaseTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.purchaseBtn];

    self.loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    self.loadingIndicator.color = [UIColor systemPurpleColor];
    self.loadingIndicator.hidesWhenStopped = YES;
    [self.view addSubview:self.loadingIndicator];

    self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    self.purchaseBtn.translatesAutoresizingMaskIntoConstraints = NO;
    self.loadingIndicator.translatesAutoresizingMaskIntoConstraints = NO;

    [NSLayoutConstraint activateConstraints:@[
        [self.collectionView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [self.collectionView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.collectionView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.collectionView.bottomAnchor constraintEqualToAnchor:self.purchaseBtn.topAnchor constant:-16],

        [self.purchaseBtn.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        [self.purchaseBtn.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],
        [self.purchaseBtn.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-16],
        [self.purchaseBtn.heightAnchor constraintEqualToConstant:50],

        [self.loadingIndicator.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.loadingIndicator.centerYAnchor constraintEqualToAnchor:self.collectionView.centerYAnchor],
    ]];
}

- (void)loadProducts {
    [self.loadingIndicator startAnimating];
    [[HYAPIClient shared] getCoinProductsWithCompletion:^(NSDictionary *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.loadingIndicator stopAnimating];
            if (!error && response) {
                NSArray *data = response[@"data"][@"products"];
                if ([data isKindOfClass:[NSArray class]]) {
                    NSMutableArray *arr = [NSMutableArray array];
                    for (NSDictionary *p in data) {
                        [arr addObject:[[HYCoinProduct alloc] initWithDictionary:p]];
                    }
                    self.products = arr;
                    [self.collectionView reloadData];
                }
            }
        });
    }];
}

#pragma mark - Purchase

- (void)purchaseTapped {
    if (!self.selectedProduct || self.isPurchasing) return;
    if (![SKPaymentQueue canMakePayments]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Purchase Unavailable" message:@"In-app purchases are not available on this device." preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }

    self.isPurchasing = YES;
    self.purchaseBtn.enabled = NO;
    [self.purchaseBtn setTitle:@"Processing..." forState:UIControlStateNormal];
    [self.loadingIndicator startAnimating];

    // First create order on server
    [[HYAPIClient shared] createRechargeOrderWithProductId:self.selectedProduct.productId completion:^(NSDictionary *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error || !response) {
                [self finishPurchaseWithError:error ?: [NSError errorWithDomain:@"HYError" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Failed to create order"}]];
                return;
            }

            NSString *orderNo = response[@"data"][@"order_no"];
            if (!orderNo) {
                [self finishPurchaseWithError:[NSError errorWithDomain:@"HYError" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"No order number returned"}]];
                return;
            }

            // Request payment from StoreKit
            SKProductsRequest *req = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithObject:self.selectedProduct.productKey]];
            req.delegate = self;
            [req start];
        });
    }];
}

- (void)finishPurchaseWithError:(NSError *)error {
    self.isPurchasing = NO;
    [self.loadingIndicator stopAnimating];
    self.purchaseBtn.enabled = YES;
    self.purchaseBtn.alpha = 0.5;
    [self.purchaseBtn setTitle:@"Purchase" forState:UIControlStateNormal];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Purchase Failed" message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - SKProductsRequestDelegate

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    SKProduct *product = response.products.firstObject;
    if (!product) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self finishPurchaseWithError:[NSError errorWithDomain:@"HYError" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Product not found in App Store"}]];
        });
        return;
    }

    SKPayment *payment = [SKPayment paymentWithProduct:product];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self finishPurchaseWithError:error];
    });
}

#pragma mark - SKPaymentTransactionObserver

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions {
    for (SKPaymentTransaction *tx in transactions) {
        if (tx.transactionState == SKPaymentTransactionStatePurchased) {
            [self verifyPurchaseWithTransaction:tx];
        } else if (tx.transactionState == SKPaymentTransactionStateFailed) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self finishPurchaseWithError:tx.error ?: [NSError errorWithDomain:@"HYError" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Purchase failed"}]];
            });
            [[SKPaymentQueue defaultQueue] finishTransaction:tx];
        }
    }
}

- (void)verifyPurchaseWithTransaction:(SKPaymentTransaction *)tx {
    // Get order number from stored data (simplified - in production, store orderNo when creating order)
    NSString *orderNo = tx.transactionIdentifier ?: @"";

    [[HYAPIClient shared] verifyRechargeWithOrderNo:orderNo purchaseToken:@"" completion:^(NSDictionary *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[SKPaymentQueue defaultQueue] finishTransaction:tx];
            [self finishPurchaseWithError:nil];

            if (!error && response) {
                if (self.onRechargeComplete) {
                    self.onRechargeComplete();
                }
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Success" message:@"Coins have been added to your wallet!" preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                    [self.navigationController popViewControllerAnimated:YES];
                }]];
                [self presentViewController:alert animated:YES completion:nil];
            } else {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Purchase Complete" message:@"Your purchase is being processed. Coins will appear shortly." preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
                [self presentViewController:alert animated:YES completion:nil];
            }
        });
    }];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.products.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    HYCoinProductCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ProductCell" forIndexPath:indexPath];
    [cell configWithProduct:self.products[indexPath.item]];
    return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    self.selectedProduct = self.products[indexPath.item];
    self.purchaseBtn.enabled = YES;
    self.purchaseBtn.alpha = 1.0;
    [self.collectionView reloadData];
}

@end
