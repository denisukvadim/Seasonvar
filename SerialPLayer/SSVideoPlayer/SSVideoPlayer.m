//
//  SSVideoPlayer.m
//  SSVideoPlayer
//
//  Created by Mrss on 16/1/9.
//  Copyright © 2016年 expai. All rights reserved.
//


#import "SSVideoPlayer.h"
#import <AVFoundation/AVFoundation.h>

static NSString *const SSVideoPlayerItemStatusKeyPath = @"status";
static NSString *const SSVideoPlayerItemLoadedTimeRangesKeyPath = @"loadedTimeRanges";

@interface SSVideoPlayer ()

@property (nonatomic,strong) AVPlayer *player;
@property (nonatomic,strong) AVPlayerLayer *playerLayer;
@property (nonatomic,strong) AVPlayerItem *currentPlayItem;
@property (nonatomic,strong) id observer;

@end

@implementation SSVideoPlayer

- (instancetype)init {
    self = [super init];
    if (self) {
        _player = [[AVPlayer alloc]init];
        _displayMode = SSVideoPlayerDisplayModeAspectFit;
        _pausePlayWhenMove = YES;
    }
    return self;
}

- (void)playInContainer:(UIView *)container {
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    self.playerLayer.frame = container.bounds;
    NSString *mode;
    switch (self.displayMode) {
        case SSVideoPlayerDisplayModeAspectFit:
            mode = AVLayerVideoGravityResizeAspect;
            break;
        default:
            mode = AVLayerVideoGravityResizeAspectFill;
            break;
    }
    self.playerLayer.videoGravity = mode;
    [container.layer addSublayer:self.playerLayer];
}

- (void)setDisplayMode:(SSVideoPlayerDisplayMode)displayMode {
    if (_displayMode == displayMode) {
        return;
    }
    _displayMode = displayMode;
    NSString *mode;
    switch (displayMode) {
        case SSVideoPlayerDisplayModeAspectFit:
            mode = AVLayerVideoGravityResizeAspect;
            break;
        default:
            mode = AVLayerVideoGravityResizeAspectFill;
            break;
    }
    self.playerLayer.videoGravity = mode;
}

- (void)setPath:(NSString *)path {
    if (path == nil) {
        return;
    }
    if ([_path isEqualToString:path]) {
        return;
    }
    _path = path;
    if (self.playState == SSVideoPlayerPlayStatePlaying) {
        [self.player pause];
    }
    if (self.currentPlayItem) {
        if ([self.delegate respondsToSelector:@selector(videoPlayerDidSwitchPlay:)]) {
            [self.delegate videoPlayerDidSwitchPlay:self];
        }
        if (self.progressBlock) {
            self.progressBlock(0.0);
        }
        if (self.bufferProgressBlock) {
            self.bufferProgressBlock(0.0);
        }
        [self clear];
    }
    NSString *p = [path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL *url = [NSURL fileURLWithPath:p];
    if ([p hasPrefix:@"http://"] || [p hasPrefix:@"https://"]) {
        url = [NSURL URLWithString:p];
    }
    AVPlayerItem *playItem = [[AVPlayerItem alloc]initWithURL:url];
    self.currentPlayItem = playItem;
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(playEndNotification) name:AVPlayerItemDidPlayToEndTimeNotification object:playItem];
    [playItem addObserver:self forKeyPath:SSVideoPlayerItemStatusKeyPath options:NSKeyValueObservingOptionNew context:NULL];
    [playItem addObserver:self forKeyPath:SSVideoPlayerItemLoadedTimeRangesKeyPath options:NSKeyValueObservingOptionNew context:NULL];
    [self.player replaceCurrentItemWithPlayerItem:playItem];
    //    _duration = CMTimeGetSeconds(self.currentPlayItem.duration);
    __weak SSVideoPlayer *weakSelf = self;
    self.observer = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1.0, 1.0) queue:dispatch_get_global_queue(0, 0) usingBlock:^(CMTime time) {
        if (CMTIME_IS_INDEFINITE(weakSelf.currentPlayItem.duration)) {
            return ;
        }
        float f = CMTimeGetSeconds(time);
        float max = CMTimeGetSeconds(weakSelf.currentPlayItem.duration);
        if (weakSelf.progressBlock) {
            weakSelf.progressBlock(f/max);
        }
    }];
}

