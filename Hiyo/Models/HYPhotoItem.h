#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HYPhotoItem : NSObject

@property (nonatomic, assign) long long photoId;
@property (nonatomic, copy) NSString *photoUrl;
@property (nonatomic, assign) NSInteger isPrivacy;
@property (nonatomic, assign) NSInteger isWall;

- (instancetype)initWithDictionary:(NSDictionary *)dict;

@end

NS_ASSUME_NONNULL_END
