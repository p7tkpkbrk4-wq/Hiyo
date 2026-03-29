#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HYGift : NSObject
@property (nonatomic, assign) NSInteger giftId;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) NSInteger price;
@property (nonatomic, assign) NSInteger sortOrder;
@property (nonatomic, copy) NSString *iconUrl;
@property (nonatomic, copy) NSString *effectUrl;
- (instancetype)initWithDictionary:(NSDictionary *)dict;
@end

@interface HYGiftGroup : NSObject
@property (nonatomic, assign) NSInteger groupId;
@property (nonatomic, copy) NSString *groupName;
@property (nonatomic, strong) NSArray<HYGift *> *gifts;
- (instancetype)initWithDictionary:(NSDictionary *)dict;
@end

@interface HYGiftBubble : NSObject
@property (nonatomic, copy) NSString *iconUrl;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) NSInteger quantity;
@property (nonatomic, copy) NSString *effectUrl;
- (instancetype)initWithDictionary:(NSDictionary *)dict;
@end

@interface HYGiftSendResult : NSObject
@property (nonatomic, copy) NSString *orderNo;
@property (nonatomic, assign) NSInteger balanceAfter;
@property (nonatomic, strong) HYGift *gift;
- (instancetype)initWithDictionary:(NSDictionary *)dict;
@end

NS_ASSUME_NONNULL_END
