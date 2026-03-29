#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HYSimpleUserInfo : NSObject
@property (nonatomic, copy) NSString *userId;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *avatar;
@property (nonatomic, assign) NSInteger sex;
@property (nonatomic, assign) NSInteger age;
@property (nonatomic, copy, nullable) NSString *bio;
@property (nonatomic, assign) BOOL isOnline;
- (instancetype)initWithDictionary:(NSDictionary *)dict;
@end

@interface HYWhoLikedMeData : NSObject
@property (nonatomic, assign) NSInteger total;
@property (nonatomic, strong) NSArray<HYSimpleUserInfo *> *users;
@property (nonatomic, assign) BOOL locked;
@property (nonatomic, copy, nullable) NSString *upgradeTip;
- (instancetype)initWithDictionary:(NSDictionary *)dict;
@end

@interface HYVisitorInfo : NSObject
@property (nonatomic, copy) NSString *userId;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *avatar;
@property (nonatomic, assign) NSInteger sex;
@property (nonatomic, assign) NSInteger age;
@property (nonatomic, copy, nullable) NSString *bio;
@property (nonatomic, assign) BOOL isOnline;
@property (nonatomic, copy) NSString *visitedAt;
- (instancetype)initWithDictionary:(NSDictionary *)dict;
@end

@interface HYProfileVisitorsData : NSObject
@property (nonatomic, assign) NSInteger total;
@property (nonatomic, strong) NSArray<HYVisitorInfo *> *visitors;
@property (nonatomic, assign) BOOL locked;
@property (nonatomic, copy, nullable) NSString *upgradeTip;
- (instancetype)initWithDictionary:(NSDictionary *)dict;
@end

NS_ASSUME_NONNULL_END
