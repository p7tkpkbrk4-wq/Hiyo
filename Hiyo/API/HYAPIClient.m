#import "HYAPIClient.h"
#import <AFNetworking/AFNetworking.h>

NSNotificationName const HYAPIClientUnauthorizedNotification = @"HYAPIClientUnauthorizedNotification";

static NSString * const kBaseURL = @"https://api.hiyochat.live/api/";
static NSString * const kTokenKey = @"hiyo_token";
static NSString * const kLanguageKey = @"HYLanguagePreference";

#ifdef DEBUG
#define HYLog(fmt, ...) NSLog((@"[HYAPIClient] " fmt), ##__VA_ARGS__)
#else
#define HYLog(fmt, ...)
#endif

@interface HYAPIClient ()

@property (nonatomic, strong) AFHTTPSessionManager *sessionManager;

@end

@implementation HYAPIClient

+ (instancetype)shared {
    static HYAPIClient *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[HYAPIClient alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        NSURL *baseURL = [NSURL URLWithString:kBaseURL];
        _sessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:baseURL];
        _sessionManager.requestSerializer = [AFJSONRequestSerializer serializer];
        _sessionManager.responseSerializer = [AFJSONResponseSerializer serializer];

        // Load saved token
        NSString *savedToken = [[NSUserDefaults standardUserDefaults] stringForKey:kTokenKey];
        if (savedToken) {
            _token = savedToken;
            [_sessionManager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", savedToken] forHTTPHeaderField:@"Authorization"];
        }

        // Accept-Language header (Android parity: respects user's selected language)
        NSString *savedLang = [[NSUserDefaults standardUserDefaults] stringForKey:kLanguageKey];
        NSString *acceptLanguage = @"en-US,en;q=0.9";
        if (savedLang.length > 0) {
            if ([savedLang isEqualToString:@"zh-CN"]) {
                acceptLanguage = @"zh-CN,zh;q=0.9,en;q=0.8";
            } else if ([savedLang isEqualToString:@"zh-TW"]) {
                acceptLanguage = @"zh-TW,zh-Hant;q=0.9,zh;q=0.8,en;q=0.7";
            } else if ([savedLang isEqualToString:@"en"]) {
                acceptLanguage = @"en-US,en;q=0.9";
            }
        } else {
            // Default to device locale
            NSString *deviceLang = [[NSLocale preferredLanguages] firstObject];
            if ([deviceLang hasPrefix:@"zh"]) {
                if ([deviceLang hasPrefix:@"zh-Hant"] || [deviceLang hasPrefix:@"zh-TW"]) {
                    acceptLanguage = @"zh-TW,zh-Hant;q=0.9,zh;q=0.8,en;q=0.7";
                } else {
                    acceptLanguage = @"zh-CN,zh;q=0.9,en;q=0.8";
                }
            }
        }
        [_sessionManager.requestSerializer setValue:acceptLanguage forHTTPHeaderField:@"Accept-Language"];
    }
    return self;
}

#pragma mark - Token Management

- (void)refreshTokenWithCompletion:(HYAPICompletion)completion {
    [self logRequest:@"POST" path:@"refresh_token" params:nil];

    [self.sessionManager POST:@"refresh_token" parameters:nil headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self logResponse:responseObject forMethod:@"POST" path:@"refresh_token"];
        [self handleRefreshTokenResponse:responseObject completion:completion];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self handleError:error completion:completion];
        // On refresh failure, clear token (Android parity)
        if (error) {
            [self clearToken];
        }
    }];
}

- (void)handleRefreshTokenResponse:(id)responseObject completion:(HYAPICompletion)completion {
    if ([responseObject isKindOfClass:[NSDictionary class]]) {
        NSDictionary *response = (NSDictionary *)responseObject;
        NSInteger code = [response[@"code"] integerValue];

        if (code == 0 || code == 200) {
            NSDictionary *data = response[@"data"];
            NSString *newToken = [data isKindOfClass:[NSDictionary class]] ? data[@"token"] : nil;
            if (newToken) {
                [self setToken:newToken];
            }
            if (completion) {
                completion(response, nil);
            }
        } else {
            NSString *message = response[@"message"] ?: @"刷新失败";
            NSError *error = [NSError errorWithDomain:@"HYAPIError" code:code userInfo:@{NSLocalizedDescriptionKey: message}];
            // Refresh failure clears token (Android parity)
            [self clearToken];
            if (completion) {
                completion(nil, error);
            }
        }
    } else {
        NSError *error = [NSError errorWithDomain:@"HYAPIError" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"无效响应"}];
        if (completion) {
            completion(nil, error);
        }
    }
}

- (void)updateAcceptLanguageHeader {
    NSString *savedLang = [[NSUserDefaults standardUserDefaults] stringForKey:kLanguageKey];
    NSString *acceptLanguage;

    if (!savedLang || [savedLang isEqualToString:@"system"] || savedLang.length == 0) {
        NSString *deviceLang = [[NSLocale preferredLanguages] firstObject];
        if ([deviceLang hasPrefix:@"zh"]) {
            if ([deviceLang hasPrefix:@"zh-Hant"] || [deviceLang hasPrefix:@"zh-TW"]) {
                acceptLanguage = @"zh-TW,zh-Hant;q=0.9,zh;q=0.8,en;q=0.7";
            } else {
                acceptLanguage = @"zh-CN,zh;q=0.9,en;q=0.8";
            }
        } else {
            acceptLanguage = @"en-US,en;q=0.9";
        }
    } else if ([savedLang isEqualToString:@"zh-Hans"]) {
        acceptLanguage = @"zh-CN,zh;q=0.9,en;q=0.8";
    } else if ([savedLang isEqualToString:@"zh-Hant"]) {
        acceptLanguage = @"zh-TW,zh-Hant;q=0.9,zh;q=0.8,en;q=0.7";
    } else {
        acceptLanguage = @"en-US,en;q=0.9";
    }

    [self.sessionManager.requestSerializer setValue:acceptLanguage forHTTPHeaderField:@"Accept-Language"];
}

