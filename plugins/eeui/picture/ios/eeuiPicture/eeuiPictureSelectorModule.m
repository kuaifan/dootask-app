#import "eeuiPictureSelectorModule.h"
#import "TZImagePickerController.h"
#import "DeviceUtil.h"
#import "eeuiNewPageManager.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <AVFoundation/AVFoundation.h>
#import "ZLShowMultimedia.h"
#import "KSPhotoBrowser.h"
#import <WeexPluginLoader/WeexPluginLoader.h>

@interface eeuiPictureSelectorModule ()<TZImagePickerControllerDelegate,UIActionSheetDelegate,UIImagePickerControllerDelegate,UIAlertViewDelegate,UINavigationControllerDelegate>

@property (nonatomic, strong) UIImagePickerController *imagePickerVc;
@property (strong, nonatomic) CLLocation *location;
@property (nonatomic, strong) NSDictionary *params;
@property (nonatomic, copy) WXModuleKeepAliveCallback callback;
@property (nonatomic, strong) NSMutableArray *selectedPhotos;
@property (nonatomic, strong) NSMutableArray *selectedAssets;
@property (nonatomic, strong) NSString *pageName;

@end

@implementation eeuiPictureSelectorModule

WX_PlUGIN_EXPORT_MODULE(eeuiPicture, eeuiPictureSelectorModule)
WX_EXPORT_METHOD(@selector(create:callback:))
WX_EXPORT_METHOD(@selector(compressImage:callback:))
WX_EXPORT_METHOD(@selector(picturePreview:paths:callback:))
WX_EXPORT_METHOD(@selector(videoPreview:))
WX_EXPORT_METHOD(@selector(deleteCache))

