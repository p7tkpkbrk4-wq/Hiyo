#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HYUser : NSObject

@property (nonatomic, assign) NSInteger userId;
@property (nonatomic, assign) long accountId;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *email;
@property (nonatomic, assign) NSInteger age;
@property (nonatomic, copy) NSString *avatar;
@property (nonatomic, copy) NSString *bio;
@property (nonatomic, assign) NSInteger sex;
@property (nonatomic, copy) NSString *birthDay;
@property (nonatomic, copy) NSString *distance;
@property (nonatomic, copy) NSArray<NSString *> *interests;
@property (nonatomic, copy) NSArray<NSString *> *photos;
@property (nonatomic, assign) long long fansCount;
@property (nonatomic, assign) long long attentionCount;
@property (nonatomic, assign) long long lookMeCount;
@property (nonatomic, assign) long long charm;
@property (nonatomic, assign) NSInteger height;
@property (nonatomic, assign) NSInteger weight;
@property (nonatomic, copy) NSString *constellation;
@property (nonatomic, copy) NSString *currentAddress;
@property (nonatomic, copy) NSString *job;
@property (nonatomic, copy) NSString *backgroundImage;
@property (nonatomic, assign) BOOL isFollowing;
@property (nonatomic, assign) BOOL isOnline;
@property (nonatomic, assign) BOOL isVip;
@property (nonatomic, copy) NSString *voiceUrl;
@property (nonatomic, assign) NSInteger voiceDuration;

- (instancetype)initWithDictionary:(NSDictionary *)dict;

@end

NS_ASSUME_NONNULL_END
