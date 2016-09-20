//
//  ResumeViewController.m
//  XLResumeTest
//
//  Created by 邓西亮 on 16/9/8.
//  Copyright © 2016年 dxl. All rights reserved.
//

#import "ResumeViewController.h"
#import "XLResumeHelper.h"

@interface ResumeViewController ()
@property (strong, nonatomic) IBOutlet UIImageView *image;
@property (strong, nonatomic) IBOutlet UIProgressView *progress;
- (IBAction)starButton:(UIButton *)sender;
- (IBAction)stopButton:(UIButton *)sender;
- (IBAction)resumeButton:(UIButton *)sender;
- (IBAction)removeButton:(UIButton *)sender;

@end

@implementation ResumeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.progress.progress = 0;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory=[paths objectAtIndex:0];//Documents目录
    NSString *path = [documentsDirectory stringByAppendingPathComponent:@"resume"];
    
    NSURL *url = [NSURL URLWithString:@"http://p1.pichost.me/i/40/1639665.png"];
    
    [[XLResumeHelper shareManager] downloadFileWithUrl:url
                                                toPath:path
                                              progress:^(NSInteger progress){
                                                  
                                                  float present = progress * 0.01;
                                                  self.progress.progress = present;
                                                  
                                              }
                                               success:^{
                                                   
                                                   self.image.image = [UIImage imageWithContentsOfFile:path];
                                                   
                                               }
                                                failed:^(NSError *error){
                                                        NSLog(@"");
                                                                            }];

    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)starButton:(UIButton *)sender {

    [[XLResumeHelper shareManager] start];
    
}

- (IBAction)stopButton:(UIButton *)sender {
    
    [[XLResumeHelper shareManager] cancel];
}

- (IBAction)resumeButton:(UIButton *)sender {
    
    self.progress.progress = 0;
    [[XLResumeHelper shareManager] reload];
    self.image.image = [UIImage imageNamed:@""];
}

- (IBAction)removeButton:(UIButton *)sender {
    
    self.progress.progress = 0;
    [[XLResumeHelper shareManager] deleteflie];
    self.image.image = [UIImage imageNamed:@""];
}
@end
