//
//  CompletionViewController.h
//  Oritsubushi
//
//  Created by 泉美 米沢 on 11/12/01.
//  Copyright (c) 2011年 合資会社ダブルエスエフ. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Station;

@interface CompletionViewController : UIViewController<UITableViewDelegate, UITableViewDataSource, UIPickerViewDelegate, UIPickerViewDataSource>

@property(nonatomic,strong) IBOutlet UITableView *tableView;
@property(nonatomic,strong) IBOutlet UIPickerView *pickerView;
@property(nonatomic,strong) IBOutlet UITableViewCell *compCell;
@property(nonatomic,strong) IBOutlet UILabel *compLabel;
@property(nonatomic,strong) IBOutlet UISwitch *compSwitch;
@property(nonatomic,strong) IBOutlet UILabel *titleLabel;
@property(nonatomic,strong) Station *station;

- (id)initWithStation:(Station *)station;
- (IBAction)valueDidChange;

@end
