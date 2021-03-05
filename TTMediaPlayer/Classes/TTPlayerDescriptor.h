//
//  TTPlayerDescriptor.h
//  MobileAir
//
//  Created by Tong on 2019/9/3.
//  Copyright © 2019 芯中芯. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * 音频资源类型
 * 有本地音乐、图灵web端、亚马逊音乐等资源类型，可以自定义类型，自定义类型需要注册专属的播放器
 */
typedef NSString * TTMediaSourceName;


#pragma mark - ---- 专辑协议定义 ----
@protocol TTAlbumTrackProtocol <NSObject>

@required
@property (nonatomic,strong) NSString *songName; //!< 歌名
@property (nonatomic,strong) NSString *singer;   //!< 歌手
@property (nonatomic,strong) NSString *playUrl;  //!< 播放地址
@property (nonatomic,strong) NSString *imageUrl; //!< 专辑封面专辑
@property (nonatomic,assign) BOOL isBoxMusic;    //!< 是否是音箱音乐<在线音乐和音箱音乐区分>
@property (nonatomic,assign) BOOL isLocalMusic;  //!< 本地音乐
@property (nonatomic,assign) BOOL isOnlineMusic;
@property (nonatomic,strong) UIImage *lockImage; //!< 如果已经加载到专辑封面 直接复制给这个属性 锁屏时不再请求网络数据

@end

#pragma mark - ---- 播放器功能协议定义 ----
@protocol TTMusicPlayerObject;

/// 兼容之前的代码
@protocol XZXMediaPlayerStatusDelegate <NSObject>
@optional
- (void)xzxMediaPlayerPlayStart;
- (void)xzxMediaPlayerPaused;
- (void)xzxMediaPlayerPlayError:(NSError *)error;
- (void)xzxMediaPlayerSeekPosition:(CGFloat)position;
- (void)xzxMediaPlayerUpdateProgress:(CGFloat)position;
- (void)xzxMediaPlayerPlayFinished;
@end

@protocol TTMusicPlayerStatusDelegate <XZXMediaPlayerStatusDelegate>
@optional
- (void)playerWillStart:(id<TTMusicPlayerObject>)player;
- (void)playerDidStart:(id<TTMusicPlayerObject>)player;
- (void)playerDidPaused:(id<TTMusicPlayerObject>)player;
- (void)playerDidFinished:(id<TTMusicPlayerObject>)player;
- (void)playerDidContiuPlay:(id<TTMusicPlayerObject>)player;
- (void)player:(id<TTMusicPlayerObject>)player playError:(NSError *)error;
- (void)playerBufferFull:(id<TTMusicPlayerObject>)player;
- (void)playerBufferEmpty:(id<TTMusicPlayerObject>)player;
- (void)player:(id<TTMusicPlayerObject>)player didSeekToPostion:(CGFloat)postion;
- (void)player:(id<TTMusicPlayerObject>)player playToPostion:(CGFloat)postion;
- (void)player:(id<TTMusicPlayerObject>)player cacheToPostion:(CGFloat)postion;

@end

@protocol TTMusicPlayerObject <NSObject>

