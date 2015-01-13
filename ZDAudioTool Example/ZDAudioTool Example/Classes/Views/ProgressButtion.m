//
//  ProgressButtion.m
//  EnglishWeekly
//
//  Created by zhuxiang on 14-7-3.
//  Copyright (c) 2014年 iflytek. All rights reserved.
//

#import "ProgressButtion.h"

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

@implementation ProgressButtion

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

-(void)initProgress{
    CAShapeLayer *shapeLayer = [[CAShapeLayer alloc] init];
    shapeLayer.frame = CGRectMake(0, 0, 19, 19);
    shapeLayer.fillColor = nil;
    shapeLayer.strokeColor = UIColorFromRGB(0x0e705e).CGColor;
    
    [self.layer addSublayer:shapeLayer];
    self.shapeLayer = shapeLayer;
    
    self.shapeLayer.lineWidth = 3;
    
    }

-(void)drawProgress:(float)progress{
    self.shapeLayer.path = [UIBezierPath bezierPathWithArcCenter:CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds))
                                                          radius:self.shapeLayer.bounds.size.width
                                                      startAngle:3*M_PI_2
                                                        endAngle:3*M_PI_2 + 2*M_PI
                                                       clockwise:YES].CGPath;
    if (progress == 0){
        [self.shapeLayer removeAllAnimations];
        [CATransaction setDisableActions:NO];
        self.shapeLayer.strokeEnd = progress;
    } else {
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        self.shapeLayer.strokeEnd = progress;
        [CATransaction commit];

    }
    
        if (progress == 1){
        [self stopProgress];
    } else {
        self.shapeLayer.hidden = NO;
    }

}

-(void)resetProgress{
    [self.shapeLayer removeAllAnimations];
    self.shapeLayer.strokeEnd = 0;
}

-(void)stopProgress{
    self.shapeLayer.strokeEnd = 0;
    self.shapeLayer.hidden = YES;
}

@end
