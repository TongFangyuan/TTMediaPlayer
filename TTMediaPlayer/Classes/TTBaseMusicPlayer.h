//
//  TTBaseMusicPlayer.h
//  MobileAir
//
//  Created by Tong on 2019/8/29.
//  Copyright © 2019 芯中芯. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "TTPlayerDescriptor.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * 播放器基类
 *
 * 遵循 TTMusicPlayerObject 协议
 *
 * @note note
 * @attention attention
 */
@interface TTBaseMusicPlayer : NSObject<TTMusicPlayerObject>

/** 歌曲 */
@property (nonatomic, strong) id<TTAlbumTrackProtocol> albumTrack;
/** 歌曲队列 */
@property (nonatomic, strong) NSArray<id<TTAlbumTrackProtocol>> *songList;
/** 当前播放索引 */
@property (nonatomic, assign) NSInteger currentTrackIndex;
/** 播放模式 */
@property (nonatomic, assign) TTPhonePlayMode playMode;
/** 当前播放时间 单位：秒*/
@property (nonatomic, assign) NSTimeInterval currentTime;
/** 当前缓存时间 单位：秒 */
@property (nonatomic, assign) NSTimeInterval cacheTime;
/** 当前播放时间 单位：毫秒 */
@property (nonatomic, assign, readonly) NSTimeInterval currentMsec;
/** 播放状态 */
@property (nonatomic, assign, readonly) BOOL isPlaying;
/** 总时长 */
@property (nonatomic, assign) NSTimeInterval duration;
/** 当前AVPlayerItem */
@property (nonatomic, strong, readonly) AVPlayerItem *currentPlayerItem;
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


#pragma mark - ---- 辅助方法 ----
/// 播放模式字符串
+ (NSString *)TTMusicPlayerModeDesc:(TTPhonePlayMode)mode;

@end

/**
 * 歌曲切换分类
 *
 * 不同播放模式下的歌曲上下首切换
 *
 * @note TTPhonePlayMode
 * @see  TTPhonePlayMode
 */
@interface TTBaseMusicPlayer (AlbumTrack)

/** 手动切到下一首 */
- (id<TTAlbumTrackProtocol>)manualNextAlbumTrack;
/** 手动切到上一首 */
- (id<TTAlbumTrackProtocol>)manualPreviousAlbumTrack;
/** 自动切到下一首 */
- (id<TTAlbumTrackProtocol>)autoNextAlbumTrack;
- (id<TTAlbumTrackProtocol>)randomAlbumTrack;
- (id<TTAlbumTrackProtocol>)firstAlbumTrack;
- (id<TTAlbumTrackProtocol>)lastAlbumTrack;
- (nullable id<TTAlbumTrackProtocol>)orderNextAlbumTrack;
- (nullable id<TTAlbumTrackProtocol>)orderPreviousAlbumTrack;
- (id<TTAlbumTrackProtocol>)circleNextAlbumTrack;
- (id<TTAlbumTrackProtocol>)circlePreviousAlbumTrack;

@end

#pragma mark - ---- 分类 ----
/**
 * 播放进度监听
 */
@interface TTBaseMusicPlayer (TimeObserver)

- (void)addTimeObserver;
- (void)removeTimeObserver;

@end

@interface TTBaseMusicPlayer (PlayerItemObserver)

/** 添加 AVPlayerItem KVO 监听 */
- (void)addPlayerItemObserver;
/** 移出 AVPlayerItem KVO 监听 */
- (void)removePlayerItemObserver;
/** 设置 KVO 监听处理器 */
- (void)setupKVOChangeHandler;
/** 移出 KVO 监听处理器 */
- (void)removeKVOChangeHandler;
@end

@interface TTBaseMusicPlayer (NSTimeInterval)

- (CGFloat)loadedPostion;

- (CGFloat)position;

- (NSTimeInterval)currentTime;

- (NSTimeInterval)cacheTime;

@end


/**
 播放状态通知给Delegate
 
 @see TTMusicPlayerStatusDelegate
 */
@interface TTBaseMusicPlayer (TTMusicPlayerStatusDelegate)

- (void)notiPlayWillStart;
- (void)notiPlayDidStart;
- (void)notiPlayError:(NSError *)error;
- (void)notiPlayPaused;
- (void)notiPlayFinished;
- (void)notiPlayDidSeekToPosition:(CGFloat)position;
- (void)notiPlayToPosition:(CGFloat)position;
- (void)notiPlayCacheToPosition:(CGFloat)position;
- (void)notiBufferFull;
- (void)notiBufferEmpty;
- (void)notiContinuePlay;

@end

/**
 播放控制分类
 */
@interface TTBaseMusicPlayer (PlayControl)

/** 一首歌播完，内部自动播放下一首，外部不建议直接调用 */
- (void)autoNext;

@end



#pragma mark - ------------- 通知定义 ------------------
typedef NSString * TTMusicPlayerStateNotificationName;

extern TTMusicPlayerStateNotificationName const TTMusicPlayerDidStartNotification;        //!< 播放器开始播放
extern TTMusicPlayerStateNotificationName const TTMusicPlayerDidFinishedNotification;     //!< 播放器结束播放
extern TTMusicPlayerStateNotificationName const TTMusicPlayerNoDelayPlayingNotification;     //!< 播放器可以无延迟播放音乐
extern TTMusicPlayerStateNotificationName const TTMusicPlayerBufferEmptyNotification;     //!< 音频缓存为空，可能需要暂停播放
NS_ASSUME_NONNULL_END
