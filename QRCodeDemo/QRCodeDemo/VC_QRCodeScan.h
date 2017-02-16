//
//  VC_ZBarScan.h
//  MyTools
//
//  Created by 李金帅 on 16/8/3.
//  Copyright © 2016年 Jin. All rights reserved.
//

#import <UIKit/UIKit.h>


typedef void(^StringBlock)(NSString *urlString);

@interface VC_QRCodeScan : UIViewController
//回调block
@property (copy, nonatomic) StringBlock scanString;

@end
