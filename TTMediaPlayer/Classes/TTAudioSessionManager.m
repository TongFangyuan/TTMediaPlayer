//
//  TTAudioSessionManager.m
//  MobileAir
//
//  Created by Tong on 2019/9/21.
//  Copyright © 2019 芯中芯. All rights reserved.
//

#import "TTAudioSessionManager.h"
#import "TTPhonePlayerTool.h"

void TTAudioSessionManagerNormalPlayerMode(NSError *error) {
    AVAudioSessionCategory category = AVAudioSessionCategoryPlayback;
    AVAudioSessionCategoryOptions options = AVAudioSessionCategoryOptionAllowBluetoothA2DP | AVAudioSessionCategoryOptionDefaultToSpeaker;
    TTAudioSessionManagerSetCategory(category, options, error);
}

void TTAudioSessionManagerIMusicPlayerMode(NSError * error) {
    AVAudioSessionCategory category = AVAudioSessionCategoryPlayback;
    AVAudioSessionCategoryOptions options = AVAudioSessionCategoryOptionAllowBluetoothA2DP | AVAudioSessionCategoryOptionDefaultToSpeaker | AVAudioSessionCategoryOptionMixWithOthers;
    TTAudioSessionManagerSetCategory(category, options, error);
}

void TTAudioSessionManagerRecorderMixMode(NSError* _Nullable error) {
    AVAudioSessionCategory category = AVAudioSessionCategoryPlayAndRecord;
    AVAudioSessionCategoryOptions options = AVAudioSessionCategoryOptionAllowBluetoothA2DP | AVAudioSessionCategoryOptionDefaultToSpeaker | AVAudioSessionCategoryOptionMixWithOthers;
    TTAudioSessionManagerSetCategory(category, options, error);
}

void TTAudioSessionManagerRecorderMode(NSError* _Nullable error) {
    AVAudioSessionCategory category = AVAudioSessionCategoryPlayAndRecord;
    AVAudioSessionCategoryOptions options = AVAudioSessionCategoryOptionAllowBluetoothA2DP | AVAudioSessionCategoryOptionDefaultToSpeaker;
    TTAudioSessionManagerSetCategory(category, options, error);
}

void TTAudioSessionManagerSetActive(BOOL active, NSError* _Nullable error) {
    AVAudioSession *session = [AVAudioSession sharedInstance];
    if (session.secondaryAudioShouldBeSilencedHint) {
        [session setActive:active withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:&error];
        NSLog(@"🈚️ 获取音频焦点 error: %@",error);
    }
}

void TTAudioSessionManagerSetCategory(AVAudioSessionCategory category, AVAudioSessionCategoryOptions options, NSError* _Nullable error) {
    AVAudioSession *session = [AVAudioSession sharedInstance];
    if (![session.category isEqualToString:category] || session.categoryOptions!=options) {
        [[AVAudioSession sharedInstance] setCategory:category withOptions:options error:&error];
        NSLog(@"🈚️ SessionCategory：%@ options: %ld error: %@", category, options, error);
    }
}

NSString *TTAudioSessionRouteChangeReasonString(AVAudioSessionRouteChangeReason reason) {
    static dispatch_once_t onceToken;
    static NSDictionary *_descDict = nil;
    dispatch_once(&onceToken, ^{
        _descDict = @{
            @(AVAudioSessionRouteChangeReasonUnknown):@"未知",
            @(AVAudioSessionRouteChangeReasonNewDeviceAvailable):@"新设备可用",
            @(AVAudioSessionRouteChangeReasonOldDeviceUnavailable):@"旧设备不可用",
            @(AVAudioSessionRouteChangeReasonCategoryChange):@"音频类别已更改",
            @(AVAudioSessionRouteChangeReasonOverride):@"音频路由已被覆盖",
            @(AVAudioSessionRouteChangeReasonWakeFromSleep):@"设备从睡眠中醒来",
            @(AVAudioSessionRouteChangeReasonNoSuitableRouteForCategory):@"当前类别没有合适的路由",
            @(AVAudioSessionRouteChangeReasonRouteConfigurationChange):@"输入和/或输出端口的集合没有改变，但是它们的某些方面配置已更改",
        };
    });
    return _descDict[@(reason)]?:@"未知";
}

@interface TTAudioSessionManager()

@property (nonatomic, strong) NSMutableArray<id<TTAudioSessionManagerDelegate>> *delegates;

@end

@implementation TTAudioSessionManager

