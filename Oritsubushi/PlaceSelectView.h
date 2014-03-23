//
//  PlaceSelectView.h
//  Oritsubushi
//
//  Created by 泉美 米沢 on 11/12/03.
//  Copyright (c) 2011年 合資会社ダブルエスエフ. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GoogleMapsLocation.h"

@class PlaceSelectView;

@protocol PlaceSelectViewDelegate <NSObject>

- (void)placeSelectView:(PlaceSelectView *)placeSelectView didSelected:(GoogleMapsLocation *)location atIndex:(NSInteger)index;

@end

@interface PlaceSelectView : UIAlertView < UIAlertViewDelegate, UITableViewDelegate, UITableViewDataSource >

@property(nonatomic,assign) id<PlaceSelectViewDelegate> selectDelegate;

- (id)initWithPlaceCandidates:(NSArray *)candidates delegate:(id<PlaceSelectViewDelegate>)selectDelegate;
- (void)dismiss;

@end
