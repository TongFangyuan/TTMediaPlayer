//
//  TTBaseMusicPlayer.m
//  MobileAir
//
//  Created by Tong on 2019/8/29.
//  Copyright © 2019 芯中芯. All rights reserved.
//

#import "TTBaseMusicPlayer.h"

@interface TTBaseMusicPlayer ()

@property (nonatomic,assign) BOOL isSeeking;

@property (nonatomic,strong) AVPlayer *player;

@property (nonatomic,strong) id timeObserver;

@property (nonatomic,strong) NSDictionary *kvoSelMap;

@end

@implementation TTBaseMusicPlayer

+ (void)initialize {
    
}

#pragma mark - ------------- TTMusicPlayerObject ------------------

- (void)play:(NSString *)url {
    if (!url) {
        NSLog(@"🔋 歌曲为空");
        [self notiPlayFinished];
        return;
    }
    
    [self stop];
    [self notiPlayWillStart];
    
    AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithURL:[NSURL URLWithString:url]];
    AVPlayer *player = [AVPlayer playerWithPlayerItem:playerItem];
    self.player = player;
    [self addTimeObserver];
    [self setupKVOChangeHandler];
    [self addPlayerItemObserver];
    
    [self.player play];
}

- (void)playAlbum:(id<TTAlbumTrackProtocol>)album {
    if (!album) {
        NSLog(@"🔋 歌曲为空");
        [self notiPlayFinished];
        return;
    }
    if (!self.songList || self.songList.count==0) {
        self.songList = @[album];
    }

    self.albumTrack = album;
    [self play:album.playUrl];
}

- (void)play:(NSArray<id<TTAlbumTrackProtocol>> *)songList index:(NSInteger)index {
    self.songList = [NSArray arrayWithArray:songList];
    id<TTAlbumTrackProtocol> album = songList[index];
    [self playAlbum:album];
}

- (void)updateAblumTracks:(NSArray<id<TTAlbumTrackProtocol>> *)ablums {
    self.songList = [NSArray arrayWithArray:ablums];
}

- (void)setSongList:(NSArray<id<TTAlbumTrackProtocol>> *)songList{
    _songList = songList;
    NSInteger i = _songList.count;
    NSMutableArray *mut = _songList.mutableCopy;
    while (--i > 0) {
        NSInteger j = rand() % (i+1);
        [mut exchangeObjectAtIndex:i withObjectAtIndex:j];
    }
    self.randomSongList = mut.copy;
}

- (void)seekToPosition:(CGFloat)position {
    if (!self.timeObserver) {
        NSLog(@"🔋 无法跳播");
        return;
    }
    if (self.isSeeking) {
        NSLog(@"🔋 无法跳播");
        return;
    }
    NSLog(@"🔋 准备跳播：%f",position);
    self.isSeeking = YES;
    BOOL isPlaying = self.isPlaying;
    typeof(self) weakSelf = self;
    [self.player seekToTime:CMTimeMake(position*self.duration, 1) completionHandler:^(BOOL finished) {
        if (finished) {
            NSLog(@"🔋 跳播完成：%f",position);
            weakSelf.isSeeking = NO;
            [weakSelf notiPlayDidSeekToPosition:position];
            if (isPlaying) {
            [weakSelf continuePlay];
            } else {
                [weakSelf pause];
            }
        }
    }];
}

- (void)continuePlay {
    if (self.player) {
        [self.player play];
        [self notiContinuePlay];
    }
}

- (void)next {
    [self playAlbum:[self manualNextAlbumTrack]];
}

- (void)pause {
    if (self.player) {
        [self.player pause];
        [self notiPlayPaused];
    }
}

- (void)previous {
    [self playAlbum:[self manualPreviousAlbumTrack]];
}

- (void)stop {
    if (!self.player) return;
    
    [self.player pause];
    [self removeTimeObserver];
    [self removePlayerItemObserver];
    [self removeKVOChangeHandler];
    self.player = nil;
}


- (NSInteger)currentTrackIndex {
    if (self.albumTrack) {
        return [self.songList indexOfObject:self.albumTrack];
    }
    return 0;
}

