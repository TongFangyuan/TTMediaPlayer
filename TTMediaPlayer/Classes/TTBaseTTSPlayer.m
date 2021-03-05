//
//  TTBaseTTSPlayer.m
//  MobileAir
//
//  Created by Tong on 2019/9/3.
//  Copyright © 2019 芯中芯. All rights reserved.
//

#import "TTBaseTTSPlayer.h"

TTTTSNotificaionName const TTTTSPlayDidStartNotification  = @"TTTTSPlayDidStartNotification";
TTTTSNotificaionName const TTTTSPlayDidFinishNotification = @"TTTTSPlayDidFinishNotification";

void TTBaseTTSPlayerNotiPlayStart() {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:TTTTSPlayDidStartNotification object:nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ASSoundBoxManagerDidStartTTSPlaybackNotification" object:nil];
    });
}

void TTBaseTTSPlayerNotiPlayFinish() {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:TTTTSPlayDidFinishNotification object:nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"TLSoundBoxManagerDidCompleteTTSPlaybackNotification" object:nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ASSoundBoxManagerDidCompleteTTSPlaybackNotification" object:nil];
    });
}

@interface TTBaseTTSPlayer ()
{
    NSInteger currentIndex;
}
@property (nonatomic,strong) AVPlayer *player;
@property (nonatomic,strong) NSMutableArray *ttsUrls;
@property (nonatomic,copy) void(^callback)(void);

@end

@implementation TTBaseTTSPlayer

- (void)play:(nonnull NSArray<NSString *> *)urls callback:(nullable void (^)(void))callback {
    [self notiPlayStart];
    currentIndex=0;
    self.ttsUrls = urls.mutableCopy;
    self.callback = callback;
    [self playTTS:self.ttsUrls.firstObject];
}

- (void)playTTS:(NSString *)url {
    NSURL *URL = nil;
    if ([url hasPrefix:@"http://"] || [url hasPrefix:@"https://"]) {
        URL =[NSURL URLWithString:url];
    } else {
        URL = [NSURL fileURLWithPath:url];
    }
    AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithURL:URL];
    AVPlayer *player = [AVPlayer playerWithPlayerItem:playerItem];
    self.player = player;
    [self addPlayerItemObserver];
    [self.player play];
}

- (void)pause {
    [self.player pause];
}

- (void)resume {
    [self.player play];
}

- (void)resetPlayer {
    [self stop];
    self.ttsUrls = nil;
}

- (void)stop {
    [self.player pause];
    [self removePlayerItemObserver];
    self.player = nil;
}

- (void)next {
    NSString *url = [self nextTTSUrl];
    if ( url.length>0 ) {
        NSString *url = self.ttsUrls[currentIndex];
        [self playTTS:url];
    } else {
        [self resetPlayer];
        [self notiPlayFinish];
    }
}

- (NSString *)nextTTSUrl {
    currentIndex++;
    NSString *url = nil;
    if (currentIndex<self.ttsUrls.count) {
        url = self.ttsUrls[currentIndex];
        NSLog(@"🐵 %@", url);
    } else {
        NSLog(@"🐵 没有TTS了");
    }
    return url;
}

- (BOOL)isPlaying {
    if ((self.player) && (self.player.rate != 0) && (self.player.error == nil)) {
        NSLog(@"🐵 播放器 isPlaying");
        return YES;
    }
    NSLog(@"🐵 播放器 isNotPlaying");
    return NO;
}

- (void)dealloc {
    NSLog(@"🐵 TTS释放 %@",self);
}
#pragma mark - ------------- 外部通知 ------------------
- (void)notiPlayStart {
    NSLog(@"🎺 TTS开始播放通知");
    TTBaseTTSPlayerNotiPlayStart();
}

- (void)notiPlayFinish {
    NSLog(@"🎺 TTS结束播放通知");
    if (self.callback) {
        self.callback();
    }
    TTBaseTTSPlayerNotiPlayFinish();
}

@end


#pragma mark - ------------- PlayerItem 状态监听 ------------------

static void* TTPlayerItemContext = &TTPlayerItemContext;

typedef NSString * TTPlayerItemProperty;
/**
 这个属性的值是一个AVPlayerItemStatus，它指示接收器是否可以用于播放，一般为可以播放。
 最重要的需要观察的属性！！当你第一次创建AVPlayerItem时，其状态值为AVPlayerItemStatusUnknown，表示其媒体尚未加载，尚未排入队列进行播放。将AVPlayerItem与AVPlayer相关联后会立即开始排列该项目的媒体并准备播放，但是在准备好使用之前，需要等到其状态变为AVPlayerItemStatusReadyToPlay;
 */
static TTPlayerItemProperty TTStatus = @"status";

@implementation TTBaseTTSPlayer (PlayerItemObserver)

- (void)addPlayerItemObserver {
    AVPlayerItem *playerItem = self.player.currentItem;
    if (playerItem) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidPlayToEndTime:) name:AVPlayerItemDidPlayToEndTimeNotification object:playerItem];
        [playerItem addObserver:self forKeyPath:TTStatus options:NSKeyValueObservingOptionNew context:TTPlayerItemContext];    }
}

- (void)removePlayerItemObserver {
    AVPlayerItem *playerItem = self.player.currentItem;
    if (playerItem) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:playerItem];
        [playerItem removeObserver:self forKeyPath:TTStatus];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    
    if (context != TTPlayerItemContext) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }
    if (object != self.player.currentItem) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        NSLog(@"🐵 不是当前 PlayerItem");
        return;
    }
    if ([keyPath isEqualToString:TTStatus]) {
        [self handleStatusChange:object];
    }
    
}

- (void)handleStatusChange:(AVPlayerItem *)item {
    if (item.status==AVPlayerItemStatusFailed) {
        NSError *error = [item error];
        NSLog(@"🐵 TTS播放出错：%@", error);
        [self stop];
        [self next];
    } else if (item.status==AVPlayerItemStatusReadyToPlay) {
        NSLog(@"🐵 TTS开始播放");
    } else if (item.status==AVPlayerItemStatusUnknown) {
        NSLog(@"🐵 TTS尚未加载，尚未排入队列进行播放");
    }
}

/// 播放完成通知
- (void)playerItemDidPlayToEndTime:(NSNotification *)noti {
    NSLog(@"🐵 TTS播放完成：%@",noti);
    [self stop];
    [self next];
}

@end
