//
//  SyncViewController.h
//  Oritsubushi
//
//  Created by 泉美 米沢 on 11/12/06.
//  Copyright (c) 2011年 合資会社ダブルエスエフ. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ASIFormDataRequest.h"

@interface SyncViewController : UIViewController <UIWebViewDelegate, ASIHTTPRequestDelegate>

@property(nonatomic,strong) IBOutlet UIView *headerView;
@property(nonatomic,strong) IBOutlet UIButton *startButton;
@property(nonatomic,strong) IBOutlet UIButton *logoutButton;
@property(nonatomic,strong) IBOutlet UIWebView *webView;
@property(nonatomic,strong) IBOutlet UIButton *resetButton;
@property(nonatomic,strong) IBOutlet UIView *confirmView;
@property(nonatomic,strong) IBOutlet UIButton *ppConfirmButton;
@property(nonatomic,strong) IBOutlet NSLayoutConstraint *confirmViewTopConstraint;
@property(nonatomic,strong) IBOutlet UILabel *ppVersionLabel;

- (IBAction)buttonDidClick:(id)sender;
- (IBAction)ppLinkButtonDidClick:(id)sender;
- (IBAction)ppConfirmButtonDidClick:(id)sender;

@end
