//
//  InformatinoViewController.m
//  Oritsubushi
//
//  Created by 泉美 米沢 on 11/11/28.
//  Copyright (c) 2011年 合資会社ダブルエスエフ. All rights reserved.
//

#import "InformationViewController.h"
#import "LoadingView.h"
#import "Consts.h"
#import "AppDelegate.h"

@interface InformationViewController () 

@property(nonatomic,strong) UIWebView *webView;
@property(nonatomic,strong) LoadingView *loadingView;

+ (void)showLoadingError:(NSString *)errorMessage;
- (void)load;

@end

@implementation InformationViewController

@synthesize webView = WebView_;
@synthesize loadingView = loadingView_;

- (id)init
{
    self = [super init];
    if (self) {
        self.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"お知らせ", nil) image:[UIImage imageNamed:@"tabicon_information"] tag:0];
        self.title = NSLocalizedString(@"お知らせ", nil);
    }
    return self;
}

- (void)dealloc
{
    self.webView = nil;
    self.loadingView = nil;
}


- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)loadView
{
    [super loadView];
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    CGRect frame = appDelegate.window.frame;
    self.view = [[UIView alloc] initWithFrame:frame];
    self.webView = [[UIWebView alloc] initWithFrame:frame];
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.webView.delegate = self;
    self.webView.scalesPageToFit = YES;
    [self.view addSubview:self.webView];
    self.loadingView = [[LoadingView alloc] initWithFrame:frame];
    self.loadingView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:self.loadingView];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(load)];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"about:blank"]]];    
}

- (void)viewWillAppear:(BOOL)animated
{
    [self load];
    [super viewWillAppear:animated];
    BOOL os6 = ((AppDelegate *)[UIApplication sharedApplication].delegate).osVersion < 7;
    if(os6) {
        self.navigationController.navigationBar.translucent = NO;
        self.navigationController.toolbar.translucent = NO;
    }
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [self.navigationController setToolbarHidden:YES animated:animated];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    self.webView = nil;
    self.loadingView = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    self.loadingView.hidden = NO;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView_
{
    self.loadingView.hidden = YES;
}

- (void)webView:(UIWebView*)webView didFailLoadWithError:(NSError *)error
{
    self.loadingView.hidden = YES;
    [InformationViewController showLoadingError:[error localizedDescription]];
}

+ (void)showLoadingError:(NSString *)errorMessage
{
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    [appDelegate showAlertViewWithTitle:NSLocalizedString(@"エラー", nil) message:errorMessage buttonTitle:nil];
}

- (void)load
{
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:INFORMATION_URL]]];    
}

- (BOOL)webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSString *URLString = [[request URL] absoluteString];
    if([URLString isEqualToString:INFORMATION_URL] || [URLString isEqualToString:@"about:blank"]
       || [URLString rangeOfString:@"/twitter.com/i/jot"].location != NSNotFound
       || [URLString rangeOfString:@"/platform.twitter.com/widgets/"].location != NSNotFound
        || [URLString rangeOfString:@"/platform.twitter.com/jot.html"].location != NSNotFound) {
        return YES;
    } else {
        [[UIApplication sharedApplication] openURL:[request URL]];
        return NO;
    }
}


@end
