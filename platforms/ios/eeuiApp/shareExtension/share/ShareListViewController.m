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

@interface ShareListViewController ()<UITableViewDelegate, UITableViewDataSource, NavigationViewDelegate, UISearchBarDelegate, UIScrollViewDelegate>
@property (nonatomic, strong)UITableView *tableView;
@property (nonatomic, strong)NSArray<ChatModelData *> *showArray;
@property (nonatomic, strong)NSArray<ChatModelData *> *originalArray; // 存储原始数据，用于搜索
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
@property (nonatomic, strong)UISearchBar *searchBar; // 搜索栏
@property (nonatomic, strong)NSString *lastSearchKeyword; // 最后搜索的关键词
@property (nonatomic, strong)NSTimer *searchTimer; // 搜索防抖动定时器

// 添加自定义语言属性
@property (nonatomic, strong)NSBundle *languageBundle;

@end

@implementation ShareListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.shareWormhole = [[MMWormhole alloc] initWithApplicationGroupIdentifier:@"group.im.dootask" optionalDirectory:@"share"];
    
    // 从 Wormhole 获取语言设置并应用
    [self setCustomLanguage:[self.shareWormhole messageWithIdentifier:@"language"]];
    
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
    [SVProgressHUD setDefaultStyle:[self inDarkAppearance]? SVProgressHUDStyleDark: SVProgressHUDStyleLight];
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
    // [SVProgressHUD setOffsetFromCenter:UIOffsetMake(0, -100)];
    
    [self presentContent];
    //    [self showNav];
    [self getShareData];
    
    // 添加点击手势，点击键盘以外区域关闭键盘
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    // 手势不会取消视图本身的触摸事件
    tapGesture.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tapGesture];
}

// 关闭键盘的方法
- (void)dismissKeyboard {
    [self.view endEditing:YES];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
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
    
    [leftButton setTitle:[self localizedStringForKey:@"cancelTitle"] forState:UIControlStateNormal];
    [leftButton addTarget:self action:@selector(cancelAction) forControlEvents:UIControlEventTouchUpInside];
    [leftButton setTitleColor:UIColor.systemBlueColor forState:UIControlStateNormal];
    
    [rightButton setTitle:[self localizedStringForKey:@"sendTitle"] forState:UIControlStateNormal];
    [rightButton addTarget:self action:@selector(sendAction) forControlEvents:UIControlEventTouchUpInside];
    [rightButton setTitleColor:UIColor.systemBlueColor forState:UIControlStateNormal];
    [rightButton setTitleColor:UIColor.lightGrayColor forState:UIControlStateDisabled];
    
    rightButton.enabled = NO;
    
    self.comfirnButton = rightButton;
    titleLabel.text = [self localizedStringForKey:@"sendTitle"];
    
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
        make.top.equalTo(self.view).offset(60); 
        make.left.right.bottom.equalTo(self.view);
        //        make.height.equalTo(@(self.view.frame.size.height - 70));
    }];
    [self.tableView layoutIfNeeded];
    
    // 创建搜索栏作为列表的头部视图（仅在根目录显示）
    [self setupSearchBar];
}

// 设置搜索栏
- (void)setupSearchBar {
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 56)];
    self.searchBar.delegate = self;
    self.searchBar.placeholder = [self localizedStringForKey:@"searchTitle"];
    self.searchBar.searchBarStyle = UISearchBarStyleMinimal;
    
    // 修改搜索栏UI（适配暗黑模式）
    if (@available(iOS 13.0, *)) {
        self.searchBar.searchTextField.backgroundColor = [UIColor systemBackgroundColor];
        UIColor *textColor = [self inDarkAppearance] ? [UIColor whiteColor] : [UIColor blackColor];
        self.searchBar.searchTextField.textColor = textColor;
    }
    
    // 将搜索栏设置为表格的头部视图（仅在根目录显示）
    if (self.isRoot) {
        self.tableView.tableHeaderView = self.searchBar;
    }
}

