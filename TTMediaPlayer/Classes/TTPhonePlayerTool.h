//
//  TTPhonePlayerTool.h
//  MobileAir
//
//  Created by Tong on 2019/8/26.
//  Copyright © 2019 芯中芯. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TTAudioSessionManager.h"
#import "TTBaseMusicPlayer.h"
#import "TTBaseTTSPlayer.h"
#import "TTUnitMacros.h"

#ifndef TTPhonePlayerTool_DEBUG
    #define TTPhonePlayerTool_DEBUG 1
#endif

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    TTPlayerStateNone,
    TTPlayerStateLoading,
    TTPlayerStateStarted,
    TTPlayerStateBuffStart,
    TTPlayerStateBuffFinsh,
    TTPlayerStatePaused,
    TTPlayerStateResume,
    TTPlayerStateFinshed,
} TTPlayerState;

@interface TTPhonePlayerTool : NSObject <TTPhonePlayToolObject>

/** 正在工作的播放器 */
@property (nonatomic, strong, readonly) id<TTMusicPlayerObject> player;
/** TTS播放器 */
@property (nonatomic, strong) id<TTTTSPlayerProtocol> ttsPLayer;

// -------------------------------- 歌曲信息  start --------------------------------

/** 歌曲 */
@property (nonatomic, strong) id<TTAlbumTrackProtocol> albumTrack;
/** 歌曲队列 */
@property (nonatomic, strong) NSArray<id<TTAlbumTrackProtocol>> *albumTracks;
/** 当前播放索引 */
@property (nonatomic, assign) NSInteger currentTrackIndex;
/** 当前时间 */
@property (nonatomic, assign) float currentTime;
/** 剩下时间 */
@property (nonatomic, assign) float duration;
/** 播放进度，0.0~1.0 */
@property (nonatomic, assign) float position;
/** 缓冲进度，0.0~1.0 */
@property (nonatomic, assign,readonly) float loadedPostion;
/** 当前格式时间 */
@property (nonatomic, copy) NSString *currentTimeText;
/** 剩下格式时间 */
@property (nonatomic, copy) NSString *durationText;
/** 音乐播放是否在前台 */
@property (nonatomic,assign) BOOL isForeground;
/** 电话打断结束后是否需要继续播放 */
@property (nonatomic,assign) BOOL needContinue;
/** 是否手动暂停 */
@property (nonatomic,assign) BOOL manualPause;
/** 本地控制 */
@property (nonatomic ,assign) TTMusicPlayerControl localControl;
/** 播放模式 */
@property (nonatomic, assign) TTPhonePlayMode playMode;
/** 当前播放器是否正在工作 */
@property (nonatomic, assign, readonly) BOOL isMediaPlaying;
/** 交互推送的音乐 */
@property (nonatomic, assign) BOOL isBoxMusic;
/** 音频资源类型*/
@property (nonatomic, strong, readonly, nullable) NSString *mediaSource;

/******************** 禁用阿里音乐播放器 **********/
@property (nonatomic, assign) BOOL disableRecognizer;
@property (nonatomic, assign) BOOL disableAliMediaPlayer;

// -------------------------------- 歌曲信息  end --------------------------------

+ (instancetype)shareTool;

- (void)applicationDidEnterBackground:(UIApplication *)application;
- (void)applicationWillEnterForeground:(UIApplication *)application;
- (void)remoteControlEventHandler;//远程控制监听,在`application:didFinishLaunchingWithOptions:`调用

@end


/// 播放器注册
@interface TTPhonePlayerTool (PlayerRegister)

/**
 注册某种类型音频的专属播放器
 
 @see TTMediaSourceName 音频来源类型
 @see TTMusicPlayerObject 播放器协议
 
 @param source 需要注册音频类型，TTMediaSourceName（可以自定义类型）
 @param cls 播放器类，该类需要遵循 TTMusicPlayerObject 协议
 */
- (void)registerSource:(NSString *)source playerClass:(Class)cls;

/// 得到播放器类名
- (nullable Class)playerClassForSource:(NSString *)source;

/// 初始化一个播放器对象
- (nullable id<TTMusicPlayerObject>)playerWithSource:(NSString *)source;

- (nullable NSString *)mediaSourceForPlayer:(id)player;

@end

/// TTS播放器控制
@interface TTPhonePlayerTool (TTSPlayer)

- (void)playTTSUrls:(NSArray<NSString *> *)urls
             source:(TTMediaSourceName)source;
- (void)playTTSUrls:(NSArray<NSString *> *)urls
             source:(TTMediaSourceName)source
           callback:(nullable void(^)(void))callback;

- (void)playTTSDatas:(NSArray<NSData *> *)datas
              source:(TTMediaSourceName)source;
- (void)playTTSDatas:(NSArray<NSData *> *)datas
              source:(TTMediaSourceName)source
            callback:(nullable void(^)(void))callback;

/// 停掉TTS播放器
- (void)stopTTSPlayer;

@end

@protocol TTPhonePlayToolObserver;

@interface TTPhonePlayerTool (MusicPlayer)

- (void)pauseMusicPlayer;
- (void)stopMusicPlayer;
- (void)seekMusicToPosition:(CGFloat)position;
- (void)manualPauseMusic;
- (void)manualPlayMusic;

- (void)updatePlaylist:(NSArray<id<TTAlbumTrackProtocol>> *)albums;

- (void)addObserver:(id<TTPhonePlayToolObserver>)observer;
- (void)removeObserver:(id<TTPhonePlayToolObserver>)observer;

@end

#pragma mark - ------------- 辅助方法 ------------------

/// 判断当前是否为爱音乐播放器
extern BOOL TTPhonePlayerToolIsIMusicPlayer(void);
/// 判断当前是否为电台播放器
extern BOOL TTPhonePlayerToolIsRadioStationPlayer(void);
/// 是否需要自己播放TTS
extern BOOL TTPhonePlayerToolIsSelfPlayTTS(void);


@protocol TTPhonePlayToolObserver <NSObject>

@optional
- (void)musicPlayer:(id<TTMusicPlayerObject>)player changeState:(TTPlayerState)state;
- (void)musicPlayer:(id<TTMusicPlayerObject>)player updateAlbumTrack:(id<TTAlbumTrackProtocol>)albumTrack;

- (void)didPlayingStateChange:(BOOL)isPlaying;
- (void)didSeekToPosition:(CGFloat)position;
- (void)didPlayToPosition:(CGFloat)position;
- (void)didCacheToPostion:(CGFloat)position;
- (void)didPlayerBufferFull;
- (void)didPlayerBufferEmpty;

@end

NS_ASSUME_NONNULL_END
