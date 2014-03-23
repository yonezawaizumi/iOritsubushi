//
//  MapWrapper.h
//  Oritsubushi
//
//  Created by 泉美 米沢 on 11/11/06.
//  Copyright (c) 2011年 合資会社ダブルエスエフ. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ShowHideAnimationProtocol.h"

@class MapWrapper;

@protocol MapWrapperTouchDelegate

- (void)mapWrapperWasTouched:(MapWrapper *)mapWrapper;

@end

@interface MapWrapper : UIView <ShowHideAnimationProtocol>

@property(nonatomic,assign) id<MapWrapperTouchDelegate> delegate;

@end
