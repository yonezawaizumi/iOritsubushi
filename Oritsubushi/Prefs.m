//
//  Prefs.m
//  Oritsubushi
//
//  Created by 泉美 米沢 on 11/11/23.
//  Copyright (c) 2011年 合資会社ダブルエスエフ. All rights reserved.
//

#import "Prefs.h"
#import "Misc.h"

static NSString *prefs[] = {
    nil,
    @"北海道",
    @"青森県",
    @"岩手県",
    @"宮城県",
    @"秋田県",
    @"山形県",
    @"福島県",
    @"茨城県",
    @"栃木県",
    @"群馬県",
    @"埼玉県",
    @"千葉県",
    @"東京都",
    @"神奈川県",
    @"新潟県",
    @"富山県",
    @"石川県",
    @"福井県",
    @"山梨県",
    @"長野県",
    @"岐阜県",
    @"静岡県",
    @"愛知県",
    @"三重県",
    @"滋賀県",
    @"京都府",
    @"大阪府",
    @"兵庫県",
    @"奈良県",
    @"和歌山県",
    @"鳥取県",
    @"島根県",
    @"岡山県",
    @"広島県",
    @"山口県",
    @"徳島県",
    @"香川県",
    @"愛媛県",
    @"高知県",
    @"福岡県",
    @"佐賀県",
    @"長崎県",
    @"熊本県",
    @"大分県",
    @"宮崎県",
    @"鹿児島県",
    @"沖縄県"
};
static BOOL initialized = NO;

@implementation Prefs

+ (void)initialize
{
    for(int i = 0; i < countof(prefs); ++i) {
        if(prefs) prefs[i] = NSLocalizedString(prefs[i], nil);
    }
    initialized = YES;
}

+ (NSString *)stringWithType:(PrefType)type
{
    if(!initialized)    [Prefs initialize];
    return type < countof(prefs) ? prefs[type] : nil;
}

+ (PrefType)typeWithString:(NSString *)string
{
    if(!initialized)    [Prefs initialize];
    for(int i = 1/*prefs[0] is nil*/; i < countof(prefs); ++i) {
        if([string isEqualToString:prefs[i]]) {
            return (PrefType)i;
        }
    }
    return PREFTYPE_ERROR;
}

+ (NSArray *)matchPrefsWithString:(NSString *)string
{
    if(!initialized)    [Prefs initialize];
    NSRange range = NSMakeRange(0, [string length]);
    NSMutableArray *results = [NSMutableArray array];
    for(int i = 1; i < countof(prefs); ++i) {
        if(![prefs[i] compare:string options:0 range:range]) {
            [results addObject:[NSString stringWithFormat:@"%d", i]];
        }
    }
    return results;
}

@end
