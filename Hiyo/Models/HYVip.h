#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HYSubscriptionPlan : NSObject
@property (nonatomic, assign) NSInteger planId;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) NSInteger durationDays;
@property (nonatomic, copy) NSString *platformProductId;
@property (nonatomic, copy) NSString *priceDisplay;
@property (nonatomic, copy) NSString *planDescription;
@property (nonatomic, copy, nullable) NSString *features;
- (instancetype)initWithDictionary:(NSDictionary *)dict;
@end

@interface HYVipStatus : NSObject
@property (nonatomic, assign) BOOL isVip;
@property (nonatomic, copy, nullable) NSString *expireAt;
@property (nonatomic, assign) BOOL autoRenew;
@property (nonatomic, copy, nullable) NSString *planName;
@property (nonatomic, assign) NSInteger daysLeft;
- (instancetype)initWithDictionary:(NSDictionary *)dict;
@end

@interface HYVipPrivilege : NSObject
@property (nonatomic, assign) NSInteger privilegeId;
@property (nonatomic, copy) NSString *privilegeKey;
@property (nonatomic, copy) NSString *freeValue;
@property (nonatomic, copy) NSString *vipValue;
@property (nonatomic, copy) NSString *description_text;
- (instancetype)initWithDictionary:(NSDictionary *)dict;
@end

@interface HYCheckinStatus : NSObject
@property (nonatomic, assign) NSInteger currentDay;
@property (nonatomic, strong) NSArray<NSNumber *> *checkedDays;
@property (nonatomic, assign) BOOL todayChecked;
@property (nonatomic, assign) NSInteger todayReward;
@property (nonatomic, strong) NSArray<NSNumber *> *rewards;
- (instancetype)initWithDictionary:(NSDictionary *)dict;
@end

@interface HYCheckinResult : NSObject
@property (nonatomic, assign) NSInteger dayNum;
@property (nonatomic, assign) NSInteger coinsEarned;
@property (nonatomic, assign) NSInteger newBalance;
- (instancetype)initWithDictionary:(NSDictionary *)dict;
@end

NS_ASSUME_NONNULL_END
