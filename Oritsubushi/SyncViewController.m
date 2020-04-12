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
static NSString *SyncURL = @"https://oritsubushi.net/oritsubushi/sync.php";
static NSString *UsersURL = @"https://oritsubushi.net/users.php";
static NSString *LogoutURL = @"https://oritsubushi.net/users.php?mode=logout";
static NSString *OritsubushiHost = @"oritsubushi.net";
static NSString *OritsubushiSiteURL = @"https://oritsubushi.net/";
static NSString *UpdateDateHeader = @"X-Oritsubushi-Updated";
static NSString *ppUrl = @"https://oritsubushi.net/staticpages/index.php/pp";

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

@property(nonatomic,strong) WKWebView *webView;

@property(nonatomic,strong) NSString *userName;
@property(nonatomic,strong) AFHTTPSessionManager *request;
@property(nonatomic,assign) NSInteger geeklogID;

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
@synthesize userName = _userName;
@synthesize request;
@synthesize geeklogID;

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

- (void)loadView
{
    [super loadView];
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    CGRect frame = appDelegate.window.frame;
    self.webView = [[WKWebView alloc] initWithFrame:frame];
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.webView.hidden = NO;
    self.webView.navigationDelegate = self;
    //self.webView.scalesPageToFit = YES;
    [self.view addSubview:self.webView];
    //[self.view bringSubviewToFront:self.webView];
}

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
    
    self.ppVersionLabel.text = [NSString stringWithFormat:NSLocalizedString(@"(%04d/%02d/%02d版)", nil), PP_VERSION / 10000, PP_VERSION / 100 % 100, PP_VERSION % 100];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self testPp];
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
            [self.request.session invalidateAndCancel];
            break;
        }
    }
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
    [self.request.session invalidateAndCancel];
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
    self.request = [AFHTTPSessionManager manager];
    self.request.responseSerializer = [AFHTTPResponseSerializer serializer];
    [self.request GET:URLString parameters:nil success:^(NSURLSessionDataTask* task, id responseObject) {
        [self requestFinished:responseObject task:task];
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        [self requestFailed:error];
    }];
}

- (void)logout
{
    [self.request.session invalidateAndCancel];
    [self setLabelString:NSLocalizedString(@"サーバー接続中", nil) tag:HeaderViewTagTitle];
    state = SyncStateLogout;
    [self startStopIndicator:YES];
    self.request = [AFHTTPSessionManager manager];
    self.request.responseSerializer = [AFHTTPResponseSerializer serializer];
    [self.request GET:LogoutURL parameters:nil success:^(NSURLSessionDataTask* task, id responseObject) {
        [self requestFinished:responseObject task:task];
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        [self requestFailed:error];
    }];
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
    self.request = [AFHTTPSessionManager manager];
    NSDictionary *params = @{
        @"d": [NSNumber numberWithInt:(int)recentUpdateDate],
        @"v": [NSNumber numberWithInt:(int)version]
    };
    NSString *tempDir = NSTemporaryDirectory();
    NSString *downloadFilePath = [tempDir stringByAppendingPathComponent:DownloadFileName];
    NSFileManager* fileManager = [NSFileManager defaultManager];
    if([fileManager fileExistsAtPath:downloadFilePath]) {
        [fileManager removeItemAtPath:downloadFilePath error:NULL];
    }
    NSOutputStream *output = [NSOutputStream outputStreamToFileAtPath:downloadFilePath append:NO];
    [output open];
    self.request.responseSerializer = [[AFHTTPResponseSerializer alloc] init];
    self.request.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"text/plain"];
    [self.request setDataTaskDidReceiveDataBlock:^(NSURLSession *session, NSURLSessionDataTask *dataTask, NSData * data) {
        [output write:[data bytes] maxLength:data.length];
    }];
    [self.request POST:SyncURL parameters:params constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        NSString *filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:UploadFileName];
        [formData appendPartWithFileURL:[NSURL fileURLWithPath:filePath] name:@"f" error:nil];
    } success:^(NSURLSessionTask *task, id responseObject) {
        [output close];
        [self requestFinished:responseObject task:(NSURLSessionDataTask *)task];
    } failure:^(NSURLSessionTask *task, NSError *error) {
        [output close];
        [self requestFailed:error];
    }];
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

