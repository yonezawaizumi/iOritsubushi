//
//  AppDelegate.h
//  Oritsubushi
//
//  Created by 泉美 米沢 on 11/10/29.
//  Copyright (c) 2011年 合資会社ダブルエスエフ. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Database.h"
#import "Settings.h"
#import <CoreLocation/CoreLocation.h>

NS_INLINE BOOL checkScreenSize (CGFloat d1, CGFloat d2) {
    CGSize nativeSize = UIScreen.mainScreen.nativeBounds.size;
    CGFloat w =  nativeSize.width;
    CGFloat h =  nativeSize.height;
    return (w == d1 && h == d2) || (w == d2 && h == d1);
}
#define IS_IPHONE           UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone
#define IS_OS_11_OR_LATER   (UIDevice.currentDevice.systemVersion.floatValue >= 11.0)
#define IS_OS_11_X_TAB_BUG  (IS_OS_11_OR_LATER && UIDevice.currentDevice.systemVersion.floatValue < 11.19)
#define IS_IPHONE_X_SIZE    checkScreenSize(1125, 2436)
#define IS_IPHONE_X         (IS_IPHONE && IS_OS_11_OR_LATER && IS_IPHONE_X_SIZE)
#define IS_IPHONE_X_TAB_BUG (IS_IPHONE_X && IS_OS_11_X_TAB_BUG)

@protocol LocationUpdatedDelegate

- (void)beginLocating:(BOOL)enabled;
- (void)locationWasUpdated:(CLLocationCoordinate2D)location;

@end

@class Station;

@interface AppDelegate : UIResponder<UIApplicationDelegate, CLLocationManagerDelegate>

@property(strong, nonatomic) UIWindow *window;
@property(nonatomic,strong,readonly) Database *database;
@property(nonatomic) id<LocationUpdatedDelegate> locationDelegate;

- (void)mapViewUpdateFilterWithFilterType:(DatabaseFilterType)type filterValue:(NSString *)value;
- (void)mapViewMoveToStation:(Station *)station;
- (void)mapViewRequestUpdate;

- (void)saveCookies;
- (void)showAlertViewWithTitle:(NSString *)title message:(NSString *)message buttonTitle:(NSString *)buttonTitle viewController:(UIViewController *)viewController;

@end
