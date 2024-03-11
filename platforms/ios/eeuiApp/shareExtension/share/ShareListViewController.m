//
//  ShareListViewController.m
//  ShareExtension
//
//  Created by Hitosea-005 on 2023/6/1.
//

#import "ShareListViewController.h"
#import "ChatCell.h"
#import <Masonry.h>
#import <MMWormhole.h>
#import <AFNetworking.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "PathNavigationView.h"
#import "ShareContent.h"
#import <SVProgressHUD.h>
#import <UIImageView+WebCache.h>
#import "ChatModel.h"

@interface NSArray (Monad)
- (NSArray*)myMap:(id(^)(id))transform;
- (NSArray*)myFilter:(BOOL(^)(id))includeElement;

@end

@implementation NSArray (Monad)
- (NSArray*)myMap:(id(^)(id))transform {
    NSMutableArray *array = [[NSMutableArray alloc] init];
    [self enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [array addObject:transform(obj)];
    }];
    return array;
    
}

- (NSArray*)myFilter:(BOOL(^)(id))includeElement {
    NSMutableArray *array = [[NSMutableArray alloc] init];
    
    [self enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (includeElement(obj)) {
            [array addObject:obj];
        }
    }];
    
    return array;
}

@end

@interface ShareListViewController ()<UITableViewDelegate, UITableViewDataSource, NavigationViewDelegate>
@property (nonatomic, strong)UITableView *tableView;
@property (nonatomic, strong)NSArray<ChatModelData *> *showArray;
@property (nonatomic, strong)MMWormhole *shareWormhole;
@property (nonatomic, strong)ChatModel *rootModel;

@property (nonatomic, strong)NSDictionary *showObjc;
@property (nonatomic, strong)PathNavigationView *tableHeaderView;
@property (nonatomic, strong)NSMutableArray<ChatModelData *> *IDArray;
@property (nonatomic, assign)BOOL isRoot;

@property (nonatomic, strong)NSMutableArray *shareArray;
@property (nonatomic, strong)NSMutableArray *sendArray;
@property (nonatomic, strong)NSMutableArray *progressArray;

@property (nonatomic, strong)UIButton *comfirnButton;
@property (nonatomic, strong)UIButton *reloadButton;

@property (nonatomic, assign)BOOL completeFlag;
@property (nonatomic, copy  )NSString *currentToken;
@property (nonatomic, strong)dispatch_group_t currenGruop;
@property (nonatomic, assign)BOOL isFile;
@end

@implementation ShareListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.shareWormhole = [[MMWormhole alloc] initWithApplicationGroupIdentifier:@"group.im.dootask" optionalDirectory:@"share"];
    
    //chatUrl dirUrl
    NSLog(@"shareMessage:%@",[self.shareWormhole messageWithIdentifier:@"chatList"]);
    
    if (@available(iOS 13.0, *)) {
        self.view.backgroundColor = UIColor.systemBackgroundColor;
    } else {
        // Fallback on earlier versions
        self.view.backgroundColor = UIColor.whiteColor;
    }
    
    self.isRoot = YES;
    self.completeFlag = NO;
    [self setupHeaderView];
    [self setupTableView];
    
    [SVProgressHUD setContainerView:self.view];
    [SVProgressHUD setDefaultStyle:[self inDarkAppearance]? SVProgressHUDStyleLight: SVProgressHUDStyleDark];
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
    // [SVProgressHUD setOffsetFromCenter:UIOffsetMake(0, -100)];
    
    [self presentContent];
    //    [self showNav];
    [self getShareData];
    
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self getMainList];
}

- (void)creatMonitorData{
    self.showArray = @[
        @{
            @"userImage":@"",
            @"nickName":@"张三"
        },
        @{
            @"userImage":@"",
            @"nickName":@"李四"
        },
        @{
            @"userImage":@"",
            @"nickName":@"坤坤"
        },
        @{
            @"userImage":@"",
            @"nickName":@"顶针"
        },
    ];
}