- (void)create:(NSDictionary*)params callback:(WXModuleKeepAliveCallback)callback
{
    self.params = params;
    self.callback = callback;

    int tag =(arc4random() % 100) + 1000;//返回随机数
    self.pageName = [NSString stringWithFormat:@"picture-%d", tag];

    NSString *type = params[@"type"] ? [WXConvert NSString:params[@"type"]] : @"gallery";

    NSInteger gallery = params[@"gallery"] ? [WXConvert NSInteger:params[@"gallery"]] : 0;
    NSInteger maxNum = params[@"maxNum"] ? [WXConvert NSInteger:params[@"maxNum"]] : 9;
    NSInteger minNum = params[@"minNum"] ? [WXConvert NSInteger:params[@"minNum"]] : 0;

    NSInteger spanCount = params[@"spanCount"] ? [WXConvert NSInteger:params[@"spanCount"]] : 4;
    NSInteger recordVideoSecond = params[@"recordVideoSecond"] ? [WXConvert NSInteger:params[@"recordVideoSecond"]] : 60;

    BOOL camera = params[@"camera"] ? [WXConvert BOOL:params[@"camera"]] : YES;
    BOOL gif = params[@"gif"] ? [WXConvert BOOL:params[@"gif"]] : NO;
    BOOL crop = params[@"crop"] ? [WXConvert BOOL:params[@"crop"]] : NO;
    BOOL circle = params[@"circle"] ? [WXConvert BOOL:params[@"circle"]] : NO;
    BOOL compress = params[@"compress"] ? [WXConvert BOOL:params[@"compress"]] : NO;
    
    NSMutableArray *selected = @[].mutableCopy;
    if ([params[@"selected"] isKindOfClass:[NSArray class]]) {
        selected = [(NSArray *) params[@"selected"] mutableCopy];
    }


    NSDictionary *result = @{@"pageName":self.pageName, @"status":@"create", @"lists":@[]};
    self.callback(result, YES);

    if ([type isEqualToString:@"camera"]) {
        [self takePhoto];
        return;
    }

    TZImagePickerController *imagePickerVc = [[TZImagePickerController alloc] initWithMaxImagesCount:maxNum columnNumber:spanCount delegate:self pushPhotoPickerVc:YES];
    // imagePickerVc.navigationBar.translucent = NO;

    #pragma mark - 五类个性化设置，这些参数都可以不传，此时会走默认设置
    //    imagePickerVc.isSelectOriginalPhoto = YES;
    //
    //    if (self.maxCountTF.text.integerValue > 1) {
    //        // 1.设置目前已经选中的图片数组
    //        imagePickerVc.selectedAssets = _selectedAssets; // 目前已经选中的图片数组
    //    }
    if (selected.count > 0) {
        NSMutableArray *selectedArray =@[].mutableCopy;
        for (int i = 0; i < _selectedAssets.count; i++) {
            PHAsset *asset = _selectedAssets[i];

            NSString *filename = [asset valueForKey:@"filename"];
            NSString *path = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject];
            NSString *imgPath = [NSString stringWithFormat:@"%@/%@", path, filename];
            for (int j = 0; j < selected.count; j++) {
                NSDictionary *sel = selected[j];
                NSString *selPath = [sel valueForKey:@"path"];
                if ([selPath isEqual:imgPath]) {
                    [selectedArray addObject:asset];
                }
            }
        }
        if (selectedArray.count > 0) {
            imagePickerVc.selectedAssets = selectedArray;
        }
    }
    
    imagePickerVc.allowTakePicture = camera; // 在内部显示拍照按钮
    //    imagePickerVc.allowTakeVideo = self.showTakeVideoBtnSwitch.isOn;   // 在内部显示拍视频按
    imagePickerVc.videoMaximumDuration = recordVideoSecond; // 视频最大拍摄时间
    [imagePickerVc setUiImagePickerControllerSettingBlock:^(UIImagePickerController *imagePickerController) {
        imagePickerController.videoQuality = UIImagePickerControllerQualityTypeHigh;
    }];

    // imagePickerVc.photoWidth = 1000;

    // 2. Set the appearance
    // 2. 在这里设置imagePickerVc的外观
    // if (iOS7Later) {
    // imagePickerVc.navigationBar.barTintColor = [UIColor greenColor];
    // }
    // imagePickerVc.oKButtonTitleColorDisabled = [UIColor lightGrayColor];
    // imagePickerVc.oKButtonTitleColorNormal = [UIColor greenColor];
    // imagePickerVc.navigationBar.translucent = NO;
    imagePickerVc.iconThemeColor = [UIColor colorWithRed:31 / 255.0 green:185 / 255.0 blue:34 / 255.0 alpha:1.0];
    imagePickerVc.showPhotoCannotSelectLayer = YES;
    imagePickerVc.cannotSelectLayerColor = [[UIColor whiteColor] colorWithAlphaComponent:0.8];
    [imagePickerVc setPhotoPickerPageUIConfigBlock:^(UICollectionView *collectionView, UIView *bottomToolBar, UIButton *previewButton, UIButton *originalPhotoButton, UILabel *originalPhotoLabel, UIButton *doneButton, UIImageView *numberImageView, UILabel *numberLabel, UIView *divideLine) {
        [doneButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    }];
    /*
     [imagePickerVc setAssetCellDidSetModelBlock:^(TZAssetCell *cell, UIImageView *imageView, UIImageView *selectImageView, UILabel *indexLabel, UIView *bottomView, UILabel *timeLength, UIImageView *videoImgView) {
     cell.contentView.clipsToBounds = YES;
     cell.contentView.layer.cornerRadius = cell.contentView.tz_width * 0.5;
     }];
     */

    // 3. Set allow picking video & photo & originalPhoto or not
    // 3. 设置是否可以选择视频/图片/原图
    switch (gallery) {
        case 0:
            imagePickerVc.allowPickingVideo = YES;
            imagePickerVc.allowPickingImage = YES;
            break;
        case 1:
            imagePickerVc.allowPickingVideo = NO;
            imagePickerVc.allowPickingImage = YES;
            break;
        case 2:
            imagePickerVc.allowPickingVideo = YES;
            imagePickerVc.allowPickingImage = NO;
            break;
        case 3:
            imagePickerVc.allowPickingVideo = YES;
            imagePickerVc.allowPickingImage = NO;
            break;

        default:
            break;
    }
    imagePickerVc.allowPickingOriginalPhoto = YES;
    imagePickerVc.allowPickingGif = gif;
    //    imagePickerVc.allowPickingMultipleVideo = self.allowPickingMuitlpleVideoSwitch.isOn; // 是否可以多选视频

    // 4. 照片排列按修改时间升序
    //    imagePickerVc.sortAscendingByModificationDate = self.sortAscendingSwitch.isOn;

     imagePickerVc.minImagesCount = minNum;
    // imagePickerVc.alwaysEnableDoneBtn = YES;

    // imagePickerVc.minPhotoWidthSelectable = 3000;
    // imagePickerVc.minPhotoHeightSelectable = 2000;

    /// 5. Single selection mode, valid when maxImagesCount = 1
    /// 5. 单选模式,maxImagesCount为1时才生效
    imagePickerVc.showSelectBtn = NO;
    imagePickerVc.allowCrop = crop;
    imagePickerVc.needCircleCrop = circle;
    // 设置竖屏下的裁剪尺寸
    //    NSInteger left = 30;
    //    NSInteger widthHeight = self.view.tz_width - 2 * left;
    //    NSInteger top = (self.view.tz_height - widthHeight) / 2;
    //    imagePickerVc.cropRect = CGRectMake(left, top, widthHeight, widthHeight);
    // 设置横屏下的裁剪尺寸
    // imagePickerVc.cropRectLandscape = CGRectMake((self.view.tz_height - widthHeight) / 2, left, widthHeight, widthHeight);
    /*
     [imagePickerVc setCropViewSettingBlock:^(UIView *cropView) {
     cropView.layer.borderColor = [UIColor redColor].CGColor;
     cropView.layer.borderWidth = 2.0;
     }];*/

    //imagePickerVc.allowPreview = NO;
    // 自定义导航栏上的返回按钮
    /*
     [imagePickerVc setNavLeftBarButtonSettingBlock:^(UIButton *leftButton){
     [leftButton setImage:[UIImage imageNamed:@"back"] forState:UIControlStateNormal];
     [leftButton setImageEdgeInsets:UIEdgeInsetsMake(0, -10, 0, 20)];
     }];
     imagePickerVc.delegate = self;
     */

    // Deprecated, Use statusBarStyle
    // imagePickerVc.isStatusBarDefault = NO;
    imagePickerVc.statusBarStyle = UIStatusBarStyleLightContent;
    imagePickerVc.modalPresentationStyle = UIModalPresentationFullScreen;

    // 设置是否显示图片序号
    //    imagePickerVc.showSelectedIndex = self.showSelectedIndexSwitch.isOn;

    // 设置首选语言 / Set preferred language
    // imagePickerVc.preferredLanguage = @"zh-Hans";

    // 设置languageBundle以使用其它语言 / Set languageBundle to use other language
    // imagePickerVc.languageBundle = [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"tz-ru" ofType:@"lproj"]];

    #pragma mark - 到这里为止

    // You can get the photos by block, the same as by delegate.
    // 你可以通过block或者代理，来得到用户选择的照片.
    __weak typeof(self) ws = self;
    [imagePickerVc setDidFinishPickingPhotosHandle:^(NSArray<UIImage *> *photos, NSArray *assets, BOOL isSelectOriginalPhoto) {
        [ws pictureTaskAssetsCompress:compress assets:assets photos:photos];
    }];
    [self openViewController:imagePickerVc];
}

