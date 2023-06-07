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
#import "UserModel.h"
#import <SVProgressHUD.h>
#import <UIImageView+WebCache.h>

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
@property (nonatomic, strong)NSArray *showArray;
@property (nonatomic, strong)MMWormhole *shareWormhole;
@property (nonatomic, strong)NSDictionary *rootDic;

@property (nonatomic, strong)NSDictionary *showObjc;
@property (nonatomic, strong)PathNavigationView *tableHeaderView;
@property (nonatomic, strong)NSMutableArray *IDArray;
@property (nonatomic, assign)BOOL isRoot;

@property (nonatomic, strong)NSMutableArray *shareArray;
@property (nonatomic, strong)NSMutableArray *sendArray;
@property (nonatomic, strong)NSMutableArray *progressArray;

@property (nonatomic, strong)UIButton *comfirnButton;

@property (nonatomic, assign)BOOL completeFlag;
@end

@implementation ShareListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.shareWormhole = [[MMWormhole alloc] initWithApplicationGroupIdentifier:@"group.im.dootask" optionalDirectory:@"share"];
    
    //chatUrl dirUrl
    NSLog(@"shareMessage:%@",[self.shareWormhole messageWithIdentifier:@"chatList"]);
    
    self.view.backgroundColor = UIColor.whiteColor;
    [SVProgressHUD setContainerView:self.view];
    [SVProgressHUD setDefaultStyle:SVProgressHUDStyleDark];
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
    self.isRoot = YES;
    self.completeFlag = NO;
    [self setupHeaderView];
    [self setupTableView];
    
    [self presentContent];
    //    [self showNav];
    [self getShareData];
    [self getList];
    
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
    
    [headerView addSubview:leftButton];
    [headerView addSubview:titleLabel];
    [headerView addSubview:rightButton];
    
    [leftButton setTitle:@"取消" forState:UIControlStateNormal];
    [leftButton addTarget:self action:@selector(cancelAction) forControlEvents:UIControlEventTouchUpInside];
    [leftButton setTitleColor:UIColor.systemBlueColor forState:UIControlStateNormal];
    
    [rightButton setTitle:@"发送至" forState:UIControlStateNormal];
    [rightButton addTarget:self action:@selector(sendAction) forControlEvents:UIControlEventTouchUpInside];
    [rightButton setTitleColor:UIColor.systemBlueColor forState:UIControlStateNormal];
    [rightButton setTitleColor:UIColor.lightGrayColor forState:UIControlStateDisabled];
    
    rightButton.enabled = NO;
    
    self.comfirnButton = rightButton;
    titleLabel.text = @"发送至";
    
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
}

-(void)getShareData{
    self.shareArray = [NSMutableArray array];
    
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
                [itemProvider loadItemForTypeIdentifier:registered options:nil completionHandler:^(id<NSSecureCoding>  _Nullable item, NSError * _Null_unspecified error) {//在这里保存获取到的分享数据
                    if([(NSObject *)item isKindOfClass:[NSURL class]]){
                        NSURL *content = (NSURL *)item;
                        ShareContent *model = [ShareContent new];
                        model.shareType = shareContentTypeOther;
                        model.fileUrl = content;
                        [self.shareArray addObject:model];
                    }
                    
                }];
            }
        }];
    }];
}

-(void)getList{
    NSString *chatUrl = [self.shareWormhole messageWithIdentifier:@"chatList"];
    if (chatUrl.length < 5) {
        [SVProgressHUD showErrorWithStatus:@"请登录后使用"];
        [SVProgressHUD dismissWithDelay:2.5 completion:^{
            self.completionCallback(DootaskShareResultFail);
        }];
        
        return;
    }
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
    [SVProgressHUD show];
    [manager GET_EEUI:chatUrl parameters:nil headers:nil progress:^(NSProgress * _Nonnull downloadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject, NSInteger resCode, NSDictionary * _Nonnull resHeader) {
        
        int ret = [responseObject[@"ret"] intValue];
        NSString *msg = responseObject[@"msg"];
        if (ret == 1) {
            self.rootDic = responseObject[@"data"];
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
            [SVProgressHUD showErrorWithStatus:@"网络异常"];
            [SVProgressHUD dismissWithDelay:2 completion:^{
                self.completionCallback(DootaskShareResultFail);
            }];
        }];
    }];
}

