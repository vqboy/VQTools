//
//  VQTools.h
//
//  Created by 周彬 on 2016/12/9.
//  Copyright © 2016年 VQBoy. All rights reserved.



//使用本工具类
//需要导入库
// AFNetworking
// info.plist 相关功能需添加字段 获取系统授权
// Privacy - Camera Usage Description              相机
// Privacy - Microphone Usage Description        麦克风
// Privacy - Photo Library Usage Description      相册
// Privacy - Location Always Usage Description  实时定位
// Privacy - Location When In Use Usage Description 使用时定位



#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface VQTools : NSObject

#pragma mark -  ********************↓*↓*↓*↓*↓*↓*↓*↓*↓*↓ 类方法 ↓*↓*↓*↓*↓*↓*↓*↓*↓*↓**********************
//MARK:  - 1. 获取当前控制器
/******************************************************************
 * 方法：获取当前控制器
 * 参数：UIWindow * 如果特殊需求可传入目标window，一般可传nil
 * 说明：本方法可以在不方便获取控制器的地方,获得当前控制器
 * 提示：在viewDidLoad中会获得上一个控制器，默认由0开始遍历window[]，找到符合条件的window所对应的控制器，
              若有容器控制器，则按照view添加的先后顺序，返回最后添加的view的控制器
 */
+(UIViewController *)getCurrentViewControllerFromWindow:(UIWindow *)window;



//MARK:  - 2. 将获取的DeviceToken转换为字符串(返回结果:去掉"< >"符号和空格)
/******************************************************************
 * 方法：将获取的DeviceToken转换为字符串
 * 参数：NSData * deviceToken
 * 说明：在appDelegate中的 application:didRegisterForRemoteNotificationsWithDeviceToken:中使用
 * 提示：该方法目前只能获取 windows[0] 对应的最顶层控制器,如果有很复杂的控制器套用,则不适用本方法
 */
+(NSString *)getDeviceTokenDataToString:(NSData *)deviceToken;

//MARK:  - 3.获取系统版本号
+ (float)getSystemVersion;

//MARK:  - 4. 判断相册权限
+ (BOOL)isPhotoLibraryAvailable;

//MARK:  - 5. 判断相机权限
+ (BOOL)isCameraAvailable;

//MARK:  - 6. 判断麦克风权限
+ (BOOL)isAudioAvailable;

//MARK:  - 7. 判断定位权限
+(BOOL)isLocationAvailable;

//MARK:  - 8. 跳转应用的系统设置界面
+ (void)openAppSettings;

//MARK:  - 9. 返回uuid (返回结果:去掉特殊符号 "-" )
+(NSString *)getUUID;

//MARK: - 11. 获取沙盒Caches文件夹路径
+(NSString *)getSandBoxCachesPath;

//MARK: - 12. 判断文件或路径是否存在
+(BOOL)isFileExistsAtPath:(NSString *)path;

//MARK: - 13.1 读取文件
+(NSData *)readFileFromPath:(NSString *)path;

//MARK: - 13.2 删除文件
+(BOOL)deleteFileWithPath:(NSString *)path;

//MARK: - 14. 将文件写入沙盒
+(BOOL)writeFile:(NSData *)data ToSandBoxPath:(NSString *)path withFileName:(NSString *)fileName;

//MARK: - 15.1 将图片存入相册
+(void)writeImage:(UIImage *)image ToPhotoLibraryWithCompletion:(void (^)(NSError *error))block;
//MARK: - 15.2 将视频存入相册
+(void)writeMovie:(NSString *)filePath ToPhotoLibraryWithCompletion:(void (^)(NSError *error))block;

//MARK: - 16. 将字符串中的中文替换成UTF8编码(返回结果:不转换中文标点和不去掉空格)
+ (NSString*)replaceChineseToUTF8:(NSString *)originalString;

//MARK: - 17.1 压缩图片 DataToImage
/******************************************************************
 * 方法：压缩图片 DataToImage
 * 参数：NSData * data //需要压缩的NSData格式的图片 数据
 *            CGFloat scale //压缩系数 取值范围 [0,1] （例如：0.5f）
 * 返回：UIImage *
 * 说明：本方法只压缩图片存储大小，不修改宽高尺寸
 */
+(UIImage *)compressDataToImage:(NSData *)data scale:(CGFloat)scale;

//MARK: 17.2  压缩图片 ImageToData
/******************************************************************
 * 方法：压缩图片 ImageToData
 * 参数：UIImage * image //需要压缩的image 数据
 *            CGFloat scale //压缩系数 取值范围 [0,1]（例如：0.5f）
 * 返回：NSData *
 * 说明：本方法只压缩图片存储大小，不修改宽高尺寸
 */
+(NSData *)compressImageToData:(UIImage *)image scale:(CGFloat)scale;

