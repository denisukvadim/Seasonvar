//
//  SSVideoPlayController.m
//  SSVideoPlayer
//
//  Created by Mrss on 16/1/22.
//  Copyright © 2016年 expai. All rights reserved.
//

#import "SSVideoPlayController.h"
#import "SSVideoPlaySlider.h"
#import "SSVideoPlayer.h"
#import <MediaPlayer/MediaPlayer.h>
#import "ContentManager.h"


@implementation SSVideoModel

- (instancetype)initWithName:(NSString *)name path:(NSString *)path {
    self = [super init];
    if (self) {
        _name = [name copy];
        _path = [path copy];
    }
    return self;
}

@end

@interface SSVideoPlayController () <UITableViewDataSource,UITableViewDelegate,SSVideoPlayerDelegate>

@property (nonatomic,strong) SSVideoPlaySlider *slider;
@property (nonatomic,strong) UIButton *playButton;
@property (nonatomic,strong) UISlider *volume;
@property (nonatomic,strong) UIToolbar *bottomBar;
@property (nonatomic,strong) UIView *playContainer;
@property (nonatomic,strong) SSVideoPlayer *player;
@property (nonatomic,strong) UITableView *videoList;
@property (nonatomic,strong) NSMutableArray *videoPaths;
@property (nonatomic,assign) BOOL hidden;
@property (nonatomic,assign) BOOL videoListHidden;
@property (nonatomic,assign) NSInteger playIndex;
@property (nonatomic,strong) UIActivityIndicatorView *indicator;
@property (nonatomic, assign) BOOL downloadButton;
@property (strong, nonatomic) ContentManager *contentManager;

@end

@implementation SSVideoPlayController

- (instancetype)initWithVideoList:(NSArray<SSVideoModel *> *)videoList  presentButton:(BOOL)presentPutton{
    self.downloadButton = presentPutton;
    _contentManager = [[ContentManager alloc] init];
    NSAssert(videoList.count, @"The playlist can not be empty!");
    self = [super init];
    if (self) {
        self.videoPaths = [videoList mutableCopy];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setup];
    [self setupNavigationBar];
    [self setupBottomBar];
    [self setupVideoList];
}

- (void)setup {
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.view.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.75];
    self.indicator = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [self.view addSubview:self.indicator];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(systemVolumeChanged:) name:@"AVSystemController_SystemVolumeDidChangeNotification" object:nil];
}

- (void)setupVideoList {
    self.videoList = [[UITableView alloc]initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.videoList.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.75];
    self.videoList.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.videoList.delegate = self;
    self.videoList.dataSource = self;
    self.videoList.tableFooterView = [[UIView alloc]init];
    [self.view addSubview:self.videoList];
    self.videoListHidden = YES;
}

- (void)setupNavigationBar {
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    UIBarButtonItem *menu = [[UIBarButtonItem alloc]initWithImage:[[self imageWithName:@"player_menu"]imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] style:UIBarButtonItemStyleDone target:self action:@selector(menu:)];
    UIBarButtonItem *quit = [[UIBarButtonItem alloc]initWithImage:[[self imageWithName:@"player_quit"]imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] style:UIBarButtonItemStyleDone target:self action:@selector(quit:)];
    self.slider = [[SSVideoPlaySlider alloc]initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width-200, 20)];
    self.slider.thumbImage = [self imageWithName:@"player_slider"];
    [self.slider addTarget:self action:@selector(playProgressChange:) forControlEvents:UIControlEventValueChanged];
    self.navigationItem.leftBarButtonItem = quit;
    self.navigationItem.titleView = self.slider;
    self.navigationItem.rightBarButtonItem = menu;
}

