//
//  NewRecordController.m
//  ZDAudioTool Example
//
//  Created by zerd on 15-1-13.
//  Copyright (c) 2015年 zerd. All rights reserved.
//

#import "NewRecordController.h"

@interface NewRecordController ()

@property (weak, nonatomic) IBOutlet UITextField *recordTitle;

@end

@implementation NewRecordController

- (void)viewDidLoad{
    self.title = @"新建录音";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"取消" style:UIBarButtonItemStyleDone target:self action:@selector(onCancle)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"确定" style:UIBarButtonItemStyleDone target:self action:@selector(onDoneClicked:)];
}

- (IBAction)onDoneClicked:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{
        if (_completionBlock) {
            self.completionBlock(_recordTitle.text);
        }
    }];
}

- (void)onCancle{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
