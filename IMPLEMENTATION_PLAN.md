# Hiyo iOS App - Complete Implementation Plan

## Context

This plan bridges the feature gap between the existing iOS app (`/Users/ningpeichao/Desktop/Hiyo`) and the Android app (`/Users/ningpeichao/Desktop/hiyo-andriod-main/app`). The iOS project is written in Objective-C using UIKit with Masonry for Auto Layout, and already has solid foundations in Meet, Profile, and Edit screens. The main gaps are in CompleteProfile, EditProfile (missing features), MyProfile/UserProfile (missing features), Settings, and shared infrastructure.

---

## Phase 0: Architecture & Infrastructure

### 0.1 HYNotificationConstants

**File:** `Hiyo/Common/HYNotificationConstants.h` (CREATE)
```objc
// Notification Names
extern NSNotificationName const HYProfileDidUpdateNotification;
extern NSNotificationName const HYNeedLoginNotification;
extern NSNotificationName const HYMatchSuccessNotification;
extern NSNotificationName const HYWebSocketConnectedNotification;
extern NSNotificationName const HYWebSocketDisconnectedNotification;
extern NSNotificationName const HYLogoutNotification;
```

### 0.2 HYColors

**File:** `Hiyo/Common/HYColors.h` (CREATE)
```objc
// Color constants matching Android theme
#define PrimaryPink       [UIColor colorWithRed:1.0 green:0.42 blue:0.616 alpha:1.0]
#define PrimaryPurple     [UIColor colorWithRed:0.77 green:0.31 blue:0.886 alpha:1.0]
#define PrimaryViolet     [UIColor colorWithRed:0.482 green:0.373 blue:1.0 alpha:1.0]
#define DarkBackground    [UIColor colorWithRed:0.039 green:0.039 blue:0.078 alpha:1.0]
#define DarkCard          [UIColor colorWithRed:0.11 green:0.11 blue:0.18 alpha:1.0]
#define DarkCardElevated  [UIColor colorWithRed:0.14 green:0.14 blue:0.22 alpha:1.0]
#define DarkLighter       [UIColor colorWithRed:0.18 green:0.18 blue:0.28 alpha:1.0]
#define TextPrimary      [UIColor whiteColor]
#define TextSecondary    [UIColor colorWithRed:0.702 green:0.702 blue:0.8 alpha:1.0]
#define TextMuted        [UIColor colorWithRed:0.502 green:0.502 blue:0.6 alpha:1.0]
#define GlassPurple       [UIColor colorWithRed:0.15 green:0.31 blue:0.886 alpha:0.15]
#define GlassBlack        [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.3]
#define BorderPurple      [UIColor colorWithRed:0.77 green:0.31 blue:0.886 alpha:0.4]
#define BorderLight       [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.15]
#define BorderGlow        [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.3]
#define OnlineGreen       [UIColor colorWithRed:0.298 green:0.686 blue:0.314 alpha:1.0]
#define DislikeRed        [UIColor colorWithRed:0.898 green:0.224 blue:0.208 alpha:1.0]
#define LikeGreen         [UIColor colorWithRed:0.298 green:0.686 blue:0.314 alpha:1.0]
#define Error             [UIColor colorWithRed:0.898 green:0.224 blue:0.208 alpha:1.0]
#define HotPink           [UIColor colorWithRed:1.0 green:0.42 blue:0.616 alpha:1.0]
#define ElectricPurple    [UIColor colorWithRed:0.58 green:0.42 blue:1.0 alpha:1.0]
#define DeepPurple        [UIColor colorWithRed:0.45 green:0.25 blue:0.85 alpha:1.0]
#define ShadowPurple       [UIColor colorWithRed:0.77 green:0.31 blue:0.886 alpha:0.3]
```

### 0.3 HYRouter

**Files:**
- `Hiyo/Common/HYRouter.h` (CREATE)
- `Hiyo/Common/HYRouter.m` (CREATE)

**Methods:**
```objc
+ (void)pushViewController:(UIViewController *)vc
                fromSource:(HYRouterSource)source
                animated:(BOOL)animated;

+ (void)presentViewController:(UIViewController *)vc
                     animated:(BOOL)animated
                   completion:(void (^)(void))completion;

+ (void)popViewControllerAnimated:(BOOL)animated;
+ (void)dismissToRootAnimated:(BOOL)animated completion:(void (^)(void))completion;

// Navigation helpers
+ (void)pushEditProfile;
+ (void)pushUserProfileWithUserId:(NSString *)userId;
+ (void)pushSettings;
+ (void)pushChatWithUserId:(NSString *)userId name:(NSString *)name avatar:(NSString *)avatar;
+ (void)pushFollowListWithUserId:(NSString *)userId type:(HYFollowListType)type title:(NSString *)title;
+ (void)pushFullscreenPhoto:(NSArray<NSString *> *)urls startIndex:(NSInteger)index;
+ (void)pushPostDetailWithPostId:(NSInteger)postId;
+ (void)pushFeedback;
+ (void)pushAbout;
+ (void)pushPrivacySettings;
+ (void)pushNotificationSettings;
+ (void)pushLanguageSettings;
+ (void)pushUserAgreement;
```