/** 歌曲 */
@property (nonatomic, strong) id<TTAlbumTrackProtocol> albumTrack;
/** 歌曲队列 */
@property (nonatomic, strong) NSArray<id<TTAlbumTrackProtocol>> *songList;
/** 当前播放索引 */
@property (nonatomic, assign) NSInteger currentTrackIndex;
/// 歌曲播放模式
typedef enum : NSUInteger {
    TTPhonePlayModeCircle,     //!< 循环播放(播放完最后一首歌会切到第一首歌播放) kTLPhonePlayModeCircle
    TTPhonePlayModeRandom,     //!< 随机播放 kTLPhonePlayModeRandom
    TTPhonePlayModeOneMusic,   //!< 单曲播放 kTLPhonePlayModeOneMusic
    TTPhonePlayModeOrder,      //!< 顺序播放(播完最后一首歌停止)
} TTPhonePlayMode;
/** 播放模式 */
@property (nonatomic, assign) TTPhonePlayMode playMode;
/** 当前播放时间 单位：秒 */
@property (nonatomic, assign) NSTimeInterval currentTime;
/** 当前缓存时间 单位：秒 */
@property (nonatomic, assign) NSTimeInterval cacheTime;
/** 当前播放时间 单位：毫秒 */
@property (nonatomic, assign, readonly) NSTimeInterval currentMsec;
/** 播放状态 */
@property (nonatomic, assign, readonly) BOOL isPlaying;
/** 总时长 */
@property (nonatomic, assign) NSTimeInterval duration;
/** 播放进度 0~1 */
@property (nonatomic, assign) CGFloat position;
/** 缓存进度 0~1 */
@property (nonatomic, assign) CGFloat loadedPostion;
/** 当前格式时间 */
@property (nonatomic, copy, readonly) NSString *currentTimeText;
/** 剩下格式时间 */
@property (nonatomic, copy, readonly) NSString *durationText;
/** 状态委托 */
@property (nonatomic, weak) id<TTMusicPlayerStatusDelegate> delegate;


// -------------------------------- 播放控制  --------------------------------
/** 单曲播放，url */
- (void)play:(NSString *)url;
/** 单曲播放，album */
- (void)playAlbum:(id<TTAlbumTrackProtocol>)album;
/** 队列播放，index为播放第几首 */
- (void)play:(NSArray<id<TTAlbumTrackProtocol>> *)songList index:(NSInteger)index;
/** 暂停播放 */
- (void)pause;
/** 停止播放 */
- (void)stop;
/** 跳播，position为0~1 */
- (void)seekToPosition:(CGFloat)position;
/** 继续播放 */
- (void)continuePlay;
/** 播放下一首 */
- (void)next;
/** 播放上一首 */
- (void)previous;
- (void)updateAblumTracks:(NSArray<id<TTAlbumTrackProtocol>> *)ablums;

// -------------------------------- 播放控制  --------------------------------


// -------------------------------- 便捷函数  --------------------------------
/** 格式转化时间 */
- (NSUInteger)getSecondsByTimeString:(NSString *)timeString;
/** 时间转化格式 */
- (NSString *)TimeformatFromSeconds:(NSInteger)seconds;
// -------------------------------- 便捷函数  --------------------------------

@end


#pragma mark - ------------- 播放器助手对象协议 ------------------

typedef NS_ENUM(NSInteger, TTMusicPlayerControl) {
    TTMusicPlayerControlPlay = 1,
    TTMusicPlayerControlPause,
    TTMusicPlayerControlPre,
    TTMusicPlayerControlNext,
    TTMusicPlayerControlStop,
    TTMusicPlayerControlManualPause,
    TTMusicPlayerControlManualResume,
    TTMusicPlayerControlInterruptPause,
    TTMusicPlayerControlInterruptResume,
};

@protocol TTPhonePlayToolObject <NSObject>

/** 正在工作的播放器 */
@property (nonatomic, strong, readonly) id<TTMusicPlayerObject> player;

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
/** 是否在后台 */
@property (nonatomic,assign) BOOL isForeground;
/** 电话打断结束后是否需要继续播放 */
@property (nonatomic,assign) BOOL needContinue;
/** 是否手动暂停 */
@property (nonatomic,assign) BOOL manualPause;

/** 本地控制 */
@property (nonatomic ,assign) TTMusicPlayerControl localControl;
/** 播放模式 */
@property (nonatomic, assign) TTPhonePlayMode playMode;
/** 有音箱时的播放状态 */
@property (nonatomic, assign, readonly) BOOL isMediaPlaying;
/** 交互推送的音乐 */
@property (nonatomic, assign) BOOL isBoxMusic;

