//
//  SyncViewController.m
//  Oritsubushi
//
//  Created by 泉美 米沢 on 11/12/06.
//  Copyright (c) 2011年 合資会社ダブルエスエフ. All rights reserved.
//

#import "SyncViewController.h"
#import "AppDelegate.h"
#import "Misc.h"
#import "NSFileHandle+TextReader.h"
#import "NSString+CountSubstrings.h"
#import "Consts.h"
#import "Settings.h"

typedef enum {
    HeaderViewTagTitle = 1,
    HeaderViewTagIndicator = 2,
    HeaderViewTagUserName = 3,
    HeaderViewTagStatus = 4
} HeaderViewTag;

typedef enum {
    SyncStateReady,
    SyncStateBeginAuth,
    SyncStateAuth,
    SyncStateAuthTwitter,
    SyncStateCreateUploadFile,
    SyncStateUploadFile,
    SyncStateUpdateDatabase,
    SyncStateLogout,
    SyncStateLogoutDone,
    SyncStateDone,
    SyncStateCancel,
    SyncStateFail,
} SyncState;

static NSString *UploadFileName = @"upload.txt";
static NSString *DownloadFileName = @"download.sql";
static NSString *SyncURL = @"http://oritsubushi.net/oritsubushi/sync.php";
static NSString *UsersURL = @"http://oritsubushi.net/users.php";
static NSString *LogoutURL = @"http://oritsubushi.net/users.php?mode=logout";
static NSString *OritsubushiHost = @"oritsubushi.net";
static NSString *OritsubushiSiteURL = @"http://oritsubushi.net/";
static NSString *UpdateDateHeader = @"X-Oritsubushi-Updated";

/*
@interface HtmlLoader

- (void)loadWithRequest:(NSURLRequest *)request;
- (void)

@end

@implementation HtmlLoader

@end
*/

@interface SyncViewController () {
    dispatch_queue_t queue;
    SyncState state;
    NSInteger recentUpdateDate;
    NSInteger newUpdateDate;
}

@property(nonatomic,strong) NSString *userName;
@property(nonatomic,strong) NSString *userName_;
@property(nonatomic,strong) ASIHTTPRequest *request;
@property(nonatomic,strong) ASIHTTPRequest *request_;

- (void)setLabelString:(NSString *)string tag:(HeaderViewTag)tag;
- (void)startStopIndicator:(BOOL)start;
- (void)setReady;
- (void)writeUploadFile;
- (void)authWithErrorMessage:(NSString *)errorMessage;
- (void)cancel;
- (void)logout;
- (void)currentLocaleDidChange:(NSNotification *)notification;
- (NSString *)dateString;

@end

@implementation SyncViewController

@synthesize headerView;
@synthesize webView = webView_;
@synthesize startButton;
@synthesize logoutButton;
@synthesize resetButton;
@synthesize userName_;
@synthesize request_;

- (id)init
{
    self = [super initWithNibName:@"SyncViewController7" bundle:nil];
    if (self) {
        self.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"同期", nil) image:[UIImage imageNamed:@"tabicon_sync"] tag:0];
        self.title = NSLocalizedString(@"同期", nil);
    }
    return self;
}

- (void)dealloc
{
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    if(queue) {
        //dispatch_release(queue);
        queue = nil;
    }
    NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
    [center removeObserver:self];
    self.headerView = nil;
    self.webView = nil;
    self.startButton = nil;
    self.logoutButton = nil;
    self.userName = nil;
    self.request = nil;    
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    queue = dispatch_queue_create("com.wsf-lp.oritsubushi.sync", NULL);
    NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(currentLocaleDidChange:) name:NSCurrentLocaleDidChangeNotification object:nil];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    if(queue) {
        //dispatch_release(queue);
        queue = nil;
    }
    NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
    [center removeObserver:self];
    self.headerView = nil;
    self.webView = nil;
    self.startButton = nil;
    self.logoutButton = nil;
    self.userName = nil;
    self.request = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.translucent = NO;
    self.navigationController.toolbar.translucent = NO;
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [self.navigationController setToolbarHidden:YES animated:animated];
    state = SyncStateReady;
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    recentUpdateDate = [userDefaults integerForKey:SETTINGS_KEY_RECENT_UPDATED_DATE];
    self.userName = [userDefaults stringForKey:SETTINGS_KEY_SERVER_USER_NAME];
    [self setReady];
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    switch(state) {
        case SyncStateReady:
        case SyncStateDone:
        case SyncStateCancel:
        case SyncStateFail:
            break;            
        default:
        {
            AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
            [appDelegate showAlertViewWithTitle:nil message:NSLocalizedString(@"同期は中断されました", nil) buttonTitle:nil viewController:self];
            [self.request cancel];
            break;
        }
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)currentLocaleDidChange:(NSNotification *)notification
{
    switch(state) {
        case SyncStateReady:
        case SyncStateDone:
        case SyncStateFail:
        case SyncStateCancel:
            [self setReady];
            break;
        default:
            break;
    }
}

