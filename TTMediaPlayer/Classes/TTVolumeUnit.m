//
//  TTVolumeUnit.m
//  HelloWord
//
//  Created by Tong on 2019/11/7.
//  Copyright © 2019 008. All rights reserved.
//

#import "TTVolumeUnit.h"
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>

static NSString * const TTSystemVolumeChangeNotification = @"AVSystemController_SystemVolumeDidChangeNotification";

@interface TTVolumeUnit ()

@property (nonatomic, strong) UISlider *volumeSlider;
@property (nonatomic, strong) MPVolumeView *volumeView;

@end

@implementation TTVolumeUnit

- (void)setVolume:(float)volume {
    NSLog(@"🔊 设置音量 %.2f",volume);
    if ([NSThread currentThread].isMainThread)
    {
        self.volumeSlider.value = volume;
    }
    else
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.volumeSlider.value = volume;
        });
    }
}

- (float)volume {
    NSLog(@"🔊 当前音量 %.2f",self.volumeSlider.value);
    if ([NSThread currentThread].isMainThread)
    {
        return self.volumeSlider.value;
    }
    /* 确保在主线程获取数据 */
    else
    {
        __block float result = 0;
        dispatch_group_t group = dispatch_group_create();
        dispatch_group_enter(group);
        dispatch_async(dispatch_get_main_queue(), ^{
            result = self.volumeSlider.value;
            dispatch_group_leave(group);
        });
        dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
        return result;
    }
}

- (void)adjustVolume:(float)volume {
    NSLog(@"🔊 调整音量 %.2f",volume);
    if ([NSThread currentThread].isMainThread)
    {
        self.volumeSlider.value+=volume;
    }
    else
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.volumeSlider.value+=volume;
        });
    }
}

#pragma mark - 单例
static id _shareInstance;

+ (instancetype)shareUnit {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        _shareInstance = [self new];
    });
    return _shareInstance;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _shareInstance = [super allocWithZone:zone];
    });
    return _shareInstance;
}

- (id)copyWithZone:(NSZone *)zone{
    return _shareInstance;
}


- (instancetype)init {
    if (self=[super init]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(systemVolumeChange:) name:TTSystemVolumeChangeNotification object:nil];
        self.hiddenVolumeView = YES;
    }
    return self;
}

- (MPVolumeView *)volumeView {
    if (!_volumeView) {
        _volumeView = [[MPVolumeView alloc] initWithFrame:CGRectMake(-100, -100, 40, 40)];
        [UIApplication.sharedApplication.keyWindow addSubview:_volumeView];
    }
    return _volumeView;
}

- (void)setHiddenVolumeView:(BOOL)hidden {
    if (_hiddenVolumeView != hidden) {
        _hiddenVolumeView = hidden;
        if (hidden) {
            self.volumeView.frame = CGRectMake(-100, -100, 40, 40);
            self.volumeView.hidden = NO;
            [UIApplication.sharedApplication.keyWindow addSubview:self.volumeView];
        } else {
            [self.volumeView setHidden:YES];
            [self.volumeView  removeFromSuperview];
        }
    }
}

- (UISlider *)volumeSlider {
    UISlider* volumeSlider =nil;
    for (UIView *view in [self.volumeView subviews]){
        if ([view.class.description isEqualToString:@"MPVolumeSlider"]){
            volumeSlider = (UISlider *)view;
            break;
        }
    }
    return volumeSlider;
}
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - ------------- 通知 ------------------
- (void)systemVolumeChange:(NSNotification *)noti {
    if([[noti.userInfo objectForKey:@"AVSystemController_AudioVolumeChangeReasonNotificationParameter"] isEqualToString:@"ExplicitVolumeChange"]) {
        float volume = [[[noti userInfo] objectForKey:@"AVSystemController_AudioVolumeNotificationParameter"] floatValue];
        NSLog(@"🔊 系统音量变化：%.2f", volume);
//        self.volume = volume;
        [[NSNotificationCenter defaultCenter] postNotificationName:TTVolumeUnitChangeNotification object:@(volume)];
    }
}

@end



#pragma mark - ------------- Public ------------------
float TTVolumeUnitGetVolume(void) {
    NSLog(@"%@",TTVolumeUnit.shareUnit.volumeSlider);
    // 在app刚刚初始化的时候使用MPVolumeView获取音量大小可能为 0，因此使用[[AVAudioSession sharedInstance]outputVolume]
    return TTVolumeUnit.shareUnit.volume?:[[AVAudioSession sharedInstance] outputVolume];
}

void  TTVolumeUnitSetVolume(float value){
    [TTVolumeUnit.shareUnit setVolume:value];
}

void  TTVolumeUnitAdjustVolume(float adjustValue) {
    [TTVolumeUnit.shareUnit adjustVolume:adjustValue];
}
