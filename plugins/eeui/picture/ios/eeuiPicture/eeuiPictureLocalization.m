//
//  eeuiPictureLocalization.m
//  eeuiPicture
//
//  Created on 2025-04-20.
//  Copyright 2025 WeexEEUI. All rights reserved.
//

#import "eeuiPictureLocalization.h"

// 用于存储用户设置的自定义语言
static NSString *_customLanguage = nil;

@implementation eeuiPictureLocalization

// 获取支持的语言列表
+ (NSArray<NSString *> *)supportedLanguages {
    return @[@"de", @"en-GB", @"en", @"fr", @"id", @"ja", @"ko", @"ru", @"zh-Hans", @"zh-Hant", @"zh-HK"];
}

// 设置当前使用的语言
+ (void)setCurrentLanguage:(NSString *)language {
    if (language && ![self.supportedLanguages containsObject:language]) {
        NSLog(@"警告：不支持的语言 '%@'，将使用默认语言", language);
        language = nil;
    }
    _customLanguage = language;
}

// 获取当前使用的语言
+ (NSString *)currentLanguage {
    if (_customLanguage) {
        return _customLanguage;
    }
    
    // 获取系统语言
    NSString *language = [NSLocale preferredLanguages].firstObject;
    // 简化语言代码，例如zh-Hans-CN变为zh-Hans
    if ([language containsString:@"-"]) {
        NSArray *components = [language componentsSeparatedByString:@"-"];
        if (components.count >= 2) {
            if ([components[0] isEqualToString:@"zh"]) {
                // 中文特殊处理
                if ([components[1] isEqualToString:@"Hans"] || [components[1] isEqualToString:@"CN"]) {
                    language = @"zh-Hans"; // 简体中文
                } else if ([components[1] isEqualToString:@"Hant"] || [components[1] isEqualToString:@"TW"]) {
                    language = @"zh-Hant"; // 繁体中文
                } else if ([components[1] isEqualToString:@"HK"]) {
                    language = @"zh-HK";   // 香港繁体
                }
            } else {
                // 其他语言只取第一部分
                language = components[0];
            }
        }
    }
    
    // 如果当前语言不在支持列表中，默认使用英语
    if (![self.supportedLanguages containsObject:language]) {
        language = @"en";
    }
    
    return language;
}

