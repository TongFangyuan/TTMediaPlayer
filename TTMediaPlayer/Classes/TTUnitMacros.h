//
//  TTUnitsMacros.h
//  Pods
//
//  Created by Tong on 2020/6/3.
//

#import <Foundation/Foundation.h>

#ifndef TT_LOCK
#define TT_LOCK(lock) dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
#endif

#ifndef TT_UNLOCK
#define TT_UNLOCK(lock) dispatch_semaphore_signal(lock);
#endif