- (void)setToken:(NSString *)token {
    _token = token;
    [[NSUserDefaults standardUserDefaults] setObject:token forKey:kTokenKey];
    [[NSUserDefaults standardUserDefaults] synchronize];

    if (token) {
        [self.sessionManager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];
    } else {
        [self.sessionManager.requestSerializer setValue:nil forHTTPHeaderField:@"Authorization"];
    }
}

- (void)clearToken {
    [self setToken:nil];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kTokenKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)isLoggedIn {
    return self.token != nil && self.token.length > 0;
}

#pragma mark - Auth APIs

- (void)sendCodeWithEmail:(NSString *)email completion:(HYAPICompletion)completion {
    NSDictionary *params = @{@"email": email};
    [self logRequest:@"POST" path:@"send_code" params:params];

    [self.sessionManager POST:@"send_code" parameters:params headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self logResponse:responseObject forMethod:@"POST" path:@"send_code"];
        [self handleResponse:responseObject completion:completion];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self handleError:error completion:completion];
    }];
}

- (void)registerWithEmail:(NSString *)email username:(NSString *)username password:(NSString *)password code:(NSString *)code avatarUrl:(NSString *)avatarUrl completion:(HYAPICompletion)completion {
    NSMutableDictionary *params = [@{
        @"email": email,
        @"user": username,
        @"passwd": password,
        @"verifycode": code
    } mutableCopy];
    if (avatarUrl.length > 0) {
        params[@"avatar_url"] = avatarUrl;
    }
    [self logRequest:@"POST" path:@"register" params:params];

    [self.sessionManager POST:@"register" parameters:params headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self logResponse:responseObject forMethod:@"POST" path:@"register"];
        [self handleResponse:responseObject completion:completion];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self handleError:error completion:completion];
    }];
}

- (void)loginWithEmail:(NSString *)email password:(NSString *)password completion:(HYAPICompletion)completion {
    NSDictionary *params = @{
        @"email": email,
        @"passwd": password
    };
    [self logRequest:@"POST" path:@"login" params:params];

    [self.sessionManager POST:@"login" parameters:params headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self logResponse:responseObject forMethod:@"POST" path:@"login"];
        [self handleResponse:responseObject completion:completion];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self handleError:error completion:completion];
    }];
}

#pragma mark - Match APIs

- (void)getMatchCardsWithLimit:(NSInteger)limit offset:(NSInteger)offset completion:(HYAPICompletion)completion {
    NSDictionary *params = @{
        @"limit": @(limit),
        @"offset": @(offset)
    };
    [self logRequest:@"GET" path:@"match/cards" params:params];

    [self.sessionManager GET:@"match/cards" parameters:params headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self logResponse:responseObject forMethod:@"GET" path:@"match/cards"];
        [self handleResponse:responseObject completion:completion];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self handleError:error completion:completion];
    }];
}

- (void)likeUserWithId:(NSInteger)userId completion:(HYLikeCompletion)completion {
    NSDictionary *params = @{@"target_id": @(userId)};
    [self logRequest:@"POST" path:@"match/like" params:params];

    [self.sessionManager POST:@"match/like" parameters:params headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self logResponse:responseObject forMethod:@"POST" path:@"match/like"];
        [self handleLikeResponse:responseObject completion:completion];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        HYLog(@"[ERROR] %@", error.localizedDescription);
        if (completion) {
            completion(nil, NO, error);
        }
    }];
}

- (void)handleLikeResponse:(id)responseObject completion:(HYLikeCompletion)completion {
    if ([responseObject isKindOfClass:[NSDictionary class]]) {
        NSDictionary *response = (NSDictionary *)responseObject;
        NSInteger code = [response[@"code"] integerValue];

        if (code == 0 || code == 200) {
            // Check matched field: could be in data.matched or top-level matched
            BOOL matched = NO;
            id matchedValue = response[@"matched"];
            if (!matchedValue) {
                matchedValue = response[@"data"][@"matched"];
            }
            if (matchedValue && [matchedValue isKindOfClass:[NSNumber class]]) {
                matched = [matchedValue boolValue];
            }
            if (completion) {
                completion(response, matched, nil);
            }
        } else {
            NSString *message = response[@"message"] ?: @"Unknown error";
            NSError *error = [NSError errorWithDomain:@"HYAPIError" code:code userInfo:@{NSLocalizedDescriptionKey: message}];
            if (completion) {
                completion(nil, NO, error);
            }
        }
    } else {
        NSError *error = [NSError errorWithDomain:@"HYAPIError" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Invalid response"}];
        if (completion) {
            completion(nil, NO, error);
        }
    }
}

- (void)dislikeUserWithId:(NSInteger)userId completion:(HYAPICompletion)completion {
    NSDictionary *params = @{@"target_id": @(userId)};
    [self logRequest:@"POST" path:@"match/dislike" params:params];

    [self.sessionManager POST:@"match/dislike" parameters:params headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self logResponse:responseObject forMethod:@"POST" path:@"match/dislike"];
        [self handleResponse:responseObject completion:completion];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self handleError:error completion:completion];
    }];
}

