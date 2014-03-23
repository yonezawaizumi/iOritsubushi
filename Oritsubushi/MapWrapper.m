//
//  MapWrapper.m
//  Oritsubushi
//
//  Created by 泉美 米沢 on 11/11/06.
//  Copyright (c) 2011年 合資会社ダブルエスエフ. All rights reserved.
//

#import "MapWrapper.h"
#import "Consts.h"

@interface MapWrapper () {
    id<MapWrapperTouchDelegate> delegate_;
}

@end

@implementation MapWrapper

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.backgroundColor = MAP_WRAPPER_COLOR;
        self.hidden = YES;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if(self) {
        self.backgroundColor = MAP_WRAPPER_COLOR;
        self.hidden = YES;
    }
    return self;
}

- (id<MapWrapperTouchDelegate>)delegate
{
    return delegate_;
}

- (void)setDelegate:(id<MapWrapperTouchDelegate>)delegate
{
    delegate_ = delegate;
    self.userInteractionEnabled = delegate_ && !self.hidden;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    [delegate_ mapWrapperWasTouched:self];
}

- (void)prepareAnimationWithShowing:(BOOL)showing
{
    if(showing) {
        self.hidden = NO;
        self.alpha = 0;
    } else {
        self.userInteractionEnabled = !!delegate_;
    }
}

- (void)setAnimationWithShowing:(BOOL)showing
{
    if(showing) {
        self.alpha = MAP_WRAPPER_ALPHA;
    } else {
        self.alpha = 0;
    }
}

- (void)finishAnimationWithShowing:(BOOL)showing
{
    if(showing) {
        self.userInteractionEnabled = YES;
    } else {
        self.hidden = YES;
    }
}

@end
