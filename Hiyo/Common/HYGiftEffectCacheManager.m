#import "HYGiftEffectCacheManager.h"
#import <CommonCrypto/CommonDigest.h>
#import <AFNetworking/AFNetworking.h>

@interface HYGiftEffectCacheManager ()
@property (nonatomic, strong) AFHTTPSessionManager *sessionManager;
@property (nonatomic, strong) NSString *cacheDir;
@property (nonatomic, strong) NSMutableDictionary<NSString *, void(^)(NSString *, NSError *)> *pendingCompletions;
@property (nonatomic, strong) NSMutableSet<NSString *> *pendingURLs;
@property (nonatomic, strong) dispatch_queue_t downloadQueue;
@end

@implementation HYGiftEffectCacheManager

+ (instancetype)shared {
    static HYGiftEffectCacheManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ instance = [[HYGiftEffectCacheManager alloc] init]; });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _sessionManager = [[AFHTTPSessionManager alloc] init];
        _sessionManager.responseSerializer = [AFHTTPResponseSerializer serializer];
        _pendingCompletions = [NSMutableDictionary dictionary];
        _pendingURLs = [NSMutableSet set];
        _downloadQueue = dispatch_queue_create("com.hiyo.giftEffectCache", DISPATCH_QUEUE_SERIAL);

        NSString *docs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
        _cacheDir = [docs stringByAppendingPathComponent:@"gift_effects"];
        [[NSFileManager defaultManager] createDirectoryAtPath:_cacheDir
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:nil];
    }
    return self;
}

- (NSString *)cachedFilePathForURL:(NSString *)effectURL {
    if (!effectURL || effectURL.length == 0) return nil;
    NSString *filename = [self md5:effectURL];
    NSString *path = [self.cacheDir stringByAppendingPathComponent:filename];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
        if ([attrs[NSFileSize] unsignedIntegerValue] > 0) return path;
    }
    return nil;
}

- (void)cacheEffectWithURL:(NSString *)effectURL
                completion:(void(^)(NSString *, NSError *))completion {
    if (!effectURL || effectURL.length == 0) {
        if (completion) dispatch_async(dispatch_get_main_queue(), ^{
            completion(nil, nil);
        });
        return;
    }

    // Check cache first
    NSString *cached = [self cachedFilePathForURL:effectURL];
    if (cached) {
        if (completion) dispatch_async(dispatch_get_main_queue(), ^{
            completion(cached, nil);
        });
        return;
    }

    // Deduplicate concurrent downloads
    @synchronized (self.pendingURLs) {
        if ([self.pendingURLs containsObject:effectURL]) {
            if (completion) {
                self.pendingCompletions[effectURL] = completion;
            }
            return;
        }
        [self.pendingURLs addObject:effectURL];
        if (completion) {
            self.pendingCompletions[effectURL] = completion;
        }
    }

    // Encode non-ASCII characters in URL path
    NSString *encodedURL = [self encodedURL:effectURL];

    [self.sessionManager GET:encodedURL
                  parameters:nil
                     headers:nil
                    progress:nil
                     success:^(NSURLSessionDataTask *task, id responseObject) {
        NSData *data = (NSData *)responseObject;
        if (!data || data.length == 0) {
            [self finishWithURL:effectURL path:nil error:[NSError errorWithDomain:@"HYGiftEffectCache"
                                                                              code:-1
                                                                          userInfo:@{NSLocalizedDescriptionKey: @"Empty response"}]];
            return;
        }

        dispatch_async(self.downloadQueue, ^{
            NSString *filename = [self md5:effectURL];
            NSString *tmpPath = [self.cacheDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.tmp", filename]];
            NSString *finalPath = [self.cacheDir stringByAppendingPathComponent:filename];

            BOOL written = [data writeToFile:tmpPath atomically:YES];
            if (written) {
                [[NSFileManager defaultManager] moveItemAtPath:tmpPath toPath:finalPath error:nil];
                [self finishWithURL:effectURL path:finalPath error:nil];
            } else {
                [self finishWithURL:effectURL path:nil error:[NSError errorWithDomain:@"HYGiftEffectCache"
                                                                                code:-2
                                                                            userInfo:@{NSLocalizedDescriptionKey: @"Write failed"}]];
            }
        });
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        [self finishWithURL:effectURL path:nil error:error];
    }];
}

- (void)finishWithURL:(NSString *)url path:(NSString *)path error:(NSError *)error {
    void(^completion)(NSString *, NSError *) = self.pendingCompletions[url];
    @synchronized (self.pendingURLs) {
        [self.pendingURLs removeObject:url];
        [self.pendingCompletions removeObjectForKey:url];
    }
    if (completion) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(path, error);
        });
    }
}

- (void)preloadEffectsWithURLs:(NSArray<NSString *> *)urls {
    dispatch_async(dispatch_get_main_queue(), ^{
        for (NSString *url in urls) {
            if ([url isKindOfClass:[NSString class]] && url.length > 0) {
                [self cacheEffectWithURL:url completion:nil];
            }
        }
    });
}

- (void)cancelAllDownloads {
    [self.sessionManager.operationQueue cancelAllOperations];
    @synchronized (self.pendingURLs) {
        [self.pendingURLs removeAllObjects];
        [self.pendingCompletions removeAllObjects];
    }
}

- (void)clearCache {
    [self cancelAllDownloads];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *files = [fm contentsOfDirectoryAtPath:self.cacheDir error:nil];
    for (NSString *file in files) {
        [fm removeItemAtPath:[self.cacheDir stringByAppendingPathComponent:file] error:nil];
    }
}

#pragma mark - Helpers

- (NSString *)md5:(NSString *)input {
    const char *cStr = [input UTF8String];
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5(cStr, (CC_LONG)strlen(cStr), digest);
    return [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            digest[0], digest[1], digest[2], digest[3],
            digest[4], digest[5], digest[6], digest[7],
            digest[8], digest[9], digest[10], digest[11],
            digest[12], digest[13], digest[14], digest[15]];
}

- (NSString *)encodedURL:(NSString *)url {
    NSURL *u = [NSURL URLWithString:url];
    if (!u) return url;
    NSString *scheme = u.scheme ?: @"";
    NSString *host = u.host ?: @"";
    NSString *path = u.path ?: @"";
    NSString *query = u.query ?: @"";

    NSMutableString *encoded = [NSMutableString string];
    for (NSUInteger i = 0; i < path.length; i++) {
        unichar c = [path characterAtIndex:i];
        if (c > 127 || c == '%' || c == '#' || c == '?') {
            [encoded appendFormat:@"%%%02X", (unsigned char)c];
        } else {
            [encoded appendFormat:@"%C", c];
        }
    }

    NSString *result = [NSString stringWithFormat:@"%@://%@%@", scheme, host, encoded];
    if (query.length > 0) result = [result stringByAppendingFormat:@"?%@", query];
    return result;
}

@end
