//
//  MapView.m
//  Oritsubushi
//
//  Created by 泉美 米沢 on 11/10/30.
//  Copyright (c) 2011年 合資会社ダブルエスエフ. All rights reserved.
//

#import "MapView.h"

@implementation MapView

- (void)wasTappedSingly:(id)sender
{
    [(id<MapViewDelegate>)self.delegate mapViewWasSingleTapped:self];
}

- (void)prepareGestureRecognizer
{
    UITapGestureRecognizer *doubleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:nil action:nil];
    doubleTapGestureRecognizer.delegate = self;
    doubleTapGestureRecognizer.numberOfTapsRequired = 2;
    [self addGestureRecognizer:doubleTapGestureRecognizer];
    UITapGestureRecognizer *singleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(wasTappedSingly:)];
    singleTapGestureRecognizer.delegate = self;
    singleTapGestureRecognizer.numberOfTapsRequired = 1;
    [self addGestureRecognizer:singleTapGestureRecognizer];
    [singleTapGestureRecognizer requireGestureRecognizerToFail:doubleTapGestureRecognizer];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self) {
        [self prepareGestureRecognizer];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if(self) {
        [self prepareGestureRecognizer];
    }
    return self;
}


@end