- (void)setupHeaderView {
    UIView *headerView = [[UIView alloc]init];
    UIButton *leftButton = [UIButton buttonWithType:UIButtonTypeCustom];
    UIButton *rightButton = [UIButton buttonWithType:UIButtonTypeCustom];
    UILabel *titleLabel = [[UILabel alloc] init];
    
    [self.view addSubview:headerView];
    if (@available(iOS 13.0, *)) {
        headerView.backgroundColor = UIColor.systemBackgroundColor;
    } else {
        
    }
    
    [headerView addSubview:leftButton];
    [headerView addSubview:titleLabel];
    [headerView addSubview:rightButton];
    
    [leftButton setTitle:NSLocalizedString(@"cancelTitle", @"") forState:UIControlStateNormal];
    [leftButton addTarget:self action:@selector(cancelAction) forControlEvents:UIControlEventTouchUpInside];
    [leftButton setTitleColor:UIColor.systemBlueColor forState:UIControlStateNormal];
    
    [rightButton setTitle:NSLocalizedString(@"sendTitle", @"") forState:UIControlStateNormal];
    [rightButton addTarget:self action:@selector(sendAction) forControlEvents:UIControlEventTouchUpInside];
    [rightButton setTitleColor:UIColor.systemBlueColor forState:UIControlStateNormal];
    [rightButton setTitleColor:UIColor.lightGrayColor forState:UIControlStateDisabled];
    
    rightButton.enabled = NO;
    
    self.comfirnButton = rightButton;
    titleLabel.text = NSLocalizedString(@"sendTitle", @"");
    
    [headerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.top.left.equalTo(self.view);
        make.height.equalTo(@70);
        
    }];
    
    [leftButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(headerView).offset(12);
        make.centerY.equalTo(headerView);
        make.height.width.greaterThanOrEqualTo(@10);
    }];
    
    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.centerY.equalTo(headerView);
    }];
    
    [rightButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(headerView).offset(-12);
        make.centerY.equalTo(headerView);
        make.height.width.greaterThanOrEqualTo(@10);
    }];
    
}

- (void)presentContent {
    UIAlertController *container = [UIAlertController alertControllerWithTitle:@"title" message:@"message" preferredStyle:UIAlertControllerStyleActionSheet];
    [container popoverPresentationController].sourceView = self.view;
    [container popoverPresentationController].sourceRect = self.view.frame;
    
    [self presentViewController:container animated:YES completion:nil];
}

- (void)setupTableView {
    self.tableView = [[UITableView alloc] init];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
//    self.tableView.backgroundColor = UIColor.redColor;
    
    self.tableView.rowHeight = 60;
    
    [self.tableView registerNib:[UINib nibWithNibName:@"ChatCell" bundle:nil] forCellReuseIdentifier:@"ChatCell"];
    [self.view addSubview:self.tableView];
    
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(70);
        make.left.right.bottom.equalTo(self.view);
        //        make.height.equalTo(@(self.view.frame.size.height - 70));
    }];
    [self.tableView layoutIfNeeded];
}

- (void)showReload{
    if (self.reloadButton) {
        self.reloadButton.hidden = NO;
        return;
    }
    self.reloadButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.reloadButton setBackgroundImage:[UIImage imageNamed:@"refresh"] forState:UIControlStateNormal];
    [self.reloadButton addTarget:self action:@selector(getSubList) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:self.reloadButton];
    
    [self.reloadButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.centerX.equalTo(self.view);
        make.width.height.equalTo(@70);
    }];
}

- (void)hideReload{
    if (self.reloadButton) {
        self.reloadButton.hidden = YES;
    }
}