- (NSDictionary *)writeCompressImageActionCompress:(BOOL)compress img:(UIImage *)img imgPath:(NSString *)imgPath idx:(int)idx typeStr:(NSString *)typeStr{
    
    if (compress) {
        NSData *data = UIImageJPEGRepresentation(img, 1);
        NSInteger imgSize = data.length/1024;

        NSInteger compressSize = self.params[@"compressSize"] ? [WXConvert NSInteger:self.params[@"compressSize"]] : 100;
        if (compressSize < imgSize) {
            [UIImageJPEGRepresentation(img, 0.5) writeToFile:imgPath atomically:YES];
        }
    } else {
       [UIImageJPEGRepresentation(img, 1.0) writeToFile:imgPath atomically:YES];
    }
    
    NSString *type = self.params[@"type"] ? [WXConvert NSString:self.params[@"type"]] : @"gallery";
    BOOL crop = self.params[@"crop"] ? [WXConvert BOOL:self.params[@"crop"]] : NO;
    
    NSDictionary *dic = @{@"path":imgPath,
                          @"cutPath":imgPath,
                          @"compressPath":imgPath,
                          @"isCut":@(crop),
                          @"isCompressed":@(compress),
                          @"compressed":@(compress),
                          @"mimeType":type,
                          @"idx": @(idx),
                          @"type_str": typeStr?typeStr:@""
    };
    
    return dic;
}

/// HEIF 格式检测
- (BOOL)isHEIF:(PHAsset *)asset {

    __block BOOL isHEIF = NO;
    if (@available(iOS 9, *)) {
        NSArray *resourceList = [PHAssetResource assetResourcesForAsset:asset];
        [resourceList enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            PHAssetResource *resource = obj;
            NSString *UTI = resource.uniformTypeIdentifier;
            if ([UTI isEqualToString:@"public.heif"] || [UTI isEqualToString:@"public.heic"]) {
                isHEIF = YES;
                *stop = YES;
            }
        }];
    } else {
        // Fallback on earlier versions
        NSString *UTI = [asset valueForKey:@"uniformTypeIdentifier"];
        isHEIF = [UTI isEqualToString:@"public.heif"] || [UTI isEqualToString:@"public.heic"];
    }
    return isHEIF;
}