- (void)analyseData {
    NSArray *dirArray = [self.rootDic valueForKey:@"dir"];
    NSArray *chatArray = [self.rootDic valueForKey:@"chatList"];
    NSArray *userArray = [self.rootDic valueForKey:@"userList"];
    
    NSDictionary *rootDir = @{
        @"type":@"dir",
        @"id":@0,
        @"name":@"全部文件",
        @"children":dirArray
    };
    chatArray = [chatArray myMap:^ChatModel *(NSDictionary * dic) {
        ChatModel *model = [[ChatModel alloc] init];
        [model setValuesForKeysWithDictionary:dic];
        
        return model;
    }];
    
    userArray = [userArray myMap:^UserModel *(NSDictionary * dic) {
        UserModel *model = [[UserModel alloc] init];
        [model setValuesForKeysWithDictionary:dic];
        
        return model;
    }];
    
    self.showArray = @[rootDir];
    self.showArray = [self.showArray arrayByAddingObjectsFromArray:chatArray];
    self.showArray = [self.showArray arrayByAddingObjectsFromArray:userArray];
    
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
       
        for (NSObject *obj in self.showArray) {
            if ([obj isKindOfClass:[ChatModel class]]) {
                ChatModel *model = (ChatModel *)obj;
                if (model.select){
                    self.comfirnButton.enabled = YES;
                    return;
                }
            }else if ([obj isKindOfClass:[UserModel class]]) {
                UserModel *model = (UserModel *)obj;
                if (model.select){
                    self.comfirnButton.enabled = YES;
                    return;
                }
            }
        }
        self.comfirnButton.enabled = NO;
    } else {
        self.comfirnButton.enabled = YES;
    }
}

- (void)upLoads:(NSDictionary *)param isDir:(BOOL)isDir{
    
    NSString *uploadUrl;
    uploadUrl = [self.shareWormhole messageWithIdentifier:@"upLoadUrl"];
    
    if (isDir) {
        uploadUrl = [self.shareWormhole messageWithIdentifier:@"fileUpLoadUrl"];
    }
    if (uploadUrl.length < 5) {
        
        return;
    }
    __block int number = 0;
    
    self.progressArray = [NSMutableArray array];
    
    [SVProgressHUD showProgress:0];
    for (ShareContent *model in self.shareArray) {
        if (model.isDir) {
            [SVProgressHUD showInfoWithStatus:@"暂不支持上传文件夹"];
            [SVProgressHUD dismissWithDelay:1 completion:^{
                self.completionCallback(DootaskShareResultSuccess);
            }];
            return;
        }
        NSProgress *progress = [[NSProgress alloc] init];
        [self.progressArray addObject:progress];
        
        [self uploadfilesWithParams:param upLoadURL:uploadUrl URL:model.fileUrl type:model.shareType withCount:number];
        number ++;
    }
    
}

- (void)uploadfilesWithParams:(NSDictionary *)params upLoadURL:(NSString *)upLoadURL URL:(NSURL *)url type:(ShareContentType)type withCount:(int)number{
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
    [manager POST_EEUI:upLoadURL parameters:params headers:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        
        NSError * error;
        [formData appendPartWithFileURL:url name:@"files" error:&error];
            
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        
        [self.progressArray replaceObjectAtIndex:number withObject:uploadProgress];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self taskComplete];
            
            NSLog(@"第%d进度:%f",number,uploadProgress.fractionCompleted);
        });
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject, NSInteger resCode, NSDictionary * _Nonnull resHeader) {
//        int ret = [responseObject[@"ret"] intValue];
        [self taskComplete];
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self taskComplete];
    }];
}

- (CGFloat)getTotalPercent{
    CGFloat percent = 0;
    
    for (NSProgress *progress in self.progressArray) {
        CGFloat currentPercent = progress.fractionCompleted;
        if (progress.isCancelled) {
            currentPercent = 1;
        }
        
        percent += currentPercent/self.progressArray.count;
    }
    
    return percent;
}

