//
//  NetworkTestViewController.m
//  ZFNetworkDemo
//
//  Created by ZhaoFei on 2024/5/30.
//

#import "NetworkTestViewController.h"
#import "DefaultServerRequest.h"

@interface NetworkTestViewController () <ZFResponseDelegate>
@property (nonatomic, strong) DefaultServerRequest *request;
@end

@implementation NetworkTestViewController

- (void)dealloc
{
    if (_request) [_request cancel];
    
}
- (instancetype)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    [@[@"调用接口A", @"调用接口B"] enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
        button.bounds = CGRectMake(0, 0, 300, 100);
        button.center = CGPointMake(self.view.center.x, 200 + 100 * (idx + 1));
        button.tag = idx;
        button.titleLabel.font = [UIFont boldSystemFontOfSize:30];
        [button setTitle:obj forState:UIControlStateNormal];
        [button addTarget:self action:@selector(clickButton:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:button];
    }];
}

- (void)clickButton:(UIButton *)button {
    if (button.tag == 0) {
        [self searchA];
    } else {
        [self searchB];
    }
}


- (void)searchA
{
    DefaultServerRequest *request = [DefaultServerRequest new];
    request.cacheHandler.writeMode = CacheWriteModeMemoryAndDisk;
    request.cacheHandler.readMode = CacheReadModeCancelNetwork;
    request.requestMethod = RequestMethodGET;
    request.requestURL = @"charconvert/change.from";
    request.requestParameter = @{@"key":@"0e27c575047e83b407ff9e517cde9c76", @"type":@"2", @"text":@"呵呵呵呵"};
    __weak typeof(self) weakSelf = self;
    [request startWithsuccess:^(ZFNetworkReponse * _Nonnull response) {
            __strong typeof(weakSelf) self = weakSelf;
            if (!self) return;
        NSLog(@"success: %@", response.responseObject);
        } failure:^(ZFNetworkReponse * _Nonnull response) {
            __strong typeof(weakSelf) self = weakSelf;
            if (!self) return;
            NSLog(@"failure: %@", @(response.errorType));
        }];
    
}

- (void)searchB
{
    [self.request start];
}

#pragma mark - zfdelegate

- (void)request:(__kindof ZFBaseRequest *)request successWithResponse:(ZFNetworkReponse *)response
{
    NSLog(@"\nresponse success : %@", response.responseObject);
}

- (void)request:(__kindof ZFBaseRequest *)request failureWithResponse:(ZFNetworkReponse *)response
{
    NSLog(@"\nresponse failure : 类型 : %@", @(response.errorType));
}

#pragma mark - getter
- (DefaultServerRequest *)request
{
    if (!_request) {
        _request = [DefaultServerRequest new];
        _request.delegate = self;
        _request.requestMethod = RequestMethodGET;
        _request.requestURL = @"charconvert/change.from";
        _request.requestParameter = @{@"key":@"0e27c575047e83b407ff9e517cde9c76", @"type":@"2", @"text":@"哈哈哈哈"};
        _request.repeatStrategy = RepeatStratetyCancelOldest;
    }
    return _request;
}

@end