- (void)favoriteUserWithId:(NSInteger)userId completion:(HYAPICompletion)completion {
    NSDictionary *params = @{@"target_id": @(userId)};
    [self logRequest:@"POST" path:@"match/favorite" params:params];

    [self.sessionManager POST:@"match/favorite" parameters:params headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self logResponse:responseObject forMethod:@"POST" path:@"match/favorite"];
        [self handleResponse:responseObject completion:completion];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self handleError:error completion:completion];
    }];
}

#pragma mark - Posts APIs

- (void)getPostsWithPage:(NSInteger)page pageSize:(NSInteger)pageSize completion:(HYAPICompletion)completion {
    NSDictionary *params = @{
        @"page": @(page),
        @"page_size": @(pageSize)
    };
    [self logRequest:@"GET" path:@"posts" params:params];

    [self.sessionManager GET:@"posts" parameters:params headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self logResponse:responseObject forMethod:@"GET" path:@"posts"];
        [self handleResponse:responseObject completion:completion];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self handleError:error completion:completion];
    }];
}

- (void)getPostDetailWithId:(NSInteger)postId completion:(HYAPICompletion)completion {
    NSString *path = [NSString stringWithFormat:@"posts/%ld", (long)postId];
    [self logRequest:@"GET" path:path params:nil];

    [self.sessionManager GET:path parameters:nil headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self logResponse:responseObject forMethod:@"GET" path:path];
        [self handleResponse:responseObject completion:completion];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self handleError:error completion:completion];
    }];
}

- (void)createPostWithTitle:(NSString *)title content:(NSString *)content imageUrl:(NSString *)imageUrl completion:(HYAPICompletion)completion {
    NSDictionary *params = @{
        @"title": title ?: @"",
        @"content": content ?: @"",
        @"image_url": imageUrl ?: @""
    };
    [self logRequest:@"POST" path:@"posts" params:params];

    [self.sessionManager POST:@"posts" parameters:params headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self logResponse:responseObject forMethod:@"POST" path:@"posts"];
        [self handleResponse:responseObject completion:completion];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self handleError:error completion:completion];
    }];
}

- (void)likePostWithId:(NSInteger)postId completion:(HYAPICompletion)completion {
    NSString *path = [NSString stringWithFormat:@"posts/%ld/like", (long)postId];
    [self logRequest:@"POST" path:path params:nil];

    [self.sessionManager POST:path parameters:nil headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self logResponse:responseObject forMethod:@"POST" path:path];
        [self handleResponse:responseObject completion:completion];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self handleError:error completion:completion];
    }];
}

- (void)deletePostWithId:(NSInteger)postId completion:(HYAPICompletion)completion {
    NSString *path = [NSString stringWithFormat:@"posts/%ld", (long)postId];
    [self logRequest:@"DELETE" path:path params:nil];

    [self.sessionManager DELETE:path parameters:nil headers:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self logResponse:responseObject forMethod:@"DELETE" path:path];
        [self handleResponse:responseObject completion:completion];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self handleError:error completion:completion];
    }];
}

- (void)createCommentWithPostId:(NSInteger)postId content:(NSString *)content completion:(HYAPICompletion)completion {
    NSString *path = [NSString stringWithFormat:@"posts/%ld/comments", (long)postId];
    NSDictionary *params = @{@"content": content ?: @""};
    [self logRequest:@"POST" path:path params:params];

    [self.sessionManager POST:path parameters:params headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self logResponse:responseObject forMethod:@"POST" path:path];
        [self handleResponse:responseObject completion:completion];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self handleError:error completion:completion];
    }];
}

- (void)deleteCommentWithId:(NSInteger)commentId completion:(HYAPICompletion)completion {
    NSString *path = [NSString stringWithFormat:@"comments/%ld", (long)commentId];
    [self logRequest:@"DELETE" path:path params:nil];

    [self.sessionManager DELETE:path parameters:nil headers:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self logResponse:responseObject forMethod:@"DELETE" path:path];
        [self handleResponse:responseObject completion:completion];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self handleError:error completion:completion];
    }];
}

- (void)uploadImageWithData:(NSData *)imageData fileName:(NSString *)fileName completion:(HYAPICompletion)completion {
    [self.sessionManager POST:@"upload_image" parameters:nil headers:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        [formData appendPartWithFileData:imageData name:@"file" fileName:fileName mimeType:@"image/jpeg"];
    } progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self logResponse:responseObject forMethod:@"POST" path:@"upload_image"];
        [self handleResponse:responseObject completion:completion];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self handleError:error completion:completion];
    }];
}

- (void)getUploadTokenWithCompletion:(void (^)(NSString *, NSString *, NSError *))completion {
    [self.sessionManager GET:@"media/upload-token" parameters:nil headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self logResponse:responseObject forMethod:@"GET" path:@"media/upload-token"];
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            NSDictionary *data = responseObject[@"data"];
            if ([data isKindOfClass:[NSDictionary class]]) {
                NSString *apiBaseUrl = data[@"api_base_url"];
                NSString *token = data[@"token"];
                if (apiBaseUrl && token) {
                    if (completion) completion(apiBaseUrl, token, nil);
                    return;
                }
            }
        }
        NSError *error = [NSError errorWithDomain:@"HYAPIError" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"获取上传凭证失败"}];
        if (completion) completion(nil, nil, error);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self handleError:error completion:^(NSDictionary *response, NSError *err) {
            if (completion) completion(nil, nil, err ?: error);
        }];
    }];
}

