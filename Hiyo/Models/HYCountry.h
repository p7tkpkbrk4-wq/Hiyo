#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HYCountry : NSObject

@property (nonatomic, assign) NSInteger countryId;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSArray<NSString *> *cities;

- (instancetype)initWithDictionary:(NSDictionary *)dict;

@end

NS_ASSUME_NONNULL_END