- (void)clear {
    [self.player removeTimeObserver:self.observer];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.currentPlayItem];
    [self.currentPlayItem removeObserver:self forKeyPath:SSVideoPlayerItemLoadedTimeRangesKeyPath context:NULL];
    [self.currentPlayItem removeObserver:self forKeyPath:SSVideoPlayerItemStatusKeyPath context:NULL];
    self.currentPlayItem = nil;
}

- (void)playEndNotification {
    if (self.progressBlock) {
        self.progressBlock(1.0);
    }
    if ([self.delegate respondsToSelector:@selector(videoPlayerDidEndPlay:)]) {
        [self.delegate videoPlayerDidEndPlay:self];
    }
}

- (void)playFailedNotification {
    if ([self.delegate respondsToSelector:@selector(videoPlayerDidFailedPlay:)]) {
        [self.delegate videoPlayerDidFailedPlay:self];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:SSVideoPlayerItemStatusKeyPath]) {
        AVPlayerStatus status = [change[NSKeyValueChangeNewKey]integerValue];
        if (status == AVPlayerStatusReadyToPlay) {
            if ([self.delegate respondsToSelector:@selector(videoPlayerDidReadyPlay:)]) {
                _duration = CMTimeGetSeconds(self.currentPlayItem.asset.duration);
                [self.delegate videoPlayerDidReadyPlay:self];
            }
        }
        else if (status == AVPlayerStatusFailed) {
            if ([self.delegate respondsToSelector:@selector(videoPlayerDidFailedPlay:)]) {
                [self.delegate videoPlayerDidFailedPlay:self];
            }
        }
    }
    else if ([keyPath isEqualToString:SSVideoPlayerItemLoadedTimeRangesKeyPath]) {
        if (CMTIME_IS_INDEFINITE(self.currentPlayItem.duration)) {
            return ;
        }
        NSArray *array = self.currentPlayItem.loadedTimeRanges;
        CMTimeRange timeRange = [array.firstObject CMTimeRangeValue];
        float duration = CMTimeGetSeconds(self.currentPlayItem.asset.duration);
        float current = CMTimeGetSeconds(timeRange.duration);
        if (self.bufferProgressBlock) {
            self.bufferProgressBlock(current/duration);
        }
    }
}

- (SSVideoPlayerPlayState)playState {
    if (ABS(self.player.rate - 1) <= 0.000001) {
        return SSVideoPlayerPlayStatePlaying;
    }
    return SSVideoPlayerPlayStateStop;
}

- (void)play {
    if (ABS(self.player.rate - 1) <= 0.000001) {
        return;
    }
    if (self.currentPlayItem.status == AVPlayerItemStatusFailed) {
        return;
    }
    [self.player play];
    if ([self.delegate respondsToSelector:@selector(videoPlayerDidBeginPlay:)]) {
        [self.delegate videoPlayerDidBeginPlay:self];
    }
}

- (void)playAtTheBeginning {
    [self moveTo:0.0];
    [self play];
}

- (void)moveTo:(float)to {
    if (self.pausePlayWhenMove) {
        [self pause];
    }
    CMTime duration = self.currentPlayItem.asset.duration;
    float max = CMTimeGetSeconds(duration);
    long long l = ceil(max*to);
    [self.player seekToTime:CMTimeMake(l, 1)];
    if (self.progressBlock) {
        self.progressBlock(to);
    }
}

- (void)pause {
    if (ABS(self.player.rate - 0) <= 0.000001) {
        return;
    }
    [self.player pause];
}

- (void)dealloc {
    [self pause];
    [self clear];
    self.player = nil;
    self.playerLayer = nil;
    self.currentPlayItem = nil;
    self.observer = nil;
}

@end
