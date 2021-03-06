//
//  NumberOfIconsViewController.h
//  Oritsubushi
//
//  Created by 泉美 米沢 on 11/11/23.
//  Copyright (c) 2011年 合資会社ダブルエスエフ. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NumberOfIconsViewController : UITableViewController

@property(nonatomic) NSInteger numberOfIcons;

+ (NSString *)labelWithValue:(NSInteger)value;
- (id)initWithNumberOfIcons:(NSInteger)numberOfIcons;

@end
