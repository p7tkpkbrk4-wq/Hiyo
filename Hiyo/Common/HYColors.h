#ifndef HYColors_h
#define HYColors_h

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

// Primary Colors
#define PrimaryPink        [UIColor colorWithRed:1.0 green:0.42 blue:0.616 alpha:1.0]
#define PrimaryPurple      [UIColor colorWithRed:0.77 green:0.31 blue:0.886 alpha:1.0]
#define PrimaryViolet     [UIColor colorWithRed:0.482 green:0.373 blue:1.0 alpha:1.0]

// Light Theme Colors
#define LightBg1          [UIColor colorWithRed:0.973 green:0.965 blue:1.0 alpha:1.0]   // #F8F6FF
#define LightBg2          [UIColor colorWithRed:0.941 green:0.929 blue:1.0 alpha:1.0]   // #F0EDFF
#define LightCard         [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0]        // #FFFFFF
#define LightCard2        [UIColor colorWithRed:0.980 green:0.973 blue:1.0 alpha:1.0]   // #FAF8FF
#define PinkGradStart     [UIColor colorWithRed:1.0 green:0.42 blue:0.62 alpha:1.0]     // #FF6B9E
#define PinkGradEnd       [UIColor colorWithRed:1.0 green:0.25 blue:0.506 alpha:1.0]    // #FF4081
#define PurpleGradStart   [UIColor colorWithRed:0.608 green:0.498 blue:1.0 alpha:1.0]   // #9B7FFF
#define PurpleGradEnd     [UIColor colorWithRed:0.769 green:0.31 blue:0.89 alpha:1.0]    // #C44FE3
#define OnlineGreenLight  [UIColor colorWithRed:0.298 green:0.686 blue:0.314 alpha:1.0]  // #4CAF50
#define VipGold           [UIColor colorWithRed:1.0 green:0.843 blue:0.0 alpha:1.0]      // #FFD700
#define CardGlowPurple    [UIColor colorWithRed:0.769 green:0.31 blue:0.89 alpha:0.15]   // purple shadow 15%

// Background Colors
#define DarkBackground     [UIColor colorWithRed:0.039 green:0.039 blue:0.078 alpha:1.0]
#define DarkCard          [UIColor colorWithRed:0.11 green:0.11 blue:0.18 alpha:1.0]
#define DarkCardElevated  [UIColor colorWithRed:0.14 green:0.14 blue:0.22 alpha:1.0]
#define DarkLighter       [UIColor colorWithRed:0.18 green:0.18 blue:0.28 alpha:1.0]

// Text Colors
#define TextPrimary       [UIColor whiteColor]
#define TextSecondary     [UIColor colorWithRed:0.702 green:0.702 blue:0.8 alpha:1.0]
#define TextMuted         [UIColor colorWithRed:0.502 green:0.502 blue:0.6 alpha:1.0]

// Glass/Overlay Colors
#define GlassPurple        [UIColor colorWithRed:0.15 green:0.31 blue:0.886 alpha:0.15]
#define GlassBlack         [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.3]

// Border Colors
#define BorderPurple       [UIColor colorWithRed:0.77 green:0.31 blue:0.886 alpha:0.4]
#define BorderLight        [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.15]
#define BorderGlow        [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.3]

// Status Colors
#define OnlineGreen        [UIColor colorWithRed:0.298 green:0.686 blue:0.314 alpha:1.0]
#define DislikeRed         [UIColor colorWithRed:0.898 green:0.224 blue:0.208 alpha:1.0]
#define LikeGreen          [UIColor colorWithRed:0.298 green:0.686 blue:0.314 alpha:1.0]
#define ErrorRed           [UIColor colorWithRed:0.898 green:0.224 blue:0.208 alpha:1.0]

// Gradient Colors
#define HotPink            [UIColor colorWithRed:1.0 green:0.42 blue:0.616 alpha:1.0]
#define ElectricPurple     [UIColor colorWithRed:0.58 green:0.42 blue:1.0 alpha:1.0]
#define DeepPurple         [UIColor colorWithRed:0.45 green:0.25 blue:0.85 alpha:1.0]
#define ShadowPurple       [UIColor colorWithRed:0.77 green:0.31 blue:0.886 alpha:0.3]

// Helper: Create gradient layer
CAGradientLayer *HYGradientLayerMake(CGRect frame, NSArray *colors, CGPoint startPoint, CGPoint endPoint);

#endif