- (BOOL)testAuthed:(NSDictionary *)headers
{
    if (self.geeklogID > 1) {
        return YES;
    };
    NSURL *URL = [NSURL URLWithString:OritsubushiSiteURL];
    if (headers != nil) {
        NSLog(@"%@", headers);
        for (NSHTTPCookie *cookie in [NSHTTPCookie cookiesWithResponseHeaderFields:headers forURL:URL]) {
            NSLog(@"#cookie %@ / %@", cookie.name, cookie.value);
            if([cookie.name isEqualToString:@"geeklog"] && [cookie.value integerValue] > 1) {
                self.geeklogID = [cookie.value integerValue];
                return YES;
            }
        }
    }
    for(NSHTTPCookie *cookie in [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:URL]) {
        NSLog(@"cookie %@ / %@", cookie.name, cookie.value);
        if([cookie.name isEqualToString:@"geeklog"] && [cookie.value integerValue] > 1) {
            self.geeklogID = [cookie.value integerValue];
            return YES;
        }
    }
    return NO;
}

- (void)requestFinished:(id)responseObject task:(NSURLSessionDataTask *)task
{
    //NSLog(@"response %@", request.url);
    //NSLog(@"%@", [request responseString]);
    NSDictionary *headers = ((NSHTTPURLResponse *)task.response).allHeaderFields;
    BOOL login = [self testAuthed:headers];
    if(login) {
        [self startStopIndicator:NO];
        [self showHideWebView:NO];
        switch(state) {
            case SyncStateBeginAuth:
                self.userName = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
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
                newUpdateDate = [[headers objectForKey:UpdateDateHeader] intValue];
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
                self.geeklogID = 0;
                [self setReady];
                break;
            case SyncStateAuth:
                //ログイン入力後のPOSTで認証不成立
                [self performSelector:@selector(authWithErrorMessage:) withObject:NSLocalizedString(@"ログインに失敗しました。", nil) afterDelay:0];
                break;
            default:
            {
                //ログイン画面か、またはリダイレクトでtwitter.comのアプリ認証画面
                NSString *HTMLString = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
                [self.webView loadHTMLString:HTMLString baseURL:((NSHTTPURLResponse *)task.response).URL];
                break;
            }
        }
    }
}

