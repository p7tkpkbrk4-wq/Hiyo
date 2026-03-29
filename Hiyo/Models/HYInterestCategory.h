#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HYInterestCategory : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSArray<NSString *> *tags;

- (instancetype)initWithDictionary:(NSDictionary *)dict;

@end

NS_ASSUME_NONNULL_END
