//
//  FGPopupViewScheduler.m
//  FGPopViewScheduler
//
//  Created by FoneG on 2021/6/22.
//

#import "FGPopupScheduler.h"
#import <CoreFoundation/CFRunLoop.h>
#import "FGPopupSchedulerStrategyQueue.h"
#import "FGPopupQueue.h"
#import "FGPopupStack.h"
#import "FGPopupPriorityList.h"

static NSHashTable *FGPopupSchedulers(void) {
    static NSHashTable *schedulers = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        schedulers = [NSHashTable weakObjectsHashTable];
    });
    return schedulers;
}

static void FGRunLoopObserverCallBack(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info){
    for (FGPopupScheduler *scheduler in FGPopupSchedulers()) {
        if (![scheduler isEmpty]) {
            [scheduler registerFirstPopupViewResponder];
        }
    }
}

@interface FGPopupScheduler ()
{
    id<FGPopupSchedulerStrategyQueue> _list;
    FGPopupSchedulerStrategy _pss;
}

@end

@implementation FGPopupScheduler

+ (void)initialize{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        CFRunLoopObserverRef observer = CFRunLoopObserverCreate(CFAllocatorGetDefault(), kCFRunLoopBeforeWaiting | kCFRunLoopExit, true, 0xFFFFFF, FGRunLoopObserverCallBack, nil);
        CFRunLoopAddObserver(CFRunLoopGetMain(), observer, kCFRunLoopCommonModes);
        CFRelease(observer);
    });
}

- (instancetype)initWithStrategy:(FGPopupSchedulerStrategy)pss{
    if (self = [super init]) {
        [FGPopupSchedulers() addObject:self];
        [self setSchedulerStrategy:pss];
    }
    return self;
}

- (void)setSchedulerStrategy:(FGPopupSchedulerStrategy)pss{
    _pss = pss;
    if (pss & FGPopupSchedulerStrategyPriority) {
        FGPopupPriorityList *PriorityList = [[FGPopupPriorityList alloc] init];
        PriorityList.PPAS = pss & FGPopupSchedulerStrategyLIFO ? FGPopupPriorityAddStrategyLIFO : FGPopupPriorityAddStrategyFIFO;
        _list = PriorityList;
    }
    else if (pss == FGPopupSchedulerStrategyFIFO) {
        _list = [[FGPopupQueue alloc] init];
    }
    else if(pss == FGPopupSchedulerStrategyLIFO){
        _list = [[FGPopupStack alloc] init];
    }
}

- (void)add:(id<FGPopupView>)view{
    [self add:view Priority:FGPopupStrategyPriorityNormal];
}

- (void)add:(id<FGPopupView>)view  Priority:(FGPopupStrategyPriority)Priority{
    [_list addPopupView:view Priority:Priority];
    [self registerFirstPopupViewResponder];
}

- (void)remove:(id<FGPopupView>)view{
    [_list removePopupView:view];
}

- (void)removeAllPopupViews{
    [_list clear];
}

- (BOOL)canRegisterFirstPopupViewResponder{
    return [_list canRegisterFirstFirstPopupViewResponder];;
}

- (void)registerFirstPopupViewResponder{
    if (!self.suspended && self.canRegisterFirstPopupViewResponder) {
        [_list execute];
    }
}

- (BOOL)isEmpty{
    return [_list isEmpty];
}

- (void)setSuspended:(BOOL)suspended{
    _suspended = suspended;
    if (!suspended) [self registerFirstPopupViewResponder];
}
@end

FGPopupScheduler * FGPopupSchedulerGetForPSS(FGPopupSchedulerStrategy pss){
    if (pss & FGPopupSchedulerStrategyPriority) {
        if (pss & FGPopupSchedulerStrategyLIFO) {
            static dispatch_once_t onceToken;
            static FGPopupScheduler *scheduler = nil;
            dispatch_once(&onceToken, ^{
                scheduler = [[FGPopupScheduler alloc] initWithStrategy:pss];
            });
            return scheduler;
        }else{
            static dispatch_once_t onceToken;
            static FGPopupScheduler *scheduler = nil;
            dispatch_once(&onceToken, ^{
                scheduler = [[FGPopupScheduler alloc] initWithStrategy:pss];
            });
            return scheduler;
        }
    }
    else if (pss == FGPopupSchedulerStrategyFIFO) {
        static dispatch_once_t onceToken;
        static FGPopupScheduler *scheduler = nil;
        dispatch_once(&onceToken, ^{
            scheduler = [[FGPopupScheduler alloc] initWithStrategy:pss];
        });
        return scheduler;
    }
    else if(pss == FGPopupSchedulerStrategyLIFO){
        static dispatch_once_t onceToken;
        static FGPopupScheduler *scheduler = nil;
        dispatch_once(&onceToken, ^{
            scheduler = [[FGPopupScheduler alloc] initWithStrategy:pss];
        });
        return scheduler;
    }else{
        return nil;
    }
}