- (BOOL)isPlaying {
    if ((self.player) && (self.player.rate != 0) && (self.player.error == nil)) {
        NSLog(@"🔋 播放器 isPlaying");
        return YES;
    }
    NSLog(@"🔋 播放器 isNotPlaying");
    return NO;
}

- (NSString *)currentTimeText {
    return [self TimeformatFromSeconds:self.currentTime];
}

- (NSString *)durationText {
    return [self TimeformatFromSeconds:self.duration];
}

- (NSUInteger)getSecondsByTimeString:(NSString *)timeString
{
    NSArray *arr = [timeString componentsSeparatedByString:@":"];
    NSEnumerator *enumer = [arr reverseObjectEnumerator];
    NSString *str = nil;
    NSUInteger seconds = 0;
    while (str = [enumer nextObject]) {
        NSUInteger mul = 1;
        for (int i = 1; [arr indexOfObject:str] + i < arr.count; ++i) {
            mul *= 60;
        }
        seconds += fabs(str.floatValue) * mul;
    }
    
    return seconds;
}

- (NSString *)TimeformatFromSeconds:(NSInteger)seconds
{
    //format of hour
    NSString *str_hour = [NSString stringWithFormat:@"%02ld",seconds/3600];
    //format of minute
    NSString *str_minute = [NSString stringWithFormat:@"%02ld",(seconds%3600)/60];
    //format of second
    NSString *str_second = [NSString stringWithFormat:@"%02ld",seconds%60];
    //format of time
    if ([str_hour isEqualToString: @"00"]) { //如果小时数为0，只显示分和秒
        return [NSString stringWithFormat:@"%@:%@",str_minute,str_second];
    } else {
        return [NSString stringWithFormat:@"%@:%@:%@",str_hour,str_minute,str_second];
    }
}

#pragma mark 废弃方法
- (void)xzxMediaContinuePlay {
    [self continuePlay];
}

- (void)xzxMediaPause {
    [self pause];
}

- (void)xzxMediaPlay:(nonnull NSString *)musicUrl {
    [self play:musicUrl];
}

- (void)xzxMediaPlayNext {
    [self next];
}

- (void)xzxMediaPlayPrevious {
    [self previous];
}

- (void)xzxMediaPlayerDidFinishPlaying {
    NSAssert(0, @"方法未实现");
}

- (void)xzxMediaSeekToPosition:(CGFloat)position {
    [self seekToPosition:position];
}

- (void)xzxMediaStop {
    [self stop];
}

#pragma mark - ------------- 私有方法 ------------------
- (void)dealloc {
    NSLog(@"🔋 释放：%@", self);
}

#pragma mark - ---- 辅助方法 ----
+ (NSString *)TTMusicPlayerModeDesc:(TTPhonePlayMode)mode {
    static dispatch_once_t onceToken;
    static NSDictionary *_modeDesc = nil;
    dispatch_once(&onceToken, ^{
        _modeDesc = @{
            @(TTPhonePlayModeOrder):@"顺序播放(播完最后一首歌停止)"
            ,@(TTPhonePlayModeCircle):@"循环播放(播放完最后一首歌会切到第一首歌播放)"
            ,@(TTPhonePlayModeRandom):@"随机播放"
            ,@(TTPhonePlayModeOneMusic):@"单曲播放"
            ,@(TTPhonePlayModeStopAfterCurrent):@"播完当前歌曲后，停止"
        };
    });
    return _modeDesc[@(mode)];
}

@end

#pragma mark - ------------- AlbumTrack ------------------

@implementation TTBaseMusicPlayer (AlbumTrack)

- (id<TTAlbumTrackProtocol>)manualNextAlbumTrack {
    switch (self.playMode) {
        case TTPhonePlayModeRandom:
            return [self randomNextAlbumTrack];
        default:
            return [self circleNextAlbumTrack];
    }
}

- (id<TTAlbumTrackProtocol>)manualPreviousAlbumTrack {
    switch (self.playMode) {
        case TTPhonePlayModeRandom:
            return [self randomPreviousAlbumTrack];
        default:
            return [self circlePreviousAlbumTrack];
    }
}