+ (NSString *)localizedStringForKey:(NSString *)key {
    // 尝试从eeuiPictureSelector.bundle获取本地化字符串
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSString *bundlePath = [mainBundle pathForResource:@"eeuiPictureSelector" ofType:@"bundle"];
    NSBundle *resourceBundle = bundlePath ? [NSBundle bundleWithPath:bundlePath] : mainBundle;
    
    // 获取当前语言
    NSString *language = [self currentLanguage];
    
    // 尝试获取对应语言的本地化字符串
    NSString *localizedString = [resourceBundle localizedStringForKey:key value:nil table:nil];
    
    // 如果没有找到本地化字符串，使用默认值
    if ([localizedString isEqualToString:key]) {
        // 默认英文映射表
        NSDictionary *defaultStrings = @{
            @"SaveVideoToAlbum": @"Save Video",
            @"Share": @"Share",
            @"SaveImageToAlbum": @"Save Image",
            @"ImageSaved": @"Image saved to album",
            @"SaveImageFailed": @"Failed to save image",
            @"Cancel": @"Cancel",
            @"VideoSaved": @"Video saved to album",
            @"SaveVideoFailed": @"Failed to save video",
            @"VideoDownloadFailed": @"Failed to download video",
            @"CannotGetVideo": @"Cannot get video file",
            @"CannotGetVideoFromAlbum": @"Cannot get video from album",
            @"EmptyDownloadData": @"Downloaded data is empty",
            
            // 相机权限相关
            @"NoCameraAccess": @"Cannot use camera",
            @"CameraAccessMessage": @"Please allow camera access in \"Settings - Privacy - Camera\"",
            @"NoPhotoLibraryAccess": @"Cannot access photo library",
            @"PhotoLibraryAccessMessage": @"Please allow photo library access in \"Settings - Privacy - Photos\"",
            @"Settings": @"Settings"
        };
        
        // 中文映射表
        NSDictionary *zhHansStrings = @{
            @"SaveVideoToAlbum": @"保存视频到相册",
            @"Share": @"分享",
            @"SaveImageToAlbum": @"保存图片到相册",
            @"ImageSaved": @"图片已保存到相册",
            @"SaveImageFailed": @"保存图片失败",
            @"Cancel": @"取消",
            @"VideoSaved": @"视频已保存到相册",
            @"SaveVideoFailed": @"保存视频失败",
            @"VideoDownloadFailed": @"视频下载失败",
            @"CannotGetVideo": @"无法获取视频文件",
            @"CannotGetVideoFromAlbum": @"无法从相册获取视频",
            @"EmptyDownloadData": @"下载的数据为空",
            
            // 相机权限相关
            @"NoCameraAccess": @"无法使用相机",
            @"CameraAccessMessage": @"请在iPhone的\"设置-隐私-相机\"中允许访问相机",
            @"NoPhotoLibraryAccess": @"无法访问相册",
            @"PhotoLibraryAccessMessage": @"请在iPhone的\"设置-隐私-相册\"中允许访问相册",
            @"Settings": @"设置"
        };
        
        // 繁体中文映射表
        NSDictionary *zhHantStrings = @{
            @"SaveVideoToAlbum": @"保存視頻到相冊",
            @"Share": @"分享",
            @"SaveImageToAlbum": @"保存圖片到相冊",
            @"ImageSaved": @"圖片已保存到相冊",
            @"SaveImageFailed": @"保存圖片失敗",
            @"Cancel": @"取消",
            @"VideoSaved": @"視頻已保存到相冊",
            @"SaveVideoFailed": @"保存視頻失敗",
            @"VideoDownloadFailed": @"視頻下載失敗",
            @"CannotGetVideo": @"無法獲取視頻文件",
            @"CannotGetVideoFromAlbum": @"無法從相冊獲取視頻",
            @"EmptyDownloadData": @"下載的數據為空",
            
            // 相机权限相关
            @"NoCameraAccess": @"無法使用相機",
            @"CameraAccessMessage": @"請在iPhone的\"設置-隱私-相機\"中允許訪問相機",
            @"NoPhotoLibraryAccess": @"無法訪問相冊",
            @"PhotoLibraryAccessMessage": @"請在iPhone的\"設置-隱私-相冊\"中允許訪問相冊",
            @"Settings": @"設置"
        };
        
        // 香港繁体映射表
        NSDictionary *zhHKStrings = @{
            @"SaveVideoToAlbum": @"儲存影片至相簿",
            @"Share": @"分享",
            @"SaveImageToAlbum": @"儲存圖片至相簿",
            @"ImageSaved": @"圖片已儲存至相簿",
            @"SaveImageFailed": @"儲存圖片失敗",
            @"Cancel": @"取消",
            @"VideoSaved": @"影片已儲存至相簿",
            @"SaveVideoFailed": @"儲存影片失敗",
            @"VideoDownloadFailed": @"影片下載失敗",
            @"CannotGetVideo": @"無法取得影片檔案",
            @"CannotGetVideoFromAlbum": @"無法從相簿取得影片",
            @"EmptyDownloadData": @"下載的數據為空",
            
            // 相机权限相关
            @"NoCameraAccess": @"無法使用相機",
            @"CameraAccessMessage": @"請在iPhone的\"設定-私隱-相機\"中允許存取相機",
            @"NoPhotoLibraryAccess": @"無法存取相簿",
            @"PhotoLibraryAccessMessage": @"請在iPhone的\"設定-私隱-相簿\"中允許存取相簿",
            @"Settings": @"設定"
        };
        
        // 日语映射表
        NSDictionary *jaStrings = @{
            @"SaveVideoToAlbum": @"ビデオをアルバムに保存",
            @"Share": @"シェア",
            @"SaveImageToAlbum": @"画像をアルバムに保存",
            @"ImageSaved": @"画像がアルバムに保存されました",
            @"SaveImageFailed": @"画像の保存に失敗しました",
            @"Cancel": @"キャンセル",
            @"VideoSaved": @"ビデオがアルバムに保存されました",
            @"SaveVideoFailed": @"ビデオの保存に失敗しました",
            @"VideoDownloadFailed": @"ビデオのダウンロードに失敗しました",
            @"CannotGetVideo": @"ビデオファイルを取得できません",
            @"CannotGetVideoFromAlbum": @"アルバムからビデオを取得できません",
            @"EmptyDownloadData": @"ダウンロードしたデータが空です",
            
            // 相机权限相关
            @"NoCameraAccess": @"カメラを使用できません",
            @"CameraAccessMessage": @"iPhoneの「設定-プライバシー-カメラ」でカメラへのアクセスを許可してください",
            @"NoPhotoLibraryAccess": @"写真ライブラリにアクセスできません",
            @"PhotoLibraryAccessMessage": @"iPhoneの「設定-プライバシー-写真」で写真へのアクセスを許可してください",
            @"Settings": @"設定"
        };
        
        // 韩语映射表
        NSDictionary *koStrings = @{
            @"SaveVideoToAlbum": @"앨범에 비디오 저장",
            @"Share": @"공유",
            @"SaveImageToAlbum": @"앨범에 이미지 저장",
            @"ImageSaved": @"이미지가 앨범에 저장되었습니다",
            @"SaveImageFailed": @"이미지 저장에 실패했습니다",
            @"Cancel": @"취소",
            @"VideoSaved": @"비디오가 앨범에 저장되었습니다",
            @"SaveVideoFailed": @"비디오 저장 실패",
            @"VideoDownloadFailed": @"비디오 다운로드 실패",
            @"CannotGetVideo": @"비디오 파일을 가져올 수 없습니다",
            @"CannotGetVideoFromAlbum": @"앨범에서 비디오를 가져올 수 없습니다",
            @"EmptyDownloadData": @"다운로드된 데이터가 비어 있습니다",
            
            // 相机权限相关
            @"NoCameraAccess": @"카메라를 사용할 수 없습니다",
            @"CameraAccessMessage": @"iPhone의 \"설정-개인 정보 보호-카메라\"에서 카메라 접근을 허용해 주세요",
            @"NoPhotoLibraryAccess": @"사진 앨범에 접근할 수 없습니다",
            @"PhotoLibraryAccessMessage": @"iPhone의 \"설정-개인 정보 보호-사진\"에서 사진 앨범 접근을 허용해 주세요",
            @"Settings": @"설정"
        };
        
        // 德语映射表
        NSDictionary *deStrings = @{
            @"SaveVideoToAlbum": @"Video im Album speichern",
            @"Share": @"Teilen",
            @"SaveImageToAlbum": @"Bild im Album speichern",
            @"ImageSaved": @"Bild wurde im Album gespeichert",
            @"SaveImageFailed": @"Fehler beim Speichern des Bildes",
            @"Cancel": @"Abbrechen",
            @"VideoSaved": @"Video wurde im Album gespeichert",
            @"SaveVideoFailed": @"Video konnte nicht gespeichert werden",
            @"VideoDownloadFailed": @"Video konnte nicht heruntergeladen werden",
            @"CannotGetVideo": @"Videodatei kann nicht abgerufen werden",
            @"CannotGetVideoFromAlbum": @"Video kann nicht aus dem Album abgerufen werden",
            @"EmptyDownloadData": @"Heruntergeladene Daten sind leer",
            
            // 相机权限相关
            @"NoCameraAccess": @"Kamera kann nicht verwendet werden",
            @"CameraAccessMessage": @"Bitte erlauben Sie den Kamerazugriff unter \"Einstellungen - Datenschutz - Kamera\"",
            @"NoPhotoLibraryAccess": @"Kein Zugriff auf die Fotobibliothek",
            @"PhotoLibraryAccessMessage": @"Bitte erlauben Sie den Zugriff auf die Fotobibliothek unter \"Einstellungen - Datenschutz - Fotos\"",
            @"Settings": @"Einstellungen"
        };
        
        // 印尼语映射表
        NSDictionary *idStrings = @{
            @"SaveVideoToAlbum": @"Simpan Video ke Album",
            @"Share": @"Bagikan",
            @"SaveImageToAlbum": @"Simpan Gambar ke Album",
            @"ImageSaved": @"Gambar telah disimpan ke album",
            @"SaveImageFailed": @"Gagal menyimpan gambar",
            @"Cancel": @"Batal",
            @"VideoSaved": @"Video telah disimpan ke album",
            @"SaveVideoFailed": @"Gagal menyimpan video",
            @"VideoDownloadFailed": @"Gagal mengunduh video",
            @"CannotGetVideo": @"Tidak dapat mengambil file video",
            @"CannotGetVideoFromAlbum": @"Tidak dapat mengambil video dari album",
            @"EmptyDownloadData": @"Data yang diunduh kosong",
            
            // 相机权限相关
            @"NoCameraAccess": @"Tidak dapat menggunakan kamera",
            @"CameraAccessMessage": @"Harap izinkan akses kamera di \"Pengaturan - Privasi - Kamera\"",
            @"NoPhotoLibraryAccess": @"Tidak dapat mengakses perpustakaan foto",
            @"PhotoLibraryAccessMessage": @"Harap izinkan akses perpustakaan foto di \"Pengaturan - Privasi - Foto\"",
            @"Settings": @"Pengaturan"
        };
        
        // 英国英语映射表
        NSDictionary *enGBStrings = @{
            @"SaveVideoToAlbum": @"Save Video to Album",
            @"Share": @"Share",
            @"SaveImageToAlbum": @"Save Image to Album",
            @"ImageSaved": @"Image saved to album",
            @"SaveImageFailed": @"Failed to save image",
            @"Cancel": @"Cancel",
            @"VideoSaved": @"Video saved to album",
            @"SaveVideoFailed": @"Failed to save video",
            @"VideoDownloadFailed": @"Failed to download video",
            @"CannotGetVideo": @"Cannot get video file",
            @"CannotGetVideoFromAlbum": @"Cannot get video from album",
            @"EmptyDownloadData": @"Downloaded data is empty",
            
            // 相机权限相关
            @"NoCameraAccess": @"Cannot use camera",
            @"CameraAccessMessage": @"Please allow camera access in \"Settings - Privacy - Camera\"",
            @"NoPhotoLibraryAccess": @"Cannot access photo library",
            @"PhotoLibraryAccessMessage": @"Please allow photo library access in \"Settings - Privacy - Photos\"",
            @"Settings": @"Settings"
        };
        
        // 法语映射表
        NSDictionary *frStrings = @{
            @"SaveVideoToAlbum": @"Enregistrer la vidéo dans l'album",
            @"Share": @"Partager",
            @"SaveImageToAlbum": @"Enregistrer l'image dans l'album",
            @"ImageSaved": @"L'image a été enregistrée dans l'album",
            @"SaveImageFailed": @"Échec de l'enregistrement de l'image",
            @"Cancel": @"Annuler",
            @"VideoSaved": @"La vidéo a été enregistrée dans l'album",
            @"SaveVideoFailed": @"Échec de l'enregistrement de la vidéo",
            @"VideoDownloadFailed": @"Échec du téléchargement de la vidéo",
            @"CannotGetVideo": @"Impossible d'obtenir le fichier vidéo",
            @"CannotGetVideoFromAlbum": @"Impossible d'obtenir la vidéo de l'album",
            @"EmptyDownloadData": @"Les données téléchargées sont vides",
            
            // 相机权限相关
            @"NoCameraAccess": @"Impossible d'utiliser l'appareil photo",
            @"CameraAccessMessage": @"Veuillez autoriser l'accès à l'appareil photo dans \"Réglages - Confidentialité - Appareil photo\"",
            @"NoPhotoLibraryAccess": @"Impossible d'accéder à la bibliothèque de photos",
            @"PhotoLibraryAccessMessage": @"Veuillez autoriser l'accès à la bibliothèque de photos dans \"Réglages - Confidentialité - Photos\"",
            @"Settings": @"Réglages"
        };
        
        // 俄语映射表
        NSDictionary *ruStrings = @{
            @"SaveVideoToAlbum": @"Сохранить видео в альбоме",
            @"Share": @"Поделиться",
            @"SaveImageToAlbum": @"Сохранить изображение в альбоме",
            @"ImageSaved": @"Изображение сохранено в альбоме",
            @"SaveImageFailed": @"Не удалось сохранить изображение",
            @"Cancel": @"Отмена",
            @"VideoSaved": @"Видео сохранено в альбоме",
            @"SaveVideoFailed": @"Не удалось сохранить видео",
            @"VideoDownloadFailed": @"Не удалось скачать видео",
            @"CannotGetVideo": @"Не удалось получить видеофайл",
            @"CannotGetVideoFromAlbum": @"Не удалось получить видео из альбома",
            @"EmptyDownloadData": @"Скачанные данные пусты",
            
            // 相机权限相关
            @"NoCameraAccess": @"Не удалось использовать камеру",
            @"CameraAccessMessage": @"Пожалуйста, разрешите доступ к камере в \"Настройки - Конфиденциальность - Камера\"",
            @"NoPhotoLibraryAccess": @"Не удалось получить доступ к библиотеке фотографий",
            @"PhotoLibraryAccessMessage": @"Пожалуйста, разрешите доступ к библиотеке фотографий в \"Настройки - Конфиденциальность - Фотографии\"",
            @"Settings": @"Настройки"
        };
        
        // 根据当前语言选择映射表
        NSDictionary *strings = defaultStrings;
        if ([language isEqualToString:@"zh-Hans"]) {
            strings = zhHansStrings;
        } else if ([language isEqualToString:@"zh-Hant"]) {
            strings = zhHantStrings;
        } else if ([language isEqualToString:@"zh-HK"]) {
            strings = zhHKStrings;
        } else if ([language isEqualToString:@"ja"]) {
            strings = jaStrings;
        } else if ([language isEqualToString:@"ko"]) {
            strings = koStrings;
        } else if ([language isEqualToString:@"de"]) {
            strings = deStrings;
        } else if ([language isEqualToString:@"id"]) {
            strings = idStrings;
        } else if ([language isEqualToString:@"en-GB"]) {
            strings = enGBStrings;
        } else if ([language isEqualToString:@"fr"]) {
            strings = frStrings;
        } else if ([language isEqualToString:@"ru"]) {
            strings = ruStrings;
        }
        
        // 获取映射字符串
        NSString *mappedString = strings[key];
        if (mappedString) {
            return mappedString;
        }
    }
    
    return localizedString ?: key;
}

@end
