//
//  AppVolume.h
//
//  Created by EEUI 19/06/14.
//  Copyright © 2019 All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AppVolume : NSObject
typedef void (^AppCallback)(id error,id result);
+ (id)singletonManger;
- (void)get:(AppCallback)callback;
- (void)set:(NSNumber *)volume :(AppCallback)callback;

@end
