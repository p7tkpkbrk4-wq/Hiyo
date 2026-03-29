#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Full-screen gift effect overlay that plays .svga, .mp4/.webm, or .gif/.webp animations.
/// Auto-dismisses when animation completes or after 60s fallback timeout.
/// Tap anywhere to dismiss early.
@interface HYGiftEffectOverlayView : UIView

/// Shows the effect overlay on the given view.
/// Downloads and caches the effect file automatically.
+ (void)showWithEffectURL:(NSString *)effectURL
                  onView:(UIView *)parentView
                 senderName:(nullable NSString *)senderName;

/// Same as above, plays from a pre-cached local file path.
+ (void)showWithCachedFilePath:(nullable NSString *)localPath
                     effectURL:(NSString *)effectURL
                        onView:(UIView *)parentView
                    senderName:(nullable NSString *)senderName;

@end

NS_ASSUME_NONNULL_END
