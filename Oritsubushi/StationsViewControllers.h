//
//  StationsViewControllers.h
//  Oritsubushi
//
//  Created by 泉美 米沢 on 11/12/02.
//  Copyright (c) 2011年 合資会社ダブルエスエフ. All rights reserved.
//

#import "GroupsViewController.h"

@interface StationsViewControllerBase : GroupsViewController
@end

@interface StationsViewController : StationsViewControllerBase
@end

@interface PrefStationsViewController : StationsViewControllerBase
@end

@interface YomiStationsViewController : StationsViewControllerBase
@end

@interface CompletionDateStationsViewController : StationsViewControllerBase
@end