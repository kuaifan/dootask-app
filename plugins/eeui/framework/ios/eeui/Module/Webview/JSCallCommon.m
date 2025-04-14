//
//  JSCallCommon.m
//  eeuiProject
//
//  Created by 高一 on 2019/1/5.
//

#import "JSCallCommon.h"
#import "NSObject+performSelector.h"
#import <objc/runtime.h>
#import "WeexInitManager.h"

#import "eeuiBridge.h"
#import "NavigatorBridge.h"
#import "NavigationBarBridge.h"

static NSMutableDictionary *sessionDataCache;

@implementation JSCallCommon

- (instancetype) init
{
    if (self = [super init]) {
        self.AllClass = [NSMutableDictionary dictionary];
        self.AllInit = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void) destroy
{
    [self viewDidUnload];
}

- (void) viewDidUnload
{
    [self.AllClass removeAllObjects];
    [self.AllInit removeAllObjects];
}

- (BOOL) isJSChunk:(NSString*)JSText
{
    NSDictionary *data = [JSCallCommon dictionaryWithJsonString:JSText];
    if (data[@"__chunked"]) {
        return YES;
    }
    return NO;
}

- (void) onJSChunk:(WKWebView*)webView JSText:(NSString*)JSText callback:(void (^)(NSString *completeData))callback
{
    NSDictionary *data = [JSCallCommon dictionaryWithJsonString:JSText];
    if (data == nil) {
        callback([JSCallCommon dictionaryToJson:@{@"code":@(500), @"result":@"not found JSText"}]);
        return;
    }
    
    BOOL last = [data[@"last"] boolValue];
    NSString *session = data[@"session"];
    NSString *chunk = data[@"chunk"];
    
    if (sessionDataCache == nil) {
        sessionDataCache = [NSMutableDictionary dictionary];
    }
    
    if (last == YES) {
        // 获取之前缓存的数据
        NSMutableString *cachedData = sessionDataCache[session];
        NSString *result = @"";
        if (cachedData) {
            [cachedData appendString:chunk];
            result = [cachedData copy];
            [sessionDataCache removeObjectForKey:session];
        } else {
            result = chunk;
        }
        [self onJSCall:webView JSText:result callback:^(NSString *completeData) {
            callback(completeData);
        }];
    } else {
        // 缓存数据
        NSMutableString *cachedData = sessionDataCache[session];
        if (cachedData) {
            [cachedData appendString:chunk];
        } else {
            cachedData = [NSMutableString stringWithString:chunk];
            sessionDataCache[session] = cachedData;
        }
        callback([JSCallCommon dictionaryToJson:@{@"code":@(202), @"result": @""}]);
    }
}

- (BOOL) isJSCall:(NSString*)JSText
{
    NSDictionary *data = [JSCallCommon dictionaryWithJsonString:JSText];
    if (data[@"__identify"]) {
        return YES;
    }
    return NO;
}

- (void) onJSCall:(WKWebView*)webView JSText:(NSString*)JSText callback:(void (^)(NSString *completeData))callback
{
    NSDictionary *data = [JSCallCommon dictionaryWithJsonString:JSText];
    if (data == nil) {
        callback([JSCallCommon dictionaryToJson:@{@"code":@(500), @"result":@"not found JSText"}]);
        return;
    }

    NSString *identify = data[@"__identify"];
    NSString *method = data[@"method"];
    NSArray *types = data[@"types"];
    NSArray *args = data[@"args"];

    if (!identify.length) {
        callback([JSCallCommon dictionaryToJson:@{@"code":@(500), @"result":@"not found identify"}]);
        return;
    }

    id bridge = [self.AllClass objectForKey:identify];
    if (bridge == nil) {
        callback([JSCallCommon dictionaryToJson:@{@"code":@(500), @"result":@"not found alloc"}]);
        return;
    }

    SEL sel = nil;
    unsigned int count = 0;
    Method *meths = class_copyMethodList([bridge class], &count);
    for(int i = 0; i < count; i++) {
        Method meth = meths[i];
        sel = method_getName(meth);
        NSString *name = [[NSString alloc] initWithUTF8String:sel_getName(sel)];
        if ([name hasPrefix:method]) {
            break;
        }
    }
    free(meths);

    if (sel == nil) {
        callback([JSCallCommon dictionaryToJson:@{@"code":@(500), @"result":[NSString stringWithFormat:@"not found method(%@) with valid parameters", method]}]);
        return;
    }

    NSMethodSignature * signature = [[bridge class] instanceMethodSignatureForSelector:sel];
    if (signature == nil) {
        callback([JSCallCommon dictionaryToJson:@{@"code":@(500), @"result":[NSString stringWithFormat:@"not found method(%@) with valid signature", method]}]);
        return;
    }

    NSMutableArray *params = [[NSMutableArray alloc] init];
    NSInteger acount = MIN(signature.numberOfArguments - 2, args.count);

    for (int index = 0; index < acount; index++) {
        NSObject *obj = args[index];
        if ([obj isKindOfClass:[NSNull class]]) {
            obj = nil;
        }
        const char *paramType = [signature getArgumentTypeAtIndex:index + 2];
        if (strcmp(paramType, @encode(typeof(^{}))) == 0) {
            [params addObject:^(id result, BOOL keepAlive) {
                if ([types[index] isEqualToString:@"function"]) {
                    [JSCallCommon WXCall2JSCall:webView identify:identify index:[(NSNumber*)obj intValue] result:result keepAlive:keepAlive];
                }
            }];
        } else {
            [params addObject:obj];
        }
    }

    signature = nil;

    NSString *initialize = [self.AllInit objectForKey:identify];
    if (![initialize isEqualToString:@"initialize"]) {
        [bridge performSelector:@selector(initialize) withObjects:nil];
        [self.AllInit setObject:@"initialize" forKey:identify];
    }

    id result = [bridge performSelector:sel withObjects:params];
    if (![result isKindOfClass:[NSDictionary class]]
        && ![result isKindOfClass:[NSNumber class]]
        && (result == nil || [result isEqual:[NSNull null]] || [result isEqualToString:@"(null)"])) {
        result = @"";
    }

    callback([JSCallCommon dictionaryToJson:@{@"code":@(200), @"result": result}]);
}

- (void) setJSCallAssign:(WKWebView*)webView name:(NSString*)name bridge:(id)bridge
{
    if (!webView) {
        return;
    }
    name = [@"__eeui_js_" stringByAppendingString:name];

    unsigned int count = 0;
    NSString *funcString = @"";
    Method *meths = class_copyMethodList([bridge class], &count);
    for(int i = 0; i < count; i++) {
        Method meth = meths[i];
        SEL sel = method_getName(meth);
        NSString *fname = [NSString stringWithUTF8String:sel_getName(sel)];
        if ([fname containsString:@":"]) {
            NSRange range = [fname rangeOfString:@":"];
            fname = [fname substringToIndex:range.location];
        }
        if (![JSCallCommon isEnglishFirst:fname]) {
            continue;
        }
        if ([name isEqualToString:@"__eeui_js_webview"]) {
            if (!([fname isEqualToString:@"setContent"] ||
                  [fname isEqualToString:@"setUrl"] ||
                  [fname isEqualToString:@"canGoBack"] ||
                  [fname isEqualToString:@"goBack"] ||
                  [fname isEqualToString:@"canGoForward"] ||
                  [fname isEqualToString:@"goForward"] ||
                  [fname isEqualToString:@"setProgressbarVisibility"] ||
                  [fname isEqualToString:@"setHapticBackEnabled"] ||
                  [fname isEqualToString:@"setDisabledUserLongClickSelect"] ||
                  [fname isEqualToString:@"setScrollEnabled"] ||
                  [fname isEqualToString:@"sendMessage"])) {
                continue;
            }
        }
        funcString = [funcString stringByAppendingString:@"a."];
        funcString = [funcString stringByAppendingString:fname];
        funcString = [funcString stringByAppendingString:@" = "];
    }
    free(meths);

    if (!funcString.length) {
        return;
    }

    NSString *javaScript = @";(function(b){console.log('eeuiModel initialization begin');if(b.__eeuiModel===true){return}b.__eeuiModel=true;var a={queue:[],callback:function(){var d=Array.prototype.slice.call(arguments,0);var c=d.shift();var e=d.shift();this.queue[c].apply(this,d)}};a.funcArray=function(){var f=Array.prototype.slice.call(arguments,0);if(f.length<1){throw'eeuiModel call error, message:miss method name'}var e=[];for(var h=1;h<f.length;h++){var c=f[h];var j=typeof c;e[e.length]=j;if(j=='function'){var d=a.queue.length;a.queue[d]=c;f[h]=d}}var requestJson=JSON.stringify({__identify:'eeuiModel',method:f.shift(),types:e,args:f});var chunkSize=8000;var finalResponse={code:0};if(requestJson.length<=chunkSize){finalResponse=JSON.parse(prompt(requestJson))}else{var chunks=Math.ceil(requestJson.length/chunkSize);var session=Date.now()+'_'+Math.random().toString(36).substring(2,9);for(var i=0;i<chunks;i++){var start=i*chunkSize;var end=Math.min((i+1)*chunkSize,requestJson.length);var chunk=requestJson.substring(start,end);var chunkObj={__chunked:true,last:i===chunks-1,chunk:chunk,session:session};var chunkResponse=prompt(JSON.stringify(chunkObj));if(chunkObj.last){finalResponse=JSON.parse(chunkResponse)}}}if(finalResponse.code!=200){throw'eeui call error, code:'+finalResponse.code+', message:'+finalResponse.result}return finalResponse.result};Object.getOwnPropertyNames(a).forEach(function(d){var c=a[d];if(typeof c==='function'&&d!=='callback'){a[d]=function(){return c.apply(a,[d].concat(Array.prototype.slice.call(arguments,0)))}}});b.eeuiModel=a;console.log('eeuiModel initialization end')})(window);";
    javaScript = [javaScript stringByReplacingOccurrencesOfString:@"eeuiModel" withString:name];
    javaScript = [javaScript stringByReplacingOccurrencesOfString:@"a.funcArray=" withString:funcString];

    [webView evaluateJavaScript:javaScript completionHandler:^(id object, NSError *error) {
        if (!error) {
            [self.AllClass setObject:bridge forKey:name];
        }
    }];
}

- (void) addRequireModule:(WKWebView*)webView
{
    if (!webView) {
        return;
    }
    NSString *javaScript = @";(function(b){console.log('requireModuleJs initialization begin');if(b.__requireModuleJs===true){return}b.__requireModuleJs=true;var a=function(name){if(['websocket','screenshots','citypicker','picture','rongim','umeng','pay','audio','deviceInfo','communication','geolocation','recorder','accelerometer','compass','amap','seekbar','network',].indexOf(name)!==-1){name='eeui/'+name}if(name==='networkTransfer'){name='eeui/network'}if(name==='videoView'){name='eeui/video'}name=name.replace(/\\/+(\\w)/g,function($1){return $1.toLocaleUpperCase()}).replace(/\\//g,'');var moduleName='__eeui_js_'+name;if(typeof b[moduleName]==='object'&&b[moduleName]!==null){return b[moduleName]}};b.requireModuleJs=a;var apiNum=0;var apiInter=setInterval(function(){if(typeof b.$ready==='function'){b.$ready();apiNum=300}else if(typeof $ready==='function'){$ready();apiNum=300}if(apiNum>=300){clearInterval(apiInter)}apiNum++},100);console.log('requireModuleJs initialization end')})(window);";
    [webView evaluateJavaScript:javaScript completionHandler:nil];
}

- (void) setJSCallAll:(id)webBridge webView:(WKWebView*)webView
{
    [self setJSCallAssign:webView name:@"eeui" bridge:[[eeuiBridge alloc] init]];
    [self setJSCallAssign:webView name:@"webview" bridge:webBridge];
    [self setJSCallAssign:webView name:@"navigator" bridge:[[NavigatorBridge alloc] init]];
    [self setJSCallAssign:webView name:@"navigationBar" bridge:[[NavigationBarBridge alloc] init]];
    [WeexInitManager setJSCallModule:self webView:(WKWebView*)webView];
}

+ (NSString*) dictionaryToJson:(NSDictionary *)dic
{
    NSError *parseError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:&parseError];
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

+ (NSDictionary*) dictionaryWithJsonString:(NSString *)jsonString
{
    if (jsonString == nil) {
        return nil;
    }
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err;
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&err];
    if (err) {
        return nil;
    }
    return dic;
}

