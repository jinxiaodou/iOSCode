//
//  VC_ZBar.m
//  MyTools
//
//  Created by 李金帅 on 16/8/3.
//  Copyright © 2016年 Jin. All rights reserved.
//

#import "VC_QRCodeBuild.h"
//二维码生成
//导入CoreImage框架
//通过滤镜CIFilter生成二维码

@interface VC_QRCodeBuild ()<UITextFieldDelegate>
{
    
}
@property (strong, nonatomic) UITextField *textFiled;
@property (strong, nonatomic) UIImageView *imgView;

@end

@implementation VC_QRCodeBuild

- (void)viewDidLoad {
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.imgView=[[UIImageView alloc]initWithFrame:CGRectMake(100, 120, SCREEN_WIDTH/2.0, SCREEN_WIDTH/2.0)];
    [self.view addSubview:_imgView];
    
    self.textFiled = [[UITextField alloc] initWithFrame:CGRectMake(20, 70, 200, 40)];
    self.textFiled.delegate = self;
    self.textFiled.borderStyle = UITextBorderStyleRoundedRect;
    [self.view addSubview:self.textFiled];

    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.frame = CGRectMake(100, SCREEN_WIDTH/2.0+150, 60, 30);
    CGPoint p = button.center;
    p.x = self.view.center.x;
    button.center = p;
    [button setTitle:@"生成" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(erweima) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    
}

-(void)erweima
{
    NSString *string = self.textFiled.text;
    if (string == nil || string.length == 0) {
        return;
    }
    //二维码滤镜
    CIFilter *filter=[CIFilter filterWithName:@"CIQRCodeGenerator"];
    
    //恢复滤镜的默认属性
    [filter setDefaults];
    
    //将字符串转换成NSData
    NSData *data=[string dataUsingEncoding:NSUTF8StringEncoding];
    
    //通过KVO设置滤镜inputmessage数据
    [filter setValue:data forKey:@"inputMessage"];
    //获得滤镜输出的图像
    
    CIImage *outputImage=[filter outputImage];
    
    //将CIImage转换成UIImage,并放大显示
    
    _imgView.image=[self createNonInterpolatedUIImageFormCIImage:outputImage withSize:100.0];
    
    
    
    //如果还想加上阴影，就在ImageView的Layer上使用下面代码添加阴影
    
    _imgView.layer.shadowOffset=CGSizeMake(0, 0.5);//设置阴影的偏移量
    
    _imgView.layer.shadowRadius=1;//设置阴影的半径
    
    _imgView.layer.shadowColor=[UIColor blackColor].CGColor;//设置阴影的颜色为黑色
    
    _imgView.layer.shadowOpacity=0.3;
    
    
    
}



//改变二维码大小

- (UIImage *)createNonInterpolatedUIImageFormCIImage:(CIImage *)image withSize:(CGFloat) size {
    
    CGRect extent = CGRectIntegral(image.extent);
    
    CGFloat scale = MIN(size/CGRectGetWidth(extent), size/CGRectGetHeight(extent));
    
    // 创建bitmap;
    
    size_t width = CGRectGetWidth(extent) * scale;
    
    size_t height = CGRectGetHeight(extent) * scale;
    
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceGray();
    
    CGContextRef bitmapRef = CGBitmapContextCreate(nil, width, height, 8, 0, cs, (CGBitmapInfo)kCGImageAlphaNone);
    
    CIContext *context = [CIContext contextWithOptions:nil];
    
    CGImageRef bitmapImage = [context createCGImage:image fromRect:extent];
    
    CGContextSetInterpolationQuality(bitmapRef, kCGInterpolationNone);
    
    CGContextScaleCTM(bitmapRef, scale, scale);
    
    CGContextDrawImage(bitmapRef, extent, bitmapImage);
    
    // 保存bitmap到图片
    
    CGImageRef scaledImage = CGBitmapContextCreateImage(bitmapRef);
    
    CGContextRelease(bitmapRef);
    
    CGImageRelease(bitmapImage);
    
    return [UIImage imageWithCGImage:scaledImage];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end
