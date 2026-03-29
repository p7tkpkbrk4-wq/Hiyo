#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HYFollowUser : NSObject

@property (nonatomic, assign) long long followId;
@property (nonatomic, copy) NSString *userId;
@property (nonatomic, assign) long long accountId;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *avatarUrl;
@property (nonatomic, copy) NSString *signature;
@property (nonatomic, assign) NSInteger sex;
@property (nonatomic, assign) BOOL isFollowing;

- (instancetype)initWithDictionary:(NSDictionary *)dict;

@end

NS_ASSUME_NONNULL_END
