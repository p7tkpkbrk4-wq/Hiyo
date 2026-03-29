#import "HYBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface ChatDetailViewController : HYBaseViewController

- (instancetype)initWithPartnerId:(NSString *)partnerId
                         partnerName:(NSString *)partnerName
                       partnerAvatar:(NSString *)partnerAvatar;

@end

NS_ASSUME_NONNULL_END
