//
//  SearchScopeBar.h
//  Oritsubushi
//
//  Created by 泉美 米沢 on 11/12/03.
//  Copyright (c) 2011年 合資会社ダブルエスエフ. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DatabaseFilterTypes.h"
#import "ShowHideAnimationProtocol.h"


@interface SearchScopeBar : UIView <ShowHideAnimationProtocol>

@property(nonatomic,assign) DatabaseFilterType filterType;

@end