- (void)pictureTaskAssetsCompress:(BOOL)compress assets:(NSArray *)assets photos:(NSArray<UIImage *> *)photos{
    
    self.selectedAssets = [NSMutableArray arrayWithArray:assets];
    self.selectedPhotos = [NSMutableArray arrayWithArray:photos];

    dispatch_group_t group = dispatch_group_create();
    
    NSMutableArray *list = [NSMutableArray arrayWithCapacity:assets.count];
    for (int i = 0; i < assets.count; i++) {
        PHAsset *asset = assets[i];
        UIImage *img = photos[i];

        NSString *filename = [asset valueForKey:@"filename"];
        NSString *path = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject];
        NSString *imgPath = [NSString stringWithFormat:@"%@/%@", path, filename];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:imgPath]) {
            NSData *no_path_img_data = UIImagePNGRepresentation(img);
            [no_path_img_data writeToFile:imgPath atomically:YES];
        }
        
        /// HEIF 格式检测
        BOOL isHEIF = [self isHEIF:asset];
        
        if (isHEIF) {
            dispatch_group_enter(group);
            [asset requestContentEditingInputWithOptions:nil completionHandler:^(PHContentEditingInput * _Nullable contentEditingInput, NSDictionary * _Nonnull info) {
                
                NSDictionary *dic;
                if (contentEditingInput.fullSizeImageURL) {
                    CIImage *ciImage = [CIImage imageWithContentsOfURL:contentEditingInput.fullSizeImageURL];
                    CIContext *context = [CIContext context];
                    NSData *jpgData;
                    /// HEIC格式为iOS11后更新的  因此不需要适配iOS10以下
                    if (@available(iOS 10.0, *)) {
                        jpgData = [context JPEGRepresentationOfImage:ciImage colorSpace:ciImage.colorSpace options:@{}];
                    }
                
                    if (jpgData) {
                        NSString *temp_path_prifx = NSTemporaryDirectory();
                        NSString *tempPath = [NSString stringWithFormat:@"%@%@%d.jpeg", temp_path_prifx, @"cache_heif_change_img_", i];
                        if ([jpgData writeToFile:tempPath atomically:YES]) {
                            UIImage *c_img = [UIImage imageWithData:jpgData];
                            dic = [self writeCompressImageActionCompress:compress img:c_img imgPath:tempPath idx:i typeStr:@"HEIC_Cache"];
                        } else {
                            dic = [self writeCompressImageActionCompress:compress img:img imgPath:imgPath idx:i typeStr: nil];
                        }
                    } else {
                        dic = [self writeCompressImageActionCompress:compress img:img imgPath:imgPath idx:i typeStr:nil];
                    }
                } else {
                    dic = [self writeCompressImageActionCompress:compress img:img imgPath:imgPath idx:i typeStr:nil];
                }
                [list addObject:dic];
                dispatch_group_leave(group);
            }];
            
        } else {
            
            dispatch_group_enter(group);
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                NSDictionary *dic = [self writeCompressImageActionCompress:compress img:img imgPath:imgPath idx:i typeStr:nil];
                [list addObject:dic];
                dispatch_group_leave(group);
            });
        }
    }
    
    dispatch_group_notify(group, dispatch_get_global_queue(0, 0), ^{
        if (self.callback) {
            
            if (list.count > 1) {
                [list sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
                    NSDictionary *dict1 = obj1;
                    NSDictionary *dict2 = obj2;
                    if ((NSInteger)[dict1 valueForKey:@"idx"] < (NSInteger)[dict2 valueForKey:@"idx"]) {
                        return NSOrderedDescending;
                    } else {
                        return NSOrderedAscending;
                    }
                }];
                
                NSDictionary *result = @{@"pageName":self.pageName, @"status":@"success", @"lists":list};
                self.callback(result, YES);
                
            } else {
                NSDictionary *result = @{@"pageName":self.pageName, @"status":@"success", @"lists":list};
                self.callback(result, YES);
            }
                
            NSDictionary *result2 = @{@"pageName":self.pageName, @"status":@"destroy", @"lists":@[]};
            self.callback(result2, NO);
        }
    });
}

- (UIImagePickerController *)imagePickerVc {
    if (_imagePickerVc == nil) {
           _imagePickerVc = [[UIImagePickerController alloc] init];
           _imagePickerVc.delegate = self;
           // set appearance / 改变相册选择页的导航栏外观
           _imagePickerVc.navigationBar.barTintColor = [DeviceUtil getTopviewControler].navigationController.navigationBar.barTintColor;
           _imagePickerVc.navigationBar.tintColor = [DeviceUtil getTopviewControler].navigationController.navigationBar.tintColor;
           UIBarButtonItem *tzBarItem, *BarItem;
           if (@available(iOS 9, *)) {
               tzBarItem = [UIBarButtonItem appearanceWhenContainedInInstancesOfClasses:@[[TZImagePickerController class]]];
               BarItem = [UIBarButtonItem appearanceWhenContainedInInstancesOfClasses:@[[UIImagePickerController class]]];
           } else {
               tzBarItem = [UIBarButtonItem appearanceWhenContainedIn:[TZImagePickerController class], nil];
               BarItem = [UIBarButtonItem appearanceWhenContainedIn:[UIImagePickerController class], nil];
           }
           NSDictionary *titleTextAttributes = [tzBarItem titleTextAttributesForState:UIControlStateNormal];
           [BarItem setTitleTextAttributes:titleTextAttributes forState:UIControlStateNormal];

       }
    return _imagePickerVc;
}

#pragma mark - UIImagePickerController

