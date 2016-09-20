//
//  XLResumeHelper.m
//  XLResumeTest
//
//  Created by 邓西亮 on 16/9/8.
//  Copyright © 2016年 dxl. All rights reserved.
//

#import "XLResumeHelper.h"

typedef void (^completionBlock)();
typedef void (^progressBlock)();

@interface XLResumeHelper ()<NSURLSessionDelegate,NSURLSessionTaskDelegate>


@property (nonatomic, strong) NSURLSession *session;    //注意一个session只能有一个请求任务
@property(nonatomic, readwrite, retain) NSError *error; //请求出错
@property(nonatomic, readwrite, copy) completionBlock completionBlock;
@property(nonatomic, readwrite, copy) progressBlock progressBlock;

@property (nonatomic, strong) NSURL *url;           //文件资源地址
@property (nonatomic, strong) NSString *filePath; //文件存放路径
@property (nonatomic, assign) float totalContentLength;             //文件总大小
@property (nonatomic, assign) float totalReceivedContentLength;     //已下载大小

@property (nonatomic, strong) NSFileHandle *fileHandle;
@property (nonatomic, strong) NSFileManager *fileManager;


@end

@implementation XLResumeHelper

+ (XLResumeHelper *)shareManager
{
    static XLResumeHelper *manager = nil;
    static dispatch_once_t onec;
    dispatch_once(&onec, ^{
        manager = [[[self class] alloc] init];
    });
    return manager;
}

- (NSFileHandle *)fileHandle
{
    if (!_fileHandle) {
        _fileHandle = [NSFileHandle fileHandleForUpdatingAtPath:self.filePath];
    }
    return _fileHandle;
}

- (NSFileManager *)fileManager
{
    if (!_fileManager) {
        _fileManager = [NSFileManager new];
    }
    return _fileManager;
}

- (void)downloadFileWithUrl:(NSURL *)url
                     toPath:(NSString *)path
                   progress:(void(^)())progress
                    success:(void(^)())success
                     failed:(void(^)())failed
{
    self.url = url;
    self.filePath = path;
    [self setCompletionBlockWithSuccess:success failure:failed];
    [self setProgressBlockWithProgress:progress];
    self.totalContentLength = 0;
    self.totalReceivedContentLength = 0;
}

#pragma mark -- 成功失败的block
/**
 *  设置成功、失败回调block
 *
 *  @param success 成功回调block
 *  @param failure 失败回调block
 */
- (void)setCompletionBlockWithSuccess:(void (^)())success
                              failure:(void (^)(NSError *error))failure{
    
    __weak typeof(self) weakSelf = self;
    self.completionBlock = ^ {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (weakSelf.error) {
                if (failure) {
                    failure(weakSelf.error);
                }
            } else {
                if (success) {
                    success();
                }
            }
            
        });
    };
}

/**
 *  设置进度回调block
 *
 *  @param progress
 */
-(void)setProgressBlockWithProgress:(void (^)())progress{
    
    __weak typeof(self) weakSelf = self;
    self.progressBlock = ^{
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            float percent = weakSelf.totalReceivedContentLength / weakSelf.totalContentLength;
            percent =  percent * 100;
            NSInteger percentInteger = percent;
            progress(percentInteger);
        });
    };
}

#pragma mark -- 获取文件大小

/**
 *  获取文件大小
 *  @param path 文件路径
 *  @return 文件大小
 *
 */
- (long long)fileSizeForPath:(NSString *)path {
    
    long long fileSize = 0;
//    self.fileManager = [NSFileManager new]; // not thread safe
    if ([self.fileManager fileExistsAtPath:path]) {
        NSError *error = nil;
        NSDictionary *fileDict = [self.fileManager attributesOfItemAtPath:path error:&error];
        if (!error && fileDict) {
            fileSize = [fileDict fileSize];
        }
    }
    return fileSize;
}




#pragma mark -- NSURLSessionDelegate

/**
 *  session失效
 */
- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(nullable NSError *)error{
    
    NSLog(@"失效了");
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error{
    
    NSLog(@"完成下载");
    
    if (error == nil && self.error == nil) {
        
        self.completionBlock();
        
    }else if (error != nil){
        
        if (error.code != -999) {
            
            self.error = error;
            self.completionBlock();
        }
        
    }else if (self.error != nil){
        
        self.completionBlock();
    }
    
    
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data{
    
    //根据status code的不同，做相应的处理
    NSHTTPURLResponse *response = (NSHTTPURLResponse*)dataTask.response;
    if (response.statusCode == 200) {
        
        self.totalContentLength = dataTask.countOfBytesExpectedToReceive;
        
    }else if (response.statusCode == 206){
        
        NSString *contentRange = [response.allHeaderFields valueForKey:@"Content-Range"];
        if ([contentRange hasPrefix:@"bytes"]) {
            NSArray *bytes = [contentRange componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" -/"]];
            if ([bytes count] == 4) {
                self.totalContentLength = [[bytes objectAtIndex:3] longLongValue];
            }
        }
    }else if (response.statusCode == 416){
        
        NSString *contentRange = [response.allHeaderFields valueForKey:@"Content-Range"];
        if ([contentRange hasPrefix:@"bytes"]) {
            NSArray *bytes = [contentRange componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" -/"]];
            if ([bytes count] == 3) {
                
                self.totalContentLength = [[bytes objectAtIndex:2] longLongValue];
                if (self.totalReceivedContentLength == self.totalContentLength) {
                    
                    //更新进度（已经完成）
                    self.progressBlock();
                }else{
                    
                    self.error = [[NSError alloc]initWithDomain:[self.url absoluteString] code:416 userInfo:response.allHeaderFields];
                }
            }
        }
        return;
    }else{
        
        //其他情况还没发现
        return;
    }
    
   
    //向文件追加数据
    [self.fileHandle seekToEndOfFile]; //将节点跳到文件的末尾
    [self.fileHandle writeData:data];//追加写入数据
    
    
    //更新进度
    self.totalReceivedContentLength += data.length;
    self.progressBlock();
}

#pragma mark -- 操作
/**
 *  重新下载
 */
- (void)reload
{
    [self deleteflie];
    [self start];
}

/**
 *  删除文件
 */
- (void)deleteflie
{
    NSFileManager * fileManager = [[NSFileManager alloc]init];
    [fileManager removeItemAtPath:self.filePath error:nil];
}

/**
 *  启动断点续传下载请求
 */
-(void)start{
    
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc]initWithURL:self.url];
    
    long long downloadedBytes = self.totalReceivedContentLength = [self fileSizeForPath:self.filePath];
    if (downloadedBytes > 0) {
    
        NSString *requestRange = [NSString stringWithFormat:@"bytes=%llu-", downloadedBytes];
        [request setValue:requestRange forHTTPHeaderField:@"Range"];
    }
    else{
        //打开文件
        int fileDescriptor = open([self.filePath UTF8String], O_CREAT | O_EXCL | O_RDWR, 0666);
        if (fileDescriptor > 0) {
            close(fileDescriptor);
        }
    }

    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSOperationQueue *queue = [[NSOperationQueue alloc]init];
    self.session = [NSURLSession sessionWithConfiguration:sessionConfiguration delegate:self delegateQueue:queue];
    
    NSURLSessionDataTask *dataTask = [self.session dataTaskWithRequest:request];
    [dataTask resume];
}


/**
 *  取消断点续传下载请求
 */
-(void)cancel{
    
    if (self.session) {
        
        [self.session invalidateAndCancel];
        self.session = nil;
    }
}


@end
