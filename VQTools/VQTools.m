//
//  VQTools.m
//
//  Created by 周彬 on 2016/12/9.
//  Copyright © 2016年 VQBoy. All rights reserved.
//

#import "VQTools.h"

//监听电话
#import <CoreTelephony/CTCallCenter.h>
#import <CoreTelephony/CTCall.h>
//判断网络
#import "AFNetworking.h"
#import <CoreTelephony/CTCellularData.h>
//声音和震动
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>//录音及播放音频
//相册
#import <AssetsLibrary/AssetsLibrary.h>//ios 4.0-9.0
#import <Photos/Photos.h>//ios8.0 later
//定位
#import <CoreLocation/CoreLocation.h>
//录音
#import "lame.h"
//播放视频
#import <MediaPlayer/MediaPlayer.h>

#define RecordAudioFile [[[NSBundle mainBundle]bundleIdentifier] stringByAppendingString:@".pcm"]  //录制的音频临时存放的位置名字
#define RecordAudioMP3fILE [[[NSBundle mainBundle]bundleIdentifier] stringByAppendingString:@".mp3"] //mp3格式的音频临时存放的位置名字
#define  audioDBUG 1  //1 输出日志 0 不输出日志
#define  videoDBUG 1  //1 输出日志 0 不输出日志

//用于区分是打开相册 相机 录像机的标记
typedef NS_ENUM(NSInteger,KVQImagePickerUseType) {
    KVQImagePickerUseType_OpenPhotoLibrary_GetImage = 1,
    KVQImagePickerUseType_OpenPhotoLibrary_GetVideo,
    KVQImagePickerUseType_TakePhotos,
    KVQImagePickerUseType_RecordVideo
};

@interface VQTools ()<AVAudioRecorderDelegate,AVAudioPlayerDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate>
//监听电话
@property (nonatomic,strong) CTCallCenter *callCenter;
//播放音效
@property (nonatomic,assign) SystemSoundID sound;
//用于录音
@property (nonatomic,strong) NSOperationQueue *queue;//用于子线程开计时器
@property (nonatomic,strong) NSTimer *timer;//计时器
@property (nonatomic,strong) AVAudioRecorder *audioRecorder; //音频录音机
@property (nonatomic,strong) AVAudioPlayer *audioPlayer;   //音频播放器
@property (nonatomic,assign) NSInteger maxSeconds;  // 最大音频录制时间
@property (nonatomic,assign) BOOL isEncoder;    //是否转码 默认转码 YES 如果不转码 置为NO
@property (nonatomic,assign) double time;//用于记录当前时间
@property (nonatomic,copy) RecordNormalFinishBlock normalFinishBlock;//正常结束回调
@property (nonatomic,copy) RecordTimeOutBlock timeOutBlock;//超时回调
@property (nonatomic,assign) BOOL isAuto;//是否自动执行超时回调
//用于播放声音
@property (nonatomic,copy) AudioPlayFinishBlock audioPlayFinishBlock;//语音播放完成回调
//用于录制视频
@property (nonatomic,strong) UIImagePickerController *imagePicker;
@property (nonatomic,copy) NSString *saveFilePath;
@property (nonatomic,copy) NSString *saveFileName;
//用于从相册获取图片视频 或者 用摄像头拍摄图片录制视频
@property (nonatomic,copy) VideoSelectionFinishBlock videoSelectionFinishBlock;//视频选择结束回调
@property (nonatomic,copy) VideoRecordFinishBlock videoRecordFinishBlock;//视频录制结束回调
@property (nonatomic,copy) PictureSelectionFinishBlock pictureSelectionFinishBlock;//图片选取结束回调
@property (nonatomic,copy) PictureTakingFinishBlock pictureTakingFinishBlock;//相片拍摄结束回调
//用于播放视频
@property (nonatomic,copy) NSString *filePath;//本地视频路径
@property (nonatomic,strong) MPMoviePlayerViewController *moviePlayerViewController;
//imagePicker使用类型标记
@property (nonatomic,assign) KVQImagePickerUseType imagePickerUseType;
@end
@implementation VQTools