-(void)getShareData{
    self.shareArray = [NSMutableArray array];
    // 创建队列组，可以使多个网络请求异步执行，执行完之后再进行操作
    dispatch_group_t group = dispatch_group_create();
    
    //创建全局队列
    dispatch_queue_t queue = dispatch_get_global_queue(0,0);

    dispatch_group_async(group, queue, ^{
        [self.extensionContext.inputItems enumerateObjectsUsingBlock:^(NSExtensionItem *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj.attachments enumerateObjectsUsingBlock:^(NSItemProvider *  _Nonnull itemProvider, NSUInteger idx, BOOL * _Nonnull stop) {
    //            UTTypeImage;
    //            NSString *urlUtiStr = (NSString *)kUTTypeURL;
    //            NSString *imageUtiStr = (NSString *)kUTTypeImage;
    //            NSString *videoUtiStr = (NSString *)kUTTypeMovie;
    //            if ([itemProvider hasItemConformingToTypeIdentifier:urlUtiStr])
    //            {
    //                [itemProvider loadItemForTypeIdentifier:urlUtiStr options:nil completionHandler:^(id<NSSecureCoding>  _Nullable item, NSError * _Null_unspecified error) {//在这里保存获取到的分享数据
    //                    if([(NSObject *)item isKindOfClass:[NSURL class]]){
    //                        NSURL *content = (NSURL *)item;
    //                        ShareContent *model = [ShareContent new];
    //                        model.shareType = shareContentTypeText;
    //                        model.fileUrl = content;
    //                        [self.shareArray addObject:model];
    //                        return;
    //                    }
    //
    //                }];
    //            }
                
    //            if ([itemProvider hasItemConformingToTypeIdentifier:imageUtiStr])
    //            {
    //                [itemProvider loadItemForTypeIdentifier:imageUtiStr options:nil completionHandler:^(id<NSSecureCoding>  _Nullable item, NSError * _Null_unspecified error) {//在这里保存获取到的分享数据
    //                    if([(NSObject *)item isKindOfClass:[NSURL class]]){
    //                        NSURL *content = (NSURL *)item;
    //                        ShareContent *model = [ShareContent new];
    //                        model.shareType = shareContentTypeImage;
    //                        model.fileUrl = content;
    //                        [self.shareArray addObject:model];
    //                        return;
    //                    }
    //
    //                }];
    //            }
    //
    //            if ([itemProvider hasItemConformingToTypeIdentifier:videoUtiStr])
    //            {
    //                [itemProvider loadItemForTypeIdentifier:videoUtiStr options:nil completionHandler:^(id<NSSecureCoding>  _Nullable item, NSError * _Null_unspecified error) {//在这里保存获取到的分享数据
    //                    NSLog(@"%@",item);
    //
    //                    if([(NSObject *)item isKindOfClass:[NSURL class]]){
    //                        NSURL *content = (NSURL *)item;
    //                        ShareContent *model = [ShareContent new];
    //                        model.shareType = shareContentTypeVideo;
    //                        model.fileUrl = content;
    //                        [self.shareArray addObject:model];
    //                        return;
    //                    }
    //
    //                }];
    //            }
                
                
                NSString *registered = itemProvider.registeredTypeIdentifiers.firstObject;

                if ([itemProvider hasItemConformingToTypeIdentifier:registered])
                {
                    dispatch_group_enter(group);
                    [itemProvider loadItemForTypeIdentifier:registered options:nil completionHandler:^(id<NSSecureCoding>  _Nullable item, NSError * _Null_unspecified error) {//在这里保存获取到的分享数据
                        
                        if([(NSObject *)item isKindOfClass:[NSURL class]]){
                            NSURL *content = (NSURL *)item;
                            ShareContent *model = [ShareContent new];
                            if (content.isFileURL || content.isFileReferenceURL) {
                                model.shareType = shareContentTypeOther;
                                model.fileUrl = content;
                                self.isFile = YES;
                                
                            } else {
                                model.content = content.absoluteString;
                                model.shareType = shareContentTypeText;
                                self.isFile = NO;
                            }
                            [self.shareArray addObject:model];
                        } else if ([(NSObject *)item isKindOfClass:[UIImage class]]) {
                            UIImage *content = (UIImage *)item;
                            ShareContent *model = [ShareContent new];
                            model.shareType = shareContentTypeImage;
                            model.image = content;
                            self.isFile = YES;
                            [self.shareArray addObject:model];
                        } else if ([(NSObject *)item isKindOfClass:[NSString class]]) {
                            NSString *content = (NSString *)item;
                            ShareContent *model = [ShareContent new];
                            model.shareType = shareContentTypeText;
                            model.content = content;
                            [self.shareArray addObject:model];
                            self.isFile = NO;
                        }
                        dispatch_group_leave(group);
                    }];
                }
            }];
        }];
    });
    
    
    
    // 当所有队列执行完成之后
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        if (self.shareArray.count == 0) {
            [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"emptyShareTitle", @"")];
            [SVProgressHUD dismissWithDelay:1.5 completion:^{
                self.completionCallback(DootaskShareResultCancel);
            }];
        }
        
    });


}

