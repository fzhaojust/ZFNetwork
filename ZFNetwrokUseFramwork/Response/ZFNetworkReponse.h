//
//  ZFNetworkReponse.h
//  ZFNetworkDemo
//
//  Created by ZhaoFei on 2024/5/30.
//

#import <Foundation/Foundation.h>
#import "ZFNetworkDefine.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZFNetworkReponse : NSObject

@property (nonatomic, strong, nullable) id responseObject;
@property (nonatomic, strong, readonly, nullable) NSError *error;
@property (nonatomic, strong, readonly, nullable) NSURLSessionTask *sessionTask;
@property (nonatomic, strong, readonly, nullable) NSHTTPURLResponse *URLResponse;

+ (instancetype)responseWithSessionTask:(nullable NSURLSessionTask *)sessionTask
                         responseObject:(nullable id)responseObject
                                  error:(nullable NSError *)error;

@end

NS_ASSUME_NONNULL_END
