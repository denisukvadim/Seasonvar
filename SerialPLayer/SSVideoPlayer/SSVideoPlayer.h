//
//  SSVideoPlayer.h
//  SSVideoPlayer
//
//  Created by Mrss on 16/1/9.
//  Copyright © 2016年 expai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class SSVideoPlayer;

@protocol SSVideoPlayerDelegate <NSObject>

@optional

- (void)videoPlayerDidReadyPlay:(SSVideoPlayer *)videoPlayer;

- (void)videoPlayerDidBeginPlay:(SSVideoPlayer *)videoPlayer;

- (void)videoPlayerDidEndPlay:(SSVideoPlayer *)videoPlayer;

- (void)videoPlayerDidSwitchPlay:(SSVideoPlayer *)videoPlayer;

- (void)videoPlayerDidFailedPlay:(SSVideoPlayer *)videoPlayer;

@end

typedef NS_ENUM(NSInteger,SSVideoPlayerPlayState) {
    SSVideoPlayerPlayStatePlaying,
    SSVideoPlayerPlayStateStop,
};

typedef NS_ENUM(NSInteger,SSVideoPlayerDisplayMode) {
    SSVideoPlayerDisplayModeAspectFit,
    SSVideoPlayerDisplayModeAspectFill
};

@interface SSVideoPlayer : NSObject

@property (nonatomic,  weak) id <SSVideoPlayerDelegate> delegate;

@property (nonatomic,  copy) void (^progressBlock)(float progress);

@property (nonatomic,  copy) void (^bufferProgressBlock)(float progress);

@property (nonatomic,assign,readonly) SSVideoPlayerPlayState playState;

@property (nonatomic,  copy) NSString *path; //Support both local and remote resource.

@property (nonatomic,assign) BOOL pausePlayWhenMove; //Default YES.

@property (nonatomic,assign,readonly) float duration;

@property (nonatomic,assign) SSVideoPlayerDisplayMode displayMode;

- (void)playInContainer:(UIView *)container ;

- (void)play;

- (void)playAtTheBeginning;

- (void)moveTo:(float)to; //0 to 1.

- (void)pause;


@end