-(void)getMainList{
    NSString *chatUrl = [self.shareWormhole messageWithIdentifier:@"chatList"];
    if (chatUrl.length < 5) {
        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"unLoginTitle", @"")];
        [SVProgressHUD dismissWithDelay:2.5 completion:^{
            self.completionCallback(DootaskShareResultFail);
        }];
        
        return;
    }
    NSArray *tokenArray = [chatUrl componentsSeparatedByString:@"?token="];
    if (tokenArray.count == 2) {
        self.currentToken = tokenArray[1];
    }
    
    NSLog(@"chaturl:%@",chatUrl);
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
    [SVProgressHUD show];
    [manager GET_EEUI:chatUrl parameters:@{@"type": self.isFile? @"file" :@"text"} headers:nil progress:^(NSProgress * _Nonnull downloadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject, NSInteger resCode, NSDictionary * _Nonnull resHeader) {
        
        int ret = [responseObject[@"ret"] intValue];
        NSString *msg = responseObject[@"msg"];
        if (ret == 1) {
            ChatModel *model = [ChatModel new];
            [model mj_setKeyValues:responseObject];
            self.rootModel = model;
            [self analyseData];
            [SVProgressHUD dismiss];
        }else {
            [SVProgressHUD dismissWithCompletion:^{
                
                [SVProgressHUD showErrorWithStatus:msg];
                [SVProgressHUD dismissWithDelay:2 completion:^{
                    self.completionCallback(DootaskShareResultFail);
                }];
            }];
        }
        NSLog(@"responseObject:%@",responseObject);
        NSLog(@"resCode:%ld",resCode);
        
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [SVProgressHUD dismissWithCompletion:^{
            [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"netWorkErrorTitle", @"")];
            [SVProgressHUD dismissWithDelay:2 completion:^{
                self.completionCallback(DootaskShareResultFail);
            }];
        }];
    }];
}

- (void)getSubList{
    [self hideReload];
    
    ChatModelData *subModel = self.IDArray.lastObject;
    if (subModel == nil) {
        return;
    }
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
    self.showArray = @[];
    [SVProgressHUD show];
    [manager GET_EEUI:subModel.url parameters:@{@"token":self.currentToken} headers:nil progress:^(NSProgress * _Nonnull downloadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject, NSInteger resCode, NSDictionary * _Nonnull resHeader) {
        
        int ret = [responseObject[@"ret"] intValue];
        NSString *msg = responseObject[@"msg"];
        
        if (ret == 1) {
            NSMutableArray *tempArray = [NSMutableArray array];
            for (NSDictionary *dic in responseObject[@"data"]) {
                ChatModelData *model = [ChatModelData new];
                [model mj_setKeyValues:dic];
                [tempArray addObject:model];
            }
            
            self.showArray = tempArray;
            
            [SVProgressHUD dismiss];
        }else {
            [SVProgressHUD dismissWithCompletion:^{
                
                [SVProgressHUD showErrorWithStatus:msg];
                [SVProgressHUD dismissWithDelay:2 completion:^{
//                    self.completionCallback(DootaskShareResultFail);
                }];
                [self showReload];
            }];
        }
        [self.tableView reloadData];
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        self.showArray = @[];
        [SVProgressHUD dismissWithCompletion:^{
            [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"netWorkErrorTitle", @"")];
            [SVProgressHUD dismissWithDelay:2 completion:^{
//                self.completionCallback(DootaskShareResultFail);
            }];
        }];
        [self.tableView reloadData];
        [self showReload];
    }];
    
}

- (void)analyseData {
    
    self.showArray = self.rootModel.data;
    
    [self.tableView reloadData];
}