+ (void) WXCall2JSCall:(WKWebView*)webView identify:(NSString*)identify index:(int)index result:(id)result keepAlive:(BOOL) keepAlive
{
    if (webView == nil) {
        return;
    }
    NSString *resultString = @", ";
    if ([result isKindOfClass:[NSDictionary class]]) {
        resultString = [resultString stringByAppendingString:[JSCallCommon dictionaryToJson:result]];
    }else if ([result isKindOfClass:[NSNumber class]]) {
        if ([JSCallCommon isBoolNumber:result]) {
            resultString = [resultString stringByAppendingString:[result boolValue] == YES ? @"true" : @"false"];
        }else{
            resultString = [resultString stringByAppendingString:result];
        }
    }else{
        resultString = [resultString stringByAppendingString:@"'"];
        if ([result isKindOfClass:[NSString class]] ) {
            resultString = [resultString stringByAppendingString:[result stringByReplacingOccurrencesOfString:@"'" withString:@"\'"]];
        }
        resultString = [resultString stringByAppendingString:@"'"];
    }
    NSString *javaScript = [NSString stringWithFormat:@";%@.callback(%d, 0%@);", identify, index, resultString];
    [webView evaluateJavaScript:javaScript completionHandler:nil];
}

+ (BOOL) isBoolNumber:(NSNumber *)num
{
    CFTypeID boolID = CFBooleanGetTypeID();
    CFTypeID numID = CFGetTypeID((__bridge CFTypeRef)(num));
    return numID == boolID;
}


+ (BOOL)isEnglishFirst:(NSString *)str {
    NSString *regular = @"^[A-Za-z].+$";
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regular];
    if ([predicate evaluateWithObject:str] == YES){
        return YES;
    }else{
        return NO;
    }
}

@end