- (void)uploadAvatarImage:(NSData *)imageData completion:(void (^)(NSString *, NSError *))completion {
    __weak typeof(self) weakSelf = self;

    [self getUploadTokenWithCompletion:^(NSString *apiBaseUrl, NSString *token, NSError *tokenError) {
        if (tokenError || !apiBaseUrl || !token) {
            if (completion) completion(nil, tokenError ?: [NSError errorWithDomain:@"HYAPIError" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"获取上传凭证失败"}]);
            return;
        }

        NSString *uploadUrl = [NSString stringWithFormat:@"%@/upload", apiBaseUrl];
        NSString *fileName = [NSString stringWithFormat:@"avatar_%@.jpg", @((NSInteger)[[NSDate date] timeIntervalSince1970])];
        [weakSelf uploadMultipartWithData:imageData fileName:fileName toUrl:uploadUrl token:token completion:completion];
    }];
}

- (void)uploadMultipartWithData:(NSData *)data
                      fileName:(NSString *)fileName
                         toUrl:(NSString *)urlString
                         token:(NSString *)token
                    completion:(void (^)(NSString *, NSError *))completion {

    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlString]];
    request.HTTPMethod = @"POST";

    NSString *boundary = [[NSUUID UUID] UUIDString];
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
    [request setValue:contentType forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];

    NSMutableData *body = [NSMutableData data];
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"file\"; filename=\"%@\"\r\n", fileName] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"Content-Type: image/jpeg\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:data];
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];

    request.HTTPBody = body;

    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable responseData, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) completion(nil, error);
            });
            return;
        }

        NSError *parseError = nil;
        NSDictionary *responseObject = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&parseError];

        NSString *imageUrl = nil;
        if (!parseError && [responseObject isKindOfClass:[NSDictionary class]]) {
            NSDictionary *resp = (NSDictionary *)responseObject;
            BOOL status = [resp[@"status"] boolValue];
            if (status) {
                NSDictionary *jsonData = resp[@"data"];
                NSDictionary *links = jsonData[@"links"];
                imageUrl = links[@"url"];
            }
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            if (imageUrl) {
                if (completion) completion(imageUrl, nil);
            } else {
                NSError *err = [NSError errorWithDomain:@"HYAPIError" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"解析上传响应失败"}];
                if (completion) completion(nil, err);
            }
        });
    }];
    [task resume];
}

#pragma mark - Notifications APIs

- (void)getUnreadCountWithCompletion:(HYAPICompletion)completion {
    [self logRequest:@"GET" path:@"notifications/unread_count" params:nil];

    [self.sessionManager GET:@"notifications/unread_count" parameters:nil headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self logResponse:responseObject forMethod:@"GET" path:@"notifications/unread_count"];
        [self handleResponse:responseObject completion:completion];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self handleError:error completion:completion];
    }];
}

- (void)markNotificationsReadWithCompletion:(HYAPICompletion)completion {
    [self logRequest:@"POST" path:@"notifications/read" params:nil];

    [self.sessionManager POST:@"notifications/read" parameters:nil headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self logResponse:responseObject forMethod:@"POST" path:@"notifications/read"];
        [self handleResponse:responseObject completion:completion];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self handleError:error completion:completion];
    }];
}

- (void)getNotificationsWithPage:(NSInteger)page pageSize:(NSInteger)pageSize completion:(HYAPICompletion)completion {
    NSDictionary *params = @{
        @"page": @(page),
        @"page_size": @(pageSize)
    };
    [self logRequest:@"GET" path:@"notifications" params:params];

    [self.sessionManager GET:@"notifications" parameters:params headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self logResponse:responseObject forMethod:@"GET" path:@"notifications"];
        [self handleResponse:responseObject completion:completion];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self handleError:error completion:completion];
    }];
}

#pragma mark - Conversations APIs

- (void)getConversationsWithLimit:(NSInteger)limit offset:(NSInteger)offset completion:(HYAPICompletion)completion {
    NSDictionary *params = @{
        @"limit": @(limit),
        @"offset": @(offset)
    };
    [self logRequest:@"GET" path:@"chat/conversations" params:params];

    [self.sessionManager GET:@"chat/conversations" parameters:params headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self logResponse:responseObject forMethod:@"GET" path:@"chat/conversations"];
        [self handleResponse:responseObject completion:completion];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self handleError:error completion:completion];
    }];
}

#pragma mark - Chat APIs

- (void)getChatHistoryWithPartnerId:(NSString *)partnerId limit:(NSInteger)limit offset:(NSInteger)offset completion:(HYAPICompletion)completion {
    NSString *path = [NSString stringWithFormat:@"chat/messages/%@", partnerId];
    NSDictionary *params = @{
        @"limit": @(limit),
        @"offset": @(offset)
    };
    [self logRequest:@"GET" path:path params:params];

    [self.sessionManager GET:path parameters:params headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self logResponse:responseObject forMethod:@"GET" path:path];
        [self handleResponse:responseObject completion:completion];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self handleError:error completion:completion];
    }];
}

- (void)sendMessageToPartnerId:(NSString *)partnerId content:(NSString *)content type:(NSString *)type extra:(NSString *)extra completion:(HYAPICompletion)completion {
    NSDictionary *params = @{
        @"target_id": partnerId ?: @"",
        @"content": content ?: @"",
        @"type": type ?: @"text",
        @"extra": extra ?: @""
    };
    [self logRequest:@"POST" path:@"chat/send" params:params];

    [self.sessionManager POST:@"chat/send" parameters:params headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self logResponse:responseObject forMethod:@"POST" path:@"chat/send"];
        [self handleResponse:responseObject completion:completion];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self handleError:error completion:completion];
    }];
}