**Implementation notes:**
- Uses `[UIApplication sharedApplication].keyWindow.rootViewController` to find the topmost navigation controller
- Wraps standalone VCs in `UINavigationController` when needed
- Handles both tab-bar embedded and standalone navigation flows

### 0.4 HYBaseViewController

**Files:**
- `Hiyo/ViewControllers/Common/HYBaseViewController.h` (CREATE)
- `Hiyo/ViewControllers/Common/HYBaseViewController.m` (CREATE)

**Features:**
- Dark background color (`DarkBackground`)
- Keyboard dismissal on tap (`dismissKeyboard` method)
- `showLoading` / `hideLoading` methods with activity indicator
- `showAlert:(NSString *)message` convenience method
- `showToast:(NSString *)message` with brief auto-dismiss feedback
- Registers for `HYNeedLoginNotification` to show login
- Registers for `HYProfileDidUpdateNotification` to reload data
- `setupNavigationBarDark` helper for consistent nav bar styling

### 0.5 HYBottomSheetController

**Files:**
- `Hiyo/ViewControllers/Common/HYBottomSheetController.h` (CREATE)
- `Hiyo/ViewControllers/Common/HYBottomSheetController.m` (CREATE)

**Features:**
- UIPresentationController subclass for iOS 7+ bottom sheet presentation
- Draggable dismiss via UIPanGestureRecognizer
- Configurable corner radius, background color (`DarkCard`), max height
- Dark overlay with tap-to-dismiss
- Block-based `onDismiss` callback
- Child view controller content sizing via `preferredContentSize`

**Subclasses to create:**

#### 0.5.1 HYCountryPickerSheet
- Inherits `HYBottomSheetController`
- Displays list of countries from `getLocations` API
- Calls `onSelect:(HYCountry *)country`
- Includes search/filter functionality

#### 0.5.2 HYCitiesPickerSheet
- Inherits `HYBottomSheetController`
- Displays cities for selected country
- Calls `onSelect:(NSString *)city`
- Scrollable list

#### 0.5.3 HYHeightPickerSheet
- Inherits `HYBottomSheetController`
- UISlider from 100-220cm with current value display
- Gradient-styled confirm button
- Calls `onConfirm:(NSInteger)height`

#### 0.5.4 HYWeightPickerSheet
- Inherits `HYBottomSheetController`
- UISlider from 30-150kg with current value display
- Gradient-styled confirm button
- Calls `onConfirm:(NSInteger)weight`

#### 0.5.5 HYInterestsPickerSheet
- Inherits `HYBottomSheetController`
- Horizontal scrollable category tabs (UISegmentedControl or scroll view)
- Grid of interest chips below
- Selected interests displayed at top with remove buttons
- Max 10, min 4 selection requirement
- Confirm button

#### 0.5.6 HYLanguagePickerSheet
- Inherits `HYBottomSheetController`
- Radio-button style list: System Default, Traditional Chinese, Simplified Chinese, English
- Persists to `NSUserDefaults` key `HYLanguagePreference`

### 0.6 HYPickerManager

**File:** `Hiyo/Common/HYPickerManager.h` + `.m` (CREATE)

Singleton that manages all picker presentations via `HYBottomSheetController`.

```objc
+ (void)showDatePickerWithMode:(UIDatePickerMode)mode
                  currentDate:(NSDate *)currentDate
                defaultYearOffset:(NSInteger)yearOffset
                     completion:(void (^)(NSDate *date))completion;

// Convenience for birthday (age 18-80 range)
+ (void)showBirthdayPickerWithCompletion:(void (^)(NSDate *date))completion;

// Country + City chain
+ (void)showCountryCityPickerWithCompletion:(void (^)(NSString *country, NSString *city))completion;

// Height/Weight
+ (void)showHeightPickerWithValue:(NSInteger)currentValue completion:(void (^)(NSInteger))completion;
+ (void)showWeightPickerWithValue:(NSInteger)currentValue completion:(void (^)(NSInteger))completion;

// Interests
+ (void)showInterestsPickerWithSelected:(NSArray<NSString *> *)selected
                             completion:(void (^)(NSArray<NSString *> *))completion;
```

### 0.7 HYCountry Model

