//
//  ProgressButtion.h
//  EnglishWeekly
//
//  Created by zhuxiang on 14-7-3.
//  Copyright (c) 2014年 iflytek. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ProgressButtion : UIButton

@property (nonatomic, retain) CAShapeLayer *shapeLayer;

-(void)initProgress;
-(void)drawProgress:(float)progress;
-(void)resetProgress;
-(void)stopProgress;

@end