- (void)markChatReadWithPartnerId:(NSString *)partnerId chatType:(NSInteger)chatType completion:(HYAPICompletion)completion {
    NSDictionary *params = @{
        @"target_id": partnerId ?: @"",
        @"chat_type": @(chatType)
    };
    [self logRequest:@"POST" path:@"chat/read" params:params];

    [self.sessionManager POST:@"chat/read" parameters:params headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self logResponse:responseObject forMethod:@"POST" path:@"chat/read"];
        [self handleResponse:responseObject completion:completion];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self handleError:error completion:completion];
    }];
}

- (void)searchUsersWithKeyword:(NSString *)keyword completion:(HYAPICompletion)completion {
    NSDictionary *params = @{@"keyword": keyword ?: @""};
    [self logRequest:@"GET" path:@"search/users" params:params];

    [self.sessionManager GET:@"search/users" parameters:params headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self logResponse:responseObject forMethod:@"GET" path:@"search/users"];
        [self handleResponse:responseObject completion:completion];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self handleError:error completion:completion];
    }];
}

#pragma mark - User APIs

- (void)getUserInfoWithId:(NSString *)userId completion:(HYAPICompletion)completion {
    NSString *path = [NSString stringWithFormat:@"users/%@", userId];
    [self logRequest:@"GET" path:path params:nil];

    [self.sessionManager GET:path parameters:nil headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self logResponse:responseObject forMethod:@"GET" path:path];
        [self handleResponse:responseObject completion:completion];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self handleError:error completion:completion];
    }];
}

- (void)completeProfileWithData:(NSDictionary *)data completion:(HYAPICompletion)completion {
    [self logRequest:@"POST" path:@"user/complete_profile" params:data];

    [self.sessionManager POST:@"user/complete_profile" parameters:data headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self logResponse:responseObject forMethod:@"POST" path:@"user/complete_profile"];
        [self handleResponse:responseObject completion:completion];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self handleError:error completion:completion];
    }];
}

#pragma mark - Profile APIs

- (void)updateProfileWithData:(NSDictionary *)data completion:(HYAPICompletion)completion {
    [self logRequest:@"POST" path:@"user/update" params:data];

    [self.sessionManager POST:@"user/update" parameters:data headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self logResponse:responseObject forMethod:@"POST" path:@"user/update"];
        [self handleResponse:responseObject completion:completion];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self handleError:error completion:completion];
    }];
}

- (void)followUserWithId:(NSString *)userId completion:(HYAPICompletion)completion {
    NSString *path = [NSString stringWithFormat:@"users/%@/follow", userId];
    [self logRequest:@"POST" path:path params:nil];

    [self.sessionManager POST:path parameters:nil headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self logResponse:responseObject forMethod:@"POST" path:path];
        [self handleResponse:responseObject completion:completion];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self handleError:error completion:completion];
    }];
}

- (void)unfollowUserWithId:(NSString *)userId completion:(HYAPICompletion)completion {
    NSString *path = [NSString stringWithFormat:@"users/%@/follow", userId];
    [self logRequest:@"DELETE" path:path params:nil];

    [self.sessionManager DELETE:path parameters:nil headers:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self logResponse:responseObject forMethod:@"DELETE" path:path];
        [self handleResponse:responseObject completion:completion];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self handleError:error completion:completion];
    }];
}

- (void)getFollowersWithUserId:(NSString *)userId limit:(NSInteger)limit lastId:(NSInteger)lastId completion:(HYAPICompletion)completion {
    NSString *path = [NSString stringWithFormat:@"users/%@/followers", userId];
    NSDictionary *params = @{@"limit": @(limit), @"last_id": @(lastId)};
    [self logRequest:@"GET" path:path params:params];

    [self.sessionManager GET:path parameters:params headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self logResponse:responseObject forMethod:@"GET" path:path];
        [self handleResponse:responseObject completion:completion];
    } failure:^(NSURLSessionDataTask * _Nonnull task, NSError * _Nonnull error) {
        [self handleError:error completion:completion];
    }];
}

- (void)getFollowingsWithUserId:(NSString *)userId limit:(NSInteger)limit lastId:(NSInteger)lastId completion:(HYAPICompletion)completion {
    NSString *path = [NSString stringWithFormat:@"users/%@/followings", userId];
    NSDictionary *params = @{@"limit": @(limit), @"last_id": @(lastId)};
    [self logRequest:@"GET" path:path params:params];

    [self.sessionManager GET:path parameters:params headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self logResponse:responseObject forMethod:@"GET" path:path];
        [self handleResponse:responseObject completion:completion];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self handleError:error completion:completion];
    }];
}

- (void)addPhotoWithUrl:(NSString *)photoUrl isWall:(BOOL)isWall completion:(HYAPICompletion)completion {
    NSDictionary *params = @{@"photo_url": photoUrl ?: @"", @"is_wall": @(isWall ? 1 : 0)};
    [self logRequest:@"POST" path:@"user/photo" params:params];

    [self.sessionManager POST:@"user/photo" parameters:params headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self logResponse:responseObject forMethod:@"POST" path:@"user/photo"];
        [self handleResponse:responseObject completion:completion];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self handleError:error completion:completion];
    }];
}

- (void)deletePhotoWithId:(NSInteger)photoId completion:(HYAPICompletion)completion {
    NSString *path = [NSString stringWithFormat:@"user/photo/%ld", (long)photoId];
    [self logRequest:@"DELETE" path:path params:nil];

    [self.sessionManager DELETE:path parameters:nil headers:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self logResponse:responseObject forMethod:@"DELETE" path:path];
        [self handleResponse:responseObject completion:completion];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self handleError:error completion:completion];
    }];
}

