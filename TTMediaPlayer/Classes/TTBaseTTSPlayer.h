//
//  TTBaseTTSPlayer.h
//  MobileAir
//
//  Created by Tong on 2019/9/3.
//  Copyright © 2019 芯中芯. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NSString * TTTTSNotificaionName;

extern TTTTSNotificaionName const TTTTSPlayDidStartNotification;
extern TTTTSNotificaionName const TTTTSPlayDidFinishNotification;

extern void TTBaseTTSPlayerNotiPlayStart(void);
extern void TTBaseTTSPlayerNotiPlayFinish(void);

@protocol TTTTSPlayerProtocol <NSObject>

@required
@property (nonatomic,assign) BOOL isPlaying;

- (void)play:(NSArray<NSString *> *)urls callback:(nullable void(^)(void))callback;
- (void)stop;
- (void)resetPlayer;

@optional
- (void)next;
- (void)pause;
- (void)resume;

@end

/**
 * TTS播放器基类
 */
@interface TTBaseTTSPlayer : NSObject <TTTTSPlayerProtocol>

@property (nonatomic,assign) BOOL isPlaying;

@end

@interface TTBaseTTSPlayer (PlayerItemObserver)

/** 添加 AVPlayerItem KVO 监听 */
- (void)addPlayerItemObserver;
/** 移出 AVPlayerItem KVO 监听 */
- (void)removePlayerItemObserver;

@end

NS_ASSUME_NONNULL_END