- (void)showNav{
    if (self.tableHeaderView) {
        self.tableHeaderView.navArray = self.IDArray;
        return;
    }
    self.tableHeaderView = [[PathNavigationView alloc] initWithArray:self.IDArray];
    self.tableHeaderView.delegate = self;
    [self.view addSubview:self.tableHeaderView];
    
    [self.tableHeaderView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.top.equalTo(self.view).offset(70);
        make.height.equalTo(@60);
    }];
    [self.tableView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(130);
    }];
}

- (void)hideNav{
    [self.tableHeaderView removeFromSuperview];
    self.tableHeaderView = nil;
    [self.tableView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(70);
    }];
}

- (void)goNext{
    
}

- (void)goPreview {
    
}

- (void)checkEnable {
    if (self.isRoot) {       
        int select = 0;
        for (ChatModelData *obj in self.showArray) {
            if (obj.select){
                select ++;
            }
        }
        if (select >= 1) {
            [self.comfirnButton setTitle:[NSLocalizedString(@"sendTitle", @"") stringByAppendingFormat:@"(%d)",select] forState:UIControlStateNormal];
            self.comfirnButton.enabled = YES;
        } else {
            [self.comfirnButton setTitle:NSLocalizedString(@"sendTitle", @"") forState:UIControlStateNormal];
            self.comfirnButton.enabled = NO;
        }
    } else {
        self.comfirnButton.enabled = YES;
    }
}

- (void)upLoads:(NSDictionary *)param isDir:(BOOL)isDir{
    
    NSString *uploadUrl;
    uploadUrl = param[@"upLoadUrl"];
//    uploadUrl = [uploadUrl stringByAppendingFormat:@"&token=%@",self.currentToken];
    
    if (uploadUrl.length < 5) {
        
        return;
    }
    __block int number = 0;
    
    self.progressArray = [NSMutableArray array];
    
    [SVProgressHUD showProgress:0];
    
    dispatch_group_t group = dispatch_group_create();
    
    //创建全局队列
    dispatch_queue_t queue = dispatch_get_global_queue(0,0);

    self.currenGruop = group;
    dispatch_group_async(group, queue, ^{
        for (ShareContent *model in self.shareArray) {
            if (model.isDir) {
                [SVProgressHUD showInfoWithStatus:NSLocalizedString(@"folderUnsupportTitle", @"")];
                [SVProgressHUD dismissWithDelay:1 completion:^{
                    self.completionCallback(DootaskShareResultSuccess);
                }];
                return;
            }
            
            
            NSProgress *progress = [[NSProgress alloc] init];
            [self.progressArray addObject:@{@"progress":progress,@"result":@0,@"muti":@0}];
            
            [self uploadfilesWithParams:param upLoadURL:uploadUrl shareModel:model withCount:number];
            number ++;
        }
    });
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        [self taskComplete];
    });
    
}

- (void)uploadfilesWithParams:(NSDictionary *)params upLoadURL:(NSString *)upLoadURL shareModel:(ShareContent *)model withCount:(int)number{
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    dispatch_group_enter(self.currenGruop);
    
    [manager POST_EEUI:upLoadURL parameters:params headers:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        
        if (model.shareType == shareContentTypeImage) {
            NSData *imageData = UIImagePNGRepresentation(model.image);
//            [formData appendPartWithFormData:imageData name:@"files"];
            NSString *imageName = [NSString stringWithFormat:@"screenShot_%@%@.png",[self getRandomString],[self getNowTimeTimestamp]];
            
            [formData appendPartWithFileData:imageData name:@"files" fileName:imageName mimeType:@"image/png"];
        } else if (model.shareType == shareContentTypeOther){
            NSError * error = nil;
            [formData appendPartWithFileURL:model.fileUrl name:@"files" error:&error];
            if (error != nil) {
                
            }
        } else if (model.shareType == shareContentTypeText) {
            NSError * error = nil;
            [formData appendPartWithFormData:[model.content dataUsingEncoding:NSUTF8StringEncoding] name:@"text"];
            if (error != nil) {
                
            }
        }
        
            
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        
        [self.progressArray replaceObjectAtIndex:number withObject:@{@"progress":uploadProgress,@"result":@0,@"muti":@1}];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            CGFloat lastProgress = [self getTotalPercent];
            NSLog(@"总体进度:%f",lastProgress);
            [SVProgressHUD showProgress:lastProgress status:[[NSString stringWithFormat:@"%@%.0f",NSLocalizedString(@"sendingTitle", @""),MIN(lastProgress*100,99)] stringByAppendingString:@"%"]];
            
        });
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject, NSInteger resCode, NSDictionary * _Nonnull resHeader) {
        int ret = [responseObject[@"ret"] intValue];
        
        NSMutableDictionary *mutiDic = [self.progressArray[number] mutableCopy];
        mutiDic[@"result"] = @(ret);
        [self.progressArray replaceObjectAtIndex:number withObject:mutiDic];
        dispatch_group_leave(self.currenGruop);
//        [self taskComplete];
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSMutableDictionary *mutiDic = [self.progressArray[number] mutableCopy];
        mutiDic[@"result"] = @(0);
        [self.progressArray replaceObjectAtIndex:number withObject:mutiDic];
        dispatch_group_leave(self.currenGruop);
//        [self taskComplete];
    }];
}