**Files:**
- `Hiyo/Models/HYCountry.h` (CREATE)
- `Hiyo/Models/HYCountry.m` (CREATE)

```objc
@interface HYCountry : NSObject
@property (nonatomic, assign) NSInteger countryId;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSArray<NSString *> *cities;
- (instancetype)initWithDictionary:(NSDictionary *)dict;
@end
```

### 0.8 HYInterestCategory Model

**Files:**
- `Hiyo/Models/HYInterestCategory.h` (CREATE)
- `Hiyo/Models/HYInterestCategory.m` (CREATE)

```objc
@interface HYInterestCategory : NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSArray<NSString *> *tags;
- (instancetype)initWithDictionary:(NSDictionary *)dict;
@end
```

---

## Phase 1: CompleteProfile Overhaul

### Files to MODIFY

#### `Hiyo/ViewControllers/CompleteProfile/CompleteProfileViewController.h`
- Add `onComplete` callback property
- Add `NSDate *selectedBirthday` property

#### `Hiyo/ViewControllers/CompleteProfile/CompleteProfileViewController.m`
Complete rewrite to match Android `CompleteProfileScreen.kt`. **Remove all existing code** and replace with new implementation.

**UI Elements to add:**
1. **Gender Selection** (required)
   - Two buttons: Male (icon: `person.fill`), Female (icon: `person.fill`)
   - Selected state: `PrimaryPink` background with `0.2` alpha, `PrimaryPink` border
   - Unselected: transparent background, `BorderLight` border
   - Size: full-width, 56pt height, 16pt corner radius
   - Gender changes height/weight defaults (male: 170cm/60kg, female: 160cm/50kg)

2. **Birthday Field** (required)
   - `UITextField` styled as `OutlinedTextField` (dark card background, `BorderLight` border, 16pt corner radius)
   - Read-only, taps trigger date picker via `HYPickerManager`
   - Calendar icon (`calendar`) as trailing icon
   - Placeholder: "选择生日" (Select Birthday)
   - Date format: `yyyy-MM-dd`

3. **Country/City Field** (required)
   - Read-only text field, taps trigger country sheet then city sheet via `HYPickerManager`
   - Shows: "国家 · 城市" format
   - Location icon (`location.fill`) as trailing icon
   - Placeholder: "选择国家和城市"

4. **Height Field** (required)
   - Read-only field showing "XXXcm", taps trigger height sheet
   - Height icon (`ruler`) as trailing icon
   - Range: 100-220cm, default depends on gender

5. **Weight Field** (required)
   - Read-only field showing "XXXkg", taps trigger weight sheet
   - Monitor weight icon (`scalemass`) as trailing icon
   - Range: 30-150kg, default depends on gender

6. **Signature Field** (required)
   - Multi-line text view, 120pt height, 4 lines max
   - Max 100 characters
   - Placeholder: "用一句话介绍自己..."
   - 16pt corner radius

7. **Interest Tags Section** (required)
   - Title: "兴趣爱好 * (X/10，至少4个)" (X = selected count)
   - Selected tags displayed in `DarkCard` box with `BorderLight` border, 16pt corner radius
   - Each selected tag: `PrimaryPink` background at 0.2 alpha, `PrimaryPink` border, "X" remove button
   - Horizontal scrollable category chips below (LazyRow equivalent with `UIScrollView`)
   - Category chips: `PrimaryPurple` selected, `DarkCard` unselected, 20pt corner radius
   - Interest chips: `PrimaryPink` selected, `DarkCard` unselected, 20pt corner radius
   - Max 10, min 4 required

8. **Complete Button**
   - Gradient background (PrimaryPink -> PrimaryPurple -> PrimaryViolet diagonal)
   - "完成" text, 18pt semibold
   - 56pt height, 28pt corner radius
   - Loading state shows white `UIActivityIndicatorView`

**Validation (before submit):**
- Avatar URL required
- Gender must be selected (sex = 1 or 2)
- Birthday required
- Country + City required
- Height 100-250
- Weight 30-200
- Signature non-empty
- Interests: 4-10 items

**Data Flow:**
1. On load: Call `getInterests` API to get categories, call `getLocations` API to get countries
2. Avatar upload on tap: call `uploadAvatarImage:` API, store returned URL
3. On complete: call `completeProfileWithData:` with:
   ```objc
   @{
       @"avatar_url": uploadedAvatarUrl,
       @"sex": @(selectedGender),
       @"birth_day": birthdayString,        // "yyyy-MM-dd"
       @"current_address": @"国家 · 城市",
       @"height": @(height),
       @"weight": @(weight),
       @"signature": signatureText,
       @"interests": selectedInterests
   }
   ```
4. On success: call `self.onComplete()` callback

