//
//  Prefs.h
//  Oritsubushi
//
//  Created by 泉美 米沢 on 11/11/23.
//  Copyright (c) 2011年 合資会社ダブルエスエフ. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    PrefHokkaido = 1,
    PrefAomori,
    PrefIwate,
    PrefMiyagi,
    PrefAkita,
    PrefYamagata,
    PrefFukushima,
    PrefIbaraki,
    PrefTochigi,
    PrefGumma,
    PrefSaitama,
    PrefChiba,
    PrefTokyo,
    PrefKanagawa,
    PrefNiigata,
    PrefToyama,
    PrefIshikawa,
    PrefFukui,
    PrefYamanashi,
    PrefNagano,
    PrefGifu,
    PrefShizuoka,
    PrefAichi,
    PrefMie,
    PrefShiga,
    PrefKyoto,
    PrefOsaka,
    PrefHyogo,
    PrefNara,
    PrefWakayama,
    PrefTottori,
    PrefShimane,
    PrefOkayama,
    PrefHiroshima,
    PrefYamaguchi,
    PrefTokushima,
    PrefKagawa,
    PrefEhime,
    PrefKouchi,
    PrefFukuoka,
    PrefSaga,
    PrefNagasaki,
    PrefKumamoto,
    PrefOoita,
    PrefMiyazaki,
    PrefKagoshima,
    PrefOkinawa,
    PREFTYPE_ERROR = 0
} PrefType;

@interface Prefs : NSObject

+ (NSString *)stringWithType:(PrefType)type;
+ (PrefType)typeWithString:(NSString *)string;
+ (NSArray *)matchPrefsWithString:(NSString *)string;;

@end