- (id<TTAlbumTrackProtocol>)autoNextAlbumTrack {
    switch (self.playMode) {
        case TTPhonePlayModeOneMusic:
            return [self albumTrack];
        case TTPhonePlayModeRandom:
            return [self randomAlbumTrack];
        case TTPhonePlayModeOrder:
            return [self orderNextAlbumTrack];
        case TTPhonePlayModeCircle:
        case TTPhonePlayModeStopAfterCurrent:
        default:
            return [self circleNextAlbumTrack];
    }
}

- (id<TTAlbumTrackProtocol>)randomAlbumTrack {
    NSInteger index = arc4random()%self.songList.count;
    return self.songList[index];
}

- (id<TTAlbumTrackProtocol>)randomNextAlbumTrack {
    NSInteger currentIndex = [self.randomSongList indexOfObject:self.albumTrack];
    if (currentIndex>=self.randomSongList.count) {
        return self.randomSongList.firstObject;
    }
    id<TTAlbumTrackProtocol> album = self.randomSongList[currentIndex+1];
    return album;
}

- (id<TTAlbumTrackProtocol>)randomPreviousAlbumTrack {
    NSInteger currentIndex = [self.randomSongList indexOfObject:self.albumTrack];
    if (currentIndex==0) {
        return self.randomSongList.lastObject;
    }
    id<TTAlbumTrackProtocol> album = self.randomSongList[currentIndex-1];
    return album;
}

- (id<TTAlbumTrackProtocol>)firstAlbumTrack {
    return self.songList.firstObject;
}

- (id<TTAlbumTrackProtocol>)lastAlbumTrack {
    return self.songList.lastObject;
}

- (nullable id<TTAlbumTrackProtocol>)orderNextAlbumTrack {
    if (self.currentTrackIndex>=self.songList.count-1) {
        return nil;
    }
    return self.songList[self.currentTrackIndex+1];
}

- (nullable id<TTAlbumTrackProtocol>)orderPreviousAlbumTrack {
    if (self.currentTrackIndex==0) {
        return nil;
    }
    return self.songList[self.currentTrackIndex-1];
}

- (id<TTAlbumTrackProtocol>)circleNextAlbumTrack {
    if (self.currentTrackIndex>=self.songList.count-1) {
        return self.songList.firstObject;
    }
    return self.songList[self.currentTrackIndex+1];
}

- (id<TTAlbumTrackProtocol>)circlePreviousAlbumTrack {
    if (self.currentTrackIndex==0) {
        return self.songList.lastObject;
    }
    return self.songList[self.currentTrackIndex-1];
}

@end

#pragma mark - ------------- 播放进度监听 ------------------

@implementation TTBaseMusicPlayer (TimeObserver)

- (void)addTimeObserver {
    [self removeTimeObserver];
    
    typeof(self) weakSelf = self;
    self.timeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1.0 / 60.0, NSEC_PER_SEC) queue:NULL usingBlock:^(CMTime time) {
        [weakSelf notiPlayToPosition:weakSelf.position];
    }];
}

- (void)removeTimeObserver {
    if (self.timeObserver) {
        [self.player removeTimeObserver:self.timeObserver];
        self.timeObserver = nil;
        NSLog(@"🔋 移除之前时间监听");
    }
}

@end

#pragma mark - ------------- PlayerItem 状态监听 ------------------

static void* TTPlayerItemContext = &TTPlayerItemContext;

/** 缓存超过指定时长，播放器继续播放 */
static CGFloat kContinuePlayOverBufferTime = 0.5;

typedef NSString * TTPlayerItemProperty;
/**
 这个属性的值是一个AVPlayerItemStatus，它指示接收器是否可以用于播放，一般为可以播放。
 最重要的需要观察的属性！！当你第一次创建AVPlayerItem时，其状态值为AVPlayerItemStatusUnknown，表示其媒体尚未加载，尚未排入队列进行播放。将AVPlayerItem与AVPlayer相关联后会立即开始排列该项目的媒体并准备播放，但是在准备好使用之前，需要等到其状态变为AVPlayerItemStatusReadyToPlay;
 */