#
- (void)setLabelString:(NSString *)string tag:(HeaderViewTag)tag
{
    switch(tag) {
        case HeaderViewTagUserName:
            [(UILabel *)[self.headerView viewWithTag:tag] setText:[string length] ? [NSString stringWithFormat:NSLocalizedString(@"%@ でログイン中", nil), string] : nil];
            break;
        default:
            [(UILabel *)[self.headerView viewWithTag:tag] setText:string];
            break;
    }
}

- (void)startStopIndicator:(BOOL)start
{
    UIActivityIndicatorView *indicator = (UIActivityIndicatorView *)[self.headerView viewWithTag:HeaderViewTagIndicator];
    start ? [indicator startAnimating] : [indicator stopAnimating];
}

- (void)showHideWebView:(BOOL)show
{
    self.headerView.hidden = show;
    self.webView.hidden = !show;
}

- (void)cancel
{
    state = SyncStateCancel;
    [self.request cancel];
    [self setReady];
}

- (void)buttonDidClick:(id)sender
{
    if(sender == self.startButton) {
        [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)] animated:NO];
        self.startButton.hidden = YES;
        self.logoutButton.hidden = YES;
        self.resetButton.hidden = YES;
        [self.headerView viewWithTag:HeaderViewTagStatus].hidden = YES;
        [self startStopIndicator:YES];
        [self authWithErrorMessage:nil];
    } else if(sender == self.logoutButton) {
        self.startButton.hidden = YES;
        self.logoutButton.hidden = YES;
        self.resetButton.hidden = YES;
        [self logout];
    } else if(sender == self.resetButton) {
        newUpdateDate = recentUpdateDate = 0;
        [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithInt:0] forKey:SETTINGS_KEY_RECENT_UPDATED_DATE];
        state = SyncStateReady;
        [self setReady];
    }
}

- (void)authWithErrorMessage:(NSString *)errorMessage
{
    [self setLabelString:NSLocalizedString(@"サーバー接続中", nil) tag:HeaderViewTagTitle];
    state = SyncStateBeginAuth;
    [self startStopIndicator:YES];
    NSMutableString *URLString = [NSMutableString stringWithString:SyncURL];
    if(errorMessage) {
        [URLString appendFormat:@"?msg=%@", [Misc URLEncode:errorMessage]];
    }
    self.request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:URLString]];
    [self.request startAsynchronous];
}

- (void)logout
{
    [self.request cancel];
    [self setLabelString:NSLocalizedString(@"サーバー接続中", nil) tag:HeaderViewTagTitle];
    state = SyncStateLogout;
    [self startStopIndicator:YES];
    self.request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:LogoutURL]];
    [self.request startAsynchronous];
}

- (void)writeUploadFile
{
    Database *database = ((AppDelegate *)[UIApplication sharedApplication].delegate).database;
    NSInteger updateDate = recentUpdateDate;
    state = SyncStateCreateUploadFile;
    [self setLabelString:NSLocalizedString(@"アップロードデータ作成中", nil) tag:HeaderViewTagTitle];
    [self startStopIndicator:YES];
    dispatch_async(queue, ^{
        NSString* tempDir = NSTemporaryDirectory();
        NSString* filePath = [tempDir stringByAppendingPathComponent:UploadFileName];
        //NSLog(@"temporary file %@", filePath);
        NSFileManager* fileManager = [NSFileManager defaultManager];
        if(![fileManager fileExistsAtPath:filePath]) {
            [fileManager createFileAtPath:filePath contents:[NSData data] attributes:nil];
        }
        NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:filePath];
        [handle truncateFileAtOffset:0];
        [database writeSyncFileWithHandle:handle recentUpdateDate:updateDate];
        [handle closeFile];
        [self performSelectorOnMainThread:@selector(uploadFile) withObject:nil waitUntilDone:NO];
    });
}

