#import "HYGiftEffectOverlayView.h"
#import "HYGiftEffectCacheManager.h"
#import <AVFoundation/AVFoundation.h>
#import <SDWebImage/SDWebImage.h>
#import <Masonry/Masonry.h>
#import <SVGAPlayer/SVGAPlayer.h>
#import <SVGAPlayer/SVGAImageView.h>
#import <SVGAPlayer/SVGAParser.h>

static const NSTimeInterval kFallbackTimeout = 60.0;

@interface HYGiftEffectOverlayView () <SVGAPlayerDelegate>
@property (nonatomic, copy) NSString *effectURL;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) NSTimer *fallbackTimer;
@property (nonatomic, strong) AVPlayer *avPlayer;
@property (nonatomic, strong) AVPlayerLayer *avPlayerLayer;
@property (nonatomic, strong) id playbackEndObserver;
@property (nonatomic, strong) SDAnimatedImageView *animatedImageView;
@property (nonatomic, strong) SVGAImageView *svgaPlayerView;
@end

@implementation HYGiftEffectOverlayView

+ (void)showWithEffectURL:(NSString *)effectURL
                   onView:(UIView *)parentView
               senderName:(NSString *)senderName {
    if (!effectURL || effectURL.length == 0) return;
    NSString *cachedPath = [[HYGiftEffectCacheManager shared] cachedFilePathForURL:effectURL];
    [self showWithCachedFilePath:cachedPath effectURL:effectURL onView:parentView senderName:senderName];
}

+ (void)showWithCachedFilePath:(NSString *)localPath
                     effectURL:(NSString *)effectURL
                        onView:(UIView *)parentView
                    senderName:(NSString *)senderName {
    if (!effectURL || effectURL.length == 0) return;

    HYGiftEffectOverlayView *overlay = [[HYGiftEffectOverlayView alloc] initWithFrame:parentView.bounds];
    overlay.effectURL = effectURL;
    overlay.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.25];
    overlay.alpha = 0;
    overlay.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:overlay action:@selector(dismiss)];
    [overlay addGestureRecognizer:tap];

    [parentView addSubview:overlay];

    // Sender name label
    if (senderName.length > 0) {
        overlay.nameLabel = [[UILabel alloc] init];
        overlay.nameLabel.text = [NSString stringWithFormat:@"%@ sent a gift", senderName];
        overlay.nameLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
        overlay.nameLabel.textColor = [UIColor whiteColor];
        overlay.nameLabel.textAlignment = NSTextAlignmentCenter;
        overlay.nameLabel.layer.shadowColor = [UIColor blackColor].CGColor;
        overlay.nameLabel.layer.shadowOffset = CGSizeMake(0, 1);
        overlay.nameLabel.layer.shadowOpacity = 0.8;
        overlay.nameLabel.layer.shadowRadius = 2;
        [overlay addSubview:overlay.nameLabel];

        [overlay.nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(overlay);
            make.bottom.equalTo(overlay.mas_centerY).offset(-120);
        }];
    }

    // Content container
    overlay.contentView = [[UIView alloc] init];
    overlay.contentView.backgroundColor = [UIColor clearColor];
    [overlay addSubview:overlay.contentView];
    [overlay.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(overlay);
        make.width.equalTo(overlay).multipliedBy(0.85);
        make.height.equalTo(overlay).multipliedBy(0.6);
    }];

    // Fade in
    [UIView animateWithDuration:0.25 animations:^{
        overlay.alpha = 1;
    }];

    // 60s fallback timeout
    overlay.fallbackTimer = [NSTimer scheduledTimerWithTimeInterval:kFallbackTimeout
                                                            target:overlay
                                                          selector:@selector(dismiss)
                                                          userInfo:nil
                                                           repeats:NO];

    // Load and play
    if (localPath && [[NSFileManager defaultManager] fileExistsAtPath:localPath]) {
        [overlay playEffectFromFile:localPath];
    } else {
        [[HYGiftEffectCacheManager shared] cacheEffectWithURL:effectURL completion:^(NSString *path, NSError *error) {
            if (path && [[NSFileManager defaultManager] fileExistsAtPath:path]) {
                [overlay playEffectFromFile:path];
            } else {
                [overlay playEffectFromURL:effectURL];
            }
        }];
    }
}

- (void)playEffectFromFile:(NSString *)path {
    NSString *ext = [[path pathExtension] lowercaseString];
    if ([@[@"svga"] containsObject:ext]) {
        [self playSVGAFromFile:path];
    } else if ([@[@"mp4", @"webm", @"mov"] containsObject:ext]) {
        [self playVideoFromFile:path];
    } else {
        // GIF / WebP / APNG — SDAnimatedImageView
        [self playAnimatedImageFromURL:[NSURL fileURLWithPath:path]];
    }
}

- (void)playEffectFromURL:(NSString *)url {
    NSString *ext = [[url pathExtension] lowercaseString];
    if ([@[@"svga"] containsObject:ext]) {
        [self playSVGAFromURL:[NSURL URLWithString:url]];
    } else if ([@[@"mp4", @"webm", @"mov"] containsObject:ext]) {
        [self playVideoFromURL:[NSURL URLWithString:url]];
    } else {
        [self playAnimatedImageFromURL:[NSURL URLWithString:url]];
    }
}

