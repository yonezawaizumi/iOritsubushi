//
//  GoogleMapsService.m
//  Oritsubushi
//
//  Created by 泉美 米沢 on 11/12/03.
//  Copyright (c) 2011年 合資会社ダブルエスエフ. All rights reserved.
//

#import "GoogleMapsService.h"
#import "SBJson4.h"
#import "GoogleMapsLocation.h"
#import "Misc.h"

@interface GoogleMapsService ()

@property(nonatomic,strong) AFHTTPSessionManager *request;

@end

@implementation GoogleMapsService

@synthesize timeoutSecond = timeoutSecond_;
@synthesize locations = locations_;
@synthesize errorMessage = errorMessage_;
@synthesize delegate = delegate_;
@synthesize request = request_;

- (id)initWithDelegate:(id<GoogleMapsServiceDelegate>)delegate timeoutSecond:(CGFloat)timeoutSecond
{
    self = [super init];
    if(self) {
        self.delegate = delegate;
        self.timeoutSecond = timeoutSecond;
    }
    return self;
}

- (id)initWithDelegate:(id<GoogleMapsServiceDelegate>)delegate
{
    return [self initWithDelegate:delegate timeoutSecond:15];
}

- (void)dealloc
{
    self.locations = nil;
    self.errorMessage = nil;
    [self.request.session invalidateAndCancel];
    self.request = nil;
}

- (void)geocodeWithAddress:(NSString *)address country:(NSString *)country
{
    NSString *URLString = [NSString stringWithFormat:@"https://oritsubushi.net/oritsubushi/yahoomap.php?k=%@", [Misc URLEncode:address]];
    
    self.locations = nil;
    self.errorMessage = nil;
    self.request = [AFHTTPSessionManager manager];
    self.request.responseSerializer = [AFHTTPResponseSerializer serializer];
    [self.request GET:URLString parameters:nil success:^(NSURLSessionDataTask* task, id responseObject) {
        [self parseData:responseObject];
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        [self delegateResult:[error localizedDescription]];
    }];
}

- (void)geocodeInJapanWithAddress:(NSString *)address
{
    [self geocodeWithAddress:address country:[[NSLocale preferredLanguages] objectAtIndex:0]];
}

- (void)parseData:(NSData *)data;
{
    if(data) {
        NSString *locsStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSMutableArray *locations = [[NSMutableArray alloc] init];
        for (NSString *loc in [locsStr componentsSeparatedByString:@"\n"]) {
            if ([loc length]) {
                NSArray *chunks = [loc componentsSeparatedByString:@"\t"];
                if ([chunks count] == 3) {
                    CLLocationCoordinate2D coords = CLLocationCoordinate2DMake([chunks[1] doubleValue] / 1000000, [chunks[2] doubleValue] / 1000000);
                    [locations addObject:[[GoogleMapsLocation alloc] initWithAddress:chunks[0]
                                                                                    coordinate:coords]];
                }
            }
        }
        if([locations count]) {
            self.locations = locations;
            [self delegateResult:nil];
            return;
        } else {
            [self delegateResult:@"地点が見つかりません"];
        }
    } else {
        [self delegateResult:@"サーバーにつながりません"];
    }
}

- (void)delegateResult:(NSString *)errorMessage
{
    self.errorMessage = errorMessage;
    [self.delegate GoogleMapsServiceDidFinish:self];
}
@end