- (void)takePhoto {
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (authStatus == AVAuthorizationStatusRestricted || authStatus == AVAuthorizationStatusDenied) {
        // 无相机权限 做一个友好的提示
        UIAlertView * alert = [[UIAlertView alloc]initWithTitle:@"无法使用相机" message:@"请在iPhone的""设置-隐私-相机""中允许访问相机" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"设置", nil];
        [alert show];
    } else if (authStatus == AVAuthorizationStatusNotDetermined) {
        // fix issue 466, 防止用户首次拍照拒绝授权时相机页黑屏
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            if (granted) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self takePhoto];
                });
            }
        }];
        // 拍照之前还需要检查相册权限
    } else if ([PHPhotoLibrary authorizationStatus] == 2) { // 已被拒绝，没有相册权限，将无法保存拍的照片
        UIAlertView * alert = [[UIAlertView alloc]initWithTitle:@"无法访问相册" message:@"请在iPhone的""设置-隐私-相册""中允许访问相册" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"设置", nil];
        [alert show];
    } else if ([PHPhotoLibrary authorizationStatus] == 0) { // 未请求过相册权限
        [[TZImageManager manager] requestAuthorizationWithCompletion:^{
            [self takePhoto];
        }];
    } else {
        [self pushImagePickerController];
    }
}

// 调用相机
- (void)pushImagePickerController {
    // 提前定位
    __weak typeof(self) weakSelf = self;
    [[TZLocationManager manager] startLocationWithSuccessBlock:^(NSArray<CLLocation *> *locations) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        strongSelf.location = [locations firstObject];
    } failureBlock:^(NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        strongSelf.location = nil;
    }];

    UIImagePickerControllerSourceType sourceType = UIImagePickerControllerSourceTypeCamera;
    if ([UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeCamera]) {
        self.imagePickerVc.sourceType = sourceType;
        NSMutableArray *mediaTypes = [NSMutableArray array];
//        if (self.showTakeVideoBtnSwitch.isOn) {
//            [mediaTypes addObject:(NSString *)kUTTypeMovie];
//        }
        if ([WXConvert BOOL:self.params[@"camera"]]) {
            [mediaTypes addObject:(NSString *)kUTTypeImage];
        }
        if (mediaTypes.count) {
            _imagePickerVc.mediaTypes = mediaTypes;
        }
        [self openViewController:_imagePickerVc];
    } else {
        NSLog(@"模拟器中无法打开照相机,请在真机中使用");
    }
}

- (void)imagePickerController:(UIImagePickerController*)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];
    NSString *type = [info objectForKey:UIImagePickerControllerMediaType];

    TZImagePickerController *tzImagePickerVc = [[TZImagePickerController alloc] initWithMaxImagesCount:1 delegate:self];
//    tzImagePickerVc.sortAscendingByModificationDate = self.sortAscendingSwitch.isOn;
    [tzImagePickerVc showProgressHUD];
    if ([type isEqualToString:@"public.image"]) {
        UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
        NSDictionary *meta = [info objectForKey:UIImagePickerControllerMediaMetadata];
        // save photo and get asset / 保存图片，获取到asset
        [[TZImageManager manager] savePhotoWithImage:image meta:meta location:self.location completion:^(PHAsset *asset, NSError *error){
            [tzImagePickerVc hideProgressHUD];
            if (error) {
                NSLog(@"图片保存失败 %@",error);
            } else {
                TZAssetModel *assetModel = [[TZImageManager manager] createModelWithAsset:asset];
                 if ([WXConvert BOOL:self.params[@"crop"]]) { // 允许裁剪,去裁剪
                    TZImagePickerController *imagePicker = [[TZImagePickerController alloc] initCropTypeWithAsset:assetModel.asset photo:image completion:^(UIImage *cropImage, id asset) {
                        [self refreshCollectionViewWithAddedAsset:asset image:cropImage];
                    }];
                    imagePicker.allowPickingImage = YES;
                    imagePicker.needCircleCrop = [WXConvert BOOL:self.params[@"circle"]];
                    imagePicker.circleCropRadius = 100;
                    [self openViewController:imagePicker];
                } else {
                    [self refreshCollectionViewWithAddedAsset:assetModel.asset image:image];
                }
            }
        }];
    } else if ([type isEqualToString:@"public.movie"]) {
        NSURL *videoUrl = [info objectForKey:UIImagePickerControllerMediaURL];
        if (videoUrl) {
            [[TZImageManager manager] saveVideoWithUrl:videoUrl location:self.location completion:^(PHAsset *asset, NSError *error) {
                [tzImagePickerVc hideProgressHUD];
                if (!error) {
                    TZAssetModel *assetModel = [[TZImageManager manager] createModelWithAsset:asset];
                    [[TZImageManager manager] getPhotoWithAsset:assetModel.asset completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
                        if (!isDegraded && photo) {
                            [self refreshCollectionViewWithAddedAsset:assetModel.asset image:photo];
                        }
                    }];
                }
            }];
        }
    }
}

