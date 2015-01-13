//
//  NewRecordController.h
//  ZDAudioTool Example
//
//  Created by zerd on 15-1-13.
//  Copyright (c) 2015年 zerd. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^CompletionBlock)(NSString *title);

@interface NewRecordController : UIViewController

@property (nonatomic, strong) CompletionBlock completionBlock;

@end
