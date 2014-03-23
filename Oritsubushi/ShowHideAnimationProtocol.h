//
//  ShowHideAnimationProtocol.h
//  Oritsubushi
//
//  Created by 泉美 米沢 on 11/12/03.
//  Copyright (c) 2011年 合資会社ダブルエスエフ. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ShowHideAnimationProtocol <NSObject>

- (void)prepareAnimationWithShowing:(BOOL)showing;
- (void)setAnimationWithShowing:(BOOL)showing;
- (void)finishAnimationWithShowing:(BOOL)showing;

@end
