//
//  ZFNetworkManager.h
//  ZFNetworkDemo
//
//  Created by ZhaoFei on 2024/5/30.
//

#import <Foundation/Foundation.h>
#import "ZFBaseRequest+Internal.h"
#import "ZFNetworkReponse.h"
#import "ZFBaseRequest.h"


NS_ASSUME_NONNULL_BEGIN

typedef void(^ZfRequestCompletionBlock)(ZFNetworkReponse *response);

@interface ZFNetworkManager : NSObject

+ (instancetype)sharedManager;

- (NSNumber *)startNetworkingWithRequest:(ZFBaseRequest *)request uploadProgress:(nullable ZFRequestProgressBlock)uploadProgress downloadProgress:(nullable ZFRequestProgressBlock)downloadProgress completion:(nullable ZfRequestCompletionBlock)completion;

- (void)cancelNetworkingWithSet:(NSSet<NSNumber *> *)set;

@end

NS_ASSUME_NONNULL_END
