#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HYSearchUser : NSObject

@property (nonatomic, copy) NSString *uid;
@property (nonatomic, copy) NSString *userId;
@property (nonatomic, assign) long long accountId;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *avatarUrl;
@property (nonatomic, copy) NSString *signature;
@property (nonatomic, assign) NSInteger status;

- (instancetype)initWithDictionary:(NSDictionary *)dict;

@end

NS_ASSUME_NONNULL_END
