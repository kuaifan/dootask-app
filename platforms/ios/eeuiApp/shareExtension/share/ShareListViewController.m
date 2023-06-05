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
#import "PathNavigationView.h"

@interface ShareListViewController ()<UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong)UITableView *tableView;
@property (nonatomic, strong)NSMutableArray *userArray;
@property (nonatomic, strong)MMWormhole *shareWormhole;

@property (nonatomic, strong)PathNavigationView *tableHeaderView;
@property (nonatomic, strong)NSMutableArray *IDArray;
@property (nonatomic, assign)BOOL isRoot;
@end

@implementation ShareListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.shareWormhole = [[MMWormhole alloc] initWithApplicationGroupIdentifier:@"group.im.dootask" optionalDirectory:@"share"];

    //chatUrl dirUrl
    NSLog(@"shareMessage:%@",[self.shareWormhole messageWithIdentifier:@"upLoadUrl"]);
    
    self.view.backgroundColor = UIColor.whiteColor;
    [self CreatMonitorData];
    [self setupHeaderView];
    [self setupTableView];
    
    [self presentContent];
    [self showNav];
    
}

- (void)CreatMonitorData{
    self.userArray = [@[
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
    ] mutableCopy];
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
    titleLabel.text = @"发送至";
    
    [headerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.top.left.equalTo(self.view);
        make.height.equalTo(@70);
        
    }];
    
    [leftButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(headerView).offset(8);
        make.centerY.equalTo(headerView);
        make.height.width.greaterThanOrEqualTo(@10);
    }];
    
    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.centerY.equalTo(headerView);
    }];
    
    [rightButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(headerView).offset(-8);
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
    self.tableView.backgroundColor = UIColor.redColor;
    
    self.tableView.rowHeight = 60;
    
    [self.tableView registerNib:[UINib nibWithNibName:@"ChatCell" bundle:nil] forCellReuseIdentifier:@"ChatCell"];
    [self.view addSubview:self.tableView];
    
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(70);
        make.left.right.bottom.equalTo(self.view);
//        make.height.equalTo(@(self.view.frame.size.height - 70));
    }];
}

- (void)showNav{
    self.tableHeaderView = [[PathNavigationView alloc] initWithArray:self.IDArray];
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
    [self.tableView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(70);
    }];
}

// action

- (void)cancelAction {
    self.completionCallback?self.completionCallback(DootaskShareResultCancel):nil;
}
- (void)sendAction {
    self.completionCallback?self.completionCallback(DootaskShareResultSuccess):nil;
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    
    ChatCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ChatCell"];
    cell.userNickLabel.text = [self.userArray[indexPath.row] objectForKey:@"nickName"];
    
    return  cell;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return  self.userArray.count;
}

@end