static TTPlayerItemProperty TTStatus = @"status";
/** 已加载Item的时间范围 */
static TTPlayerItemProperty TTLoadedTimeRanges = @"loadedTimeRanges";
/** 指示播放是否消耗了所有缓冲媒体，播放将停止或结束 */
static TTPlayerItemProperty TTPlaybackBufferEmptys = @"playbackBufferEmpty";
/** 缓存区是否已经满了，并且进一步的I / O是否被挂起 */
static TTPlayerItemProperty TTPlaybackBufferFull = @"playbackBufferFull";
/**
 指示该item是否能无延迟播放，用于监听缓存足够播放的状态，在这里，当属性playbackBufferFull指示YES时，可能是playbackLikelyToKeepUp指示NO。 在这种情况下，播放缓存已经达到了容量，但是没有统计数据来支持，所以播放可能持续，所以这里需要程序员决定是否继续媒体播放;
 */
static TTPlayerItemProperty TTPlaybackLikelyToKeepUp = @"playbackLikelyToKeepUp";

@implementation TTBaseMusicPlayer (PlayerItemObserver)

- (void)addPlayerItemObserver {
    AVPlayerItem *playerItem = self.player.currentItem;
    if (playerItem) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidPlayToEndTime:) name:AVPlayerItemDidPlayToEndTimeNotification object:playerItem];
        [playerItem addObserver:self forKeyPath:TTStatus options:NSKeyValueObservingOptionNew context:TTPlayerItemContext];
        [playerItem addObserver:self forKeyPath:TTLoadedTimeRanges options:NSKeyValueObservingOptionNew context:TTPlayerItemContext];
        [playerItem addObserver:self forKeyPath:TTPlaybackBufferEmptys options:NSKeyValueObservingOptionNew context:TTPlayerItemContext];
        [playerItem addObserver:self forKeyPath:TTPlaybackBufferFull options:NSKeyValueObservingOptionNew context:TTPlayerItemContext];
        [playerItem addObserver:self forKeyPath:TTPlaybackLikelyToKeepUp options:NSKeyValueObservingOptionNew context:TTPlayerItemContext];
    }
}

- (void)removePlayerItemObserver {
    AVPlayerItem *playerItem = self.player.currentItem;
    if (playerItem) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:playerItem];
        [playerItem removeObserver:self forKeyPath:TTStatus];
        [playerItem removeObserver:self forKeyPath:TTLoadedTimeRanges];
        [playerItem removeObserver:self forKeyPath:TTPlaybackBufferEmptys];
        [playerItem removeObserver:self forKeyPath:TTPlaybackBufferFull];
        [playerItem removeObserver:self forKeyPath:TTPlaybackLikelyToKeepUp];
    }
}

- (void)setupKVOChangeHandler {
    self.kvoSelMap = @{
                       TTStatus:NSStringFromSelector(@selector(handleStatusChange:)),
                       TTLoadedTimeRanges:NSStringFromSelector(@selector(handleLoadedTimeRanges:)),
                       TTPlaybackBufferEmptys:NSStringFromSelector(@selector(handlePlaybackBufferEmpty:)),
                       TTPlaybackBufferFull:NSStringFromSelector(@selector(handlePlaybackBufferFull:)),
                       TTPlaybackLikelyToKeepUp:NSStringFromSelector(@selector(handlePlaybackLikelyToKeepUp:))
                       };
}

- (void)removeKVOChangeHandler {
    self.kvoSelMap = nil;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    
    if (context != TTPlayerItemContext) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }
    if (object != self.player.currentItem) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        NSLog(@"⚠️ 不是当前 PlayerItem");
        return;
    }
    
    if (self.kvoSelMap[keyPath]) {
        SEL selector = NSSelectorFromString(self.kvoSelMap[keyPath]);
        if ([self respondsToSelector:selector]) {
            [self performSelector:selector withObject:object];
        }
    } else {
        NSAssert(0, @"未处理KVO , %@",keyPath);
    }
    
}

- (void)handleStatusChange:(AVPlayerItem *)item {
    if (item.status==AVPlayerItemStatusFailed) {
        NSError *error = [item error];
        NSLog(@"🔋 播放出错：%@", error);
        [self notiPlayError:error];
    } else if (item.status==AVPlayerItemStatusReadyToPlay) {
        NSLog(@"🔋 音频可以开始播放了");
        [self notiPlayDidStart];
    } else if (item.status==AVPlayerItemStatusUnknown) {
        NSLog(@"🔋 媒体尚未加载，尚未排入队列进行播放");
    }
}

