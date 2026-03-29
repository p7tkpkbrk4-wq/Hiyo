#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HYWalletInfo : NSObject
@property (nonatomic, assign) NSInteger balance;
@property (nonatomic, assign) NSInteger totalRecharged;
@property (nonatomic, assign) NSInteger totalConsumed;
- (instancetype)initWithDictionary:(NSDictionary *)dict;
@end

@interface HYWalletFlow : NSObject
@property (nonatomic, assign) NSInteger flowId;
@property (nonatomic, copy) NSString *flowNo;
@property (nonatomic, assign) NSInteger direction; // 1=income, 2=expense
@property (nonatomic, assign) NSInteger amount;
@property (nonatomic, assign) NSInteger balanceAfter;
@property (nonatomic, copy) NSString *type; // recharge, gift_send, gift_receive, checkin
@property (nonatomic, copy, nullable) NSString *refId;
@property (nonatomic, copy, nullable) NSString *remark;
@property (nonatomic, copy) NSString *createdAt;
- (instancetype)initWithDictionary:(NSDictionary *)dict;
@end

NS_ASSUME_NONNULL_END