- (CGFloat)getTotalPercent{
    CGFloat percent = 0;
    
    for (NSDictionary *param in self.progressArray) {
        NSProgress *progress = param[@"progress"];
        CGFloat currentPercent = progress.fractionCompleted;
        if (progress.isCancelled) {
            currentPercent = 1;
        }
        
        percent += currentPercent/self.progressArray.count;
    }
    
    return percent;
}

- (void)taskComplete{
    
    int success = 0;
    int fail = 0;
    for (NSDictionary *params in self.progressArray ) {
        NSInteger result = [params[@"result"] integerValue];
        if (result == 1) {
            success ++;
        } else {
            fail ++;
        }
    }
    
    NSString *msg;
    DootaskShareResult result;
    if (fail == 0) {
        msg = NSLocalizedString(@"sendSuccessTitle", @"");
        [SVProgressHUD showSuccessWithStatus:msg];
        result = DootaskShareResultSuccess;
    } else if (success == 0) {
        msg = NSLocalizedString(@"sendFailTitle", @"");
        [SVProgressHUD showErrorWithStatus:msg];
        result = DootaskShareResultFail;
    }else  {
        
        msg = [NSString stringWithFormat:@"%d%@,%d%@",success,NSLocalizedString(@"successTotal", @""),fail,NSLocalizedString(@"failTotal", @"")];
        [SVProgressHUD showInfoWithStatus:msg];
        result = DootaskShareResultSuccess;
    }
    
    [SVProgressHUD dismissWithDelay:1 completion:^{
        self.completionCallback(result);
    }];
 
    
}

- (void)getURLComponents:(NSURL *)index {
    NSLog(@"1=%@",[index lastPathComponent]);
    NSLog(@"3=%@",[index pathExtension]);

    NSLog(@"9=%@",[[index lastPathComponent] stringByDeletingPathExtension]);
}

// action