- (void)setupBottomBar {
    self.bottomBar = [[UIToolbar alloc]init];
    self.bottomBar.barStyle = UIBarStyleBlack;
    [self.view addSubview:self.bottomBar];
    UIBarButtonItem *space = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:NULL];
    UIBarButtonItem *previousItem = [[UIBarButtonItem alloc]initWithImage:[[self imageWithName:@"player_previous"]imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] style:UIBarButtonItemStyleDone target:self action:@selector(previous:)];
    self.playButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.playButton.frame = CGRectMake(0, 0, 30, 30);
    [self.playButton setBackgroundImage:[self imageWithName:@"player_pause"] forState:UIControlStateNormal];
    [self.playButton setBackgroundImage:[self imageWithName:@"player_play"] forState:UIControlStateSelected];
    [self.playButton addTarget:self action:@selector(playAction:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *playItem = [[UIBarButtonItem alloc]initWithCustomView:self.playButton];
    UIBarButtonItem *nextItem = [[UIBarButtonItem alloc]initWithImage:[[self imageWithName:@"player_next"]imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] style:UIBarButtonItemStyleDone target:self action:@selector(next:)];
    UIButton *displayButton = [UIButton buttonWithType:UIButtonTypeCustom];
    displayButton.frame = CGRectMake(0, 0, 30, 30);
    [displayButton setBackgroundImage:[self imageWithName:@"player_fill"] forState:UIControlStateNormal];
    [displayButton setBackgroundImage:[self imageWithName:@"player_fit"] forState:UIControlStateSelected];
    [displayButton addTarget:self action:@selector(displayModeChanged:) forControlEvents:UIControlEventTouchUpInside];
    self.volume = [[UISlider alloc]initWithFrame:CGRectMake(0, 0, 150, 20)];
    self.volume.value = [[MPMusicPlayerController applicationMusicPlayer]volume];
    [self.volume setThumbImage:[self imageWithName:@"player_volume"] forState:UIControlStateNormal];
    [self.volume addTarget:self action:@selector(volumeChanged:) forControlEvents:UIControlEventValueChanged];
    UIBarButtonItem *volumnItem = [[UIBarButtonItem alloc]initWithCustomView:self.volume];
    UIBarButtonItem *displayItem = [[UIBarButtonItem alloc]initWithCustomView:displayButton];
    self.bottomBar.items = @[volumnItem,space,previousItem,space,playItem,space,nextItem,space,space,displayItem,space];
}

#pragma mark - Action

- (void)quit:(UIBarButtonItem *)item {
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (void)volumeChanged:(UISlider *)slider {
    [[MPMusicPlayerController applicationMusicPlayer]setVolume:slider.value];
}

- (void)displayModeChanged:(UIButton *)sender {
    sender.selected = !sender.selected;
    if (sender.selected) {
        self.player.displayMode = SSVideoPlayerDisplayModeAspectFill;
    }
    else {
        self.player.displayMode = SSVideoPlayerDisplayModeAspectFit;
    }
}

- (void)playProgressChange:(SSVideoPlaySlider *)slider {
    [self.player moveTo:slider.value];
    if (!self.playButton.selected) {
        [self.player play];
    }
}

- (void)menu:(UIBarButtonItem *)item {
    [UIView animateWithDuration:0.25 animations:^{
        CGFloat offset = self.videoListHidden ? -300 : 0;
        self.videoList.frame = CGRectMake(self.view.bounds.size.width+offset, 32, 300, self.view.bounds.size.height-76);
    } completion:^(BOOL finished) {
        self.videoListHidden = !self.videoListHidden;
    }];
}
- (void)playAction:(UIButton *)sender {
    sender.selected = !sender.selected;
    if (sender.selected) {
        [self.player pause];
    }
    else {
        [self.player play];
    }
}

- (void)next:(UIBarButtonItem *)item {
    if (self.playIndex >= self.videoPaths.count-1) {
        return;
    }
    self.playIndex++;
    [self.videoList reloadData];
    
    SSVideoModel *model = self.videoPaths[self.playIndex];
    NSString *linkVideoTMP = model.path;
    NSMutableString *serverUrl = [[linkVideoTMP componentsSeparatedByString:@"/"] objectAtIndex:2];
    NSMutableString *serverFolder = [[linkVideoTMP componentsSeparatedByString:@"/"] objectAtIndex:3];
    NSMutableString *requestTokken = [_contentManager requestTokken];
    NSMutableString *videoFileName = [[linkVideoTMP componentsSeparatedByString:@"/"] objectAtIndex:5];
    
    NSMutableString *videoPath = [[NSMutableString alloc]init];
    
    [videoPath appendString:@"http://"];
    [videoPath appendString:serverUrl];
    [videoPath appendString:@"/"];
    [videoPath appendString:serverFolder];
    [videoPath appendString:@"/"];
    [videoPath appendString:requestTokken];
    [videoPath appendString:@"/"];
    [videoPath appendString:videoFileName];
    
    NSLog(@"VideoLink %@", videoPath);
    
    [self playVideoWithPath:videoPath];
}

- (void)previous:(UIBarButtonItem *)item {
    if (self.playIndex <= 0) {
        [self.player playAtTheBeginning];
        return;
    }
    self.playIndex--;
    [self.videoList reloadData];
    SSVideoModel *model = self.videoPaths[self.playIndex];
    NSString *linkVideoTMP = model.path;
    NSMutableString *serverUrl = [[linkVideoTMP componentsSeparatedByString:@"/"] objectAtIndex:2];
    NSMutableString *serverFolder = [[linkVideoTMP componentsSeparatedByString:@"/"] objectAtIndex:3];
    NSMutableString *requestTokken = [_contentManager requestTokken];
    NSMutableString *videoFileName = [[linkVideoTMP componentsSeparatedByString:@"/"] objectAtIndex:5];
    
    NSMutableString *videoPath = [[NSMutableString alloc]init];
    
    [videoPath appendString:@"http://"];
    [videoPath appendString:serverUrl];
    [videoPath appendString:@"/"];
    [videoPath appendString:serverFolder];
    [videoPath appendString:@"/"];
    [videoPath appendString:requestTokken];
    [videoPath appendString:@"/"];
    [videoPath appendString:videoFileName];
    
    NSLog(@"VideoLink %@", videoPath);
    

    [self playVideoWithPath:videoPath];
}

- (void)playVideoWithPath:(NSString *)path {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.player.path = path;
    });
}

