//
//  VC_ZBarScan.m
//  MyTools
//
//  Created by 李金帅 on 16/8/3.
//  Copyright © 2016年 Jin. All rights reserved.
//

#import "VC_QRCodeScan.h"
#import <AVFoundation/AVFoundation.h>


//这是使用系统框架进行的二维码扫描
//其他框架包括第三方ZBar和ZXing
@interface VC_QRCodeScan ()<AVCaptureMetadataOutputObjectsDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate>
@property (weak, nonatomic) IBOutlet UIView *viewPreview;
@property (weak, nonatomic) IBOutlet UILabel *lblStatus;
@property (weak, nonatomic) IBOutlet UIButton *startBtn;
- (IBAction)startStopReading:(id)sender;

@property (strong, nonatomic) UIView *boxView;
@property (nonatomic) BOOL isReading;
@property (strong, nonatomic) CALayer *scanLayer;

//捕捉会话
@property (nonatomic, strong) AVCaptureSession *captureSession;
//展示layer
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *videoPreviewLayer;



@end

@implementation VC_QRCodeScan

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    //检测相机权限
    
    [self checkDeviceStatus];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    _captureSession = nil;
    _isReading = NO;
    
}

- (BOOL)startReading {
    NSError *error;
    
    //1.初始化捕捉设备（AVCaptureDevice），类型为AVMediaTypeVideo
    AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    //2.用captureDevice创建输入流
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
    if (!input) {
        NSLog(@"%@", [error localizedDescription]);
        return NO;
    }
    
    //3.创建媒体数据输出流
    AVCaptureMetadataOutput *captureMetadataOutput = [[AVCaptureMetadataOutput alloc] init];
    
    //4.实例化捕捉会话
    _captureSession = [[AVCaptureSession alloc] init];
    
    //4.1.将输入流添加到会话
    [_captureSession addInput:input];
    
    //4.2.将媒体输出流添加到会话中
    [_captureSession addOutput:captureMetadataOutput];
    
    //5.创建串行队列，并加媒体输出流添加到队列当中
    dispatch_queue_t dispatchQueue;
    dispatchQueue = dispatch_queue_create("myQueue", NULL);
    //5.1.设置代理
    [captureMetadataOutput setMetadataObjectsDelegate:self queue:dispatchQueue];
    
    //5.2.设置输出媒体数据类型为QRCode
    // 设置输出数据类型，需要将元数据输出添加到会话后，才能指定元数据类型，否则会报错
    [captureMetadataOutput setMetadataObjectTypes:[NSArray arrayWithObject:AVMetadataObjectTypeQRCode]];
    
    //6.实例化预览图层 传递_captureSession是为了告诉图层将来显示什么内容
    _videoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
    
    //7.设置预览图层填充方式
    [_videoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    
    //8.设置图层的frame
    [_videoPreviewLayer setFrame:_viewPreview.layer.bounds];
    
    //9.将图层添加到预览view的图层上
    [_viewPreview.layer addSublayer:_videoPreviewLayer];
    
    //10.设置扫描范围
    captureMetadataOutput.rectOfInterest = CGRectMake(0.2f, 0.2f, 0.8f, 0.8f);
    
    //10.1.扫描框
    _boxView = [[UIView alloc] initWithFrame:CGRectMake(_viewPreview.bounds.size.width * 0.2f, _viewPreview.bounds.size.height * 0.2f, _viewPreview.bounds.size.width - _viewPreview.bounds.size.width * 0.4f, _viewPreview.bounds.size.height - _viewPreview.bounds.size.height * 0.4f)];
    _boxView.layer.borderColor = [UIColor greenColor].CGColor;
    _boxView.layer.borderWidth = 1.0f;
    
    [_viewPreview addSubview:_boxView];
    
    //10.2.扫描线
    _scanLayer = [[CALayer alloc] init];
    _scanLayer.frame = CGRectMake(0, 0, _boxView.bounds.size.width, 1);
    _scanLayer.backgroundColor = [UIColor brownColor].CGColor;
    
    [_boxView.layer addSublayer:_scanLayer];
    
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:0.2f target:self selector:@selector(moveScanLayer:) userInfo:nil repeats:YES];
    
    [timer fire];
    
    
    
    
    return YES;
}

- (IBAction)startStopReading:(id)sender {
    if (!_isReading) {
        if ([self startReading]) {
            [_startBtn setTitle:@"Stop" forState:UIControlStateNormal];
            [_lblStatus setText:@"Scanning for QR Code"];
        }
    }
    else{
        [self stopReading];
        [_startBtn setTitle:@"Start!" forState:UIControlStateNormal];
    }
    
    _isReading = !_isReading;
}

-(void)stopReading{
    [_captureSession stopRunning];
    _captureSession = nil;
    [_scanLayer removeFromSuperlayer];
    [_videoPreviewLayer removeFromSuperlayer];
}