// 显示或隐藏搜索框
- (void)updateSearchBarVisibility {
    if (self.isRoot) {
        // 在根目录显示搜索框
        self.tableView.tableHeaderView = self.searchBar;
    } else {
        // 在子目录隐藏搜索框
        self.tableView.tableHeaderView = nil;
    }
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
            [SVProgressHUD showErrorWithStatus:[self localizedStringForKey:@"emptyShareTitle"]];
            [SVProgressHUD dismissWithDelay:1.5 completion:^{
                self.completionCallback(DootaskShareResultCancel);
            }];
        } else {
            [self getMainList];
        }
        
    });

}

-(void)getMainList{
    NSString *chatUrl = [self.shareWormhole messageWithIdentifier:@"chatList"];
    if (chatUrl.length < 5) {
        [SVProgressHUD showErrorWithStatus:[self localizedStringForKey:@"unLoginTitle"]];
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
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [SVProgressHUD dismissWithCompletion:^{
            [SVProgressHUD showErrorWithStatus:[self localizedStringForKey:@"netWorkErrorTitle"]];
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
            [SVProgressHUD showErrorWithStatus:[self localizedStringForKey:@"netWorkErrorTitle"]];
            [SVProgressHUD dismissWithDelay:2 completion:^{
//                self.completionCallback(DootaskShareResultFail);
            }];
        }];
        [self.tableView reloadData];
        [self showReload];
    }];
    
}

- (void)analyseData {
    
    self.originalArray = self.rootModel.data; // 保存原始数据
    self.showArray = self.originalArray;
    
    // 确保在主线程更新UI
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
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
        make.top.equalTo(self.view).offset(60); // 顶部偏移保持60
        make.height.equalTo(@56); // 调整导航栏高度为56，与搜索栏相同
    }];
    [self.tableView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(116); // 60 + 56 = 116，使表格位置刚好在导航栏下方
    }];
    
    // 进入子目录时隐藏搜索框
    [self updateSearchBarVisibility];
}

- (void)hideNav{
    [self.tableHeaderView removeFromSuperview];
    self.tableHeaderView = nil;
    [self.tableView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(60); // 从70减小到60，与setupTableView中的偏移保持一致
    }];
    
    // 返回根目录时显示搜索框
    [self updateSearchBarVisibility];
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
            [self.comfirnButton setTitle:[[self localizedStringForKey:@"sendTitle"] stringByAppendingFormat:@"(%d)",select] forState:UIControlStateNormal];
            self.comfirnButton.enabled = YES;
        } else {
            [self.comfirnButton setTitle:[self localizedStringForKey:@"sendTitle"] forState:UIControlStateNormal];
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
                [SVProgressHUD showInfoWithStatus:[self localizedStringForKey:@"folderUnsupportTitle"]];
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
        
        [self.progressArray replaceObjectAtIndex:number withObject:@{@"progress": uploadProgress, @"result": @0, @"muti": @1}];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            CGFloat lastProgress = [self getTotalPercent];
            NSLog(@"总体进度:%f",lastProgress);
            [SVProgressHUD showProgress:lastProgress status:[[NSString stringWithFormat:@"%@%.0f", [self localizedStringForKey:@"sendingTitle"], MIN(lastProgress*100, 99)] stringByAppendingString: @"%"]];
            
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
        msg = [self localizedStringForKey:@"sendSuccessTitle"];
        [SVProgressHUD showSuccessWithStatus:msg];
        result = DootaskShareResultSuccess;
    } else if (success == 0) {
        msg = [self localizedStringForKey:@"sendFailTitle"];
        [SVProgressHUD showErrorWithStatus:msg];
        result = DootaskShareResultFail;
    }else  {
        
        msg = [NSString stringWithFormat:@"%d%@,%d%@", success, [self localizedStringForKey:@"successTotal"], fail, [self localizedStringForKey:@"failTotal"]];
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
        ChatModelData *model = self.IDArray.lastObject;
        int folderID = self.IDArray.lastObject.extend.upload_file_id;
        NSString *uploadUrl = model.url;
        [self upLoads:@{
            @"upload_file_id": @(folderID),
            @"upLoadUrl": uploadUrl,
            @"token": self.currentToken
        } isDir:YES];
    }
    //self.completionCallback?self.completionCallback(DootaskShareResultSuccess):nil;
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    
    ChatCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ChatCell"];
    
    // 添加安全检查，防止数组越界崩溃
    if (self.showArray.count == 0 || indexPath.row >= self.showArray.count) {
        // 返回空白cell避免崩溃
        cell.userNickLabel.text = @"";
        cell.userNameLabel.text = @"";
        cell.selectImageView.image = nil;
        return cell;
    }
    
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
            rootData.name = [self localizedStringForKey:@"allTitle"];
            rootData.type = @"root";
            
            [self.IDArray addObject:rootData];
        }
        
        self.isRoot = NO;

        [self.IDArray addObject:param];
        [self getSubList];