- (void)uploadFile
{
    Database *database = ((AppDelegate *)[UIApplication sharedApplication].delegate).database;
    NSInteger version = [database userVersion];
    state = SyncStateUploadFile;
    [self setLabelString:NSLocalizedString(@"データアップロード中", nil) tag:HeaderViewTagTitle];
    ASIFormDataRequest *request =[ASIFormDataRequest requestWithURL:[NSURL URLWithString:SyncURL]];
    [request setPostValue:[NSString stringWithFormat:@"%d", (int)recentUpdateDate] forKey:@"d"];
    [request setPostValue:[NSString stringWithFormat:@"%d", (int)version] forKey:@"v"];
    NSString *tempDir = NSTemporaryDirectory();
    [request setFile:[tempDir stringByAppendingPathComponent:UploadFileName] forKey:@"f"];
    NSString *downloadFilePath = [tempDir stringByAppendingPathComponent:DownloadFileName];
    NSFileManager* fileManager = [NSFileManager defaultManager];
    if([fileManager fileExistsAtPath:downloadFilePath]) {
        [fileManager removeItemAtPath:downloadFilePath error:NULL];
    }
    [request setDownloadDestinationPath:downloadFilePath];
    self.request = request;
    [self.request startAsynchronous];
}

- (void)updateDatabase
{
    Database *database = ((AppDelegate *)[UIApplication sharedApplication].delegate).database;
    state = SyncStateUpdateDatabase;
    [self setLabelString:NSLocalizedString(@"データベース更新中", nil) tag:HeaderViewTagTitle];
    [self startStopIndicator:YES];
    dispatch_async(queue, ^{
        NSString* tempDir = NSTemporaryDirectory();
        NSString* filePath = [tempDir stringByAppendingPathComponent:DownloadFileName];
        NSFileManager* fileManager = [NSFileManager defaultManager];
        if([fileManager fileExistsAtPath:filePath] && ![database reloadDatabaseWithSQLFilePath:filePath]) {
            filePath = nil;
        }
        [self performSelectorOnMainThread:@selector(finalUpdating:) withObject:filePath waitUntilDone:NO];
    });
}

- (void)finalUpdating:(NSString *)succeeded
{
    state = succeeded ? SyncStateDone : SyncStateFail;
    [self setReady];
}

- (BOOL)testAuthed
{
    for(NSHTTPCookie *cookie in [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[NSURL URLWithString:OritsubushiSiteURL]]) {
        if([cookie.name isEqualToString:@"geeklog"] && [cookie.value integerValue] > 1) {
            return YES;
        }
    }
    return NO;
}

- (void)requestFinished:(ASIHTTPRequest *)request
{
    //NSLog(@"response %@", request.url);
    //NSLog(@"%@", [request responseString]);
    BOOL login = [self testAuthed];
    if(login) {
        [self startStopIndicator:NO];
        [self showHideWebView:NO];
        switch(state) {
            case SyncStateBeginAuth:
                self.userName = request.responseString;
                [self writeUploadFile];
                break;
            case SyncStateAuth:
            case SyncStateAuthTwitter:
                [self authWithErrorMessage:nil];
                break;
            case SyncStateCreateUploadFile:
                [self uploadFile];
                break;
            case SyncStateUploadFile:
                newUpdateDate = [[[request responseHeaders] objectForKey:UpdateDateHeader] intValue];
                [self updateDatabase];
                break;
            default:
                ;
        }
    } else {
        switch(state) {
            case SyncStateLogout:
                //ログアウト成功
                state = SyncStateLogoutDone;
                self.userName = nil;
                [self setReady];
                break;
            case SyncStateAuth:
                //ログイン入力後のPOSTで認証不成立
                [self performSelector:@selector(authWithErrorMessage:) withObject:NSLocalizedString(@"ログインに失敗しました。", nil) afterDelay:0];
                break;
            default:
                //ログイン画面か、またはリダイレクトでtwitter.comのアプリ認証画面
                [self.webView loadHTMLString:request.responseString baseURL:request.url];
                break;
        }
    }
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
    state = SyncStateFail;
    [self.request cancel];
    [self setReady];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    if([self testAuthed]) {
        switch(state) {
            case SyncStateAuth:
            case SyncStateAuthTwitter:
                //NSLog(@"webViewDidFinishLoad %@ / state:%d", webView.request.URL.absoluteURL, state);
                [self performSelector:@selector(authWithErrorMessage:) withObject:nil afterDelay:0];
                break;
            default:
                break;
        }
    } else {
        [self startStopIndicator:NO];
        [self showHideWebView:YES];
    }
}

