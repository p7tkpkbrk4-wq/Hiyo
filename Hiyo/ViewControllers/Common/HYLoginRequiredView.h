#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface HYLoginRequiredView : UIView

@property (nonatomic, copy, nullable) void (^onLoginTapped)(void);
@property (nonatomic, copy) NSString *tipText;
- (void)setLoginButtonTitle:(NSString *)title;

@end

NS_ASSUME_NONNULL_END
