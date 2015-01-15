//
//  ZDAudioPlayer.h
//  ZDAudioTool
//
//  Created by zerd on 15-1-15.
//  Copyright (c) 2015年 zerd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZDAudioPlayer : NSObject

- (instancetype)initWithFilePath:(NSString *)filePath;

- (void)play;

@end