- (void)refreshCollectionViewWithAddedAsset:(id)asset image:(UIImage *)image {
    [_selectedAssets addObject:asset];
    [_selectedPhotos addObject:image];
//    [_collectionView reloadData];

    if ([asset isKindOfClass:[PHAsset class]]) {

        NSString *filename = [asset valueForKey:@"filename"];
        NSString *path = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject];
        NSString *imgPath = [NSString stringWithFormat:@"%@/%@", path, filename];

        BOOL compress = self.params[@"compress"] ? [WXConvert BOOL:self.params[@"compress"]] : NO;

        //压缩
        if (compress) {
            NSData *data = UIImageJPEGRepresentation(image, 1);
            NSInteger imgSize = data.length/1024;

            NSInteger compressSize = self.params[@"compressSize"] ? [WXConvert NSInteger:self.params[@"compressSize"]] : 100;
            if (compressSize < imgSize) {
                [UIImageJPEGRepresentation(image, 0.5) writeToFile:imgPath atomically:YES];
            }
        } else {
           [UIImageJPEGRepresentation(image, 1.0) writeToFile:imgPath atomically:YES];
        }

        NSString *type = self.params[@"type"] ? [WXConvert NSString:self.params[@"type"]] : @"gallery";
        BOOL crop = self.params[@"crop"] ? [WXConvert BOOL:self.params[@"crop"]] : NO;

        NSDictionary *dic = @{@"path":imgPath,
                              @"cutPath":imgPath,
                              @"compressPath":imgPath,
                              @"isCut":@(crop),
                              @"isCompressed":@(compress),
                              @"compressed":@(compress),
                              @"mimeType":type};

        if (self.callback) {
            NSDictionary *result = @{@"pageName":self.pageName, @"status":@"success", @"lists":@[dic]};
            self.callback(result, YES);

            NSDictionary *result2 = @{@"pageName":self.pageName, @"status":@"destroy", @"lists":@[]};
            self.callback(result2, NO);
        }
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    if ([picker isKindOfClass:[UIImagePickerController class]]) {
        [picker dismissViewControllerAnimated:YES completion:nil];

        if (self.callback) {
            NSDictionary *result = @{@"pageName":self.pageName, @"status":@"destroy", @"lists":@[]};
            self.callback(result, YES);
        }
    }
}


#pragma mark - TZImagePickerControllerDelegate

/// User click cancel button
/// 用户点击了取消
- (void)tz_imagePickerControllerDidCancel:(TZImagePickerController *)picker {
    // NSLog(@"cancel");
}

// The picker should dismiss itself; when it dismissed these handle will be called.
// You can also set autoDismiss to NO, then the picker don't dismiss itself.
// If isOriginalPhoto is YES, user picked the original photo.
// You can get original photo with asset, by the method [[TZImageManager manager] getOriginalPhotoWithAsset:completion:].
// The UIImage Object in photos default width is 828px, you can set it by photoWidth property.
// 这个照片选择器会自己dismiss，当选择器dismiss的时候，会执行下面的代理方法
// 你也可以设置autoDismiss属性为NO，选择器就不会自己dismis了
// 如果isSelectOriginalPhoto为YES，表明用户选择了原图
// 你可以通过一个asset获得原图，通过这个方法：[[TZImageManager manager] getOriginalPhotoWithAsset:completion:]
// photos数组里的UIImage对象，默认是828像素宽，你可以通过设置photoWidth属性的值来改变它
- (void)imagePickerController:(TZImagePickerController *)picker didFinishPickingPhotos:(NSArray<UIImage *> *)photos sourceAssets:(NSArray *)assets isSelectOriginalPhoto:(BOOL)isSelectOriginalPhoto infos:(NSArray<NSDictionary *> *)infos {
    _selectedPhotos = [NSMutableArray arrayWithArray:photos];
    _selectedAssets = [NSMutableArray arrayWithArray:assets];
//    _isSelectOriginalPhoto = isSelectOriginalPhoto;
//    [_collectionView reloadData];
    // _collectionView.contentSize = CGSizeMake(0, ((_selectedPhotos.count + 2) / 3 ) * (_margin + _itemWH));

    // 1.打印图片名字
//    [self printAssetsName:assets];
    // 2.图片位置信息
    for (PHAsset *phAsset in assets) {
        NSLog(@"location:%@",phAsset.location);
    }

    // 3. 获取原图的示例，用队列限制最大并发为1，避免内存暴增
//    self.operationQueue = [[NSOperationQueue alloc] init];
//    self.operationQueue.maxConcurrentOperationCount = 1;
//    for (NSInteger i = 0; i < assets.count; i++) {
//        PHAsset *asset = assets[i];
//        // 图片上传operation，上传代码请写到operation内的start方法里，内有注释
//        TZImageUploadOperation *operation = [[TZImageUploadOperation alloc] initWithAsset:asset completion:^(UIImage * photo, NSDictionary *info, BOOL isDegraded) {
//            if (isDegraded) return;
//            NSLog(@"图片获取&上传完成");
//        } progressHandler:^(double progress, NSError * _Nonnull error, BOOL * _Nonnull stop, NSDictionary * _Nonnull info) {
//            NSLog(@"获取原图进度 %f", progress);
//        }];
//        [self.operationQueue addOperation:operation];
//    }
}

