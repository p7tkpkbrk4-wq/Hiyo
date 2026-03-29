#import <UIKit/UIKit.h>
@class HYGift;
@class HYGiftBubble;

NS_ASSUME_NONNULL_BEGIN

@interface GiftPanelSheetController : UIViewController
@property (nonatomic, assign) NSInteger receiverId;
@property (nonatomic, copy, nullable) void (^onGiftSent)(HYGiftBubble *bubble, BOOL isFromMe);
@property (nonatomic, copy, nullable) void (^onDismiss)(void);
@property (nonatomic, copy, nullable) void (^onInsufficientBalance)(void);
@end

NS_ASSUME_NONNULL_END
