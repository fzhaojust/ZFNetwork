//
//  ViewController.m
//  ZFNetworkDemo
//
//  Created by ZhaoFei on 2024/5/30.
//

#import "ViewController.h"
#import "NetworkTestViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = UIColor.whiteColor;
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.bounds = CGRectMake(0, 0, 300, 100);
    button.center = self.view.center;
    button.titleLabel.font = [UIFont boldSystemFontOfSize:30];
    [button setTitle:@"点击跳转" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(clickButton) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
   // 处理耗时操作在此次添加
        NSLog(@"子线程");
        sleep(2);
        
   //通知主线程刷新
   dispatch_async(dispatch_get_main_queue(), ^{
   //在主线程刷新UI
       NSLog(@"主线程刷新UI");
   });

   });
    
    
}

- (void)clickButton
{
//    [self.navigationController pushViewController:[[NetworkTestViewController alloc] init] animated:YES];
    [self presentViewController:[[NetworkTestViewController alloc] init] animated:YES completion:nil];
}


@end
