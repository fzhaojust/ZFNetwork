//
//  ZFNetworkManager.m
//  ZFNetworkDemo
//
//  Created by ZhaoFei on 2024/5/30.
//

#import "ZFNetworkManager.h"
#import <pthread/pthread.h>

#define ZFNM_TASKRECORD_LOCK(...) \
pthread_mutex_lock(&self->_lock); \
__VA_ARGS__ \
pthread_mutex_unlock(&self->_lock); \

@interface ZFNetworkManager ()

@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSURLSessionTask *> *taskRecord;

@end

@implementation ZFNetworkManager {
    pthread_mutex_t _lock;
}
#pragma mark -- life cycle

- (void)dealloc
{
    pthread_mutex_destroy(&_lock);
}

+ (instancetype)sharedManager
{
    static ZFNetworkManager *manager = nil;
    static dispatch_once_t onecToken;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[ZFNetworkManager alloc] initSpecially];
    });
    return manager;
}

- (instancetype)initSpecially
{
    self = [super init];
    if (self) {
        pthread_mutex_init(&_lock, NULL);
    }
    return self;
}

#pragma mark -- public

- (void)cancelNetworkingWithSet:(NSSet<NSNumber *> *)set
{
    ZFNM_TASKRECORD_LOCK(
     [set enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, BOOL * _Nonnull stop) {
         NSURLSessionTask *task = self.taskRecord[obj];
         if (task) {
             [task cancel];
             [self.taskRecord removeObjectForKey:obj];
         }
     }];
    )
}
- (NSNumber *)startNetworkingWithRequest:(ZFBaseRequest *)request uploadProgress:(nullable ZFRequestProgressBlock)uploadProgress downloadProgress:(nullable ZFRequestProgressBlock)downloadProgress completion:(nullable ZfRequestCompletionBlock)completion
{
    
}

#pragma mark -- private

- (NSNumber *)startDownloadTaskwithManager:(AFHTTPSessionManager *)manager URLRequest:(NSURLRequest *)URLRequest downloadPath:(NSString *)downloadPath downloadProgress:(nullable ZFRequestProgressBlock)downloadProgress completion:(ZfRequestCompletionBlock)completion
{
    NSString *validDownloadPath = downloadPath.copy;
    BOOL isDirectory;
    if (![[NSFileManager defaultManager] fileExistsAtPath:validDownloadPath isDirectory:&isDirectory]) {
        isDirectory = NO;
    }
    if (isDirectory) {
        validDownloadPath = [NSString pathWithComponents:@[validDownloadPath, URLRequest.URL.lastPathComponent]];
        
    }
    if ([[NSFileManager defaultManager] fileExistsAtPath:validDownloadPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:validDownloadPath error:nil];
    }
    __block NSURLSessionDownloadTask *task = [manager downloadTaskWithRequest:URLRequest progress:downloadProgress destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        return [NSURL fileURLWithPath:validDownloadPath isDirectory:NO];
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        ZFNM_TASKRECORD_LOCK([self.taskRecord removeObjectForKey:@(task.taskIdentifier)];)
        if (completion) {
            completion([ZFNetworkReponse responseWithSessionTask:task responseObject:filePath error:error]);
        }
    }];
    NSNumber *taskIdentifier = @(task.taskIdentifier);
    ZFNM_TASKRECORD_LOCK(self.taskRecord[taskIdentifier] = task;)
    [task resume];
    return taskIdentifier;
}

- (NSNumber *)startDataTaskWithManager:(AFHTTPSessionManager *)manager URLRequest:(NSURLRequest *)URLrequest uploadProgress:(nullable ZFRequestProgressBlock)uploadProgress downloadProgress:(nullable ZFRequestProgressBlock)downloadProgress completion:(ZfRequestCompletionBlock)completion
{
    __block NSURLSessionDataTask *task = [manager dataTaskWithRequest:URLrequest uploadProgress:^(NSProgress * _Nonnull _uploadProgress) {
        if (uploadProgress) {
            uploadProgress(_uploadProgress);
        }
    } downloadProgress:^(NSProgress * _Nonnull _downloadProgress) {
        if (downloadProgress) {
            downloadProgress(_downloadProgress);
        }
    } completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        ZFNM_TASKRECORD_LOCK([self.taskRecord removeObjectForKey:@(task.taskIdentifier)];)
        if (completion) {
            completion([ZFNetworkReponse responseWithSessionTask:task responseObject:responseObject error:error]);
        }
    }];
    
    NSNumber *taskIdentifier = @(task.taskIdentifier);
    ZFNM_TASKRECORD_LOCK(self.taskRecord[taskIdentifier] = task;)
    [task resume];
    return taskIdentifier;
}

- (void)cancelTaskWithIdentifier:(NSNumber *)identifier
{
    ZFNM_TASKRECORD_LOCK(NSURLSessionTask *task = self.taskRecord[identifier];)
    if (task) {
        [task cancel];
        ZFNM_TASKRECORD_LOCK([self.taskRecord removeObjectForKey:identifier];)
    }
}

- (void)cancelAllTask
{
    ZFNM_TASKRECORD_LOCK(
     for (NSURLSessionTask *task in self.taskRecord) {
         [task cancel];
     }
     [self.taskRecord removeAllObjects];
    )
}

#pragma mark - read info from request
- (AFHTTPRequestSerializer *)requestSerializerForrequest:(ZFBaseRequest *)request
{
    AFHTTPRequestSerializer *serializer = [AFJSONRequestSerializer serializer];
    
    
    return serializer;
}
- (AFHTTPSessionManager *)sessionManagerForRequest:(ZFBaseRequest *)request
{
    AFHTTPSessionManager *manager;
    if (!manager) {
        static AFHTTPSessionManager *defaultManager = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            defaultManager = [AFHTTPSessionManager new];
        });
        manager = defaultManager;
    }
    manager.completionQueue = dispatch_queue_create("com.zfnetwork.completionblock", DISPATCH_QUEUE_CONCURRENT);
    AFHTTPResponseSerializer *customSerializer;
    if (customSerializer) {
        manager.responseSerializer = customSerializer;
    }
    return manager;
}


- (NSMutableDictionary<NSNumber *,NSURLSessionTask *> *)taskRecord
{
    if (!_taskRecord) {
        _taskRecord = [[NSMutableDictionary alloc] init];
    }
    return _taskRecord;
}

@end