/******************** 禁用阿里音乐播放器 **********/
@property (nonatomic, assign) BOOL disableRecognizer;
@property (nonatomic, assign) BOOL disableAliMediaPlayer;

// -------------------------------- 歌曲信息  end --------------------------------

/// 播放单曲，根据资源类型内部使用对应播放器播放
- (void)playMusic:(NSString *)url
           source:(TTMediaSourceName)source;

/// 播放专辑
- (void)playMusicWithAlbum:(id<TTAlbumTrackProtocol>)album
                    source:(TTMediaSourceName)source;

/// 播放队列歌曲
- (void)playMusics:(NSArray<id<TTAlbumTrackProtocol>> *)albums
             index:(NSInteger)index
            source:(TTMediaSourceName)source;

/// 播放控制
- (void)playControl:(TTMusicPlayerControl)control;

/// 暂停音乐播放器
- (void)pause;
/// 电话打进来时候暂停音乐播放器
- (void)interruptPause;
/// 继续播放
- (void)continuePlay;
/// 停止音乐播放器
- (void)stop;
/// 停止所有播放器
- (void)allStop;
/// 前一首
- (void)playPrevious;
/// 下一首
- (void)playNext;

- (void)updateLockScreenInfo;

#pragma mark  ⚠️ ⚠️ ⚠️ ⚠️ ⚠️
#pragma mark  ⚠️  废 弃 方 法
#pragma mark  ⚠️ ⚠️ ⚠️ ⚠️ ⚠️

/** 本地播放歌曲语音交互操作类型 */
typedef NS_ENUM(NSUInteger, LocalPlaySpeechType) {
    kLocalPlaySpeechTypePlay  = TTMusicPlayerControlPlay,
    kLocalPlaySpeechTypePause = TTMusicPlayerControlPause,
    kLocalPlaySpeechTypePrev  = TTMusicPlayerControlPre,
    kLocalPlaySpeechTypeNext  = TTMusicPlayerControlNext,
    kLocalPlaySpeechTypeStop  = TTMusicPlayerControlStop
} DEPRECATED_MSG_ATTRIBUTE("提示使用 TTMusicPlayerControl 代替");

/**
 设置系统锁频界面，歌曲信息

 @param music 歌曲信息
 */
- (void)setLockScreenNowPlayingInfo:(id<TTAlbumTrackProtocol>)music DEPRECATED_MSG_ATTRIBUTE("提示使用updateLockScreenInfo方法代替");


/// 内部本质调用的是 setLockScreenNowPlayingInfo: 方法
- (void)operate DEPRECATED_MSG_ATTRIBUTE("提示使用updateLockScreenInfo方法代替");

@end


#pragma mark - ------------- 音频资源类型定义 ------------------
extern TTMediaSourceName const TTMediaSourceLocal;          //!< 本地资源
extern TTMediaSourceName const TTMediaSourceTuringWeb;      //!< 图灵web端资源
extern TTMediaSourceName const TTMediaSourceTuringMusic;    //!< 图灵音乐领域资源
extern TTMediaSourceName const TTMediaSourceTuringStory;    //!< 图灵故事
extern TTMediaSourceName const TTMediaSourceTuringPoetry;   //!< 图灵诗词
extern TTMediaSourceName const TTMediaSourceAlexaMusic;     //!< alexa音乐
extern TTMediaSourceName const TTMediaSourceIMusic;         //!< 爱音乐资源
extern TTMediaSourceName const TTMediaSourceTuringTTS;      //!< 图灵TTS播放
extern TTMediaSourceName const TTMediaSourceTuringOnlieTTS; //!< 图灵语音合成TTS
extern TTMediaSourceName const TTMediaSourceAlexaTTS;       //!< AlexaTTS资源
extern TTMediaSourceName const TTMediaSourceTuringInstrument; //!< 图灵乐器
extern TTMediaSourceName const TTMediaSourceRadioStation;   //!< 国际电台

NS_ASSUME_NONNULL_END
