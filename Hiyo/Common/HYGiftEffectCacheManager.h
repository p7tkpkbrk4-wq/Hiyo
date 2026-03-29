#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Manages downloading and caching of gift effect files (mp4, webm, svga, gif, webp).
/// Uses MD5 hash of URL as local filename.
@interface HYGiftEffectCacheManager : NSObject

+ (instancetype)shared;

/// Returns the cached local file path for an effect URL.
/// Returns nil if not cached.
- (nullable NSString *)cachedFilePathForURL:(NSString *)effectURL;

/// Downloads and caches an effect file. Calls completion on main queue.
- (void)cacheEffectWithURL:(NSString *)effectURL completion:(nullable void(^)(NSString * _Nullable localPath, NSError * _Nullable error))completion;

/// Preloads all effect URLs from the gift list in background.
- (void)preloadEffectsWithURLs:(NSArray<NSString *> *)urls;

/// Cancels all pending downloads.
- (void)cancelAllDownloads;

/// Clears the entire effect cache.
- (void)clearCache;

@end

NS_ASSUME_NONNULL_END