**Layout:**
- ScrollView with 24pt horizontal padding
- Avatar: 120pt diameter, centered, circular
- Title: 32pt bold, 8pt subtitle below
- 32pt spacing before avatar
- Each section: 16pt title, 8pt gap, field
- 24pt spacing between sections
- 32pt spacing before button
- Button: full width, 56pt height
- 24pt bottom padding

---

## Phase 2: EditProfile Improvements

### Files to MODIFY

#### `Hiyo/ViewControllers/Profile/EditProfileViewController.h`
- Add `NSString *uploadedBackgroundImageUrl` property
- Add `NSDate *selectedBirthday` property
- Add `HYCountry *selectedCountry` property
- Add `NSString *selectedCity` property
- Add `NSMutableArray<HYInterestCategory *> *interestCategories` property
- Add `NSMutableArray<HYCountry *> *countries` property

#### `Hiyo/ViewControllers/Profile/EditProfileViewController.m`

**UI Elements to ADD:**

1. **Background Image Upload**
   - Add 280pt height header image view behind avatar
   - Tap on background image triggers `PHPickerViewController` for background photo
   - Upload via `uploadImageWithData:fileName:completion:` API
   - `HYBottomSheetController` with "更换背景图" / "删除背景图" options
   - On upload success, store `uploadedBackgroundImageUrl` and update `backgroundImage` field

2. **Country/City Field** (replace `locationField`)
   - Read-only field with country/city parsing from `currentAddress`
   - Tap triggers `HYPickerManager` country+city picker
   - Updates `selectedCountry` + `selectedCity`

3. **Birthday Field** (replace existing text input)
   - Read-only field, tap triggers `HYPickerManager` birthday picker
   - Shows "YYYY-MM-DD (XX岁)" format
   - Calculates age automatically

4. **Height Field** (replace `heightField`)
   - Read-only, tap triggers height picker sheet
   - Shows "XXXcm"

5. **Weight Field** (replace `weightField`)
   - Read-only, tap triggers weight picker sheet
   - Shows "XXXkg"

6. **Interest Tags** (improve existing implementation)
   - Tap on interest field opens `HYInterestsPickerSheet` via `HYPickerManager`
   - Shows count and "选择兴趣标签" or "X 个标签"
   - Load categories via `getInterests` API

**Add to `loadData`:**
```objc
// Load interests
[[HYAPIClient shared] getInterestsWithCompletion:^(NSDictionary *response, NSError *error) {
    // Parse and store interestCategories
}];

// Load countries
[[HYAPIClient shared] getLocationsWithCompletion:^(NSDictionary *response, NSError *error) {
    // Parse and store countries
}];
```

**Update save logic:**
```objc
NSMutableDictionary *params = [NSMutableDictionary dictionary];
params[@"name"] = nickname;
params[@"bio"] = self.bioField.text ?: @"";
params[@"sex"] = @(self.user.sex);  // Keep existing if not changed
params[@"birth_day"] = birthdayString;
params[@"current_address"] = [NSString stringWithFormat:@"%@ · %@", selectedCountry.name, selectedCity];
params[@"height"] = @(height);
params[@"weight"] = @(weight);
params[@"job"] = self.jobField.text ?: @"";
params[@"interests"] = self.selectedInterests;
if (self.uploadedAvatarUrl) params[@"avatar_url"] = self.uploadedAvatarUrl;
if (self.uploadedBackgroundImageUrl) params[@"background_image_url"] = self.uploadedBackgroundImageUrl;
```

**Section card layout** (matching Android `SectionCard`):
- Card: `DarkCard` background, 20pt corner radius, `BorderPurple` border (1pt), shadow (8pt elevation, `ShadowPurple`)
- Section header: 28pt circle with `GlassPurple` background, 16pt icon inside, `iconColor` tint, section title text (15pt semibold, `TextSecondary`)
- Padding: 20pt inside card

---

## Phase 3: Meet Screen Improvements

### Files to MODIFY

#### `Hiyo/ViewControllers/Meet/MeetViewController.m`

**3.1 Improve Match Success Dialog**

Current `setupMatchOverlay` is basic. Improve to match Android:

- **Heart burst animation** on match (CAEmitterLayer with heart particles, or UIKit animation)
- **Animated avatar appearance** (scale from 0 to 1 with spring animation)
- **"配对成功!" text with shimmer animation**
- **Subtitle**: "你和 [Name] 互相喜欢!" in `TextSecondary`
- **"开始聊天" button**: gradient background (PrimaryPink -> PrimaryPurple), 48pt height, 24pt corner radius
- **"继续浏览" button**: text only in `TextSecondary`
- Background: `DarkBackground` at 0.92 alpha, dark overlay

