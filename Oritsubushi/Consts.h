//
//  Header.h
//  Oritsubushi
//
//  Created by 泉美 米沢 on 11/11/03.
//  Copyright (c) 2011年 合資会社ダブルエスエフ. All rights reserved.
//

#ifndef Oritsubushi_Header_h
#define Oritsubushi_Header_h

#include "DatabaseVersion.h"
#include "PpVersion.h"

#define ANIMATION_DURATION              0.25

#define ANNOTATION_CACHING_AREA         1.1
#define ANNOTATION_UPDATE_DELAY         0.02
#define CONTEXT_UPDATE_DELAY            0.001
#define INITIAL_REGION_DELTA            0.1

#define JAPAN_MAX_LATITUDE              45.5
#define JAPAN_MIN_LATITUDE              24.0
#define JAPAN_MAX_LONGITUDE             154.0
#define JAPAN_MIN_LONGITUDE             122.9
#define JAPAN_HESO_LATITUDE             35.002076
#define JAPAN_HESO_LONGITUDE            134.997618

#define SINGLE_TAP_DELAY                0.3
#define FIRST_LOCATING_DECIDE_DELAY     2
#define FIRST_LOCATING_TERMINATE_DELAY  7

#define BAR_COLOR                       [UIColor darkGrayColor]

#define OS7_TINT_COLOR                  [UIColor colorWithRed:0.0 green:(122.0/255) blue:1.0 alpha:1.0]

#define SCOPE_BAR_HEIGHT                88
#define SCOPE_BAR_HORIZONTAL_MARGIN     10

#define PROMPT_TEXT_COLOR               [UIColor whiteColor];
#define PROMPT_COLOR                    [UIColor colorWithRed:0.22 green:0.22 blue:0.22 alpha:1]
#define PROMPT_HEIGHT                   28
#define PROMPT_FONT                     [UIFont systemFontOfSize:14]
#define PROMPT_INDICATOR_MARGIN         8

#define OS13_PROMPT_TEXT_COLOR          [UIColor labelColor]
#define OS7_PROMPT_TEXT_COLOR           [UIColor blackColor]
#define OS13_PROMPT_COLOR               [UIColor systemGray4Color]
#define OS7_PROMPT_COLOR                [UIColor colorWithRed:(239.0/255) green:(239.0/255) blue:(244.0/255) alpha:1.0]

#define OS13_PROMPT_COLOR_TEMP          [UIColor systemGroupedBackgroundColor]
//iOS7 GMでDNRRealTimeBlurが激しくメモリリークするための緊急避難
#define OS7_PROMPT_COLOR_TEMP           [UIColor colorWithRed:(239.0/255) green:(239.0/255) blue:(244.0/255) alpha:0.98]
#define OS7_PROPMT_BOTTOM_EDGE_COLOR    /*[UIColor colorWithRed:(167.0/255) green:(167.0/255) blue:(170.0/255) alpha:1.0]*/[UIColor lightGrayColor]

#define SEARCH_BAR_LEFT_MARGIN          88
#define SEARCH_BAR_HEIGHT               44

#define MAP_WRAPPER_COLOR               [UIColor darkGrayColor]
#define MAP_WRAPPER_ALPHA               0.6

#define NUMBER_OF_ICONS_DEFAULT         100
#define NUMBER_OF_ICONS_LIST            { 50, 100, 150, 200, 300, 500 }

#define LOADING_VIEW_COLOR              [UIColor colorWithRed:0.6 green:0.6 blue:0.6 alpha:0.5]

#define INFORMATION_URL                 @"https://ss1.coressl.jp/timeline.oritsubushi.net/oritsubushi/timeline.php"

// 地名検索結果の複数候補の選択画面での、テーブルビューの背景色（RGBα）
#define PLACE_SELECT_BACKGROUND_COLOR [UIColor colorWithRed:1 green:1 blue:1 alpha:0.9]
// 地名検索結果の複数候補の選択画面での、四隅の丸め
#define PLACE_SELECT_CORNER_RADIUS 5
// 地名検索結果の複数候補の選択画面での、最大行数（小数も設定可）
#define PLACE_SELECT_MAX_NUM_ROWS 5.5
#define OS7_PLACE_SELECT_MAX_NUM_ROWS 3.5
// 地名検索結果の複数候補の選択画面の１行の高さ、上辺マージン、左右マージン
#define PLACE_SELECT_ROW_HEIGHT 40
#define PLACE_SELECT_MARGIN_TOP 50
#define PLACE_SELECT_MARGIN_LEFT 12

#define INCOMPLETION_STRING             @"未乗下車"
#define AMBIGOUS_DATE_STRING            @"不明"
#define CONCAT_ANBIGOUS_DATE_STRING(str)    str "不明"
#define CONCAT_2_ANBIGOUS_DATE_STRING(pre, suf)    pre "不明" suf

#define SYNC_PP_READ_WAIT_NSEC          (int64_t)(2.0 * NSEC_PER_SEC)
#define SYNC_PP_CONFIRM_ANIM_DELAY      0.1
#define SYNC_PP_CONFIRM_ANIM_DULATION   0.3

#define GROUP_NAME                      @"group.com.wsf-lp.iOritsubushi"

#endif
