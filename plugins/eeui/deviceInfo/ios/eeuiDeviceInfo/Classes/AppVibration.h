//
//  AppVibration.h
//
//  Created by EEUI 19/06/14.
//  Copyright © 2019 All rights reserved.
//


#import <Foundation/Foundation.h>

@interface AppVibration : NSObject
typedef void (^AppCallback)(id error,id result);
+ (id)singletonManger;


- (void)vibrate:(NSNumber *)time :(AppCallback)callback;

@end
