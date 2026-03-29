#ifndef HYPickerManager_h
#define HYPickerManager_h

#import <UIKit/UIKit.h>
#import "HYColors.h"
#import "HYBottomSheetController.h"

typedef void (^HYDatePickerCompletion)(NSDate *date);
typedef void (^HYCountryCityCompletion)(NSString *country, NSString *city);
typedef void (^HYValueCompletion)(NSInteger value);
typedef void (^HYInterestsCompletion)(NSArray<NSString *> *interests);

@interface HYPickerManager : NSObject

+ (instancetype)shared;

// Birthday picker (18-80 years range)
+ (void)showBirthdayPickerWithCurrentDate:(NSDate *)date completion:(HYDatePickerCompletion)completion;

// Country + City chain
+ (void)showCountryCityPickerWithCountry:(NSString *)country city:(NSString *)city completion:(HYCountryCityCompletion)completion;

// Height (100-220cm)
+ (void)showHeightPickerWithValue:(NSInteger)value completion:(HYValueCompletion)completion;

// Weight (30-150kg)
+ (void)showWeightPickerWithValue:(NSInteger)value completion:(HYValueCompletion)completion;

// Interests
+ (void)showInterestsPickerWithSelected:(NSArray<NSString *> *)selected completion:(HYInterestsCompletion)completion;

@end

#endif
