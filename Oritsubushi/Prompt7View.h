//
//  Prompt7View.h
//  Oritsubushi
//
//  Created by yonezawaizumi on 2013/09/18.
//  Copyright (c) 2013年 合資会社ダブルエスエフ. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    KBlurUndefined = 0,
    KStaticBlur = 1,
    KLiveBlur = 2
} BlurType;

@class BLRColorComponents;

@interface Prompt7View : UILabel

@property(nonatomic, strong) UILabel *textLabel;

- (id) initWithFrame:(CGRect)frame parent:(UIView *)parent;
- (void) blurWithColor:(BLRColorComponents *) components;
- (void) blurWithColor:(BLRColorComponents *) components updateInterval:(float) interval;
- (void) pauseBlur;

@end

@interface BLRColorComponents : NSObject

@property(nonatomic, assign) CGFloat radius;
@property(nonatomic, strong) UIColor *tintColor;
@property(nonatomic, assign) CGFloat saturationDeltaFactor;
@property(nonatomic, strong) UIImage *maskImage;

+ (BLRColorComponents *) defaultEffect;

///Light color effect.
///
+ (BLRColorComponents *) lightEffect;

///Dark color effect.
///
+ (BLRColorComponents *) darkEffect;

///Coral color effect.
///
+ (BLRColorComponents *) coralEffect;

///Neon color effect.
///
+ (BLRColorComponents *) neonEffect;

///Sky color effect.
///
+ (BLRColorComponents *) skyEffect;

@end