- (void)getLocationsWithCompletion:(HYAPICompletion)completion {
    [self logRequest:@"GET" path:@"common/locations" params:nil];

    [self.sessionManager GET:@"common/locations" parameters:nil headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self logResponse:responseObject forMethod:@"GET" path:@"common/locations"];
        [self handleResponse:responseObject completion:completion];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self handleError:error completion:completion];
    }];
}

- (void)getInterestsWithCompletion:(HYAPICompletion)completion {
    [self logRequest:@"GET" path:@"common/interests" params:nil];

    [self.sessionManager GET:@"common/interests" parameters:nil headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self logResponse:responseObject forMethod:@"GET" path:@"common/interests"];
        [self handleResponse:responseObject completion:completion];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self handleError:error completion:completion];
    }];
}

- (void)submitFeedbackWithContent:(NSString *)content completion:(HYAPICompletion)completion {
    NSDictionary *params = @{@"content": content ?: @""};
    [self logRequest:@"POST" path:@"feedback" params:params];

    [self.sessionManager POST:@"feedback" parameters:params headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self logResponse:responseObject forMethod:@"POST" path:@"feedback"];
        [self handleResponse:responseObject completion:completion];
    } failure:^(NSURLSessionDataTask * _Nonnull task, NSError * _Nonnull error) {
        [self handleError:error completion:completion];
    }];
}

- (void)getMyPostsWithPage:(NSInteger)page pageSize:(NSInteger)pageSize completion:(HYAPICompletion)completion {
    NSDictionary *params = @{@"page": @(page), @"page_size": @(pageSize)};
    [self logRequest:@"GET" path:@"posts/mine" params:params];

    [self.sessionManager GET:@"posts/mine" parameters:params headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self logResponse:responseObject forMethod:@"GET" path:@"posts/mine"];
        [self handleResponse:responseObject completion:completion];
    } failure:^(NSURLSessionDataTask * _Nonnull task, NSError * _Nonnull error) {
        [self handleError:error completion:completion];
    }];
}

#pragma mark - Response Handling

- (void)handleResponse:(id)responseObject completion:(HYAPICompletion)completion {
    if ([responseObject isKindOfClass:[NSDictionary class]]) {
        NSDictionary *response = (NSDictionary *)responseObject;
        NSInteger code = [response[@"code"] integerValue];

        if (code == 0 || code == 200) {
            if (completion) {
                completion(response, nil);
            }
        } else {
            NSString *message = response[@"message"] ?: @"Unknown error";
            NSError *error = [NSError errorWithDomain:@"HYAPIError" code:code userInfo:@{NSLocalizedDescriptionKey: message}];

            // Check for unauthorized error (code -1 with "未提供认证信息")
            if (code == -1 && [message containsString:@"认证"]) {
                [self clearToken];
                [[NSNotificationCenter defaultCenter] postNotificationName:HYAPIClientUnauthorizedNotification object:nil];
            }

            if (completion) {
                completion(nil, error);
            }
        }
    } else {
        NSError *error = [NSError errorWithDomain:@"HYAPIError" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Invalid response"}];
        if (completion) {
            completion(nil, error);
        }
    }
}

- (void)handleError:(NSError *)error completion:(HYAPICompletion)completion {
    HYLog(@"[ERROR] %@", error.localizedDescription);
    if (completion) {
        completion(nil, error);
    }
}

#pragma mark - Logging Helpers

- (void)logRequest:(NSString *)method path:(NSString *)path params:(NSDictionary *)params {
    NSString *paramString = @"";
    if (params.count > 0) {
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:params options:0 error:&error];
        if (!error) {
            paramString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        }
    }
    HYLog(@"[REQUEST] %@ %@%@", method, kBaseURL, path);
    if (paramString.length > 0) {
        HYLog(@"[PARAMS] %@", paramString);
    }
}

#pragma mark - Background Image

- (void)uploadBackgroundImage:(NSData *)imageData completion:(void (^)(NSString * _Nullable, NSError * _Nullable))completion {
    [self getUploadTokenWithCompletion:^(NSString * _Nullable apiBaseUrl, NSString * _Nullable token, NSError * _Nullable error) {
        if (error || !token || !apiBaseUrl) {
            if (completion) completion(nil, error);
            return;
        }

        NSString *fileName = [NSString stringWithFormat:@"bg_%@.jpg", @((NSInteger)[[NSDate date] timeIntervalSince1970])];
        [self uploadMultipartWithData:imageData fileName:fileName toUrl:apiBaseUrl token:token completion:completion];
    }];
}

#pragma mark - Settings APIs

- (void)updateNotificationSettings:(NSDictionary *)settings completion:(HYAPICompletion)completion {
    [self logRequest:@"POST" path:@"user/notification_settings" params:settings];

    [self.sessionManager POST:@"user/notification_settings" parameters:settings headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self logResponse:responseObject forMethod:@"POST" path:@"user/notification_settings"];
        [self handleResponse:responseObject completion:completion];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self handleError:error completion:completion];
    }];
}

- (void)updatePrivacySettings:(NSDictionary *)settings completion:(HYAPICompletion)completion {
    [self logRequest:@"POST" path:@"user/privacy_settings" params:settings];

    [self.sessionManager POST:@"user/privacy_settings" parameters:settings headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self logResponse:responseObject forMethod:@"POST" path:@"user/privacy_settings"];
        [self handleResponse:responseObject completion:completion];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self handleError:error completion:completion];
    }];
}