//MARK: - 18. 快捷创建简单的alert提示框
typedef void(^OkBlock)();
typedef void(^CancleBlock)();
+(void)showAlertWithTitle:(NSString *)title
                          Message:(NSString *)message
                   OkButtonTitle:(NSString *)okTitle
            CancleButtonTitle:(NSString *)cancaleTitle
     CurrentViewController:(UIViewController *)currentVC
                           OkBlock:(OkBlock)okBlock
                    CancleBlock:(CancleBlock)cancleBlock;

//MARK: - 19. 保持/关闭屏幕常亮
/******************************************************************
 * 方法：保持屏幕常量
 * 参数：BOOL isOn //传YES 会保持常亮状态，传NO恢复系统设置
 * 说明：修改状态只需要再次调用传值
 */
+(void)keepBacklightOfScreen:(BOOL)isOn;

//MARK: - 20 获取视频封面
+ (UIImage *)getVideoCover:(NSString *)videoURL isLocalVideo:(BOOL)isLocal;
#pragma mark -  ********************↓*↓*↓*↓*↓*↓*↓*↓*↓*↓ 对象方法 ↓*↓*↓*↓*↓*↓*↓*↓*↓*↓**********************
//MARK:  - 1.1 监听电话并执行回调
/******************************************************************
 * 方法：监听电话
 * 参数：CallStateDialingBlock //可传NULL
              CallStateIncomingBlock //可传NULL
              CallStateConnectedBlock //可传NULL
              CallStateDisconnectedBlock //可传NULL
 * 返回：无
 * 说明：先创建本对象，保证被控制器强引用，然后传入对应的Block操作就可以
 * 提示：避免循环引用
 * (使用多个block而不使用一个blok传枚举的方式，可以保证使用者快速分清楚state填入对应操作即可，省去if else 判断)
 */
typedef void(^CallStateDialingBlock)();//开始呼叫
typedef void(^CallStateIncomingBlock)();//来电
typedef void(^CallStateConnectedBlock)();//接通
typedef void(^CallStateDisconnectedBlock)();//挂断
-(void)callPhoneCenterWithDialingBlock:(CallStateDialingBlock)dialingBlock
                                         IncomingBlock:(CallStateIncomingBlock)incomingBlock
                                      ConnectedBlock:(CallStateConnectedBlock)connectedBlock
                                  DisconnectedBlock:(CallStateDisconnectedBlock)disconnectedBlock;

//MARK:  1.2 拨打电话
/******************************************************************
 * 方法：拨打电话
 * 参数：NSString * numStr //直接传具体的 电话号码字符串即可，如：@"10086"
 * 返回：无
 * 说明：修改状态只需要再次调用传值
 */
-(void)callPhoneNum:(NSString *)numStr;



//MARK: - 2.1 播放系统音效
/******************************************************************
 * 方法：播放系统音效和震动（直接播放系统音效自带震动）
 * 参数：UInt32 systemSoundID//参数值为 系统提示音列表
 *            int num//参数值为 正整数(例如:2,表示循环两次), 0(表示不循环),负整数(例:-1,表示无限循环)
 * 返回：无
 * 说明：该方法只能播放系统音效，错误的systemSoundID不会播放任何音效
 * 提示：该方法自带系统震动
 */
-(void)startSystemSound:(UInt32)systemSoundID RunLoopNum:(int)num;

//MARK: 2.2 播放自定义音效
/******************************************************************
 * 方法：播放自定义音效
 * 参数：NSString * soundPath //为音乐文件完整路径 如：/..../test.mp3
 *            int num //参数值为 正整数(例如:2,表示循环两次), 0(表示不循环),负整数(例:-1,表示无限循环)
 * 返回：无
 * 说明：该方法只能播放系统规定格式和时长的音效文件
 * 提示：此方法只支持简短音效文件，超过30s的请不要使用该方法
 */
-(void)startCustomSound:(NSString *)soundPath RunLoopNum:(int)num;

//MARK: 2.3 停止音效
/**
 * 方法名：停止音效
 */
-(void)stopSound;

//MARK:  - 3.1 开启震动
/******************************************************************
 * 方法：开启震动
 * 参数：int num //参数值为 正整数(例如:2,表示循环两次), 0(不震动),负整数(例:-1,表示无限循环)
 * 返回：无
 */
-(void)startShakeWithRunLoopNum:(int)num;

//MARK:  3.2 开启震动
/**
 * 方法名：停止震动
 */
-(void)stopShake;

