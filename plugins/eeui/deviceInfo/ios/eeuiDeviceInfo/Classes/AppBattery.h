//
//  AppBattery.h
//
//  Created by EEUI 19/06/14.
//  Copyright © 2019 All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AppBattery : NSObject
typedef void (^AppCallback)(id error,id result);
+ (id)singletonManger;
- (void)status:(AppCallback)callback;

@end
