//
//  ZDAudioRecorder.h
//  ZDAudioTool
//
//  Created by zerd on 15-1-13.
//  Copyright (c) 2015年 zerd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@protocol ZDAudioRecorderDelegate <NSObject>

@optional
- (void)onRecordBuffer:(const void *)buffer bufferSize:(int)size;
- (void)onRecordPower:(float)power;

@end

@interface ZDAudioRecorder : NSObject

@property (assign, nonatomic) id<ZDAudioRecorderDelegate> delegate;

- (void)startRecord:(NSString *)fileName;
- (void)stopRecord;

- (Boolean)isRunning;

@end