//MARK:  - 获取当前控制器
+(UIViewController *)getCurrentViewControllerFromWindow:(UIWindow *)window
{
    UIViewController *targetVC = nil;
    if (window) {
        id obj = window.rootViewController;//系统创建的window的根控制器可能为私有api控制器UIInputWindowController
        if ([obj isKindOfClass:[UIViewController class]]) {
            UIViewController *rootVC = obj;
            targetVC = [VQTools checkViewController:rootVC];
        }else{
            targetVC = nil;
        }
    }else{
        for (UIWindow *window in [UIApplication sharedApplication].windows) {
            //1.获取window
            id obj = window.rootViewController;//系统创建的window的根控制器可能为私有api控制器UIInputWindowController
            if ([obj isKindOfClass:[UIViewController class]]) {
                UIViewController *rootVC = obj;
                targetVC = [VQTools checkViewController:rootVC];
                //当找到第一个符合要求rootVC的window的时候 停止遍历
                break;
            }else{
                targetVC = nil;
            }
        }
        
    }
    return targetVC;
}
+(UIViewController *)checkViewController:(UIViewController *)currentVC
{
    UIViewController *tempVC = currentVC;
    if ([currentVC isKindOfClass:[UINavigationController class]]) {
        UINavigationController *currentNav = (UINavigationController *)currentVC;
        tempVC = [VQTools checkViewController:currentNav.visibleViewController];
    }else if ([currentVC isKindOfClass:[UITabBarController class]]){
        UITabBarController *currentTab = (UITabBarController *)currentVC;
        tempVC = [VQTools checkViewController:currentTab.selectedViewController];
    }else{
        //当为UIViewController 的时候 判断是否为 容器控制器，当为容器控制器判断是否有自控制器
        if (currentVC.childViewControllers.count > 0) {
            NSInteger maxIndex = 0;//存储屏幕最顶层控制器的view的index
            UIViewController *topViewVC = nil;//顶层视图控制器
            for (UIViewController *vc in currentVC.childViewControllers) {
                if ([currentVC.view.subviews containsObject:vc.view]) {//如果容器控制器包含这个控制器视图
                    NSInteger currentIndex = [currentVC.view.subviews indexOfObject:vc.view];
                    if (currentIndex >= maxIndex) {
                        maxIndex = currentIndex;
                        topViewVC = vc;
                    }
                }
            }
            if (topViewVC) {
                tempVC = [VQTools checkViewController:topViewVC];
            }else{
                //不做操作
            }
        }else{
            if (currentVC.presentedViewController) {//分析有没有modal的情况
                tempVC = [VQTools checkViewController:currentVC.presentedViewController];
            }else{
                //不做操作
            }
        }
    }
    return tempVC;
}
//MARK: - 将deviceToken 转换为 字符串
+(NSString *)getDeviceTokenDataToString:(NSData *)deviceToken
{
    NSString *token = [deviceToken description];
//    [deviceToken description] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]
    token = [token stringByReplacingOccurrencesOfString:@"<" withString:@""];
    token = [token stringByReplacingOccurrencesOfString:@">" withString:@""];
    token = [token stringByReplacingOccurrencesOfString:@" " withString:@""];
    return token;
}
//MARK:  - 获取系统版本号
+(float)getSystemVersion
{
    return [[[UIDevice currentDevice] systemVersion] floatValue];
}
//MARK:  - 跳转到app设置页
+(void)openAppSettings
{
    NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        [[UIApplication sharedApplication] openURL:url];
    }
}

//MARK:  - 监听电话并执行对应回调
-(void)callPhoneCenterWithDialingBlock:(CallStateDialingBlock)dialingBlock
                         IncomingBlock:(CallStateIncomingBlock)incomingBlock
                        ConnectedBlock:(CallStateConnectedBlock)connectedBlock
                     DisconnectedBlock:(CallStateDisconnectedBlock)disconnectedBlock{
    if (!self.callCenter) {
        CTCallCenter *callCenter = [[CTCallCenter alloc] init];
        self.callCenter = callCenter;
    }
    
    self.callCenter.callEventHandler = ^(CTCall* call) {
            if ([call.callState isEqualToString:CTCallStateDisconnected])//挂断电话
            {
                disconnectedBlock();
            }
            else if ([call.callState isEqualToString:CTCallStateConnected])//接通电话
            {
                connectedBlock();
            }
            else if([call.callState isEqualToString:CTCallStateIncoming])//来电话
            {
                incomingBlock();
            }
            else if ([call.callState isEqualToString:CTCallStateDialing])//开始拨打电话
            {
                dialingBlock();
            }
            else//嘛都没做Nothing is done
            {
            }
        };
}

//MARK:  - 开始震动
int shakePlayNum;//震动次数
-(void)startShakeWithRunLoopNum:(int)num
{
    shakePlayNum = num;
    if (num != 0) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            AudioServicesAddSystemSoundCompletion(kSystemSoundID_Vibrate, NULL, NULL, shakeCompleteCallback, NULL);
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);//震动
        });
    }
}
- (void)shakeRunLoop {
    NSLog(@"haha");
}

//MARK:  - 终止震动
- (void)stopShake
{
    shakePlayNum = 0;
    AudioServicesDisposeSystemSoundID(kSystemSoundID_Vibrate);//停止震动
    AudioServicesRemoveSystemSoundCompletion(kSystemSoundID_Vibrate);//移除回调
}

//震动完成之后的回调
void shakeCompleteCallback(SystemSoundID sound,void * clientData)
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (shakePlayNum > 0) {
            shakePlayNum--;
        }
        if (shakePlayNum > 0) {
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);  //震动
        }else if (shakePlayNum == 0){
            AudioServicesDisposeSystemSoundID(kSystemSoundID_Vibrate);//停止震动
            AudioServicesRemoveSystemSoundCompletion(kSystemSoundID_Vibrate);//移除回调
        }else{
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);  //震动
        }
    });
}