// If user picking a video, this callback will be called.
// If system version > iOS8,asset is kind of PHAsset class, else is ALAsset class.
// 如果用户选择了一个视频，下面的handle会被执行
// 如果系统版本大于iOS8，asset是PHAsset类的对象，否则是ALAsset类的对象
- (void)imagePickerController:(TZImagePickerController *)picker didFinishPickingVideo:(UIImage *)coverImage sourceAssets:(id)asset {
    _selectedPhotos = [NSMutableArray arrayWithArray:@[coverImage]];
    _selectedAssets = [NSMutableArray arrayWithArray:@[asset]];
    // open this code to send video / 打开这段代码发送视频
    [[TZImageManager manager] getVideoOutputPathWithAsset:asset presetName:AVAssetExportPreset640x480 success:^(NSString *outputPath) {
        NSLog(@"视频导出到本地完成,沙盒路径为:%@",outputPath);
        // Export completed, send video here, send by outputPath or NSData
        // 导出完成，在这里写上传代码，通过路径或者通过NSData上传

        //callback
        NSString *types = self.params[@"type"] ? [WXConvert NSString:self.params[@"type"]] : @"gallery";
        BOOL crop = self.params[@"crop"] ? [WXConvert BOOL:self.params[@"crop"]] : NO;
        BOOL compress = self.params[@"compress"] ? [WXConvert BOOL:self.params[@"compress"]] : NO;

        NSDictionary *dic = @{@"path":outputPath,
                              @"cutPath":outputPath,
                              @"compressPath":outputPath,
                              @"isCut":@(crop),
                              @"isCompressed":@(compress),
                              @"compressed":@(compress),
                              @"mimeType":types};

        NSDictionary *result = @{@"pageName":self.pageName, @"status":@"success", @"lists":@[dic]};
        if (self.callback) {
            self.callback(result, YES);
        }
    } failure:^(NSString *errorMessage, NSError *error) {
        NSLog(@"视频导出失败:%@,error:%@",errorMessage, error);
    }];
//    [_collectionView reloadData];
    // _collectionView.contentSize = CGSizeMake(0, ((_selectedPhotos.count + 2) / 3 ) * (_margin + _itemWH));
}

// If user picking a gif image, this callback will be called.
// 如果用户选择了一个gif图片，下面的handle会被执行
- (void)imagePickerController:(TZImagePickerController *)picker didFinishPickingGifImage:(UIImage *)animatedImage sourceAssets:(id)asset {
    _selectedPhotos = [NSMutableArray arrayWithArray:@[animatedImage]];
    _selectedAssets = [NSMutableArray arrayWithArray:@[asset]];
//    [_collectionView reloadData];
}

// Decide album show or not't
// 决定相册显示与否
- (BOOL)isAlbumCanSelect:(NSString *)albumName result:(id)result {
    /*
     if ([albumName isEqualToString:@"个人收藏"]) {
     return NO;
     }
     if ([albumName isEqualToString:@"视频"]) {
     return NO;
     }*/
    return YES;
}

// Decide asset show or not't
// 决定asset显示与否
- (BOOL)isAssetCanSelect:(id)asset {
    /*
     if (iOS8Later) {
     PHAsset *phAsset = asset;
     switch (phAsset.mediaType) {
     case PHAssetMediaTypeVideo: {
     // 视频时长
     // NSTimeInterval duration = phAsset.duration;
     return NO;
     } break;
     case PHAssetMediaTypeImage: {
     // 图片尺寸
     if (phAsset.pixelWidth > 3000 || phAsset.pixelHeight > 3000) {
     // return NO;
     }
     return YES;
     } break;
     case PHAssetMediaTypeAudio:
     return NO;
     break;
     case PHAssetMediaTypeUnknown:
     return NO;
     break;
     default: break;
     }
     } else {
     ALAsset *alAsset = asset;
     NSString *alAssetType = [[alAsset valueForProperty:ALAssetPropertyType] stringValue];
     if ([alAssetType isEqualToString:ALAssetTypeVideo]) {
     // 视频时长
     // NSTimeInterval duration = [[alAsset valueForProperty:ALAssetPropertyDuration] doubleValue];
     return NO;
     } else if ([alAssetType isEqualToString:ALAssetTypePhoto]) {
     // 图片尺寸
     CGSize imageSize = alAsset.defaultRepresentation.dimensions;
     if (imageSize.width > 3000) {
     // return NO;
     }
     return YES;
     } else if ([alAssetType isEqualToString:ALAssetTypeUnknown]) {
     return NO;
     }
     }*/
    return YES;
}