- (void)changePasswordWithOldPassword:(NSString *)oldPassword newPassword:(NSString *)newPassword completion:(HYAPICompletion)completion {
    NSDictionary *params = @{
        @"old_password": oldPassword,
        @"new_password": newPassword
    };
    [self logRequest:@"POST" path:@"user/change_password" params:params];

    [self.sessionManager POST:@"user/change_password" parameters:params headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self logResponse:responseObject forMethod:@"POST" path:@"user/change_password"];
        [self handleResponse:responseObject completion:completion];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self handleError:error completion:completion];
    }];
}

#pragma mark - Favorites & Matches

- (void)getFavoritesWithPage:(NSInteger)page pageSize:(NSInteger)pageSize completion:(HYAPICompletion)completion {
    NSDictionary *params = @{@"page": @(page), @"page_size": @(pageSize)};
    [self logRequest:@"GET" path:@"match/favorites" params:params];

    [self.sessionManager GET:@"match/favorites" parameters:params headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self logResponse:responseObject forMethod:@"GET" path:@"match/favorites"];
        [self handleResponse:responseObject completion:completion];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self handleError:error completion:completion];
    }];
}

- (void)getMatchesWithPage:(NSInteger)page pageSize:(NSInteger)pageSize completion:(HYAPICompletion)completion {
    NSDictionary *params = @{@"page": @(page), @"page_size": @(pageSize)};
    [self logRequest:@"GET" path:@"match/matches" params:params];

    [self.sessionManager GET:@"match/matches" parameters:params headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self logResponse:responseObject forMethod:@"GET" path:@"match/matches"];
        [self handleResponse:responseObject completion:completion];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self handleError:error completion:completion];
    }];
}

- (void)deleteConversationWithId:(NSString *)conversationId completion:(HYAPICompletion)completion {
    NSDictionary *params = @{@"conversation_id": conversationId};
    [self logRequest:@"POST" path:@"chat/conversations/delete" params:params];

    [self.sessionManager POST:@"chat/conversations/delete" parameters:params headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self logResponse:responseObject forMethod:@"POST" path:@"chat/conversations/delete"];
        [self handleResponse:responseObject completion:completion];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self handleError:error completion:completion];
    }];
}

- (void)logResponse:(NSDictionary *)response forMethod:(NSString *)method path:(NSString *)path {
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:response options:NSJSONWritingPrettyPrinted error:&error];
    NSString *responseString = @"";
    if (!error) {
        responseString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    HYLog(@"[RESPONSE] %@ %@", method, path);
    HYLog(@"[RESPONSE_DATA] %@", responseString);
}

#pragma mark - Wallet

- (void)getWalletBalanceWithCompletion:(HYAPICompletion)completion {
    [self logRequest:@"GET" path:@"wallet/balance" params:nil];

    [self.sessionManager GET:@"wallet/balance" parameters:nil headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self logResponse:responseObject forMethod:@"GET" path:@"wallet/balance"];
        [self handleResponse:responseObject completion:completion];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self handleError:error completion:completion];
    }];
}

- (void)getWalletFlowsWithType:(NSString *)type page:(NSInteger)page pageSize:(NSInteger)pageSize completion:(HYAPICompletion)completion {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"page"] = @(page);
    params[@"page_size"] = @(pageSize);
    if (type.length > 0) {
        params[@"type"] = type;
    }
    [self logRequest:@"GET" path:@"wallet/flows" params:params];

    [self.sessionManager GET:@"wallet/flows" parameters:params headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self logResponse:responseObject forMethod:@"GET" path:@"wallet/flows"];
        [self handleResponse:responseObject completion:completion];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self handleError:error completion:completion];
    }];
}

#pragma mark - Recharge

- (void)getCoinProductsWithCompletion:(HYAPICompletion)completion {
    [self logRequest:@"GET" path:@"coin/products" params:@{@"platform": @"ios"}];

    [self.sessionManager GET:@"coin/products" parameters:@{@"platform": @"ios"} headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self logResponse:responseObject forMethod:@"GET" path:@"coin/products"];
        [self handleResponse:responseObject completion:completion];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self handleError:error completion:completion];
    }];
}

- (void)createRechargeOrderWithProductId:(NSInteger)productId completion:(HYAPICompletion)completion {
    NSDictionary *params = @{@"product_id": @(productId)};
    [self logRequest:@"POST" path:@"recharge/create" params:params];

    [self.sessionManager POST:@"recharge/create" parameters:params headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self logResponse:responseObject forMethod:@"POST" path:@"recharge/create"];
        [self handleResponse:responseObject completion:completion];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self handleError:error completion:completion];
    }];
}

- (void)verifyRechargeWithOrderNo:(NSString *)orderNo purchaseToken:(NSString *)purchaseToken completion:(HYAPICompletion)completion {
    NSDictionary *params = @{@"order_no": orderNo, @"purchase_token": purchaseToken};
    [self logRequest:@"POST" path:@"recharge/verify" params:params];

    [self.sessionManager POST:@"recharge/verify" parameters:params headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self logResponse:responseObject forMethod:@"POST" path:@"recharge/verify"];
        [self handleResponse:responseObject completion:completion];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self handleError:error completion:completion];
    }];
}

- (void)getRechargeOrdersWithPage:(NSInteger)page pageSize:(NSInteger)pageSize completion:(HYAPICompletion)completion {
    NSDictionary *params = @{@"page": @(page), @"page_size": @(pageSize)};
    [self logRequest:@"GET" path:@"recharge/orders" params:params];

    [self.sessionManager GET:@"recharge/orders" parameters:params headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self logResponse:responseObject forMethod:@"GET" path:@"recharge/orders"];
        [self handleResponse:responseObject completion:completion];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self handleError:error completion:completion];
    }];
}

