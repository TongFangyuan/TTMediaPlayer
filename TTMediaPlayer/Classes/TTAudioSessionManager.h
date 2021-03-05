//
//  TTAudioSessionManager.h
//  MobileAir
//
//  Created by Tong on 2019/9/21.
//  Copyright © 2019 芯中芯. All rights reserved.
//
//  功能未实现
//
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 普通播放器模式
/// @param error error description
extern void TTAudioSessionManagerNormalPlayerMode(NSError* _Nullable error);

/// 爱音乐模式
/// @param error error description
extern void TTAudioSessionManagerIMusicPlayerMode(NSError* _Nullable error);

/// 录音模式，混播
/// @param error error description
extern void TTAudioSessionManagerRecorderMixMode(NSError* _Nullable error);

/// 录音模式
extern void TTAudioSessionManagerRecorderMode(NSError* _Nullable error);


/// 获取音频焦点
/// @param active active description
/// @param error error description
extern void TTAudioSessionManagerSetActive(BOOL active, NSError* _Nullable error);

/// 设置AudioSession Category
/// @param category category description
/// @param options options description
/// @param error error description
extern void TTAudioSessionManagerSetCategory(AVAudioSessionCategory category, AVAudioSessionCategoryOptions options, NSError* _Nullable error);

@protocol TTAudioSessionManagerDelegate;

/// 音频管理，如果要切换模式，需要先设置音频焦点
@interface TTAudioSessionManager : NSObject

+ (instancetype)shareSession;

- (void)setup;

- (void)addDelegate:(id<TTAudioSessionManagerDelegate>)delegate;
- (void)removeDeleagte:(id<TTAudioSessionManagerDelegate>)delegate;

@end

@protocol TTAudioSessionManagerDelegate <NSObject>

- (void)audioSession:(AVAudioSession *)session didInterruption:(AVAudioSessionInterruptionType)type usnerInfo:(NSDictionary *)userInfo;

@end

NS_ASSUME_NONNULL_END