#pragma mark - Video (MP4/WebM/MOV)

- (void)playVideoFromFile:(NSString *)path {
    [self playVideoPlayerWithURL:[NSURL fileURLWithPath:path]];
}

- (void)playVideoFromURL:(NSURL *)url {
    [self playVideoPlayerWithURL:url];
}

- (void)playVideoPlayerWithURL:(NSURL *)url {
    self.avPlayer = [AVPlayer playerWithURL:url];
    self.avPlayer.actionAtItemEnd = AVPlayerActionAtItemEndNone;

    self.avPlayerLayer = [AVPlayerLayer playerLayerWithPlayer:self.avPlayer];
    self.avPlayerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    self.avPlayerLayer.frame = self.contentView.bounds;

    [self.contentView.layer addSublayer:self.avPlayerLayer];

    __weak typeof(self) wself = self;
    self.playbackEndObserver = [[NSNotificationCenter defaultCenter] addObserverForName:AVPlayerItemDidPlayToEndTimeNotification
                                                                              object:self.avPlayer.currentItem
                                                                               queue:[NSOperationQueue mainQueue]
                                                                          usingBlock:^(NSNotification *note) {
        [wself dismiss];
    }];

    [self.avPlayer play];
}

#pragma mark - Animated Image (GIF/WebP/APNG)

- (void)playAnimatedImageFromURL:(NSURL *)url {
    self.animatedImageView = [[SDAnimatedImageView alloc] init];
    self.animatedImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.animatedImageView.clipsToBounds = YES;
    self.animatedImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.animatedImageView.frame = self.contentView.bounds;
    [self.contentView addSubview:self.animatedImageView];

    // sd_setImageWithURL handles download + cache + playback automatically
    __weak typeof(self) wself = self;
    [self.animatedImageView sd_setImageWithURL:url placeholderImage:nil options:0 completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        if (!image || error) {
            [wself dismiss];
            return;
        }
        if (!wself) return;

        // If static image (not animated), dismiss immediately
        if (![wself.animatedImageView isAnimating]) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [wself dismiss];
            });
            return;
        }

        // KVO: watch isAnimating → when animation stops, dismiss
        [wself.animatedImageView addObserver:wself
                                 forKeyPath:@"isAnimating"
                                    options:NSKeyValueObservingOptionNew
                                    context:NULL];
    }];
}

#pragma mark - SVGA Animation

- (void)playSVGAFromFile:(NSString *)path {
    [self playSVGAPlayerWithURL:[NSURL fileURLWithPath:path]];
}

- (void)playSVGAFromURL:(NSURL *)url {
    [self playSVGAPlayerWithURL:url];
}

- (void)playSVGAPlayerWithURL:(NSURL *)url {
    SVGAImageView *playerView = [[SVGAImageView alloc] init];
    playerView.contentMode = UIViewContentModeScaleAspectFit;
    playerView.clipsToBounds = YES;
    playerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    playerView.frame = self.contentView.bounds;
    [self.contentView addSubview:playerView];
    self.svgaPlayerView = playerView;
    playerView.delegate = self;

    SVGAParser *parser = [[SVGAParser alloc] init];
    [parser parseWithURL:url completionBlock:^(SVGAVideoEntity *videoItem) {
        if (!videoItem) {
            [self dismiss];
            return;
        }
        self.svgaPlayerView.videoItem = videoItem;
        [self.svgaPlayerView startAnimation];
    } failureBlock:^(NSError *error) {
        [self dismiss];
    }];
}

#pragma mark - Dismiss

- (void)dismiss {
    [self.fallbackTimer invalidate];
    self.fallbackTimer = nil;

    if (self.playbackEndObserver) {
        [[NSNotificationCenter defaultCenter] removeObserver:self.playbackEndObserver];
        self.playbackEndObserver = nil;
    }

    @try {
        [self.animatedImageView removeObserver:self forKeyPath:@"isAnimating"];
    } @catch (NSException *exception) {
        // Observer not registered
    }

    [self.avPlayer pause];
    self.avPlayer = nil;

    [self.svgaPlayerView stopAnimation];
    self.svgaPlayerView = nil;

    [UIView animateWithDuration:0.3 animations:^{
        self.alpha = 0;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

- (void)dealloc {
    [self.fallbackTimer invalidate];
    if (self.playbackEndObserver) {
        [[NSNotificationCenter defaultCenter] removeObserver:self.playbackEndObserver];
    }
    @try {
        [self.animatedImageView removeObserver:self forKeyPath:@"isAnimating"];
    } @catch (NSException *exception) {
        // Observer not registered
    }
    [self.avPlayer pause];
}

#pragma mark - NSKeyValueObserving

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"isAnimating"] && object == self.animatedImageView) {
        BOOL animating = [change[NSKeyValueChangeNewKey] boolValue];
        if (!animating) {
            [self dismiss];
        }
    }
}

#pragma mark - SVGAPlayerDelegate

- (void)svgaPlayerDidFinishedAnimation:(SVGAPlayer *)player {
    [self dismiss];
}

@end
