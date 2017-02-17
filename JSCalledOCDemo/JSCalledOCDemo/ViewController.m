//
//  ViewController.m
//  JSCalledOCDemo
//
//  Created by 李金帅 on 17/2/17.
//  Copyright (c) 2017年 李金帅. All rights reserved.
//

#import "ViewController.h"
#import "WebViewJavascriptBridge.h"



@interface ViewController ()<UIWebViewDelegate, UINavigationControllerDelegate>
{
    UIWebView *myWebView;
}
@property WebViewJavascriptBridge* bridge;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    myWebView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    //加载网络页面
    //    [self loadWebHtml:@"https://www.baidu.com"];
    //加载本地页面
    [self loadLocalPage:@"ExampleApp"];
    [self.view addSubview:myWebView];
    
    [WebViewJavascriptBridge enableLogging];
    
    //初始化桥
    _bridge = [WebViewJavascriptBridge bridgeForWebView:myWebView];
    [_bridge setWebViewDelegate:self];
    
    //JS调用OC方法
    //无参数的
    [_bridge registerHandler:@"AutoJSCalledOC" handler:^(id data, WVJBResponseCallback responseCallback) {
        NSLog(@"JS 调用OC 的 AutoJSCalledOC 方法成功");
        
        responseCallback(@{@"AutoJSCalledOCParam":@"AutoJSCalledOC参数"});
    }];
    
    //JS调用OC方法
    //有参数的
    [_bridge registerHandler:@"JSCalledOC" handler:^(id data, WVJBResponseCallback responseCallback) {
        NSLog(@"JS 调用OC 的 JSCalledOC 方法成功，参数为：%@", data);
        //回调数据
        responseCallback(@{@"JSCalledOCResponse":@"JSCalledOC回调数据"});
    }];
    //OC调用JS方法(无回调)
    [_bridge callHandler:@"OCCalledJSNoParamNoResponse" data:nil];
    NSLog(@"OC 调用JS 的 OCCalledJSNoParamNoResponse 方法");
    
    [self callHandler:nil];
    
}

//加载网络页面
- (void)loadWebHtml:(NSString *)string {
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:string]];
    [myWebView loadRequest:request];
}

//加载本地代码
-(void)loadLocalPage:(NSString *)htmlName
{
    NSString* htmlPath = [[NSBundle mainBundle]pathForResource:htmlName ofType:@"html"];
    NSString* appHtml =[NSString stringWithContentsOfFile:htmlPath encoding:NSUTF8StringEncoding error:nil];
    NSURL *baseURL = [NSURL fileURLWithPath:htmlPath];
    [myWebView loadHTMLString:appHtml baseURL:baseURL];
}



//OC调用js方法
- (void)callHandler:(id)sender {
    id data = @{ @"OCCalledJSParam": @"OCCalledJS参数" };
    NSLog(@"OC 调用JS 的 OCCalledJS 方法");
    [_bridge callHandler:@"OCCalledJS" data:data responseCallback:^(id response) {
        NSLog(@"OC收到JS的 OCCalledJS 回调的数据: %@", response);
    }];
}






- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