**Method to add:**
```objc
- (void)showMatchAnimationWithUser:(HYUser *)user {
    // Spring animation on avatar
    // CAEmitterLayer heart burst
    // Fade in overlay with delay
}
```

**3.2 Improve Swipe Overlays**

Current overlay labels are basic. Improve:

- **LIKE overlay**: Green border + "LIKE" text, positioned top-left at -15 degrees rotation, fades in progressively
- **NOPE overlay**: Red border + "NOPE" text, positioned top-right at +15 degrees rotation, fades in progressively
- **SUPER LIKE overlay**: Add purple "SUPER LIKE" text (optional, for super-like button)
- Labels should pulse/glow slightly when fully visible

**3.3 No More Users View**

Current `setupEmptyView` is decent. Improve:

- **Animated icon** (rotating or pulsing refresh icon)
- **"暂无更多推荐"** title
- **"我们正在为您寻找更多有趣的人"** subtitle
- **"刷新试试" button**: gradient background
- **Background blur effect** on the card view

**3.4 Chat Navigation from Match**

Update `startChatTapped`:
```objc
- (void)startChatTapped {
    [self dismissMatchOverlay];
    HYUser *matchedUser = self.lastMatchedUser; // store this
    if (matchedUser) {
        ChatDetailViewController *vc = [[ChatDetailViewController alloc]
            initWithPartnerId:[@(matchedUser.id) stringValue]
            partnerName:matchedUser.name
            partnerAvatar:matchedUser.avatar];
        [self.navigationController pushViewController:vc animated:YES];
    }
}
```

**3.5 Undo Functionality**

Current undo is basic. Improve:
- Store up to 3 previous swipes in memory
- Animate card back onto stack with flip animation
- Clear undo history on refresh

---

## Phase 4: MyProfile Improvements

### Files to MODIFY

#### `Hiyo/ViewControllers/Profile/MyProfileViewController.m`

**4.1 Gender/Age Badge on Name**

Add below the name label in the header:
```objc
// Gender icon + Age
UIImageView *genderIcon = [[UIImageView alloc] init];
genderIcon.contentMode = UIViewContentModeScaleAspectFit;
genderIcon.tintColor = user.sex == 2 ? HotPink : PrimaryViolet;
genderIcon.image = [UIImage systemImageNamed:user.sex == 2 ? @"person.fill" : @"person.fill"];

UILabel *ageLabel = [[UILabel alloc] init];
ageLabel.text = [NSString stringWithFormat:@"%ld岁", (long)user.age];
ageLabel.font = [UIFont systemFontOfSize:16];
ageLabel.textColor = TextSecondary;
```

**4.2 Background Image Blur Effect**

In `viewDidLayoutSubviews`, update the background image:
```objc
// Blur the avatar for background
// Option A: Use CIFilter Gaussian blur (can be heavy)
// Option B: Use SDWebImage's blurred variant
// Option C: Set backgroundImage to avatar URL with overlay

if (self.currentUser.avatar.length > 0) {
    [self.bgImageView sd_setImageWithURL:[NSURL URLWithString:self.currentUser.avatar]];
    // Add blur effect
    UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:blur];
    blurView.frame = self.bgImageView.bounds;
    blurView.alpha = 0.8;
    [self.bgImageView addSubview:blurView];
}
```

**4.3 Real Photo Wall**

Current photo wall has placeholder logic. Implement properly:

```objc
// In updatePhotoWall:
// Remove placeholder photos
// Add real photo ImageViews from user.photos
// Each photo: 120x120pt, 12pt corner radius, tap to fullscreen, long-press to delete
// Add photo button at the end
// Layout: horizontal scroll, 120pt square cells, 10pt gap

// Add photo tap: PHPicker for new photo
// Long press: action sheet with "删除照片" option
// Delete: call deletePhotoWithId: API, then reload

- (void)addPhotoFromPicker:(UIImage *)image {
    // Resize to max 1080px
    // Upload via uploadImageWithData:fileName:completion:
    // On success, call addPhotoWithUrl:isWall:YES
    // Reload photo wall
}
```

**4.4 Interests Section**

Add a dedicated interests section below the photo wall:
```objc
// HYGradientCard *interestsCard = [[HYGradientCard alloc] init];
// Title: "兴趣爱好" with star icon
// Flow layout of interest chips (PrimaryPurple chips, 32pt height, full wrapping)
// Each chip: "标签名" text, 16pt horizontal padding, 20pt corner radius
// Horizontal scroll or wrap layout
```

**4.5 Header Background Image**

```objc
// In updateUI:
// Load background image if available, else use avatar blur
// "更换背景图" button in top-right corner (camera icon)
// Tap opens HYBottomSheetController with:
//   - "上传新背景图" -> PHPicker -> upload -> update
//   - "使用头像模糊" -> apply blur
//   - "移除背景图"
```