//MARK:  - 播放系统音效
int soundPlayNum;//音效播放次数
-(void)startSystemSound:(UInt32)systemSoundID RunLoopNum:(int)num
{
    soundPlayNum = num;
    if (systemSoundID != 0 && num != 0) {
        SystemSoundID sound = systemSoundID;
        AudioServicesAddSystemSoundCompletion(sound, NULL, NULL, soundCompleteCallback, NULL);
        AudioServicesPlaySystemSound(sound);
        self.sound = sound;
    }
}
//MARK:  - 播放自定义音效
-(void)startCustomSound:(NSString *)soundPath RunLoopNum:(int)num
{
    soundPlayNum = num;
    if (soundPath.length > 0  && num != 0) {
        SystemSoundID sound;
        NSURL *url = [NSURL URLWithString:soundPath];
        AudioServicesCreateSystemSoundID((__bridge CFURLRef)url, &sound);
        AudioServicesAddSystemSoundCompletion(sound, NULL, NULL, soundCompleteCallback, NULL);
        AudioServicesPlaySystemSound(sound);
        self.sound = sound;
    }
}
//MARK:  - 终止音效
-(void)stopSound
{
    soundPlayNum = 0;
    SystemSoundID sound;
    sound = self.sound;
    AudioServicesDisposeSystemSoundID(sound);//停止声音
    AudioServicesRemoveSystemSoundCompletion(sound);//移除回调
    self.sound = 0;
    
}
//音效播放完毕之后的回调
void soundCompleteCallback(SystemSoundID sound,void * clientData)
{
    if (soundPlayNum > 0) {
        soundPlayNum--;
    }
    if (soundPlayNum > 0) {
        AudioServicesPlaySystemSound(sound);
    }else if (soundPlayNum == 0){
        AudioServicesDisposeSystemSoundID(sound);//停止声音
        AudioServicesRemoveSystemSoundCompletion(sound);//移除回调
    }else{
        AudioServicesPlaySystemSound(sound);
    }
}
//MARK:  - 保持屏幕常亮开关
+(void)keepBacklightOfScreen:(BOOL)isOn
{
    [[UIApplication sharedApplication] setIdleTimerDisabled: isOn];
}

//MARK:  - 拨打电话
-(void)callPhoneNum:(NSString *)numStr
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"tel:%@",numStr]];
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        [[UIApplication sharedApplication] openURL:url];
    }
}
//MARK:  - 压缩图片 DataToImage
+(UIImage *)compressDataToImage:(NSData *)data scale:(CGFloat)scale
{
    if (data) {
        if (scale < 0) scale = 0;
        if (scale > 1) scale = 1;
        UIImage *dataImage = [UIImage imageWithData:data scale:scale];
        return dataImage;
    }else{
        return nil;
    }
}
//MARK:  - 压缩图片 ImageToData
+(NSData *)compressImageToData:(UIImage *)image scale:(CGFloat)scale
{
    if (image) {
        if (scale < 0) scale = 0;
        if (scale > 1) scale = 1;
        NSData *imageData = UIImageJPEGRepresentation(image, scale);
        return imageData;
    }else{
        return nil;
    }
}
//MARK:  - 检测网络是否连通
-(void)checkNetworkConnectedState:(void (^)(BOOL,kVQNetworkState))block
{
    AFNetworkReachabilityManager *mgr = [AFNetworkReachabilityManager sharedManager];
    [mgr startMonitoring];
    __weak typeof (AFNetworkReachabilityManager)*weakMgr = mgr;
    [mgr setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        [weakMgr stopMonitoring];
        // 当网络状态改变了, 就会调用这个block
        switch (status) {
            case AFNetworkReachabilityStatusUnknown: // 未知网络
                block(false,kVQNetworkState_UnKnown);
                break;
            case AFNetworkReachabilityStatusNotReachable: // 没有网络(断网)
                block(false,kVQNetworkState_NotReachable);
                break;
            case AFNetworkReachabilityStatusReachableViaWWAN: // 手机自带网络
                block(true,kVQNetworkState_WWAN);
                break;
            case AFNetworkReachabilityStatusReachableViaWiFi: // WIFI
                block(true,kVQNetworkState_WiFi);
                break;
        }
    }];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
