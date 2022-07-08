//
//  AppCommunication.h
//


#import <Foundation/Foundation.h>
#import <MessageUI/MessageUI.h>

@interface AppCommunication : NSObject<MFMessageComposeViewControllerDelegate,MFMailComposeViewControllerDelegate>

typedef void (^AppCallback)(id error, id result);

+ (AppCommunication *)singletonManger;
- (void)call:(NSString *)phone :(AppCallback)callback;
- (void)mail:(NSArray *)mail :(NSDictionary*)params :(AppCallback)callback;
- (void)sms:(NSArray *)phone :(NSString *)text :(AppCallback)callback;

@end