- (void)postRequestWithNSURLRequest:(NSURLRequest *)request
{
    self.request = [[ASIHTTPRequest alloc] initWithURL:request.URL];
    self.request.requestMethod = @"POST";
    [self.request appendPostData:request.HTTPBody];
    [self.request addRequestHeader:@"Content-Type" value:@"application/x-www-form-urlencoded"];
    [self.request startAsynchronous];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    switch(state) {
        case SyncStateBeginAuth:
            switch(navigationType) {
                //パスワード認証もTwitter認証もここで呼ばれる
                case UIWebViewNavigationTypeFormSubmitted:
                {
                    [self showHideWebView:NO];
                    [self startStopIndicator:YES];
                    NSRange range = [request.URL.relativeString rangeOfString:@"twitter" options:NSCaseInsensitiveSearch];
                    //NSLog(@"request: %d / %@", range.length, request.URL.relativeString);
                    state = range.length ? SyncStateAuthTwitter : SyncStateAuth;
                    [self postRequestWithNSURLRequest:request];
                    return NO;
                    //return YES;
                case UIWebViewNavigationTypeLinkClicked:
                    [[UIApplication sharedApplication] openURL:request.URL];
                    return NO;
                //文字列からのロードはここを通る
                case UIWebViewNavigationTypeOther:
                    return YES;
                default:
                    return NO;                    
                }
            }
        case SyncStateAuthTwitter:
        {
            NSRange range = [request.URL.absoluteString rangeOfString:@"oritsubushi.net" options:NSCaseInsensitiveSearch];
            //NSLog(@"request: %d / %@", range.length, request.URL.relativeString);
            switch(navigationType) {
                case UIWebViewNavigationTypeFormSubmitted:
                    [self showHideWebView:NO];
                    [self startStopIndicator:YES];
                    [self postRequestWithNSURLRequest:request];
                    return NO;
                case UIWebViewNavigationTypeLinkClicked:
                    if(range.length) {
                        [self performSelector:@selector(authWithErrorMessage:) withObject:NSLocalizedString(@"Twitterログインがキャンセルされました", nil) afterDelay:0];
                    } else {
                        [[UIApplication sharedApplication] openURL:request.URL];                        
                    }
                    return NO;
                case UIWebViewNavigationTypeOther:
                    return YES;
                default:
                    return NO;
            }
        }
        default:
            return NO;
    }
}

- (NSString *)dateString
{
    if(recentUpdateDate) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
        return [dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:recentUpdateDate]];
    } else {
        return NSLocalizedString(@"なし", nil);
    }
}

- (void)setReady
{
    [self showHideWebView:NO];
    [self.navigationItem setRightBarButtonItem:nil animated:NO];
    [self.headerView viewWithTag:HeaderViewTagStatus].hidden = NO;
    NSString *title;
    NSString *dateFormat;
    BOOL first = NO;
    switch(state) {
        case SyncStateDone:
            recentUpdateDate = newUpdateDate;
            [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithInteger:recentUpdateDate] forKey:SETTINGS_KEY_RECENT_UPDATED_DATE];
            title = NSLocalizedString(@"降りつぶし.net と同期しました", nil);
            dateFormat = NSLocalizedString(@"同期日時: %@", nil);
            break;
        case SyncStateCancel:
            title = NSLocalizedString(@"同期はキャンセルされました", nil);
            dateFormat = NSLocalizedString(@"前回同期日時: %@", nil);
            break;
        case SyncStateFail:
            title = NSLocalizedString(@"同期中にエラーが発生しました", nil);
            dateFormat = NSLocalizedString(@"前回同期日時: %@", nil);
            break;
        case SyncStateLogoutDone:
            title = NSLocalizedString(@"ログアウトしました", nil);
            dateFormat = NSLocalizedString(@"前回同期日時: %@", nil);
            break;
        default:
            title = NSLocalizedString(@"降りつぶし.net と同期します", nil);
            dateFormat = NSLocalizedString(@"前回同期日時: %@", nil);
            first = YES;
            break;
    }
    newUpdateDate = recentUpdateDate;
    self.resetButton.hidden = !recentUpdateDate;
    [self setLabelString:title tag:HeaderViewTagTitle];
    [self setLabelString:[NSString stringWithFormat:dateFormat, [self dateString]] tag:HeaderViewTagStatus];
    [self.startButton setTitle:first ? NSLocalizedString(@"同期を開始する", nil) : NSLocalizedString(@"改めて同期を開始する", nil) forState:UIControlStateNormal];
    self.startButton.hidden = NO;
    self.logoutButton.hidden = ![self.userName length];
    [self startStopIndicator:NO];
    state = SyncStateReady;
}

- (ASIHTTPRequest *)request
{
    return self.request_;
}

- (void)setRequest:(ASIHTTPRequest *)request
{
    [self.request_ clearDelegatesAndCancel];
    self.request_ = request;
    self.request_.delegate = self;
}

- (NSString *)userName
{
    return self.userName_;
}

- (void)setUserName:(NSString *)userName
{
    self.userName_ = userName;
    [[NSUserDefaults standardUserDefaults] setValue:userName forKey:SETTINGS_KEY_SERVER_USER_NAME];
    [self setLabelString:userName tag:HeaderViewTagUserName];
}

@end
