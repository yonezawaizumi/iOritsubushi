//
//  MemoViewController.h
//  Oritsubushi
//
//  Created by 泉美 米沢 on 11/12/01.
//  Copyright (c) 2011年 合資会社ダブルエスエフ. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Station;

@interface MemoViewController : UITableViewController

@property(nonatomic,strong) Station *station;
@property(nonatomic,strong) IBOutlet UITableViewCell *cell;

- (id)initWithStation:(Station *)station;

@end