**4.6 ID Copy Feature**

On `idLabel` tap:
```objc
UIPasteboard.generalPasteboard.string = [NSString stringWithFormat:@"%ld", (long)self.currentUser.accountId];
[self showBriefFeedback:@"ID已复制" color:PrimaryPurple];
```

---

## Phase 5: UserProfile Improvements

### Files to MODIFY

#### `Hiyo/ViewControllers/Profile/UserProfileViewController.m`

**5.1 Real Photo Wall**

Replace placeholder photo logic with real data:
```objc
// In setupPhotoWall, use user.photos array
// Load actual photos from user.photos (NSArray<NSString *>)
// Tap: fullscreen photo viewer (reuse FullscreenPhotoViewController)
// Long press: show action sheet if own profile
```

**5.2 Gender/Age Badge**

Add below name in header:
```objc
// After nameLabel setup, add gender/age row
UIImageView *genderIcon = [[UIImageView alloc] initWithImage:
    [UIImage systemImageNamed:self.user.sex == 2 ? @"person.fill" : @"person.fill"]];
genderIcon.tintColor = self.user.sex == 2 ? HotPink : PrimaryViolet;
UILabel *ageLabel = [[UILabel alloc] init];
ageLabel.text = [NSString stringWithFormat:@" %ld岁", (long)self.user.age];
ageLabel.font = [UIFont systemFontOfSize:16];
ageLabel.textColor = TextSecondary;
```

**5.3 Interests Section**

Add below photo wall or about card:
```objc
// Create tagsContainer for interests
// Flow layout similar to MyProfile
// Only show if user.interests.count > 0
```

**5.4 Background Image Display**

```objc
// Load user.backgroundImage into bgImageView
// Show gradient overlay for text readability
// If no background, blur the avatar as fallback
```

**5.5 ID Copy Feature**

Same as MyProfile:
```objc
// Add UITapGestureRecognizer to idLabel
// Copy ID to clipboard and show toast
```

**5.6 Post Detail Navigation Fix**

`photoTapped:` currently does nothing. Implement:
```objc
- (void)photoTapped:(UITapGestureRecognizer *)gesture {
    if (self.user.photos.count == 0) return;
    NSInteger index = gesture.view.tag - 900;
    if (index >= 0 && index < self.user.photos.count) {
        FullscreenPhotoViewController *vc = [[FullscreenPhotoViewController alloc]
            initWithPhotoUrls:self.user.photos startIndex:index];
        vc.modalPresentationStyle = UIModalPresentationFullScreen;
        [self presentViewController:vc animated:YES completion:nil];
    }
}
```

---

## Phase 6: Settings Completions

### Files to CREATE

#### `Hiyo/ViewControllers/Profile/Settings/AccountSettingsViewController.h` + `.m`
- Password change screen (form with old password, new password, confirm)
- Email change screen (form with new email, verification code)
- Phone binding screen (form with phone number, verification code)
- All use `HYBaseViewController` as base class

#### `Hiyo/ViewControllers/Profile/Settings/AppSettingsViewController.h` + `.m`
- Contains Language, Notifications, Privacy sub-settings
- Push to dedicated screens

#### `Hiyo/ViewControllers/Profile/Settings/LanguageSettingsViewController.h` + `.m`
- Radio-button list matching Android `LanguageOption`:
  - 跟随系统 (System Default)
  - 繁體中文 (Traditional Chinese)
  - 简体中文 (Simplified Chinese)
  - English
- Selected item highlighted with `GlassPurple` background
- On selection: save to `NSUserDefaults` key `HYLanguagePreference`, post notification for app-wide language change

#### `Hiyo/ViewControllers/Profile/Settings/NotificationSettingsViewController.h` + `.m`
- Toggle switches for:
  - 新消息通知 (New message notifications)
  - 匹配通知 (Match notifications)
  - 关注通知 (Follow notifications)
  - 系统通知 (System notifications)
- Each toggle calls `HYAPIClient` update API if available, or saves to `NSUserDefaults`

#### `Hiyo/ViewControllers/Profile/Settings/PrivacySettingsViewController.h` + `.m`
- Toggle switches for:
  - 隐藏在线状态 (Hide online status)
  - 隐藏距离 (Hide distance)
  - 隐藏最后登录时间 (Hide last seen)
- Privacy mode indicator

#### `Hiyo/ViewControllers/Profile/Settings/AboutViewController.h` + `.m`
- App logo
- "Hiyo" title
- "Version X.X.X" subtitle
- Features list
- Links: Privacy Policy, Terms of Service, Open Source Licenses
- Developer contact

### Files to MODIFY