//MARK:  - 相册权限判断
+ (BOOL)isPhotoLibraryAvailable
{
    BOOL available = [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary];//设备是否支持该操作
    if (available && [VQTools getSystemVersion] >= 8.0) {
        PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
        if (status == PHAuthorizationStatusRestricted || status == PHAuthorizationStatusDenied)
        {
            available = NO;
        }
    }else{
        if(available && [VQTools getSystemVersion]  >= 6.0){
            ALAuthorizationStatus status = [ALAssetsLibrary authorizationStatus];
            if(status == AVAuthorizationStatusDenied || status == ALAuthorizationStatusRestricted){//未授权或受限
                available = NO;
            }
        }
    }
    return available;
}
//MARK:  - 相机权限判断
+ (BOOL)isCameraAvailable
{
    BOOL available = [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];
    if (available && [VQTools getSystemVersion] >= 7.0) {
        AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        if(status == AVAuthorizationStatusDenied || status == ALAuthorizationStatusRestricted){
            
            available = NO;
        }
    }
    return available;
}
//MARK:  - 麦克风权限判断
+ (BOOL)isAudioAvailable
{
    BOOL available = YES;
    if (available && [VQTools getSystemVersion] >= 7.0) {
        AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
        if(status == AVAuthorizationStatusDenied || status == ALAuthorizationStatusRestricted){
            
            available = NO;
        }
    }
    return available;
}
//MARK:  - 定位权限判断
+(BOOL)isLocationAvailable
{
    BOOL available = [CLLocationManager locationServicesEnabled];
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    if (!(available && (status == kCLAuthorizationStatusAuthorizedAlways || status == kCLAuthorizationStatusAuthorizedWhenInUse))) {
        available = NO;
    }
    return available;
}
#pragma clang diagnostic pop
//MARK: - 返回uuid 不带特殊符号-
+(NSString *)getUUID
{
    NSString *uuid = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    uuid = [uuid stringByReplacingOccurrencesOfString:@"-" withString:@""];
    return uuid;
}
//MARK: - 读取文件
+(NSData *)readFileFromPath:(NSString *)path
{
    NSData *data = [NSData dataWithContentsOfFile:path];
    return data;
}
//MARK: - 删除文件
+(BOOL)deleteFileWithPath:(NSString *)path{
    if ([VQTools isFileExistsAtPath:path]) {
        NSError *error = nil;
        BOOL result = [[NSFileManager defaultManager]removeItemAtPath:path error:&error];
        return result;
    }else{
        return YES;
    }
}
//MARK: - 判断文件或路径是否存在
+(BOOL)isFileExistsAtPath:(NSString *)path
{
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:path];
    return fileExists;
}
//MARK: - 将文件写入沙盒
+(BOOL)writeFile:(NSData *)data ToSandBoxPath:(NSString *)path withFileName:(NSString *)fileName
{
    BOOL isSucceed;
    if (data) {
        BOOL fileExists = [VQTools isFileExistsAtPath:path];
        if (fileExists) {
            if (fileName.length > 0) {
                path = [path stringByAppendingPathComponent:fileName];
                isSucceed = [data writeToFile:path atomically:YES];
            }else{
                NSTimeInterval time = [[NSDate date] timeIntervalSince1970];
                path = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%lf",time]];
                isSucceed = [data writeToFile:path atomically:YES];
            }
        }else{
            NSError *directoryCreateError = nil;
            BOOL isCreated = [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&directoryCreateError];
            if (isCreated) {
                if (fileName.length > 0) {
                    path = [path stringByAppendingPathComponent:fileName];
                    isSucceed = [data writeToFile:path atomically:YES];
                }else{
                    NSTimeInterval time = [[NSDate date] timeIntervalSince1970];
                    path = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%lf",time]];
                    isSucceed = [data writeToFile:path atomically:YES];
                }
            }else{
                isSucceed = NO;
            }
        }
    }else{
        isSucceed = NO;
    }
    return isSucceed;
}
//MARK: - 将图片存入相册
void(^_writeImageBlock)(NSError *);
+(void)writeImage:(UIImage *)image ToPhotoLibraryWithCompletion:(void (^)(NSError *error))block{
    _writeImageBlock = block;
    [[VQTools new] writeImage:image ToPhotoLibraryWithCompletion:block];
}
-(void)writeImage:(UIImage *)image ToPhotoLibraryWithCompletion:(void (^)(NSError *error))block{
    UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:),nil);
}
- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo{
    if (_writeImageBlock) {
        _writeImageBlock(error);
    }
}

//MARK: - 将视频存入相册
void(^_writeMovieBlock)(NSError *);
+(void)writeMovie:(NSString *)filePath ToPhotoLibraryWithCompletion:(void (^)(NSError *error))block{
    _writeMovieBlock = block;
    [[VQTools new] writeMovie:filePath ToPhotoLibraryWithCompletion:block];
}
-(void)writeMovie:(NSString *)filePath ToPhotoLibraryWithCompletion:(void (^)(NSError *error))block{
    UISaveVideoAtPathToSavedPhotosAlbum(filePath, [VQTools new], @selector(video:didFinishSavingWithError:contextInfo:), NULL);
}
- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo{
    if (_writeMovieBlock) {
        _writeMovieBlock(error);             
    }
}


//MARK: - 获取沙盒Caches文件夹路径
+(NSString *)getSandBoxCachesPath
{
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    return path;
}
//MARK: - 将字符串中的中文转换成UTF8
+ (NSString*)replaceChineseToUTF8:(NSString *)originalString
{
    
    NSError* error = NULL;
    
    //1.写正则
    NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:@"[\u4e00-\u9fa5]" options:NSRegularExpressionCaseInsensitive error:&error];
    
    //2.获取结果
    NSArray<NSTextCheckingResult *> *array = [regex matchesInString:originalString options:NSMatchingReportProgress range:NSMakeRange(0, originalString.length)];
    //3.用来存储 目标结果
    NSMutableDictionary *dictM = [NSMutableDictionary dictionaryWithCapacity:array.count];
    //4.遍历 获取结果
    for (NSTextCheckingResult *result in array) {
        NSString *targetStr = [originalString substringWithRange:result.range];
        dictM[targetStr] = [targetStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    }
    //遍历替换
    for (NSString *key  in [dictM allKeys]) {
        originalString = [originalString stringByReplacingOccurrencesOfString:key withString:dictM[key]];
    }
    return originalString;
}
//MARK:  - 简单的alert提示
+(void)showAlertWithTitle:(NSString *)title Message:(NSString *)message OkButtonTitle:(NSString *)okTitle CancleButtonTitle:(NSString *)cancaleTitle CurrentViewController:(UIViewController *)currentVC OkBlock:(OkBlock)okBlock CancleBlock:(CancleBlock)cancleBlock
{
    UIViewController *sourceVC = currentVC;
    if (currentVC) {
        sourceVC = currentVC;
    }else{
        sourceVC = [VQTools getCurrentViewControllerFromWindow:nil];
    }
    
    if (title.length < 1)  title = @"提示";
    if (message.length < 1) message = @"";
    if (okTitle.length < 1) okTitle = @"确定";
    if (cancaleTitle.length < 1) cancaleTitle = @"取消";

    
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:okTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if (okBlock) {
            okBlock();
        }
    }];
    UIAlertAction *cancleAction = [UIAlertAction actionWithTitle:cancaleTitle style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        if (cancleBlock) {
            cancleBlock();
        }
    }];
    [alertVC addAction:okAction];
    [alertVC addAction:cancleAction];
    [sourceVC presentViewController:alertVC animated:YES completion:NULL];
}
//MARK:  - 获得视频封面
+ (UIImage *)getVideoCover:(NSString *)videoURL isLocalVideo:(BOOL)isLocal
{
    NSURL *url;
    if (isLocal)
    {
        url = [NSURL fileURLWithPath:videoURL];
    }
    else
    {
        url = [NSURL URLWithString:videoURL];
    }
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:url options:nil];
    AVAssetImageGenerator *gen = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    gen.appliesPreferredTrackTransform = YES;
    CMTime time = CMTimeMakeWithSeconds(0.0, 600);
    NSError *error = nil;
    CMTime actualTime;
    CGImageRef image = [gen copyCGImageAtTime:time actualTime:&actualTime error:&error];
    UIImage *thumb = [[UIImage alloc] initWithCGImage:image];
    CGImageRelease(image);
    return thumb;
}

