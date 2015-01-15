//
//  ZDTableViewCell.m
//  ZDAudioTool Example
//
//  Created by zerd on 15-1-14.
//  Copyright (c) 2015年 zerd. All rights reserved.
//

#import "ZDTableViewCell.h"
#import "ProgressButtion.h"
#import "ZDAudioTool.h"

@interface ZDTableViewCell () <ZDAudioRecorderDelegate>

@property (nonatomic, strong) ZDAudioRecorder *audioRecorder;
@property (nonatomic, strong) ZDAudioPlayer *audioPlayer;

@property (weak, nonatomic) IBOutlet ProgressButtion *recordButton;

@property (weak, nonatomic) IBOutlet ProgressButtion *playButton;

@end

@implementation ZDTableViewCell

- (void)awakeFromNib {
    // Initialization code
    _audioRecorder = [[ZDAudioRecorder alloc]init];
    _audioRecorder.delegate = self;
    
    [self.textLabel addObserver:self forKeyPath:@"text" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (IBAction)onRecordClicked:(id)sender {
    if (!_recordButton.selected) {
        _recordButton.selected = YES;
        [_recordButton initProgress];
        //开始录音
        NSString *filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.caf",self.textLabel.text]];
        NSLog(@"%@",filePath);
        [_audioRecorder startRecord:filePath];
    }else{
        //停止录音
        [_audioRecorder stopRecord];
        _recordButton.selected = NO;
        [self checkAudioExist];
    }
}

- (IBAction)onPlayClicked:(id)sender {
    if (_audioPlayer == nil) {
        NSString *filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.caf",self.textLabel.text]];
        _audioPlayer = [[ZDAudioPlayer alloc]initWithFilePath:filePath];
    }
    
    [_audioPlayer play];
}

#pragma ZDAudioToolDelegate

- (void)onRecordPower:(float)power{
    
    float   level;                // The linear 0.0 .. 1.0 value we need.
    float   minDecibels = -80.0f; // Or use -60dB, which I measured in a silent room.
    float   decibels    = power;
    
    if (decibels < minDecibels)
    {
        level = 0.0f;
    }
    else if (decibels >= 0.0f)
    {
        level = 1.0f;
    }
    else
    {
        float   root            = 2.0f;
        float   minAmp          = powf(10.0f, 0.05f * minDecibels);
        float   inverseAmpRange = 1.0f / (1.0f - minAmp);
        float   amp             = powf(10.0f, 0.05f * decibels);
        float   adjAmp          = (amp - minAmp) * inverseAmpRange;
        
        level = powf(adjAmp, 1.0f / root);
    }
    
    NSLog(@"%f",level);
    
    [_recordButton drawProgress:level];
    
}


- (void)checkAudioExist{
    NSString *filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.caf",self.textLabel.text]];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:filePath]) {
        _playButton.hidden = NO;
    }else{
        _playButton.hidden = YES;
    }
}

#pragma mark- KVO
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if ([keyPath isEqualToString:@"text"]) {
        [self checkAudioExist];
    }
}

- (void)dealloc
{
    [self.textLabel removeObserver:self forKeyPath:@"text"];
}

@end
