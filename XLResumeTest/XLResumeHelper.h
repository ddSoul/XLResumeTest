//
//  XLResumeHelper.h
//  XLResumeTest
//
//  Created by 邓西亮 on 16/9/8.
//  Copyright © 2016年 dxl. All rights reserved.
//

#import <Foundation/Foundation.h>



@interface XLResumeHelper : NSObject

+ (XLResumeHelper *)shareManager;

/**
 *  断点下载
 *
 *  @param url      url
 *  @param path     path
 *  @param progress progress
 *  @param success  成功结果
 *  @param failed   失败结果
 */
- (void)downloadFileWithUrl:(NSURL *)url
                     toPath:(NSString *)path
                   progress:(void(^)())progress
                    success:(void(^)())success
                     failed:(void(^)())failed;



/**
 *  启动断点续传下载请求
 */
-(void)start;

/**
 *  取消断点续传下载请求
 */
-(void)cancel;

/**
 *  重新下载
 */
- (void)reload;

/**
 *  删除文件
 */
- (void)deleteflie;

@end
