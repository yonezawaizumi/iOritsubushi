//
//  Prompt7View.m
//  Oritsubushi
//
//  Created by yonezawaizumi on 2013/09/18.
//  Copyright (c) 2013年 合資会社ダブルエスエフ. All rights reserved.
//

#import "UIImage+ImageEffects.h"
#import "Prompt7View.h"

@interface Prompt7View ()

@property(nonatomic, assign) CGPoint location;
@property(nonatomic, strong) UIView *parent;
@property(nonatomic, assign) BlurType blurType;
@property(nonatomic, strong) BLRColorComponents *colorComponents;
@property(nonatomic, strong) UIImageView *backgroundImageView;
@property(nonatomic, assign) dispatch_source_t timer;

@end

@implementation Prompt7View

- (id)initWithFrame:(CGRect)frame parent:(UIView *)parent
{
    self = [super initWithFrame:frame];
    if (self) {
        self.parent = parent;
        self.location = CGPointMake(0, 64);
        frame.origin = CGPointMake(0, 0);
        self.textLabel = [[UILabel alloc] initWithFrame:frame];
        self.backgroundImageView = [[UIImageView alloc] initWithFrame:frame];
        [self addSubview:self.backgroundImageView];
        [self addSubview:self.textLabel];
    }
    return self;
}

- (void)cancelTimer
{
    if(self.timer) {
        dispatch_source_cancel(self.timer);
        //dispatch_release(self.timer);
        self.timer = nil;
    }
}

- (void)dealloc
{
    [self cancelTimer];
    self.textLabel = nil;
    self.parent = nil;
    self.backgroundImageView = nil;
    self.colorComponents = nil;
}

- (void) blurBackground {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(CGRectGetWidth(self.parent.frame), CGRectGetHeight(self.parent.frame)), NO, 1);
    
    //Snapshot finished in 0.051982 seconds.
    [self.parent drawViewHierarchyInRect:CGRectMake(0, 0, CGRectGetWidth(self.parent.frame), CGRectGetHeight(self.parent.frame)) afterScreenUpdates:NO];
    
    __block UIImage *snapshot = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        //Blur finished in 0.004884 seconds.
        snapshot = [snapshot applyBlurWithCrop:CGRectMake(self.location.x, self.location.y, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame)) resize:CGSizeMake(CGRectGetWidth(self.frame), CGRectGetHeight(self.frame)) blurRadius:self.colorComponents.radius tintColor:self.colorComponents.tintColor saturationDeltaFactor:self.colorComponents.saturationDeltaFactor maskImage:self.colorComponents.maskImage];
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            self.backgroundImageView.image = snapshot;
        });
    });
}


- (void) blurWithColor:(BLRColorComponents *) components {
    if(self.blurType == KBlurUndefined) {
        self.blurType = KStaticBlur;
        self.colorComponents = components;
    }
    [self blurBackground];
}

- (void) blurWithColor:(BLRColorComponents *) components updateInterval:(float) interval {
    self.blurType = KLiveBlur;
    self.colorComponents = components;
    [self cancelTimer];
    self.timer = CreateDispatchTimer(interval * NSEC_PER_SEC, 1ull * NSEC_PER_SEC, dispatch_get_main_queue(), ^{[self blurWithColor:components];});
}

- (void) pauseBlur
{
    [self cancelTimer];
    [self blurBackground];
}

static dispatch_source_t CreateDispatchTimer(uint64_t interval, uint64_t leeway, dispatch_queue_t queue, dispatch_block_t block) {
    
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    
    if (timer) {
        dispatch_source_set_timer(timer, dispatch_walltime(NULL, 0), interval, leeway);
        dispatch_source_set_event_handler(timer, block);
        
        dispatch_resume(timer);
    }
    
    return timer;
}


@end

@interface BLRColorComponents()
@end

@implementation BLRColorComponents

+ (BLRColorComponents *) defaultEffect {
    BLRColorComponents *components = [[BLRColorComponents alloc] init];
    
    components.radius = 6;
    components.tintColor = [UIColor colorWithWhite:.8f alpha:.2f];
    components.saturationDeltaFactor = 1.8f;
    components.maskImage = nil;
    
    return components;
}

+ (BLRColorComponents *) lightEffect {
    BLRColorComponents *components = [[BLRColorComponents alloc] init];
    
    components.radius = 6;
    components.tintColor = [UIColor colorWithWhite:.8f alpha:.2f];
    components.saturationDeltaFactor = 1.8f;
    components.maskImage = nil;
    
    return components;
}

+ (BLRColorComponents *) darkEffect {
    BLRColorComponents *components = [[BLRColorComponents alloc] init];
    
    components.radius = 8;
    components.tintColor = [UIColor colorWithRed:0.0f green:0.0 blue:0.0f alpha:.5f];
    components.saturationDeltaFactor = 3.0f;
    components.maskImage = nil;
    
    return components;
}

+ (BLRColorComponents *) coralEffect {
    BLRColorComponents *components = [[BLRColorComponents alloc] init];
    
    components.radius = 8;
    components.tintColor = [UIColor colorWithRed:1.0f green:0.0f blue:0.0f alpha:.1f];
    components.saturationDeltaFactor = 3.0f;
    components.maskImage = nil;
    
    return components;
}

+ (BLRColorComponents *) neonEffect {
    BLRColorComponents *components = [[BLRColorComponents alloc] init];
    
    components.radius = 8;
    components.tintColor = [UIColor colorWithRed:0.0f green:1.0f blue:0.0f alpha:.1f];
    components.saturationDeltaFactor = 3.0f;
    components.maskImage = nil;
    
    return components;
}

+ (BLRColorComponents *) skyEffect {
    BLRColorComponents *components = [[BLRColorComponents alloc] init];
    
    components.radius = 8;
    components.tintColor = [UIColor colorWithRed:0.0f green:0.0f blue:1.0f alpha:.1f];
    components.saturationDeltaFactor = 3.0f;
    components.maskImage = nil;
    
    return components;
}

@end