- (void)startIndicator {
    if (![self.indicator isAnimating]) {
        [NSThread detachNewThreadSelector:@selector(startAnimating) toTarget:self.indicator withObject:nil];
    }
}

- (void)stopIndicator {
    if ([self.indicator isAnimating]) {
        [NSThread detachNewThreadSelector:@selector(stopAnimating) toTarget:self.indicator withObject:nil];
    }
}

- (void)systemVolumeChanged:(NSNotification *)not {
    float new = [not.userInfo[@"AVSystemController_AudioVolumeNotificationParameter"] floatValue];
    self.volume.value = new;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.videoPaths.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellId = @"cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (cell == nil) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
        cell.backgroundColor = [UIColor clearColor];
        if(self.downloadButton)
        {
            UIButton *del = [UIButton buttonWithType:UIButtonTypeCustom];
            del.frame = CGRectMake(0, 0, 40, 40);
            [del setImage:[self imageWithName:@"player_delete"] forState:UIControlStateNormal];
            [del addTarget:self action:@selector(delVideo:) forControlEvents:UIControlEventTouchUpInside];
            cell.accessoryView = del;
        }
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    cell.accessoryView.tag = indexPath.row;
    SSVideoModel *model = self.videoPaths[indexPath.row];
    if (self.playIndex == indexPath.row) {
        cell.textLabel.textColor = [UIColor whiteColor];
        cell.textLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:17];
    }
    else {
        cell.textLabel.textColor = [UIColor lightGrayColor];
        cell.textLabel.font = [UIFont fontWithName:@"Helvetica" size:17];
    }
    cell.textLabel.text = model.name;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == self.playIndex) {
        return;
    }
    self.playIndex = indexPath.row;
    [self.videoList reloadData];
    SSVideoModel *model = self.videoPaths[indexPath.row];
    
    NSString *linkVideoTMP = model.path;
    NSMutableString *serverUrl = [[linkVideoTMP componentsSeparatedByString:@"/"] objectAtIndex:2];
    NSMutableString *serverFolder = [[linkVideoTMP componentsSeparatedByString:@"/"] objectAtIndex:3];
    NSMutableString *requestTokken = [_contentManager requestTokken];
    NSMutableString *videoFileName = [[linkVideoTMP componentsSeparatedByString:@"/"] objectAtIndex:5];
    
    NSMutableString *videoPath = [[NSMutableString alloc]init];
    
    [videoPath appendString:@"http://"];
    [videoPath appendString:serverUrl];
    [videoPath appendString:@"/"];
    [videoPath appendString:serverFolder];
    [videoPath appendString:@"/"];
    [videoPath appendString:requestTokken];
    [videoPath appendString:@"/"];
    [videoPath appendString:videoFileName];
    
    NSLog(@"VideoLink %@", videoPath);
    
    
    [self playVideoWithPath:videoPath];
}

