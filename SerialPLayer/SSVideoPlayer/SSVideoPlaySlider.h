//
//  SSVideoPlaySlider.h
//  SSVideoPlayer
//
//  Created by Mrss on 16/1/22.
//  Copyright © 2016年 expai. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SSVideoPlaySlider : UIControl

@property (nonatomic,assign) float value; //0 - 1.
@property (nonatomic,assign) float bufferValue; //0 - 1.

@property (nonatomic,strong) UIColor *minTrackColor;
@property (nonatomic,strong) UIColor *maxTrackColor;
@property (nonatomic,strong) UIColor *bufferTrackColor;

@property (nonatomic,strong) UIImage *thumbImage;
@property (nonatomic,strong) UIImage *thumbImageHighlighted;

@property (nonatomic,assign) BOOL continuous; //Default NO.

@property (nonatomic,assign,readonly) BOOL slide;

@end