- (void)handleLoadedTimeRanges:(AVPlayerItem *)item {
    
    NSTimeInterval currentTime = self.currentTime;
    NSTimeInterval cacheTime   = self.cacheTime;
    [self notiPlayCacheToPosition:self.loadedPostion];
    
    if (cacheTime-currentTime>=kContinuePlayOverBufferTime) {
//        NSLog(@"🔋 预加载超过%.2f秒",kContinuePlayOverBufferTime);
    } else if (cacheTime-currentTime<kContinuePlayOverBufferTime) {
//        NSLog(@"🔋 预加载少于%.2f秒",kContinuePlayOverBufferTime);
    }
}

- (void)handlePlaybackBufferEmpty:(AVPlayerItem *)item {
    if (item.playbackBufferEmpty) {
        NSLog(@"🔋 音频缓存为空，可能需要暂停播放");
        [self notiBufferEmpty];
        [[NSNotificationCenter defaultCenter] postNotificationName:TTMusicPlayerBufferEmptyNotification object:nil];
    }
}

- (void)handlePlaybackBufferFull:(AVPlayerItem *)item {
    if (item.playbackBufferFull) {
        NSLog(@"🔋 音频缓存完毕");
        [self notiBufferFull];
    }
}

- (void)handlePlaybackLikelyToKeepUp:(AVPlayerItem *)item {
    if (item.playbackLikelyToKeepUp) {
        NSLog(@"🔋 可以无延迟播放音乐了");
        [self notiBufferFull];
        [[NSNotificationCenter defaultCenter] postNotificationName:TTMusicPlayerNoDelayPlayingNotification object:nil];
    }
}

/// 播放完成通知
- (void)playerItemDidPlayToEndTime:(NSNotification *)noti {
    NSLog(@"🔋 播放完成：%@",noti);
    [self notiPlayFinished];
    if (self.playMode!=TTPhonePlayModeStopAfterCurrent) {
    [self autoNext];
    }
}

@end

#pragma mark - ------------- 时间计算 ------------------

@implementation TTBaseMusicPlayer (NSTimeInterval)

- (CGFloat)loadedPostion {
    return self.cacheTime / self.duration;
}

- (CGFloat)position {
    return self.currentTime / self.duration;
}

- (NSTimeInterval)currentTime {
    AVPlayerItem *item = self.player.currentItem;
    return CMTimeGetSeconds(item.currentTime);
}

- (NSTimeInterval)cacheTime {
    NSArray *loadedTimeRanges = [[self.player currentItem] loadedTimeRanges];
    CMTimeRange timeRange = [loadedTimeRanges.firstObject CMTimeRangeValue];// 获取缓冲区域
    float startSeconds = CMTimeGetSeconds(timeRange.start);
    float durationSeconds = CMTimeGetSeconds(timeRange.duration);
    NSTimeInterval result = startSeconds + durationSeconds;// 计算缓冲总进度
    return result;
}

- (NSTimeInterval)duration {
    
    AVPlayerItem *item = self.player.currentItem;
    double timeLength =  CMTimeGetSeconds(item.duration);
    if (isnan(timeLength)) {
        timeLength = CMTimeGetSeconds(item.asset.duration);
    }
    
#if TT_DEBUG
    if (CMTIME_IS_INDEFINITE(item.duration)) {
        // The value of duration may remain kCMTimeIndefinite for live streams.
        // https://developer.apple.com/documentation/avfoundation/avplayeritem/1389386-duration?language=objc
        CMTimeShow(item.duration);
    }
#endif
    
    return timeLength > 0 ? timeLength : self.currentTime;
}

- (AVPlayerItem *)currentPlayerItem {
    return self.player.currentItem;
}
@end

#pragma mark - ------------- 播放器状态通知给代理 ------------------

@implementation TTBaseMusicPlayer (TTMusicPlayerStatusDelegate)