+ (void)load {
    [TTAudioSessionManager performSelector:@selector(shareSession) withObject:nil];
}

#pragma mark - 单例
static id _shareInstance;

+ (instancetype)shareSession {
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
        _delegates = [NSMutableArray array];
        [self addNotiObserver];
    }
    return self;
}

- (void)dealloc {
    [self removeNotiObserver];
}

- (void)setup {
    
}

#pragma mark - ------------- 通知监听 ------------------
- (void)addNotiObserver {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionInterruption:) name:AVAudioSessionInterruptionNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionRouteChange:) name:AVAudioSessionRouteChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionMediaServerKill:) name:AVAudioSessionMediaServicesWereLostNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionMediaRestart:) name:AVAudioSessionMediaServicesWereResetNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionOtherAppAudioStartOrStop:) name:AVAudioSessionSilenceSecondaryAudioHintNotification object:nil];
}

- (void)removeNotiObserver {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVAudioSessionInterruptionNotification object:nil];
}

#pragma mark - < 代理 >
- (void)addDelegate:(id<TTAudioSessionManagerDelegate>)delegate {
    [self.delegates addObject:delegate];
}

- (void)removeDeleagte:(id<TTAudioSessionManagerDelegate>)delegate {
    [self.delegates removeObject:delegate];
}

#pragma mark - ------------- 事件 ------------------
- (void)sessionInterruption:(NSNotification *)noti {
    
    AVAudioSessionInterruptionType type = [noti.userInfo[AVAudioSessionInterruptionTypeKey] intValue];
    
    if (AVAudioSessionInterruptionTypeBegan == type) {
        NSLog(@"🈚️ 音频打断开始");
#ifdef DEBUG
        NSString *mediaSource = TTPhonePlayerTool.shareTool.mediaSource;
        NSLog(@"🈚️ 当前资源类型：%@",mediaSource);
#endif
        // Bug #9979 播放器：播放周杰伦歌曲10分钟，播放器界面，歌曲停止播放
        if (TTPhonePlayerToolIsIMusicPlayer()) {
            NSLog(@"🈚️ 当前是爱音乐播放且app在前台，不暂停音乐");
        } else {
            NSLog(@"🈚️ 中断音乐");
            [[TTPhonePlayerTool shareTool] interruptPause];
        }
    } else if (AVAudioSessionInterruptionTypeEnded == type) {
        NSLog(@"🈚️ 音频打断结束");
        if ([TTPhonePlayerTool shareTool].needContinue && ![TTPhonePlayerTool shareTool].isMediaPlaying) {
            NSLog(@"🈚️ 恢复音乐");
            [[TTPhonePlayerTool shareTool] continuePlay];
        }
    }
    
    [self.delegates enumerateObjectsUsingBlock:^(id<TTAudioSessionManagerDelegate>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj respondsToSelector:@selector(audioSession:didInterruption:usnerInfo:)]) {
            [obj audioSession:AVAudioSession.sharedInstance didInterruption:type usnerInfo:noti.userInfo];
        }
    }];
}

- (void)sessionRouteChange:(NSNotification *)noti {
    AVAudioSessionRouteChangeReason reason = [noti.userInfo[AVAudioSessionRouteChangeReasonKey] unsignedIntegerValue];
    NSLog(@"🈚️ 音频路由切换,原因：%@", TTAudioSessionRouteChangeReasonString(reason));
    if (reason==AVAudioSessionRouteChangeReasonOldDeviceUnavailable) {
        [TTPhonePlayerTool shareTool].manualPause = YES;
        [[TTPhonePlayerTool shareTool] pause];
    }
}

- (void)sessionMediaServerKill:(NSNotification *)noti {
    NSLog(@"🈚️ 音频 Mediakill:%@",noti);
}

- (void)sessionMediaRestart:(NSNotification *)noti {
    NSLog(@"🈚️ MediaRestart:%@",noti);
}

- (void)sessionOtherAppAudioStartOrStop:(NSNotification *)noti {
    int value = [noti.userInfo[@"AVAudioSessionSilenceSecondaryAudioHintTypeKey"] intValue];
    NSLog(@"🈚️ 其他App播放状态:%d",value);
    if (value==0 && ![TTPhonePlayerTool.shareTool.mediaSource isEqualToString:TTMediaSourceIMusic] && TTPhonePlayerTool.shareTool.manualPause==NO) {
        [[TTPhonePlayerTool shareTool] continuePlay];
    }
}

@end
