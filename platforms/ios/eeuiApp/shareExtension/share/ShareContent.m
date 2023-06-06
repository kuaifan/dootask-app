//
//  ShareContent.m
//  ShareExtension
//
//  Created by Hitosea-005 on 2023/6/5.
//

#import "ShareContent.h"

@implementation ShareContent

-(void)setFileUrl:(NSURL *)fileUrl{
    _fileUrl = fileUrl;
    BOOL isDirectory = NO;
    [[NSFileManager defaultManager] fileExistsAtPath:[fileUrl absoluteString] isDirectory:&isDirectory];
    NSString *lastString = [[fileUrl absoluteString] substringFromIndex:[fileUrl absoluteString].length-1];
    if([lastString isEqualToString:@"/"]){
        isDirectory = YES;
    }
    
    self.isDir = isDirectory;
}

@end
