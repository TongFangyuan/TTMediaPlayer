//
//  TTVolumeUnit.h
//  HelloWord
//
//  Created by Tong on 2019/11/7.
//  Copyright © 2019 008. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 系统音量变化通知
static NSString * const TTVolumeUnitChangeNotification = @"TTVolumeUnitChangeNotification";

/// 获取当前音量: 0.0～1.0
extern float TTVolumeUnitGetVolume(void);
/// 设置音量: 0.0～1.0
extern void  TTVolumeUnitSetVolume(float value);
/// 调整音量：值为-1.0~1.0
extern void  TTVolumeUnitAdjustVolume(float adjustValue);

@interface TTVolumeUnit : NSObject

/// 获取当前音量: 0.0～1.0
@property (nonatomic, assign, readonly) float volume;

/// Default YES
@property (nonatomic, assign) BOOL hiddenVolumeView;

+ (instancetype)shareUnit;

/// 设置音量: 0.0～1.0
- (void)setVolume:(float)volume;

/// 调整音量：值为-1.0~1.0
- (void)adjustVolume:(float)volume;

@end

NS_ASSUME_NONNULL_END