- (void)taskComplete{
    
    if (self.completeFlag == YES) {
        return;
    }
    CGFloat lastProgress = [self getTotalPercent];
    NSLog(@"总体进度:%f",lastProgress);
    [SVProgressHUD showProgress:lastProgress status:[[NSString stringWithFormat:@"发送中%.0f",lastProgress*100] stringByAppendingString:@"%"]];
    NSString *strProgress = [NSString stringWithFormat:@"%f",lastProgress];

    
    if([strProgress isEqualToString:@"1.000000"]) {
        
        self.completeFlag = YES;
        
        int success = 0;
        int fail = 0;
        
        NSString *msg;
        if (fail == 0) {
            msg = @"上传成功";
        }else {
            for (NSProgress *progress in self.progressArray ) {
                if (progress.fractionCompleted == 1) {
                    success ++;
                } else {
                    fail ++;
                }
            }
            msg = [NSString stringWithFormat:@"%d文件上传成功,%d文件上传失败",success,fail];
        }
        
        [SVProgressHUD dismissWithCompletion:^{
            [SVProgressHUD showSuccessWithStatus:msg];
            [SVProgressHUD dismissWithDelay:1 completion:^{
                self.completionCallback(DootaskShareResultSuccess);
            }];
        }];
    }
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
        NSString *userStr = @"";
        for (int a = 0; a<self.showArray.count; a++) {
            NSObject * model = self.showArray[a];
            if ([model isKindOfClass:[ChatModel class]]) {
                ChatModel *chat = (ChatModel *)model;
                if (chat.select)
                    dialogStr = [dialogStr stringByAppendingFormat:@"%ld,",(long)chat.dialog_id];
                
            } else if ([model isKindOfClass:[UserModel class]]) {
                UserModel *user = (UserModel *)model;
                if (user.select)
                    userStr = [userStr stringByAppendingFormat:@"%ld,",(long)user.user_id];
            }
        }
        
        NSMutableDictionary *param = [NSMutableDictionary new];
        
        if (dialogStr.length > 0) {
            dialogStr = [dialogStr substringToIndex:dialogStr.length -1];
            param[@"dialog_ids"] = dialogStr;
        }
        if (userStr.length > 0) {
            userStr = [userStr substringToIndex:userStr.length -1];
            param[@"user_ids"] = userStr;
        }
        
        
        [self upLoads:param isDir:NO];
    } else {
        //发送文件
        NSNumber *folderID = [self.IDArray.lastObject valueForKey:@"id"];
        [self upLoads:@{@"pid": folderID} isDir:YES];
    }
    //self.completionCallback?self.completionCallback(DootaskShareResultSuccess):nil;
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    
    ChatCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ChatCell"];
    
    id param = self.showArray[indexPath.row];
    if ([param isKindOfClass:[ChatModel class]]) {
        ChatModel *model = (ChatModel *)param;
        if (!model.select) {
            cell.selectImageView.image = [UIImage imageNamed:@"radio-button-default"];
        } else {
            cell.selectImageView.image = [UIImage imageNamed:@"radio-button-selected"];
        }
        cell.userNickLabel.text = model.name;
        cell.userNameLabel.text = [self getLastTwoStr:model.name];
        [cell.userImageView sd_setImageWithURL:[NSURL URLWithString:model.avatar]];
    } else if ([param isKindOfClass:[UserModel class]]) {
        UserModel *model = (UserModel *)param;
        if (!model.select) {
            cell.selectImageView.image = [UIImage imageNamed:@"radio-button-default"];
        } else {
            cell.selectImageView.image = [UIImage imageNamed:@"radio-button-selected"];
        }
        cell.userNickLabel.text = model.name;
        cell.userNameLabel.text = [self getLastTwoStr:model.name];
        [cell.userImageView sd_setImageWithURL:[NSURL URLWithString:model.avatar]];
    }else {
        cell.selectImageView.image = [UIImage imageNamed:@"arrow_black_right"];
        cell.userImageView.image = [UIImage imageNamed:@"dir"];
        cell.userNickLabel.text = [param objectForKey:@"name"];
    }
    
    return  cell;
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
//    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    id param = self.showArray[indexPath.row];
    if ([param isKindOfClass:[ChatModel class]]) {
        ChatModel *model = (ChatModel *)param;
        model.select = !model.select;
        [tableView reloadData];
    } else if ([param isKindOfClass:[UserModel class]]) {
        UserModel *model = (UserModel *)param;
        model.select = !model.select;
        [tableView reloadData];
    } else {
        self.isRoot = false;
        self.showArray = param[@"children"];
        [self.IDArray addObject:param];
        [tableView reloadData];
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
    if (pathArray.count == 0) {
        self.isRoot = YES;
        [self hideNav];
        
        [self analyseData];
        self.IDArray = [pathArray mutableCopy];
    } else {
        
        self.isRoot = NO;
        self.showArray = pathArray.lastObject[@"children"];
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

@end