- (void)requestFailed:(NSError *)error
{
    state = SyncStateFail;
    [self.request.session invalidateAndCancel];
    [self setReady];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    if([self testAuthed:nil]) {
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
    NSData *body;
    NSLog(@"%@", request);
    if (request.HTTPBodyStream) {
        NSInputStream *stream = request.HTTPBodyStream;
        uint8_t byteBuffer[4096];
        [stream open];
        NSMutableData *data = [[NSMutableData alloc] init];
        while (stream.hasBytesAvailable) {
            NSInteger len = [stream read:byteBuffer maxLength:sizeof(byteBuffer)];
            if (len > 0) {
                [data appendData:[NSData dataWithBytes:byteBuffer length:len]];
            }
        }
        [stream close];
    } else {
        body = request.HTTPBody;
    }
    self.request = [AFHTTPSessionManager manager];
    [self.request.requestSerializer setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    NSLog(@"%@", body);
    [self.request.requestSerializer setQueryStringSerializationWithBlock:^NSString *(NSURLRequest *request_, id parameters, NSError * __autoreleasing * error) {
        NSString *body = [[NSString alloc] initWithData:parameters encoding:NSUTF8StringEncoding];
        NSLog(@"%@", body);
        return body;
    }];
    self.request.responseSerializer = [AFHTTPResponseSerializer serializer];
    [self.request POST:request.URL.absoluteString parameters:body success:^(NSURLSessionDataTask *task, id responseObject) {
        NSLog(@"%@", [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding]);
        [self requestFinished:responseObject task:task];
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        [self requestFailed:error];
    }];
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    switch(state) {
        case SyncStateBeginAuth:
            switch(navigationAction.navigationType) {
                //パスワード認証もTwitter認証もここで呼ばれる
                case WKNavigationTypeFormSubmitted:
                {
                    [self showHideWebView:NO];
                    [self startStopIndicator:YES];
                    NSRange range = [navigationAction.request.URL.relativeString rangeOfString:@"twitter" options:NSCaseInsensitiveSearch];
                    //NSLog(@"request: %d / %@", range.length, request.URL.relativeString);
                    state = range.length ? SyncStateAuthTwitter : SyncStateAuth;
                    [self postRequestWithNSURLRequest:navigationAction.request];
                    decisionHandler(WKNavigationActionPolicyCancel);
                    break;
                case WKNavigationTypeLinkActivated:
                    decisionHandler(WKNavigationActionPolicyCancel);
                    [[UIApplication sharedApplication] openURL:navigationAction.request.URL];
                    break;
                //文字列からのロードはここを通る
                case WKNavigationTypeOther:
                    decisionHandler(WKNavigationActionPolicyAllow);
                    break;
                default:
                    decisionHandler(WKNavigationActionPolicyCancel);
                    break;
                }
            }
            break;
        case SyncStateAuthTwitter:
        {
            NSRange range = [navigationAction.request.URL.absoluteString rangeOfString:@"oritsubushi.net" options:NSCaseInsensitiveSearch];
            //NSLog(@"request: %d / %@", range.length, request.URL.relativeString);
            switch(navigationAction.navigationType) {
                case WKNavigationTypeFormSubmitted:
                    [self showHideWebView:NO];
                    [self startStopIndicator:YES];
                    [self postRequestWithNSURLRequest:navigationAction.request];
                    decisionHandler(WKNavigationActionPolicyCancel);
                    break;
                case WKNavigationTypeLinkActivated:
                    decisionHandler(WKNavigationActionPolicyCancel);
                    if(range.length) {
                        [self performSelector:@selector(authWithErrorMessage:) withObject:NSLocalizedString(@"Twitterログインがキャンセルされました", nil) afterDelay:0];
                    } else {
                        [[UIApplication sharedApplication] openURL:navigationAction.request.URL];
                    }
                    break;
                case WKNavigationTypeOther:
                    decisionHandler(WKNavigationActionPolicyAllow);
                    break;
                default:
                    decisionHandler(WKNavigationActionPolicyCancel);
                    break;
            }
            break;
        }
        default:
            decisionHandler(WKNavigationActionPolicyCancel);
            break;
    }
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler
{
    NSDictionary *headers = ((NSHTTPURLResponse *)navigationResponse.response).allHeaderFields;
    [self testAuthed:headers];
    decisionHandler(WKNavigationResponsePolicyAllow);
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

- (void)setUserName:(NSString *)userName
{
    _userName = userName;
    [[NSUserDefaults standardUserDefaults] setValue:userName forKey:SETTINGS_KEY_SERVER_USER_NAME];
    [self setLabelString:userName tag:HeaderViewTagUserName];
}

- (void)testPp {
    NSInteger ppVersion = [[NSUserDefaults standardUserDefaults] integerForKey:SETTINGS_KEY_PP_VERSION];
    self.confirmView.hidden = ppVersion >= PP_VERSION;
}

- (void)ppLinkButtonDidClick:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:ppUrl]];
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, SYNC_PP_READ_WAIT_NSEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        self.ppConfirmButton.enabled = YES;
    });
}

- (void)ppConfirmButtonDidClick:(id)sender {
    [[NSUserDefaults standardUserDefaults] setInteger:PP_VERSION forKey:SETTINGS_KEY_PP_VERSION];
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem: self.view
                       attribute:  NSLayoutAttributeBottom
                       relatedBy:  NSLayoutRelationEqual
                       toItem:     self.confirmView
                       attribute:  NSLayoutAttributeTop
                       multiplier: 1.0
                       constant:   0.0
     ];
    [self.view removeConstraint:self.confirmViewTopConstraint];
    [self.view addConstraint:constraint];
    [UIView animateWithDuration:0.5
                               delay:0.3
                               options:UIViewAnimationOptionCurveEaseOut
                               animations: ^{
                                   [self.view layoutIfNeeded];
                               }
                               completion: nil
                               ];
}

@end