//MARK: - 开始录音
//取得音频录制路径
-(NSString *)getSavePath{
    NSString *urlStr=[NSTemporaryDirectory() stringByAppendingString:RecordAudioFile];
    if (audioDBUG) NSLog(@"file path:%@",urlStr);
    return urlStr;
}
 //取得MP3音频路径
- (NSString*)getSaveMP3Path{
    NSString *urlStr=[NSTemporaryDirectory() stringByAppendingString:RecordAudioMP3fILE];
    if (audioDBUG) NSLog(@"file path:%@",urlStr);
    return urlStr;
}
//取得录音文件设置
- (NSDictionary*)getAudioSetting{
    NSMutableDictionary *dicM=[NSMutableDictionary dictionary];
    //设置录音格式
    [dicM setObject:@(kAudioFormatLinearPCM) forKey:AVFormatIDKey];
    //设置录音采样率，8000是电话采样率，对于一般录音已经够了
    [dicM setObject:@(11025.0) forKey:AVSampleRateKey];
    //设置通道,这里采用单声道
    [dicM setObject:@(2) forKey:AVNumberOfChannelsKey];
    //    //每个采样点位数,分为8、16、24、32
    //    [dicM setObject:@(8) forKey:AVLinearPCMBitDepthKey];
    //    //是否使用浮点数采样
    //    [dicM setObject:@(YES) forKey:AVLinearPCMIsFloatKey];
    //音频质量,采样质量
    [dicM setValue:[NSNumber numberWithInt:AVAudioQualityMin] forKey:AVEncoderAudioQualityKey];
    //....其他设置等
    return dicM;
}
//录音所需计时器
-(void)startTimer{
    if (self.timer) {
        [self endTimer];
    }
    __weak typeof (self)weakSelf = self;
    NSBlockOperation *op = [NSBlockOperation blockOperationWithBlock:^{
        NSTimer *timer=[NSTimer scheduledTimerWithTimeInterval:1.0f
                                                        target:weakSelf
                                                      selector:@selector(changeTime)
                                                      userInfo:nil
                                                       repeats:YES] ;
        //scheduledTimerWithTimeInterval 会自动加入到运行循环
        //        [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
        //        weakSelf.timerThread = [NSThread currentThread];
        //        NSLog(@"thread = %@",weakSelf.timerThread);
        weakSelf.timer = timer;
        [[NSRunLoop currentRunLoop] run];//子线程 手动开启运行循环
    }];
    
    NSOperationQueue *queue = [NSOperationQueue new];
    self.queue = queue;
    [queue addOperation:op];
}
- (void)changeTime {
    self.time++;
    NSLog(@"self.time = %f",self.time);
    if (self.maxSeconds > 0) {
        if (self.time >= self.maxSeconds) {
            if (self.isAuto) {
                [self audioStopRecord];
            }
        }
    }
}
-(void)endTimer{
    //取消定时器
    [self.timer invalidate];//销毁定时器
    self.timer = nil;
    [self.queue cancelAllOperations];
    self.queue = nil;
    
    //    [self performSelector:@selector(cancleTimer) onThread:self.timerThread withObject:nil waitUntilDone:YES];
    //    [self cancleTimer];
    //    NSOperation *op = self.queue.operations.firstObject;
    //    [op cancel];
    
    [self.queue cancelAllOperations];
    self.queue = nil;
}
//懒加载 录音机
-(AVAudioRecorder *)audioRecorder{
    if(_audioRecorder) return _audioRecorder;
    
    AVAudioSession *audioSession=[AVAudioSession sharedInstance];
    //此为录音 故设置为录音状态，
    [audioSession setCategory:AVAudioSessionCategoryRecord error:nil];
    [audioSession setActive:YES error:nil];
    //创建录音文件保存路径
    NSURL *url=[NSURL URLWithString:[self getSavePath]];
    //创建录音格式设置
    NSDictionary *setting=[self getAudioSetting];
    //创建录音机
    NSError *error=nil;
    _audioRecorder=[[AVAudioRecorder alloc]initWithURL:url settings:setting error:&error];
    _audioRecorder.delegate=self;
    _audioRecorder.meteringEnabled=YES;//如果要监控声波则必须设置为YES
    if (error) {
        if (audioDBUG) NSLog(@"创建录音机对象时发生错误，错误信息：%@",error.localizedDescription);
        return nil;
    }
    return _audioRecorder;
}
//开始录音
- (void)audioStartRecordWithMaxTime:(NSInteger)maxSeconds NormalFinishBlock:(RecordNormalFinishBlock)normalFinishBlock TimeOutBlock:(RecordTimeOutBlock)timeOutBlock AutomaticTimeOutBlock:(BOOL)isAuto EncoderMP3:(BOOL)isEncoder{

    self.time = 0;//初始化计时
    self.maxSeconds = maxSeconds;
    self.isEncoder = isEncoder;//yes为转为MP3
    
    self.isAuto = isAuto;
    self.normalFinishBlock = normalFinishBlock;
    self.timeOutBlock = timeOutBlock;
    
    [self audioStartRecord];
}
- (void)audioStartRecord{
    if (![self.audioRecorder isRecording]) {//当正在录制 不会重复执行
        [self.audioRecorder record];
        if (self.timer) {
            self.timer.fireDate=[NSDate distantPast];//开始定时器
        }else{
            [self startTimer];
        }
    }
}
//暂停录音
-(void)audioPauseRecord {
    if ([self.audioRecorder isRecording]) {
        [self.audioRecorder pause];
    }
    if (self.timer) {
        self.timer.fireDate=[NSDate distantFuture];//暂停定时器
    }
}
//恢复录音
- (void)audioResumeRecord{
        if (self.timer) {
            [self audioStartRecord];
        }
}
//结束录音
- (void)audioStopRecord{
    [self.audioRecorder stop];
    self.audioRecorder = nil;
    [self endTimer];
}

