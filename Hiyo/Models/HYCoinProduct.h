#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HYCoinProduct : NSObject
@property (nonatomic, assign) NSInteger productId;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) NSInteger coinAmount;
@property (nonatomic, assign) NSInteger priceCents;
@property (nonatomic, copy) NSString *currency;
@property (nonatomic, assign) NSInteger bonusCoins;
@property (nonatomic, copy) NSString *productKey;
@property (nonatomic, copy, nullable) NSString *iconUrl;
- (instancetype)initWithDictionary:(NSDictionary *)dict;
@end

@interface HYRechargeOrder : NSObject
@property (nonatomic, assign) NSInteger orderId;
@property (nonatomic, copy) NSString *orderNo;
@property (nonatomic, assign) NSInteger coinAmount;
@property (nonatomic, assign) NSInteger payAmountCents;
@property (nonatomic, copy) NSString *currency;
@property (nonatomic, assign) NSInteger status; // 0=pending, 1=completed, 2=failed
@property (nonatomic, copy) NSString *createdAt;
- (instancetype)initWithDictionary:(NSDictionary *)dict;
@end

NS_ASSUME_NONNULL_END