//        [tableView reloadData];
        [self showNav];
        
        // 进入子目录时隐藏搜索框
        [self updateSearchBarVisibility];
    }
    
    [self checkEnable];
    
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // 添加安全检查，避免返回错误的行数
    return self.showArray ? self.showArray.count : 0;
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
    
    // 更新搜索框可见性
    [self updateSearchBarVisibility];
    
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

#pragma mark  - 暗黑模式适配

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

// 获取当前时间戳
-(NSString *)getNowTimeTimestamp{

    NSDate *datenow = [NSDate date];//现在时间,你可以输出来看下是什么格式

    NSString *timeSp = [NSString stringWithFormat:@"%ld", (long)[datenow timeIntervalSince1970]];

    return timeSp;

}

// 获取随机字符串
-(NSString *)getRandomString{
    NSString *alphabet = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    NSMutableString *randomString = [NSMutableString stringWithCapacity:4];

    for (NSUInteger i = 0U; i < 4; ++i) {
        [randomString appendFormat:@"%C", [alphabet characterAtIndex: arc4random_uniform((u_int32_t)[alphabet length])]];
    }
    
    return randomString;
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self dismissKeyboard];
}

#pragma mark - UISearchBarDelegate
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    // 取消之前的定时器
    if (self.searchTimer) {
        [self.searchTimer invalidate];
        self.searchTimer = nil;
    }
    
    if (searchText.length > 0) {
        // 设置300毫秒的延迟
        self.searchTimer = [NSTimer scheduledTimerWithTimeInterval:0.3 target:self selector:@selector(performDelayedSearch:) userInfo:searchText repeats:NO];
    } else {
        // 如果搜索框为空，恢复原始数据
        self.lastSearchKeyword = nil; // 重置最后搜索的关键词
        if (self.isRoot) {
            // 重新获取主列表数据
            [self getMainList];
        } else {
            // 重新获取子目录数据
            [self getSubList];
        }
    }
}

// 添加延迟搜索方法
- (void)performDelayedSearch:(NSTimer *)timer {
    NSString *searchText = timer.userInfo;
    if (![searchText isEqualToString:self.lastSearchKeyword]) {
        self.lastSearchKeyword = searchText;
        // 执行搜索
        [self searchWithKeyword:searchText];
    }
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
    // 当点击搜索按钮时，检查是否与之前的搜索关键词相同
    if (searchBar.text.length > 0 && ![searchBar.text isEqualToString:self.lastSearchKeyword]) {
        self.lastSearchKeyword = searchBar.text;
        // 取消可能存在的定时器
        if (self.searchTimer) {
            [self.searchTimer invalidate];
            self.searchTimer = nil;
        }
        [self searchWithKeyword:searchBar.text];
    }
}

// 添加新方法：根据关键词进行搜索
- (void)searchWithKeyword:(NSString *)keyword {
    // 根据当前是在根目录还是子目录，选择不同的请求方式
    if (self.isRoot) {
        // 在根目录进行搜索
        [self searchMainListWithKeyword:keyword];
    } else {
        // 在子目录进行搜索
        [self searchSubListWithKeyword:keyword];
    }
}