- (void)delVideo:(UIButton *)sender {
    if (self.videoPaths.count == 1) {
        [self dismissViewControllerAnimated:YES completion:nil];
        return;
    }
    if (self.playIndex > sender.tag) {
        self.playIndex--;
    }
    else if (self.playIndex == sender.tag) {
        [self.player pause];
        if (self.playIndex == self.videoPaths.count-1) {
            SSVideoModel *model = self.videoPaths[0];
            NSString *linkVideoTMP = model.path;
            NSMutableString *serverUrl = [[linkVideoTMP componentsSeparatedByString:@"/"] objectAtIndex:2];
            NSMutableString *serverFolder = [[linkVideoTMP componentsSeparatedByString:@"/"] objectAtIndex:3];
            NSMutableString *requestTokken = [_contentManager requestTokken];
            NSMutableString *videoFileName = [[linkVideoTMP componentsSeparatedByString:@"/"] objectAtIndex:5];
            
            NSMutableString *videoPath = [[NSMutableString alloc]init];
            
            [videoPath appendString:@"http://"];
            [videoPath appendString:serverUrl];
            [videoPath appendString:@"/"];
            [videoPath appendString:serverFolder];
            [videoPath appendString:@"/"];
            [videoPath appendString:requestTokken];
            [videoPath appendString:@"/"];
            [videoPath appendString:videoFileName];
            
            NSLog(@"VideoLink %@", videoPath);
            
            
            [self playVideoWithPath:videoPath];
            self.playIndex = 0;
        }
        else {
            SSVideoModel *model = self.videoPaths[self.playIndex+1];
            NSString *linkVideoTMP = model.path;
            NSMutableString *serverUrl = [[linkVideoTMP componentsSeparatedByString:@"/"] objectAtIndex:2];
            NSMutableString *serverFolder = [[linkVideoTMP componentsSeparatedByString:@"/"] objectAtIndex:3];
            NSMutableString *requestTokken = [_contentManager requestTokken];
            NSMutableString *videoFileName = [[linkVideoTMP componentsSeparatedByString:@"/"] objectAtIndex:5];
            
            NSMutableString *videoPath = [[NSMutableString alloc]init];
            
            [videoPath appendString:@"http://"];
            [videoPath appendString:serverUrl];
            [videoPath appendString:@"/"];
            [videoPath appendString:serverFolder];
            [videoPath appendString:@"/"];
            [videoPath appendString:requestTokken];
            [videoPath appendString:@"/"];
            [videoPath appendString:videoFileName];
            
            NSLog(@"VideoLink %@", videoPath);
            
            
            [self playVideoWithPath:videoPath];
        }
    }
    [self.videoPaths removeObjectAtIndex:sender.tag];
    [self.videoList reloadData];
}

- (void)viewWillLayoutSubviews {
    self.bottomBar.frame = CGRectMake(0, self.view.bounds.size.height-44, self.view.bounds.size.width, 44);
    self.videoList.frame = CGRectMake(self.view.bounds.size.width, 32, 300, self.view.bounds.size.height-76);
    self.indicator.center = self.view.center;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.player playInContainer:self.view];
    [self.view bringSubviewToFront:self.bottomBar];
    [self.view bringSubviewToFront:self.videoList];
    [self.view bringSubviewToFront:self.indicator];
    [self startIndicator];
    [self hide];
}

