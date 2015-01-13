//
//  ViewController.m
//  ZDAudioTool Example
//
//  Created by zerd on 15-1-12.
//  Copyright (c) 2015年 zerd. All rights reserved.
//

#import "ViewController.h"
#import "ZDAudioTool.h"

@interface ViewController () <ZDAudioRecorderDelegate>

@property (weak, nonatomic) IBOutlet UIButton *recordButton;
@property (weak, nonatomic) IBOutlet UIButton *playButton;

@property (nonatomic, strong) ZDAudioRecorder *audioRecorder;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    _audioRecorder = [[ZDAudioRecorder alloc]init];
    _audioRecorder.delegate = self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)onRecordClicked:(id)sender {
    if ([_audioRecorder isRunning]) {
        [_audioRecorder stopRecord];
        [_recordButton setTitle:@"record" forState:UIControlStateNormal];
    }else {
        [_audioRecorder startRecord:@"test.pcm"];
        NSLog(@"%@",[NSTemporaryDirectory() stringByAppendingPathComponent:@"test.pcm"]);
        [_recordButton setTitle:@"stop" forState:UIControlStateNormal];
    }
}


#pragma mark- delegate
-(void)onRecordBuffer:(const void *)buffer bufferSize:(int)size{

}

- (void)onRecordPower:(float)power{
    NSLog(@"AveragePower:%f",power);
}

@end