- (void)notiPlayWillStart {
    if ([self.delegate respondsToSelector:@selector(playerWillStart:)]) {
        [self.delegate playerWillStart:self];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:TTMusicPlayerDidStartNotification object:nil];
    NSLog(@"🔋 准备开始播放");
}

- (void)notiPlayDidStart {
    NSInteger i = self.randomSongList.count;
    NSMutableArray*mut = self.randomSongList.mutableCopy;
    while (--i > 0) {
        NSInteger j = rand() % (i+1);
        [mut exchangeObjectAtIndex:i withObjectAtIndex:j];
    }
    self.randomSongList = mut.copy;
    if ([self.delegate respondsToSelector:@selector(playerDidStart:)]) {
        [self.delegate playerDidStart:self];
    }
    NSLog(@"🔋 开始播放");
}

- (void)notiPlayError:(NSError *)error {
    if ([self.delegate respondsToSelector:@selector(player:playError:)]) {
        [self.delegate player:self playError:error];
    }
    NSLog(@"🔋 播放出错：%@", error);
}

- (void)notiPlayPaused {
    if ([self.delegate respondsToSelector:@selector(playerDidPaused:)]) {
        [self.delegate playerDidPaused:self];
    }
    NSLog(@"🔋 播放暂停");

}

- (void)notiPlayFinished {
    if ([self.delegate respondsToSelector:@selector(playerDidFinished:)]) {
        [self.delegate playerDidFinished:self];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:TTMusicPlayerDidFinishedNotification object:nil];
    NSLog(@"🔋 播放完成");
}

- (void)notiPlayDidSeekToPosition:(CGFloat)position {
    if ([self.delegate respondsToSelector:@selector(player:didSeekToPostion:)]) {
        [self.delegate player:self didSeekToPostion:position];
    }
    NSLog(@"🔋 跳播完成：%f",position);
}

- (void)notiPlayToPosition:(CGFloat)position {
    if ([self.delegate respondsToSelector:@selector(player:playToPostion:)]) {
        [self.delegate player:self playToPostion:self.position];
    }
//    NSLog(@"🔋 播放进度：%f",position);
}

- (void)notiPlayCacheToPosition:(CGFloat)position {
    if ([self.delegate respondsToSelector:@selector(player:cacheToPostion:)]) {
        [self.delegate player:self cacheToPostion:self.loadedPostion];
    }
    NSLog(@"🔋 缓存进度：%f",position);
}

- (void)notiBufferFull {
    if ([self.delegate respondsToSelector:@selector(playerBufferFull:)]) {
        [self.delegate playerBufferFull:self];
    }
    NSLog(@"🔋 缓存完成");
}

- (void)notiBufferEmpty {
    if ([self.delegate respondsToSelector:@selector(playerBufferEmpty:)]) {
        [self.delegate playerBufferEmpty:self];
    }
    NSLog(@"🔋 缓存不足");
}

- (void)notiContinuePlay {
    if ([self.delegate respondsToSelector:@selector(playerDidContiuPlay:)]) {
        [self.delegate playerDidContiuPlay:self];
    }
    NSLog(@"🔋 继续播放");
}
@end

#pragma mark - ------------- 播放控制  ------------------
@implementation TTBaseMusicPlayer (PlayControl)

- (void)autoNext {
    [self playAlbum:[self autoNextAlbumTrack]];
}

@end

#pragma mark - ------------- 通知 ------------------

TTMusicPlayerStateNotificationName const TTMusicPlayerDidStartNotification = @"TTMusicPlayerDidStartNotification";        //!< 播放器开始播放
TTMusicPlayerStateNotificationName const TTMusicPlayerDidFinishedNotification = @"TTMusicPlayerDidFinishedNotification";     //!< 播放器结束播放

TTMusicPlayerStateNotificationName const TTMusicPlayerNoDelayPlayingNotification = @"TTMusicPlayerNoDelayPlayingNotification";    //!< 播放器可以无延迟播放音乐
TTMusicPlayerStateNotificationName const TTMusicPlayerBufferEmptyNotification = @"TTMusicPlayerBufferEmptyNotification";    //!< 音频缓存为空，可能需要暂停播放
