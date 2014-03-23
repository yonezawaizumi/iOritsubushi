//
//  LoadingView.m
//  Oritsubushi
//
//  Created by 泉美 米沢 on 11/12/04.
//  Copyright (c) 2011年 合資会社ダブルエスエフ. All rights reserved.
//

#import "LoadingView.h"
//#import "QuartzCore/QuartzCore.h"
#import "Consts.h"

//CGFloat version = 0;

@interface LoadingView ()

@property(nonatomic,strong) UIActivityIndicatorView *indicator;

@end

@implementation LoadingView

@synthesize indicator;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = LOADING_VIEW_COLOR;
        self.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        self.indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        /*if(!version) {
            version = [[[UIDevice currentDevice] systemVersion] floatValue];
        }
        if (version < 5) {
            indicator.frame = CGRectMake(0, 0, 50, 50);
        } else {
            indicator.color = [UIColor whiteColor];
            [indicator.layer setValue:[NSNumber numberWithFloat:1.39f] forKeyPath:@"transform.scale"];
        }*/
        [self addSubview:self.indicator];
        [super setHidden:YES];
    }
    return self;
}

- (void)dealloc
{
    self.indicator = nil;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.indicator.center = self.center;
}

- (void)setHidden:(BOOL)hidden
{
    [super setHidden:hidden];
    if(hidden) {
        [self.indicator stopAnimating];
    } else {
        [self.indicator startAnimating];
    }
}

@end
