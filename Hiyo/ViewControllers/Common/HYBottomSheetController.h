#ifndef HYBottomSheetController_h
#define HYBottomSheetController_h

#import <UIKit/UIKit.h>
#import "HYColors.h"

typedef void (^HYBottomSheetDismissCallback)(void);

@interface HYBottomSheetController : UIViewController

@property (nonatomic, assign) CGFloat cornerRadius;
@property (nonatomic, assign) CGFloat maxHeight;
@property (nonatomic, copy) HYBottomSheetDismissCallback onDismiss;

- (instancetype)initWithContentViewController:(UIViewController *)contentVC;
- (void)show;
- (void)dismiss;

@end

#endif
