//
//  GoogleMapsService.m
//  Oritsubushi
//
//  Created by 泉美 米沢 on 11/12/03.
//  Copyright (c) 2011年 合資会社ダブルエスエフ. All rights reserved.
//

#import "GoogleMapsService.h"
#import "SBJson.h"
#import "GoogleMapsLocation.h"
#import "Misc.h"

@interface GoogleMapsService ()

@property(nonatomic,strong) ASIHTTPRequest *request;

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
    [self.request cancel];
    self.request = nil;
}

- (void)geocodeWithAddress:(NSString *)address country:(NSString *)country
{
    NSString *URLString = [NSString stringWithFormat:@"https://maps.google.com/maps/api/geocode/json?address=%@&sensor=false&language=%@", [Misc URLEncode:address], country];
    
    self.locations = nil;
    self.errorMessage = nil;
    self.request = nil;
    
    self.request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:URLString]];
    self.request.delegate = self;
    [self.request startAsynchronous];
    
}

- (void)geocodeInJapanWithAddress:(NSString *)address
{
    [self geocodeWithAddress:address country:[[NSLocale preferredLanguages] objectAtIndex:0]];
}

- (NSString *)parseData:(NSData *)data;
{
    if(!data) {
        return @"サーバーにつながりません";
    }
    SBJsonParser *parser = [[SBJsonParser alloc] init];
    NSDictionary *dict = [parser objectWithData:data];
    if(!dict) {
        return @"サーバーからの結果が不正です";
    }
    id value = [dict objectForKey:@"status"];
    if(![value isKindOfClass:[NSString class]]) {
        return @"検索できませんでした";
    } else if([@"OK" isEqualToString:value]) {
        id results = [dict objectForKey:@"results"];
        if([results isKindOfClass:[NSArray class]]) {
            NSMutableArray *locations = [[NSMutableArray alloc] init];
            for (NSDictionary *placemark in results) {
                id address = [placemark objectForKey:@"formatted_address"];
                if(![address isKindOfClass:[NSString class]] || ![(NSString *)address length]) {
                    continue;
                }
                id loc = [[placemark objectForKey:@"geometry"] objectForKey:@"location"];
                id lat = [loc objectForKey:@"lat"];
                id lng = [loc objectForKey:@"lng"];
                if(![lat isKindOfClass:[NSNumber class]] || ![lng isKindOfClass:[NSNumber class]]) {
                    continue;
                }
                GoogleMapsLocation *location = [[GoogleMapsLocation alloc] initWithAddress:address coordinate:CLLocationCoordinate2DMake([lat doubleValue], [lng doubleValue])];
                [locations addObject:location];
            }
            if([locations count]) {
                self.locations = locations;
                return nil;
            }
        }
        return @"地点が見つかりません";
    } else if([@"ZERO_RESULTS" isEqualToString:value]) {
        return @"地点が見つかりません";
    } else if([@"REQUEST_DENIED" isEqualToString:value]) {
        return @"実行制限回数に達しました";
    } else {
        return @"サーバーエラー";
    }
}

- (void)requestFinished:(ASIHTTPRequest *)request
{
    self.errorMessage = [self parseData:request.responseData];
    [self.delegate GoogleMapsServiceDidFinish:self];
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
    self.errorMessage = [[request error] localizedDescription];
    [self.delegate GoogleMapsServiceDidFinish:self];
}

@end
