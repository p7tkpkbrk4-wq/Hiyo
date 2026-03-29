#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface FullscreenPhotoViewController : UIViewController

- (instancetype)initWithPhotoUrls:(NSArray<NSString *> *)urls startIndex:(NSInteger)index;

@end

NS_ASSUME_NONNULL_END