// 在主列表中搜索
- (void)searchMainListWithKeyword:(NSString *)keyword {
    NSString *chatUrl = [self.shareWormhole messageWithIdentifier:@"chatList"];
    if (chatUrl.length < 5) {
        return;
    }
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
    [SVProgressHUD show];
    
    // 保存当前搜索关键词用于后续验证
    NSString *currentKeyword = keyword;
    
    // 添加keyword参数到请求中
    NSDictionary *params = @{
        @"type": self.isFile ? @"file" : @"text",
        @"key": keyword // 添加关键词参数
    };
    
    [manager GET_EEUI:chatUrl parameters:params headers:nil progress:^(NSProgress * _Nonnull downloadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject, NSInteger resCode, NSDictionary * _Nonnull resHeader) {
        
        // 检查关键词是否发生变化，如果变化则不更新UI
        if (![currentKeyword isEqualToString:self.lastSearchKeyword]) {
            [SVProgressHUD dismiss];
            return;
        }
        
        int ret = [responseObject[@"ret"] intValue];
        NSString *msg = responseObject[@"msg"];
        if (ret == 1) {
            ChatModel *model = [ChatModel new];
            [model mj_setKeyValues:responseObject];
            self.rootModel = model;
            [self analyseData];
            [SVProgressHUD dismiss];
        } else {
            [SVProgressHUD dismissWithCompletion:^{
                [SVProgressHUD showErrorWithStatus:msg];
                [SVProgressHUD dismissWithDelay:2 completion:nil];
            }];
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [SVProgressHUD dismissWithCompletion:^{
            [SVProgressHUD showErrorWithStatus:[self localizedStringForKey:@"netWorkErrorTitle"]];
            [SVProgressHUD dismissWithDelay:2 completion:nil];
        }];
    }];
}

// 在子列表中搜索
- (void)searchSubListWithKeyword:(NSString *)keyword {
    ChatModelData *subModel = self.IDArray.lastObject;
    if (subModel == nil) {
        return;
    }
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
    self.showArray = @[];
    [SVProgressHUD show];
    
    // 保存当前搜索关键词用于后续验证
    NSString *currentKeyword = keyword;
    
    // 添加keyword参数到请求中
    NSDictionary *params = @{
        @"token": self.currentToken,
        @"key": keyword // 添加关键词参数
    };
    
    [manager GET_EEUI:subModel.url parameters:params headers:nil progress:^(NSProgress * _Nonnull downloadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject, NSInteger resCode, NSDictionary * _Nonnull resHeader) {
        
        // 检查关键词是否发生变化，如果变化则不更新UI
        if (![currentKeyword isEqualToString:self.lastSearchKeyword]) {
            [SVProgressHUD dismiss];
            return;
        }
        
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
        } else {
            [SVProgressHUD dismissWithCompletion:^{
                
                [SVProgressHUD showErrorWithStatus:msg];
                [SVProgressHUD dismissWithDelay:2 completion:nil];
            }];
        }
        [self.tableView reloadData];
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        self.showArray = @[];
        [SVProgressHUD dismissWithCompletion:^{
            [SVProgressHUD showErrorWithStatus:[self localizedStringForKey:@"netWorkErrorTitle"]];
            [SVProgressHUD dismissWithDelay:2 completion:nil];
        }];
        [self.tableView reloadData];
    }];
}

// 添加自定义语言属性设置方法
- (void)setCustomLanguage:(NSString *)language {
    // 验证语言参数是否有效
    if (!language || ![language isKindOfClass:[NSString class]] || language.length == 0) {
        NSLog(@"没有找到有效的语言设置，不调整语言");
        return;
    }
    
    // 获取语言包路径
    NSString *languageBundlePath = [[NSBundle mainBundle] pathForResource:language ofType:@"lproj"];
    
    // 如果语言包路径存在，则设置语言包
    if (languageBundlePath) {
        self.languageBundle = [NSBundle bundleWithPath:languageBundlePath];
        NSLog(@"使用自定义语言: %@", language);
    } else {
        // 如果语言包路径不存在，则使用系统默认语言包
        self.languageBundle = [NSBundle mainBundle];
        NSLog(@"找不到语言包: %@，回退到系统默认语言", language);
    }
}

// 添加获取本地化字符串的方法
- (NSString *)localizedStringForKey:(NSString *)key {
    if (self.languageBundle) {
        return [self.languageBundle localizedStringForKey:key value:@"" table:nil];
    }
    return NSLocalizedString(key, @"");
}

@end