#pragma mark
- (void)compressImage:(id)idParam callback:(WXModuleKeepAliveCallback)callback
{
    BOOL isSave = NO;
    NSMutableDictionary *params = @{}.mutableCopy;
    if ([idParam isKindOfClass:[NSDictionary class]]) {
        params = [(NSDictionary *) idParam mutableCopy];
    }else if ([idParam isKindOfClass:[NSArray class]]) {
        params = @{@"lists": (NSArray *)idParam, @"compressSize": @(90)}.mutableCopy;
    }
    
    NSInteger compressSize = params[@"compressSize"] ? [WXConvert NSInteger:params[@"compressSize"]] : 90;
    NSMutableArray *list = [NSMutableArray arrayWithArray: params[@"lists"]];
    for (NSInteger i = 0; i < list.count; i++) {
        
        NSMutableDictionary *mDic = @{}.mutableCopy;
        id item = [NSMutableDictionary dictionaryWithDictionary:list[i]];
        
        if ([item isKindOfClass:[NSDictionary class]]) {
            mDic = [(NSDictionary *) item mutableCopy];
        } else if ([item isKindOfClass:[NSString class]]) {
            mDic = @{ @"path": item }.mutableCopy;
        }
        
        [mDic setObject:@(1) forKey:@"isCompressed"];
        [mDic setObject:@(1) forKey:@"compressed"];

        NSString *path = [mDic objectForKey:@"path"];
        UIImage *img = [UIImage imageWithContentsOfFile:path];

        NSData *data = UIImageJPEGRepresentation(img, 1);
        NSInteger imgSize = data.length/1024;
        if (imgSize > compressSize) {
            isSave = [UIImageJPEGRepresentation(img, 0.5) writeToFile:path atomically:YES];
        }

        [list replaceObjectAtIndex:i withObject:mDic];
    }

    if (callback && list) {
        NSDictionary *res = @{@"status":isSave?@"success":@"error", @"lists":list};
        callback(res, YES);
    }
}

- (void)picturePreview:(NSInteger)index paths:(NSArray*)paths callback:(WXModuleKeepAliveCallback)callback
{
    NSMutableArray *items = @[].mutableCopy;
    for (id dic in paths) {
        NSString * path = nil;
        if ([dic isKindOfClass:[NSDictionary class]]) {
            if (dic[@"path"]) {
                path = dic[@"path"];
            }
        } else if ([dic isKindOfClass:[NSString class]]) {
            path = dic;
        }
        if (path != nil) {
            NSString *url = [path stringByReplacingOccurrencesOfString:@"bmiddle" withString:@"large"];
            KSPhotoItem *item = nil;
            if ([url hasPrefix:@"http://"] || [url hasPrefix:@"https://"] || [url hasPrefix:@"ftp://"]) {
                item = [KSPhotoItem itemWithSourceView:nil imageUrl:[NSURL URLWithString:url]];
            }else{
                item = [KSPhotoItem itemWithSourceView:nil image:[UIImage imageNamed:url]];
            }
            [items addObject:item];
        }
    }
    KSPhotoBrowser *browser = [KSPhotoBrowser browserWithPhotoItems:items selectedIndex:index];
    browser.dismissalStyle = KSPhotoBrowserInteractiveDismissalStyleScale;
    browser.backgroundStyle = KSPhotoBrowserBackgroundStyleBlack;
    browser.pageindicatorStyle = KSPhotoBrowserPageIndicatorStyleText;
    browser.removeCallback = callback ? ^(NSInteger currentPage) {
        callback(@{@"position":@(currentPage)}, YES);
    } : 0;
    [browser showFromViewController:[[DeviceUtil getTopviewControler] navigationController]];
}

- (void)videoPreview:(NSString*)path
{
    if (path.length > 0) {
        ZLMediaInfo *info=[[ZLMediaInfo alloc]init];
        info.isLocal = YES;
        info.type = ZLMediaInfoTypeVideo;
        info.url = path;

        ZLShowMultimedia *zlShow = [[ZLShowMultimedia alloc]init];
        zlShow.infos = @[info];
        zlShow.currentIndex = 0;
        [zlShow show];
    }
}

- (void)deleteCache
{
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject];
    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];

}

- (void)openViewController:(UIViewController *) vc
{
    if ([[DeviceUtil getTopviewControler] isKindOfClass:[eeuiViewController class]]) {
        eeuiViewController *top_vc = (eeuiViewController*)[DeviceUtil getTopviewControler];
        [[eeuiNewPageManager sharedIntstance] onPageStatusListener:@{@"listenerName": @"otherPlugin", @"pageName": top_vc.pageName} status:@"pauseBefore" weexInstance:nil];
        if ([top_vc.animatedType isEqualToString:@"present"]) {
            vc.modalPresentationStyle = UIModalPresentationPageSheet;
        } else {
            vc.modalPresentationStyle = UIModalPresentationFullScreen;
        }
    }
    [[DeviceUtil getTopviewControler] presentViewController:vc animated:YES completion:nil];
}

@end