#pragma mark - Subscription / VIP

- (void)getSubscriptionPlansWithCompletion:(HYAPICompletion)completion {
    [self logRequest:@"GET" path:@"subscription/plans" params:@{@"platform": @"ios"}];

    [self.sessionManager GET:@"subscription/plans" parameters:@{@"platform": @"ios"} headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self logResponse:responseObject forMethod:@"GET" path:@"subscription/plans"];
        [self handleResponse:responseObject completion:completion];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self handleError:error completion:completion];
    }];
}

- (void)verifySubscriptionWithPlanId:(NSInteger)planId purchaseToken:(NSString *)purchaseToken completion:(HYAPICompletion)completion {
    NSDictionary *params = @{@"plan_id": @(planId), @"purchase_token": purchaseToken, @"platform": @"ios"};
    [self logRequest:@"POST" path:@"subscription/verify" params:params];

    [self.sessionManager POST:@"subscription/verify" parameters:params headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self logResponse:responseObject forMethod:@"POST" path:@"subscription/verify"];
        [self handleResponse:responseObject completion:completion];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self handleError:error completion:completion];
    }];
}

- (void)getVipStatusWithCompletion:(HYAPICompletion)completion {
    [self logRequest:@"GET" path:@"subscription/status" params:nil];

    [self.sessionManager GET:@"subscription/status" parameters:nil headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self logResponse:responseObject forMethod:@"GET" path:@"subscription/status"];
        [self handleResponse:responseObject completion:completion];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self handleError:error completion:completion];
    }];
}

- (void)getVipPrivilegesWithCompletion:(HYAPICompletion)completion {
    [self logRequest:@"GET" path:@"vip/privileges" params:nil];

    [self.sessionManager GET:@"vip/privileges" parameters:nil headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self logResponse:responseObject forMethod:@"GET" path:@"vip/privileges"];
        [self handleResponse:responseObject completion:completion];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self handleError:error completion:completion];
    }];
}

#pragma mark - Checkin

- (void)getCheckinStatusWithCompletion:(HYAPICompletion)completion {
    [self logRequest:@"GET" path:@"checkin/status" params:nil];

    [self.sessionManager GET:@"checkin/status" parameters:nil headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self logResponse:responseObject forMethod:@"GET" path:@"checkin/status"];
        [self handleResponse:responseObject completion:completion];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self handleError:error completion:completion];
    }];
}

- (void)performCheckinWithCompletion:(HYAPICompletion)completion {
    [self logRequest:@"POST" path:@"checkin" params:nil];

    [self.sessionManager POST:@"checkin" parameters:nil headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self logResponse:responseObject forMethod:@"POST" path:@"checkin"];
        [self handleResponse:responseObject completion:completion];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self handleError:error completion:completion];
    }];
}

#pragma mark - Gift

- (void)getGiftsWithCompletion:(HYAPICompletion)completion {
    [self logRequest:@"GET" path:@"gifts" params:nil];

    [self.sessionManager GET:@"gifts" parameters:nil headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self logResponse:responseObject forMethod:@"GET" path:@"gifts"];
        [self handleResponse:responseObject completion:completion];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self handleError:error completion:completion];
    }];
}

- (void)sendGiftToReceiverId:(NSInteger)receiverId giftId:(NSInteger)giftId quantity:(NSInteger)quantity completion:(HYAPICompletion)completion {
    NSDictionary *params = @{
        @"receiver_id": @(receiverId),
        @"gift_id": @(giftId),
        @"quantity": @(quantity)
    };
    [self logRequest:@"POST" path:@"gifts/send" params:params];

    [self.sessionManager POST:@"gifts/send" parameters:params headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self logResponse:responseObject forMethod:@"POST" path:@"gifts/send"];
        [self handleResponse:responseObject completion:completion];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self handleError:error completion:completion];
    }];
}

- (void)getGiftOrdersWithDirection:(NSString *)direction page:(NSInteger)page pageSize:(NSInteger)pageSize completion:(HYAPICompletion)completion {
    NSDictionary *params = @{
        @"direction": direction,
        @"page": @(page),
        @"page_size": @(pageSize)
    };
    [self logRequest:@"GET" path:@"gifts/orders" params:params];

    [self.sessionManager GET:@"gifts/orders" parameters:params headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self logResponse:responseObject forMethod:@"GET" path:@"gifts/orders"];
        [self handleResponse:responseObject completion:completion];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self handleError:error completion:completion];
    }];
}

#pragma mark - Social

- (void)getWhoLikedMeWithPage:(NSInteger)page pageSize:(NSInteger)pageSize completion:(HYAPICompletion)completion {
    NSDictionary *params = @{@"page": @(page), @"page_size": @(pageSize)};
    [self logRequest:@"GET" path:@"match/who-liked-me" params:params];

    [self.sessionManager GET:@"match/who-liked-me" parameters:params headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self logResponse:responseObject forMethod:@"GET" path:@"match/who-liked-me"];
        [self handleResponse:responseObject completion:completion];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self handleError:error completion:completion];
    }];
}

- (void)getProfileVisitorsWithPage:(NSInteger)page pageSize:(NSInteger)pageSize completion:(HYAPICompletion)completion {
    NSDictionary *params = @{@"page": @(page), @"page_size": @(pageSize)};
    [self logRequest:@"GET" path:@"user/profile-visitors" params:params];

    [self.sessionManager GET:@"user/profile-visitors" parameters:params headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self logResponse:responseObject forMethod:@"GET" path:@"user/profile-visitors"];
        [self handleResponse:responseObject completion:completion];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self handleError:error completion:completion];
    }];
}

@end