- (SSVideoPlayer *)player {
    if (_player == nil) {
        _player = [[SSVideoPlayer alloc]init];
        _player.delegate = self;
        __weak SSVideoPlayController *weakSelf = self;
        _player.bufferProgressBlock = ^(float f) {
            dispatch_async(dispatch_get_main_queue(), ^{
                weakSelf.slider.bufferValue = f;
            });
        };
        _player.progressBlock = ^(float f) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!weakSelf.slider.slide) {
                    weakSelf.slider.value = f;
                }
            });
        };
        SSVideoModel *model = self.videoPaths[0];
        NSString *linkVideoTMP = model.path;
        NSMutableString *serverUrl = [[linkVideoTMP componentsSeparatedByString:@"/"] objectAtIndex:2];
        NSMutableString *serverFolder = [[linkVideoTMP componentsSeparatedByString:@"/"] objectAtIndex:3];
        NSMutableString *requestTokken = [_contentManager requestTokken];
        NSMutableString *videoFileName = [[linkVideoTMP componentsSeparatedByString:@"/"] objectAtIndex:5];
        
        NSMutableString *videoPath = [[NSMutableString alloc]init];
        
        [videoPath appendString:@"http://"];
        [videoPath appendString:serverUrl];
        [videoPath appendString:@"/"];
        [videoPath appendString:serverFolder];
        [videoPath appendString:@"/"];
        [videoPath appendString:requestTokken];
        [videoPath appendString:@"/"];
        [videoPath appendString:videoFileName];
        
        NSLog(@"VideoLink %@", videoPath);
        
        
        
        _player.path = videoPath;
    }
    return _player;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.player pause];
    self.player = nil;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (!self.videoListHidden) {
        self.videoListHidden = YES;
        [UIView animateWithDuration:0.15 animations:^{
            self.videoList.frame = CGRectMake(self.view.bounds.size.width, 32, 300, self.view.bounds.size.height-76);
        } completion:^(BOOL finished) {
            
        }];
    }
    if (self.hidden) {
        [UIView animateWithDuration:0.15 animations:^{
            self.navigationController.navigationBar.alpha = 1;
            self.bottomBar.alpha = 1;
        } completion:^(BOOL finished) {
            self.hidden = NO;
            [self hide];
        }];
    }
    else {
        [[self class]cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideBar) object:self];
        [self hideBar];
    }
}

- (void)hide {
    [[self class]cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideBar) object:self];
    [self performSelector:@selector(hideBar) withObject:self afterDelay:4];
}

- (void)hideBar {
    if (!self.videoListHidden) {
        return;
    }
    [UIView animateWithDuration:0.15 animations:^{
        self.navigationController.navigationBar.alpha = 0;
        self.bottomBar.alpha = 0;
    } completion:^(BOOL finished) {
        self.hidden = YES;
    }];
}

#pragma mark - SSVideoPlayerDelegate

- (void)videoPlayerDidReadyPlay:(SSVideoPlayer *)videoPlayer {
    [self stopIndicator];
    [self.player play];
}

- (void)videoPlayerDidBeginPlay:(SSVideoPlayer *)videoPlayer {
    self.playButton.selected = NO;
}

- (void)videoPlayerDidEndPlay:(SSVideoPlayer *)videoPlayer {
    self.playButton.selected = YES;
}

- (void)videoPlayerDidSwitchPlay:(SSVideoPlayer *)videoPlayer {
    [self startIndicator];
}

- (void)videoPlayerDidFailedPlay:(SSVideoPlayer *)videoPlayer {
    [self stopIndicator];
    [[[UIAlertView alloc]initWithTitle:@"Видео файл больше не доступный" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil]show];
}

- (UIImage *)imageWithName:(NSString *)name {
    NSString *path = [[NSBundle mainBundle]pathForResource:@"SSVideoPlayer" ofType:@"bundle"];
    NSString *imagePath = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png",name]];
    return [UIImage imageWithContentsOfFile:imagePath];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


@end