- (void)cancelAction {
    self.completionCallback?self.completionCallback(DootaskShareResultCancel):nil;
}
- (void)sendAction {
    if (self.isRoot) {
        //发送聊天
        NSString *dialogStr = @"";
        NSString *uploadUrl = nil;
        for (int a = 0; a<self.showArray.count; a++) {
            ChatModelData * model = self.showArray[a];
            
            if (model.select){
                dialogStr = [dialogStr stringByAppendingFormat:@"%ld,",(long)model.extend.dialog_ids];
                uploadUrl = model.url;
            }
        }
        
        if ([dialogStr containsString:@","]) {
            dialogStr = [dialogStr substringToIndex:dialogStr.length-1];
        }
        
        NSMutableDictionary *param = [NSMutableDictionary new];
        
        param[@"dialog_ids"] = dialogStr;
        param[@"upLoadUrl"] = uploadUrl;
        param[@"token"] = self.currentToken;
       
        [self upLoads:param isDir:NO];
    } else {
        //发送文件
        ChatModelData * model = self.IDArray.lastObject;
        int folderID = self.IDArray.lastObject.extend.upload_file_id;
        NSString *uploadUrl = model.url;
        [self upLoads:@{@"upload_file_id": @(folderID),@"upLoadUrl":uploadUrl,@"token":self.currentToken} isDir:YES];
    }
    //self.completionCallback?self.completionCallback(DootaskShareResultSuccess):nil;
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    
    ChatCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ChatCell"];
    
    ChatModelData *model = self.showArray[indexPath.row];
    if (![model.type isEqualToString:@"children"]){
        if (!model.select) {
            cell.selectImageView.image = [UIImage imageNamed:@"radio-button-default"];
        } else {
            cell.selectImageView.image = [UIImage imageNamed:@"radio-button-selected"];
        }
    }else {
        cell.selectImageView.image = [UIImage imageNamed:@"arrow_black_right"];
    }
    
    cell.userNickLabel.text = model.name;
    cell.userNameLabel.text = [self getLastTwoStr:model.name];
    [cell.userImageView sd_setImageWithURL:[NSURL URLWithString:model.icon]];
    
    return  cell;
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
//    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    ChatModelData * param = self.showArray[indexPath.row];
    if (![param.type isEqualToString:@"children"]) {
    
        param.select = !param.select;
        [tableView reloadData];
    } else {
        if (self.isRoot) {
            ChatModelData *rootData = [ChatModelData new];
            rootData.name = NSLocalizedString(@"allTitle", @"");
            rootData.type = @"root";
            
            [self.IDArray addObject:rootData];
        }
        
        self.isRoot = NO;

        [self.IDArray addObject:param];
        [self getSubList];
//        [tableView reloadData];
        [self showNav];
        
    }
    
    [self checkEnable];
    
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.showArray.count;
}

#pragma mark -

- (void)selectWithArray:(NSArray *)pathArray {
    self.IDArray = [pathArray mutableCopy];
    if (pathArray.count <= 1) {
        pathArray = @[];
        [self hideReload];
        self.isRoot = YES;
        [self hideNav];
        
        [self analyseData];
        self.IDArray = [pathArray mutableCopy];
    } else {
        
        self.isRoot = NO;
//        self.showArray = pathArray.lastObject[@"children"];
        [self getSubList];
        [self showNav];
        [self.tableView reloadData];
    }
    [self checkEnable];
}



#pragma mark - getter

- (NSMutableArray *)IDArray{
    if (!_IDArray) {
        _IDArray = [NSMutableArray array];
    }
    return _IDArray;
}

- (long long)fileSizeAtPath:(NSString*)filePath {

    NSFileManager* manager = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath:filePath]){
        return [[manager attributesOfItemAtPath:filePath error:nil] fileSize];
    }
    return 0;

}

- (NSString *)getLastTwoStr:(NSString *)source{
    if (source.length < 2) {
        return source;
    }else{
        source = [source substringWithRange:NSMakeRange(source.length-2, 2)];
    }
    
    return source;
}

#pragma mark  -

- (BOOL)inDarkAppearance{
  BOOL res = NO;
  if (@available(iOS 13.0, *)) {
    switch (UITraitCollection.currentTraitCollection.userInterfaceStyle) {
      case UIUserInterfaceStyleDark:
        NSLog(@"深色模式");
        res = YES;
        break;
      case UIUserInterfaceStyleLight:
        NSLog(@"浅色模式");
        break;
      case UIUserInterfaceStyleUnspecified:
        NSLog(@"未指定");
        break;
    }
  }
  return res;
}

-(NSString *)getNowTimeTimestamp{

    NSDate *datenow = [NSDate date];//现在时间,你可以输出来看下是什么格式

    NSString *timeSp = [NSString stringWithFormat:@"%ld", (long)[datenow timeIntervalSince1970]];

    return timeSp;

}

-(NSString *)getRandomString{
    NSString *alphabet = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    NSMutableString *randomString = [NSMutableString stringWithCapacity:4];

    for (NSUInteger i = 0U; i < 4; ++i) {
        [randomString appendFormat:@"%C", [alphabet characterAtIndex: arc4random_uniform((u_int32_t)[alphabet length])]];
    }
    
    return randomString;
}

@end
