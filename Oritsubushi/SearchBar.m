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
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
}

@end
