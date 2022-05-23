//
//  AppVibration.m
//
//  Created by EEUI 19/06/14.
//  Copyright © 2019 All rights reserved.
//

#import "AppVibration.h"
#import <AVFoundation/AVFoundation.h>

@interface AppVibration ()
{
    NSTimer *timer;
}

@property(nonatomic, assign)NSInteger time;

@end

@implementation AppVibration


+ (id)singletonManger{
    static id manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}


- (void)vibrate:(NSNumber *)time :(AppCallback)callback{
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
}


@end