#### `Hiyo/ViewControllers/Profile/SettingsViewController.m`

Complete redesign to match Android `SettingsScreen.kt` styling:

**Appearance:**
- Gradient top bar (PrimaryPurple at 0.2 alpha -> PrimaryViolet at 0.2 alpha, horizontal)
- Dark card containers, `BorderPurple` border, 20pt corner radius, shadow

**Section Structure:**

```
Account Section (icon: person.circle.fill, PrimaryPink)
  ├── 修改密码 (lock icon, PrimaryPurple) -> AccountSettingsViewController
  ├── 绑定邮箱 (mail icon, PrimaryViolet) -> AccountSettingsViewController
  └── 绑定手机 (phone icon, ElectricPurple) -> AccountSettingsViewController

App Section (icon: gearshape.fill, PrimaryViolet)
  ├── 语言 (language icon, PrimaryPink) -> LanguageSettingsViewController
  ├── 消息通知 (bell icon, PrimaryPurple) -> NotificationSettingsViewController
  └── 隐私设置 (eye.slash icon, DeepPurple) -> PrivacySettingsViewController

Support Section (icon: questionmark.circle.fill, ElectricPurple)
  ├── 帮助与反馈 (speech.bubble icon, PrimaryViolet) -> FeedbackViewController
  ├── 帮助中心 (help icon, PrimaryPurple) -> HelpCenterViewController (CREATE)
  └── 关于我们 (info icon, PrimaryPink) -> AboutViewController

[Logout Button]
  Gradient (Error red), full width, 56pt, 28pt corner radius
  Icon: arrow.right.square, text: "退出登录"

[Version Info]
  "Hiyo v1.0.0" centered, TextMuted color
```

**Row appearance:**
- 40pt icon container with `GlassPurple` radial gradient background, circular
- 22pt icon inside with `iconColor` tint
- 16pt title text, `TextPrimary`
- Chevron right on right side
- 20pt horizontal padding, 16pt vertical padding

---

## Phase 7: Additional ViewControllers

### 7.1 HelpCenterViewController

**Files:** `Hiyo/ViewControllers/Profile/HelpCenterViewController.h` + `.m` (CREATE)
- FAQ list with expandable sections
- Contact support button
- Search bar for FAQ

### 7.2 ProfileViewController Cleanup

**File:** `Hiyo/ViewControllers/Profile/ProfileViewController.h` + `.m` (EXISTS, REVIEW)

Check if this file is still needed or is an unused duplicate. If unused, mark for deletion or refactor into one of the other profile VCs.

---

## Phase 8: API Client Updates

### `Hiyo/API/HYAPIClient.h` / `.m`

**Add new methods:**
```objc
// Complete profile
- (void)completeProfileWithData:(NSDictionary *)data completion:(HYAPICompletion)completion;

// Locations/Countries
- (void)getLocationsWithCompletion:(HYAPICompletion)completion;

// Interests
- (void)getInterestsWithCompletion:(HYAPICompletion)completion;

// Background image
- (void)uploadBackgroundImage:(NSData *)imageData completion:(void (^)(NSString *imageUrl, NSError *error))completion;

// Photo management
- (void)deletePhotoWithId:(NSInteger)photoId completion:(HYAPICompletion)completion;

// Settings
- (void)updateNotificationSettings:(NSDictionary *)settings completion:(HYAPICompletion)completion;
- (void)updatePrivacySettings:(NSDictionary *)settings completion:(HYAPICompletion)completion;
```

**Update `HYUser.h` model** (already has fields, verify completeness):
- Confirm `sex`, `age`, `birthDay`, `backgroundImage`, `interests`, `photos` all mapped correctly
- Add `HYInterestCategory` parsing support

---

## File Manifest

### Create (NEW files)