//MARK: - 4.  检测网络是否畅通和联网环境4G/WiFi (Bug：如果连上热点，热点网络不通，依然显示网络畅通WiFi环境)
typedef NS_ENUM(NSInteger,kVQNetworkState){
    kVQNetworkState_UnKnown = 1,//未知
    kVQNetworkState_NotReachable,//断网
    kVQNetworkState_WWAN,//手机蜂窝移动网络
    kVQNetworkState_WiFi//WIFI
};
/******************************************************************
 * 方法：检测网络是否畅通和联网环境4G/WiFi (Bug：如果连上热点，热点网络不通，依然显示网络畅通WiFi环境)
 * 参数：Block
 * 返回：无
 * 说明：BOOL isConnected YES为网络畅通 NO为断网或未知
 *            kVQNetworkState 分别对应 未知 断网 手机蜂窝移动网络 WiFi
 * 提示：关闭应用访问网络权限及真实无WiFi或手机网都会走断网
    示例：
 VQTools *tools = [VQTools new];
 [tools checkNetworkConnectedState:^(BOOL isConnected, kVQNetworkState state) {
     if(isConnected){//畅通
         if (state == kVQNetworkState_WWAN){//手机网
         }else{//Wifi
         }
     }else{//断网
     }
 }];
 */
-(void)checkNetworkConnectedState:(void(^)(BOOL isConnected,kVQNetworkState state))block;

//MARK: - 5. 录制音频
typedef void (^RecordNormalFinishBlock)(NSData *recordData);
typedef void (^RecordTimeOutBlock)(NSData *recordData);
//开始录音
/**
 * 方法：录制音频
 * 参数：NSInteger maxSeconds 最大录制音频时间 （大于0为计时录音时长，小于0表示不限时长）
              RecordNormalFinishBlock 正常录制完成所走的回调
              RecordTimeOutBlock 超时后所走的回调
              BOOL  AutomaticTimeOutBlock  超时是否自动执行超时回调
              BOOL  EncoderMP3 是否自动转成MP3格式，NO为pcm YES为MP3
 * 提示：两个block只会走一个，当maxSeconds大于0时，未超时走正常回调(NormalFinishBlock)，超时走超时回调(TimeOutBlock)
            当AutomaticTimeOutBlock参数传YES，当录音超时就自动走超时回调，传NO，在手动结束录音时走超时回调
            当maxSeconds 小于0，既不限时长录音的时候，只会走正常回调
 */
- (void)audioStartRecordWithMaxTime:(NSInteger)maxSeconds
                                NormalFinishBlock:(RecordNormalFinishBlock)normalFinishBlock
                                        TimeOutBlock:(RecordTimeOutBlock)timeOutBlock
                        AutomaticTimeOutBlock:(BOOL)isAuto
                                         EncoderMP3:(BOOL)isEncoder;
//暂停录音
- (void)audioPauseRecord;
//恢复录音 只需要调用开始方法即可 AVAudioSession会帮助你记录上次录音的位置并追加
- (void)audioResumeRecord;
//停止录音
-(void)audioStopRecord;

//MARK: - 6. 播放本地音频
typedef void (^AudioPlayFinishBlock)();//播放完成回调block
//开始播放
-(void)audioStartPlayWithFilePath:(NSString *)filePath AudioPlayFinishBlock:(AudioPlayFinishBlock)playFinishBlock;
//暂停播放
-(void)audioPausePlay;
//恢复播放
-(void)audioResumePlay;
//停止播放
-(void)audioStopPlay;
//设置当前播放的进度时间
-(void)audioSetCurrentPlayTime:(NSTimeInterval)currentTime;
//获取当前播放的进度时间
-(NSTimeInterval)audioGetCurrentPlayTime;
//获取文件总时长
-(NSTimeInterval)audioGetDurationPlayTime;

//MARK: - 7. 使用系统工具录制视频
typedef void (^VideoRecordFinishBlock)(NSData *recordData);//视频录制完成回调block //返回mov格式兼容mp4
-(void)videoStartRecordWithCurrentVC:(UIViewController *)vc MaxTime:(NSInteger)maxSeconds VideoRecordFinishBlock:(VideoRecordFinishBlock)recordFinishBlock;

//MARK: - 8. 使用系统工具播放视频
-(void)videoStartPlayWithCurrentVC:(UIViewController *)vc FilePath:(NSString *)filePath;

//MARK: - 9. 使用系统工具打开相册 获取单个视频
typedef void (^VideoSelectionFinishBlock)(NSData *data);//选择视频完成回调block
-(void)getVideoFromPhotoLibWithCurrentVC:(UIViewController *)vc VideoSelectFinish:(VideoSelectionFinishBlock)selectionFinishBlock;

//MARK: - 10. 使用系统工具打开相册 获取单张图片
typedef void (^PictureSelectionFinishBlock)(UIImage *image);//选择图片完成回调block
-(void)getImageFromPhotoLibWithCurrentVC:(UIViewController *)vc PicSelectFinish:(PictureSelectionFinishBlock)selectionFinishBlock;

//MARK: - 11. 使用系统工具打开相机 拍摄单张图片
typedef void (^PictureTakingFinishBlock)(UIImage *image);//拍摄图片完成回调block
-(void)getImageFromCameraWithCurrentVC:(UIViewController *)vc PicTakeFinish:(PictureTakingFinishBlock)takingFinishBlock;

@end