/**
 *  录音完成自动代用此方法
 *
 *  @param recorder 录音机对象
 *  @param flag     是否成功呢
 */
-(void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag{
    //根据实际情况播放完成可以将会话关闭，其他音频应用继续播放
    [[AVAudioSession sharedInstance]setActive:NO error:nil];
    
    NSString *cafFilePath =[self getSavePath] ;//原caf文件位置
    NSString *mp3FilePath = [self getSaveMP3Path];//转化过后的MP3文件位置
    NSData * delegateData= nil;
    NSFileManager* fileManager=[NSFileManager defaultManager];
    
    if([fileManager removeItemAtPath:mp3FilePath error:nil])
    {
        NSLog(@"删除");
    }
    if (_isEncoder) {
        @try {
            int read, write;
            FILE *pcm = fopen([cafFilePath cStringUsingEncoding:1], "rb");  //source 被转换的音频文件位置
            if(pcm == NULL)
            {
                NSLog(@"file not found");
            }
            else
            {
                fseek(pcm, 4*1024, SEEK_CUR);                                   //skip file header,跳过头文件 有的文件录制会有音爆，加上此句话去音爆
                FILE *mp3 = fopen([mp3FilePath cStringUsingEncoding:1], "wb");  //output 输出生成的Mp3文件位置
                const int PCM_SIZE = 8192;
                const int MP3_SIZE = 8192;
                short int pcm_buffer[PCM_SIZE*2];
                unsigned char mp3_buffer[MP3_SIZE];
                
                lame_t lame = lame_init();
                lame_set_in_samplerate(lame, 11025.0);
                lame_set_VBR(lame, vbr_default);
                lame_init_params(lame);
                
                do {
                    read = (int)fread(pcm_buffer, 2*sizeof(short int), PCM_SIZE, pcm);//强制转换int 消除提示
                    if (read == 0)
                        write = lame_encode_flush(lame, mp3_buffer, MP3_SIZE);
                    else
                        write = lame_encode_buffer_interleaved(lame, pcm_buffer, read, mp3_buffer, MP3_SIZE);
                    fwrite(mp3_buffer, write, 1, mp3);
                } while (read != 0);
                lame_close(lame);
                fclose(mp3);
                fclose(pcm);
            }
        }
        @catch (NSException *exception) {
            if (audioDBUG) NSLog(@"%@",[exception description]);
        }
        @finally {
            delegateData = [NSData dataWithContentsOfFile:[self getSaveMP3Path]];//此处可以打断点看下data文件的大小，如果太小，很可能是个空文件
            if (audioDBUG)  NSLog(@"执行完成");
        }
    }
    else{
        delegateData = [NSData dataWithContentsOfFile:cafFilePath];
    }
    
    if (self.maxSeconds > 0) {//如果self.maxSeconds 大于0 说明有时长限制 可能超时也可能未超时
        if (_time < self.maxSeconds) {//正常结束
            if (self.normalFinishBlock) {self.normalFinishBlock(delegateData);}
        }
        else if (_time >= self.maxSeconds){//超时
            if (self.timeOutBlock) {self.timeOutBlock(delegateData);}
        }
    }else{//如果self.maxSeconds 小于或等于0 说明不限时长，就不存在执行超时回调逻辑
        if (self.normalFinishBlock) {self.normalFinishBlock(delegateData);}
    }

    // 删除文件夹及文件级内的文件：
    NSString *saveMP3Path = [self getSaveMP3Path];
    NSString *savePath = [self getSavePath];
    if([fileManager removeItemAtPath:saveMP3Path error:nil])
    {
        NSLog(@"删除");
    }
    if([fileManager removeItemAtPath:savePath error:nil])
    {
        NSLog(@"删除");
    }
}

//MARK:  - 播放录音
-(void)audioStartPlayWithFilePath:(NSString *)filePath AudioPlayFinishBlock:(AudioPlayFinishBlock)playFinishBlock{
    
    self.audioPlayFinishBlock = playFinishBlock;
    
    AVAudioSession *audioSession=[AVAudioSession sharedInstance];
    //此为播放 故设置为播放状态，
    [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
    [audioSession setActive:YES error:nil];
    
    NSError *error = nil;
    NSURL *url = [NSURL URLWithString:filePath];
    self.audioPlayer = [[AVAudioPlayer alloc]initWithContentsOfURL:url error:&error];
    self.audioPlayer.numberOfLoops = 0;
    self.audioPlayer.delegate = self;
    [self.audioPlayer prepareToPlay];
    if (error) {
        if (audioDBUG) NSLog(@"创建播放器过程中发生错误，错误信息：%@",error.localizedDescription);
    }
    [self playAudio];

}
//开始播放
-(void)playAudio{
    if (![self.audioPlayer isPlaying]) {
        [self.audioPlayer play];
    }
}
//暂停播放
-(void)audioPausePlay{
    if ([self.audioPlayer isPlaying]) {
        [self.audioPlayer pause];
    }
}
//恢复播放
-(void)audioResumePlay{
    [self.audioPlayer play];
}
//停止播放
-(void)audioStopPlay{
    [self.audioPlayer stop];
     [[AVAudioSession sharedInstance]setActive:NO error:nil];
    self.audioPlayer = nil;
}
//设置播放时间
-(void)audioSetCurrentPlayTime:(NSTimeInterval)currentTime{
    if (currentTime < 0) {
        currentTime = 0;
    }else if (currentTime > self.audioPlayer.duration){
        currentTime = self.audioPlayer.duration;
    }
    self.audioPlayer.currentTime = currentTime;
}
//获取当前播放时间
-(NSTimeInterval)audioGetCurrentPlayTime{
   return self.audioPlayer.currentTime;
}
//获取文件总时长
-(NSTimeInterval)audioGetDurationPlayTime{
   return self.audioPlayer.duration;
}

//音频播放器代理方法
-(void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag{
    if (flag) {
        if (self.audioPlayFinishBlock) {
            self.audioPlayFinishBlock();
        }
    }
    if (audioDBUG) NSLog(@"音乐播放完成...");
    //根据实际情况播放完成可以将会话关闭，其他音频应用继续播放
    [[AVAudioSession sharedInstance]setActive:NO error:nil];
}

//MARK: - 录制视频
-(UIImagePickerController *)imagePicker{
    if (_imagePicker) return _imagePicker;

    switch (self.imagePickerUseType) {
        case KVQImagePickerUseType_OpenPhotoLibrary_GetImage:
        {
            _imagePicker = [UIImagePickerController new];
            _imagePicker.mediaTypes = @[@"public.image"];
            _imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;//图库选项包含相册
            _imagePicker.delegate = self;
        }
            break;
        case KVQImagePickerUseType_OpenPhotoLibrary_GetVideo:
        {
            _imagePicker = [UIImagePickerController new];
            _imagePicker.mediaTypes = @[@"public.movie"];
            _imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;//图库选项包含相册
            _imagePicker.delegate = self;
        }
            break;
        case KVQImagePickerUseType_TakePhotos:
        {
            _imagePicker = [UIImagePickerController new];
            _imagePicker.mediaTypes = @[@"public.image"];
            _imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
            _imagePicker.cameraCaptureMode=UIImagePickerControllerCameraCaptureModePhoto;
            _imagePicker.delegate = self;
        }
            break;
            case KVQImagePickerUseType_RecordVideo:
        {
            _imagePicker = [UIImagePickerController new];
            _imagePicker.mediaTypes = @[@"public.movie"];
            _imagePicker.sourceType=UIImagePickerControllerSourceTypeCamera;//设置image picker的来源，这里设置为摄像头
            _imagePicker.cameraCaptureMode=UIImagePickerControllerCameraCaptureModeVideo;//设置摄像头模式（拍照，录制视频）
            _imagePicker.videoMaximumDuration = self.maxSeconds;
            _imagePicker.delegate = self;
        }
            break;
        default:
            break;
    }
    return _imagePicker;
}
//MARK: - 使用系统自带工具从相册获取视频
-(void)getVideoFromPhotoLibWithCurrentVC:(UIViewController *)vc VideoSelectFinish:(VideoSelectionFinishBlock)selectionFinishBlock{
    self.imagePicker = nil;//手动置空
    self.imagePickerUseType = KVQImagePickerUseType_OpenPhotoLibrary_GetVideo;
    self.videoSelectionFinishBlock = selectionFinishBlock;
    UIViewController *sourceVC = [self checkVC:vc];
    if (sourceVC) { [sourceVC presentViewController:self.imagePicker animated:YES completion:^{}]; }
}

//MARK: - 使用系统自带工具录制视频
-(void)videoStartRecordWithCurrentVC:(UIViewController *)vc MaxTime:(NSInteger)maxSeconds VideoRecordFinishBlock:(VideoRecordFinishBlock)recordFinishBlock{
    if (maxSeconds <= 0) { return; }
    self.imagePicker = nil;//手动置空
    self.imagePickerUseType = KVQImagePickerUseType_RecordVideo;
    
    self.maxSeconds = maxSeconds;
    self.videoRecordFinishBlock = recordFinishBlock;
    
    UIViewController *sourceVC = [self checkVC:vc];
    if (sourceVC) { [sourceVC presentViewController:self.imagePicker animated:YES completion:^{}]; }
}

//MARK: - 使用系统自带工具从相册获取图片
-(void)getImageFromPhotoLibWithCurrentVC:(UIViewController *)vc PicSelectFinish:(PictureSelectionFinishBlock)selectionFinishBlock{
    self.imagePicker = nil;//手动置空
    self.imagePickerUseType = KVQImagePickerUseType_OpenPhotoLibrary_GetImage;
    self.pictureSelectionFinishBlock = selectionFinishBlock;
    
    UIViewController *sourceVC = [self checkVC:vc];
    if (sourceVC) { [sourceVC presentViewController:self.imagePicker animated:YES completion:^{}]; }
}

//MARK: - 使用系统自带工具从摄像头获取图片
-(void)getImageFromCameraWithCurrentVC:(UIViewController *)vc PicTakeFinish:(PictureTakingFinishBlock)takingFinishBlock{
    self.imagePicker = nil;//手动置空
    self.imagePickerUseType = KVQImagePickerUseType_TakePhotos;
    self.pictureTakingFinishBlock = takingFinishBlock;
    
    UIViewController *sourceVC = [self checkVC:vc];
    if (sourceVC) { [sourceVC presentViewController:self.imagePicker animated:YES completion:^{}]; }
}

//检查控制器是否为空 如果为空 则掉用自己的方法 遍历获取控制器
-(UIViewController *)checkVC:(UIViewController *)currentVC{
    UIViewController *sourceVC;
    if (currentVC) {
        sourceVC = currentVC;
    }else{
        sourceVC = [VQTools getCurrentViewControllerFromWindow:nil];
    }
    return sourceVC;
}

//MARK: - 录制视频完成 代开相册图库 拍摄照片 需要走的回调
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info{
     __weak typeof (self)weakSelf = self;
    switch (self.imagePickerUseType) {
            case KVQImagePickerUseType_OpenPhotoLibrary_GetImage://打开图库
        {
            [self.imagePicker dismissViewControllerAnimated:YES completion:^{
                if (weakSelf.pictureSelectionFinishBlock) {
                    UIImage *image = info[@"UIImagePickerControllerOriginalImage"];
                    weakSelf.pictureSelectionFinishBlock(image);
                }
            }];
        }
            break;
        case KVQImagePickerUseType_OpenPhotoLibrary_GetVideo://打开图库
        {
            [self.imagePicker dismissViewControllerAnimated:YES completion:^{
                if (weakSelf.videoSelectionFinishBlock) {
                    NSURL *url=[info objectForKey:UIImagePickerControllerMediaURL];//视频路径
                    NSString *urlStr = [url path];
                    NSData *data = nil;
                    if (urlStr.length > 0) {
                        data = [NSData dataWithContentsOfFile:urlStr];
                    }
                    weakSelf.videoSelectionFinishBlock(data);
                }
            }];
        }
            break;
        case KVQImagePickerUseType_TakePhotos://拍摄照片
        {
            [self.imagePicker dismissViewControllerAnimated:YES completion:^{
                if (weakSelf.pictureTakingFinishBlock) {
                    UIImage *image = info[@"UIImagePickerControllerOriginalImage"];
                    weakSelf.pictureTakingFinishBlock(image);
                }
            }];
        }
            break;
        case KVQImagePickerUseType_RecordVideo://录制视频
        {
            [self.imagePicker dismissViewControllerAnimated:YES completion:^{
                if (weakSelf.videoRecordFinishBlock) {
                    NSURL *url=[info objectForKey:UIImagePickerControllerMediaURL];//视频路径
                    NSString *urlStr=[url path];
                    NSData * data = [[NSData alloc]initWithContentsOfFile:urlStr]; //录制得到的视频
                    weakSelf.videoRecordFinishBlock(data);
                }
            }];
        }
            break;
        default:
            break;
    }
}

//MARK: - 播放视频
-(MPMoviePlayerViewController *)moviePlayerViewController{
    if (_moviePlayerViewController) return _moviePlayerViewController;
        NSURL *url = [NSURL fileURLWithPath:self.filePath];
    return _moviePlayerViewController = [[MPMoviePlayerViewController alloc]initWithContentURL:url];
}
-(void)videoStartPlayWithCurrentVC:(UIViewController *)vc FilePath:(NSString *)filePath{
    self.filePath = filePath;
    
    if (filePath.length > 0) {
        self.moviePlayerViewController=nil;//保证每次点击都重新创建视频播放控制器视图，避免再次点击时由于不播放的问题
        UIViewController *sourceVC = [self checkVC:vc];
        if (sourceVC) {
            [sourceVC presentMoviePlayerViewControllerAnimated:self.moviePlayerViewController];
        }
    }
}

//MARK: - 释放方法
-(void)dealloc{
    
}
@end