| File | Type | Purpose |
|------|------|---------|
| `Hiyo/Common/HYNotificationConstants.h` | Header | All notification name constants |
| `Hiyo/Common/HYColors.h` | Header | All color constants |
| `Hiyo/Common/HYRouter.h` | Header | Centralized navigation |
| `Hiyo/Common/HYRouter.m` | Implementation | Centralized navigation |
| `Hiyo/ViewControllers/Common/HYBaseViewController.h` | Header | Base VC with common patterns |
| `Hiyo/ViewControllers/Common/HYBaseViewController.m` | Implementation | Base VC with common patterns |
| `Hiyo/ViewControllers/Common/HYBottomSheetController.h` | Header | iOS-style bottom sheet |
| `Hiyo/ViewControllers/Common/HYBottomSheetController.m` | Implementation | iOS-style bottom sheet |
| `Hiyo/Common/HYPickerManager.h` | Header | Picker presentation manager |
| `Hiyo/Common/HYPickerManager.m` | Implementation | Picker presentation manager |
| `Hiyo/Models/HYCountry.h` | Header | Country model |
| `Hiyo/Models/HYCountry.m` | Implementation | Country model |
| `Hiyo/Models/HYInterestCategory.h` | Header | Interest category model |
| `Hiyo/Models/HYInterestCategory.m` | Implementation | Interest category model |
| `Hiyo/ViewControllers/Profile/Settings/AccountSettingsViewController.h` | Header | Password/Email/Phone |
| `Hiyo/ViewControllers/Profile/Settings/AccountSettingsViewController.m` | Implementation | Password/Email/Phone |
| `Hiyo/ViewControllers/Profile/Settings/AppSettingsViewController.h` | Header | App settings hub |
| `Hiyo/ViewControllers/Profile/Settings/AppSettingsViewController.m` | Implementation | App settings hub |
| `Hiyo/ViewControllers/Profile/Settings/LanguageSettingsViewController.h` | Header | Language selection |
| `Hiyo/ViewControllers/Profile/Settings/LanguageSettingsViewController.m` | Implementation | Language selection |
| `Hiyo/ViewControllers/Profile/Settings/NotificationSettingsViewController.h` | Header | Notification toggles |
| `Hiyo/ViewControllers/Profile/Settings/NotificationSettingsViewController.m` | Implementation | Notification toggles |
| `Hiyo/ViewControllers/Profile/Settings/PrivacySettingsViewController.h` | Header | Privacy toggles |
| `Hiyo/ViewControllers/Profile/Settings/PrivacySettingsViewController.m` | Implementation | Privacy toggles |
| `Hiyo/ViewControllers/Profile/Settings/AboutViewController.h` | Header | About screen |
| `Hiyo/ViewControllers/Profile/Settings/AboutViewController.m` | Implementation | About screen |
| `Hiyo/ViewControllers/Profile/HelpCenterViewController.h` | Header | FAQ/Help |
| `Hiyo/ViewControllers/Profile/HelpCenterViewController.m` | Implementation | FAQ/Help |

### Modify (EXISTING files)

| File | Changes |
|------|---------|
| `Hiyo/ViewControllers/CompleteProfile/CompleteProfileViewController.m` | Complete rewrite: gender buttons, birthday picker, country/city bottom sheet, height/weight sliders, interest tags, validation, API integration |
| `Hiyo/ViewControllers/Profile/EditProfileViewController.m` | Add background image upload, country/city picker, birthday picker, height/weight picker sheets, interest picker, section card layout |
| `Hiyo/ViewControllers/Profile/MyProfileViewController.m` | Add gender/age badge, background image with blur, real photo wall, interests section, ID copy, header background image picker |
| `Hiyo/ViewControllers/Profile/UserProfileViewController.m` | Add gender/age badge, real photo wall, interests section, background image display, ID copy, fix photoTapped navigation |
| `Hiyo/ViewControllers/Profile/SettingsViewController.m` | Complete redesign: gradient top bar, glass card sections, all sub-screen navigation |
| `Hiyo/API/HYAPIClient.h` | Add new API methods |
| `Hiyo/API/HYAPIClient.m` | Implement new API methods |
| `Hiyo/Models/HYUser.h` | Verify/add `sex`, `age`, `birthDay`, `backgroundImage` fields |
| `Hiyo/Models/HYUser.m` | Verify/add field parsing |
| `Hiyo/AppDelegate.m` | Update `HYNotificationConstants` references |

---

## Implementation Order

1. **Phase 0** (Infrastructure) -- These are prerequisites for all other phases
2. **Phase 1** (CompleteProfile) -- Critical path for new user onboarding
3. **Phase 8** (API Updates) -- Needed by CompleteProfile and EditProfile
4. **Phase 2** (EditProfile) -- Depends on Phase 1 structure
5. **Phase 3** (Meet) -- Independent, can start in parallel with Phase 4
6. **Phase 4** (MyProfile) -- Independent
7. **Phase 5** (UserProfile) -- Independent
8. **Phase 6** (Settings) -- Depends on Phase 0
9. **Phase 7** (Additional VCs) -- Lower priority

---

## Testing Checklist

Before marking each phase complete:

- [ ] All fields validate correctly with appropriate error messages
- [ ] Loading states shown during API calls
- [ ] Error states handled gracefully
- [ ] Keyboard dismissal works on all screens
- [ ] Dark mode consistent across all screens
- [ ] Memory: no retain cycles, proper weak self usage
- [ ] API errors show user-friendly messages
- [ ] Empty states shown when no data
- [ ] Scrolling smooth under 60fps on all scroll views
- [ ] All buttons have touch feedback
- [ ] Navigation bar styling consistent
