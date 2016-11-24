//
//  SearchBar.m
//  Oritsubushi
//
//  Created by 泉美 米沢 on 11/11/05.
//  Copyright (c) 2011年 合資会社ダブルエスエフ. All rights reserved.
//

#import "AppDelegate.h"
#import "SearchBar.h"

@implementation SearchBar

- (id)initWithFrame:(CGRect)rect
{
    self = [super initWithFrame:rect];
    if(self) {
        self.autocapitalizationType = UITextAutocapitalizationTypeNone;
        self.keyboardType = UIKeyboardTypeDefault;
        
        //iOS 5.0以下では、UITextFieldの実態はUISearchBarの子ビュー
        //iOS7ではこの処理はなくても求める動作になってる
            /*self.backgroundColor = [UIColor clearColor];
            self.tintColor = [UIColor lightGrayColor];
            for(UIView *view in self.subviews) {
                if([view isKindOfClass:[UITextField class]]) {
                    UITextField *searchBarTextField = (UITextField *)view;
                    searchBarTextField.enablesReturnKeyAutomatically = NO;
                    break;
                }
            }*/
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    //iOS5.0以下では、UIScopeBarの無いUISearchBarの最初の子ビューは背景を表している
    /*if(((AppDelegate *)[UIApplication sharedApplication].delegate).osVersion < 7) {
        [[self.subviews objectAtIndex:0] setHidden:YES];
    }*/
}

@end