//检测摄像头允许状态
- (void)checkDeviceStatus {
    //检测状态
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    switch (status) {
        case AVAuthorizationStatusNotDetermined:{
            // 许可对话没有出现，发起授权许可
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                if (granted) {
                    //第一次用户接受
                    NSLog(@"同意使用摄像头");
                    [self allowed];
                }else{
                    //用户拒绝
                    [self notAllowed];
                }
            }];
            break;
        }
        case AVAuthorizationStatusAuthorized:{
            // 已经开启授权，可继续
            NSLog(@"同意使用摄像头");
            [self allowed];
            break;
        }
        case AVAuthorizationStatusDenied:
        case AVAuthorizationStatusRestricted:
            // 用户明确地拒绝授权，或者相机设备无法访问
            [self notAllowed];
            break;
        default:
            break;
    }
}

//未允许访问摄像头
- (void)notAllowed {
    NSLog(@"拒绝使用摄像头");
    // 无权限 引导去开启
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"开启相机权限" message:@"没有权限使用相机，请去设置中开启" delegate:self cancelButtonTitle:nil otherButtonTitles:@"去设置", nil];
    [alert show];
}

//同意
- (void)allowed {
    
    //10.开始扫描
    [_captureSession startRunning];}


#pragma mark - AVCaptureMetadataOutputObjectsDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    //所有的二维码都是字符串, 所以我们可以根据返回的字符串类型进行判断是否进行叶面跳转
    //比如以http://开头的字符串, 我们就可以进行叶面跳转到网页
    //metadataObjects是返回数据的数组
    
    //判断是否有数据
    if (metadataObjects != nil && [metadataObjects count] > 0) {
        AVMetadataMachineReadableCodeObject *metadataObj = [metadataObjects objectAtIndex:0];
        //判断回传的数据类型
        if ([[metadataObj type] isEqualToString:AVMetadataObjectTypeQRCode]) {
            [_lblStatus performSelectorOnMainThread:@selector(setText:) withObject:[metadataObj stringValue] waitUntilDone:NO];

            [self performSelectorOnMainThread:@selector(stopReading) withObject:nil waitUntilDone:NO];
            _isReading = NO;
        }
    }
}

- (void)moveScanLayer:(NSTimer *)timer
{
    CGRect frame = _scanLayer.frame;
    if (_boxView.frame.size.height < _scanLayer.frame.origin.y) {
        frame.origin.y = 0;
        _scanLayer.frame = frame;
    }else{
        
        frame.origin.y += 5;
        
        [UIView animateWithDuration:0.1 animations:^{
            _scanLayer.frame = frame;
        }];
    }
}

- (BOOL)shouldAutorotate
{
    return NO;
}

//生成二维码
- (IBAction)buildQRCode:(id)sender {
    Class class = NSClassFromString(@"VC_QRCodeBuild");
    id obj = [[class alloc] init];
    [self.navigationController pushViewController:obj animated:YES];
}

#pragma mark -------------实现相册二维码识别---------------

//打开系统相册
- (IBAction)openCameralClick:(id)sender {
    // 1.判断相册是否可以打开
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) return;
    // 2. 创建图片选择控制器
    UIImagePickerController *ipc = [[UIImagePickerController alloc] init];
    
    ipc.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    
    // 4.设置代理
    ipc.delegate = self;
    
    // 5.modal出这个控制器
    [self presentViewController:ipc animated:YES completion:nil];
}


#pragma mark -------- UIImagePickerControllerDelegate---------

//实现代理方法(注意需要遵守两个代理协议)
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    // 1.取出选中的图片
    UIImage *pickImage = info[UIImagePickerControllerOriginalImage];
    [self readQRCodeFromImage:pickImage];
    // 注意: 如果实现了该方法, 当选中一张图片时系统就不会自动关闭相册控制器
    [picker dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark 读取图片二维码
/**
 *  读取图片中二维码信息
 *
 *  @param image 图片
 *
 *  @return 二维码内容
 */
- (void)readQRCodeFromImage:(UIImage *)image{
    // 1.图片变数据
    NSData *data = UIImagePNGRepresentation(image);
    CIImage *ciimage = [CIImage imageWithData:data];
    if (ciimage) {
        // 2.从选中的图片中读取二维码数据
        // 2.1创建一个探测器
        CIDetector *qrDetector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:[CIContext contextWithOptions:@{kCIContextUseSoftwareRenderer:@(YES)}] options:@{CIDetectorAccuracy : CIDetectorAccuracyHigh}];
        // 2.2利用探测器探测数据
        NSArray *resultArr = [qrDetector featuresInImage:ciimage];
        // 2.3取出探测到的数据
        if (resultArr.count >0) {
            CIFeature *feature = resultArr[0];
            CIQRCodeFeature *qrFeature = (CIQRCodeFeature *)feature;
            NSString *result = qrFeature.messageString;
            [_lblStatus performSelectorOnMainThread:@selector(setText:) withObject:result waitUntilDone:NO];
        }
    }
}

@end
