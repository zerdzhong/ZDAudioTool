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

@end

@implementation ZDTableViewCell

- (void)awakeFromNib {
    // Initialization code
    _audioRecorder = [[ZDAudioRecorder alloc]init];
    _audioRecorder.delegate = self;
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
        [_audioRecorder startRecord:@"test.pcm"];
    }else{
        //停止录音
        [_audioRecorder stopRecord];
        _recordButton.selected = NO;
    }
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

@end
