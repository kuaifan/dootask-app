//
//  eeuiUmengManager.h
//

#import <Foundation/Foundation.h>
#import "WeexSDK.h"
#import <UMPush/UMessage.h>

@interface eeuiUmengManager : NSObject

@property (nonatomic, strong) NSDictionary *token;

+ (eeuiUmengManager *)sharedIntstance;
- (void)init:(NSString*)key channel:(NSString*)channel launchOptions:(NSDictionary*)launchOptions;

@end
