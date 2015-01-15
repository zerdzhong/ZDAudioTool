//
//  ViewController.m
//  ZDAudioTool Example
//
//  Created by zerd on 15-1-12.
//  Copyright (c) 2015年 zerd. All rights reserved.
//

#import "MainViewController.h"
#import "NewRecordController.h"
#import "ZDAudioTool.h"

#define kFilePath         [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:@"records.data"]

@interface MainViewController () <ZDAudioRecorderDelegate>

@property (weak, nonatomic) IBOutlet UIButton *recordButton;
@property (weak, nonatomic) IBOutlet UIButton *playButton;

@property (nonatomic, strong) NSMutableArray *recordTitles;
@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.tableView.tableFooterView = [UIView new];
    self.recordTitles = [NSKeyedUnarchiver unarchiveObjectWithFile:kFilePath];
    if (self.recordTitles == nil) {
        self.recordTitles = [NSMutableArray array];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onAddItemClicked:(id)sender {
    NewRecordController *newRecordVC = [[NewRecordController alloc]init];
    
    __unsafe_unretained MainViewController *main = self;
    
    newRecordVC.completionBlock = ^(NSString *title) {
        [self addRecordTitlesObject:title];
        [main.tableView reloadData];
    };
    
    UINavigationController *nav = [[UINavigationController alloc]initWithRootViewController:newRecordVC];
    nav.modalPresentationStyle = UIModalPresentationFormSheet;
    
    [self presentViewController:nav animated:YES completion:nil];
}

#pragma mark- delegate
-(void)onRecordBuffer:(const void *)buffer bufferSize:(int)size{

}

- (void)onRecordPower:(float)power{
    NSLog(@"AveragePower:%f",power);
}


#pragma mark- UITableViewDelegate
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [_recordTitles count];
}

-(CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 100;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *cellIden = @"myCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIden forIndexPath:indexPath];
    
    //    if (cell == nil) {
    //        cell = [[TableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIden];
    //    }
    //
    
    cell.textLabel.text = [_recordTitles objectAtIndex:indexPath.row];
    
    return cell;
}

#pragma mark- KVO
-(void)insertObject:(NSString *)object inRecordTitlesAtIndex:(NSUInteger)index{
    [_recordTitles insertObject:object atIndex:index];
    [NSKeyedArchiver archiveRootObject:_recordTitles toFile:kFilePath];
}

-(void)removeObjectFromRecordTitlesAtIndex:(NSUInteger)index{
    [_recordTitles removeObjectAtIndex:index];
    [NSKeyedArchiver archiveRootObject:_recordTitles toFile:kFilePath];
}

-(void)addRecordTitlesObject:(NSString *)object{
    [_recordTitles addObject:object];
    [NSKeyedArchiver archiveRootObject:_recordTitles toFile:kFilePath];
}


@end
