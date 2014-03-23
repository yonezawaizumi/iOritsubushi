//
//  SearchScopeBar.m
//  Oritsubushi
//
//  Created by 泉美 米沢 on 11/12/03.
//  Copyright (c) 2011年 合資会社ダブルエスエフ. All rights reserved.
//

#import "AppDelegate.h"
#import "SearchScopeBar.h"
#import "Consts.h"
#import "Misc.h"

typedef enum {
    TypeIndexNone,
    TypeIndexPref,
    TypeIndexName,
    TypeIndexYomi,
    TypeIndexLine,
    TypeIndexDate,
} TypeIndex;

static NSString *typeLabels[] = {
    @"地点",
    @"県",
    @"駅名",
    @"読み",
    @"路線",
    @"日付"
};

typedef enum {
    MatchIndexForward,
    MatchIndexMatch
} MatchIndex;

static NSString *matchLabels[] = {
    @"開始",
    @"含む"
};

static BOOL initialized = NO;

@interface SearchScopeBar () {
    DatabaseFilterType filterType_;
    CGFloat originalOriginY;
}

@property(nonatomic,strong) UISegmentedControl *typeControl;
@property(nonatomic,strong) UISegmentedControl *matchControl;

@end

@implementation SearchScopeBar

@synthesize typeControl;
@synthesize matchControl;

- (id)initWithFrame:(CGRect)frame
{
    if(!initialized) {
        for(int index = 0; index < countof(typeLabels); ++index) {
            typeLabels[index] = NSLocalizedString(typeLabels[index], nil);
        }
        for(int index = 0; index < countof(matchLabels); ++index) {
            matchLabels[index] = NSLocalizedString(matchLabels[index], nil);
        }
        initialized = YES;
    }
    
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        BOOL os7 = ((AppDelegate *)([UIApplication sharedApplication].delegate)).osVersion >= 7;
        originalOriginY = frame.origin.y;
        self.hidden = YES;
        self.backgroundColor = os7 ? OS7_PROMPT_COLOR : SCOPE_BAR_COLOR;
        self.typeControl = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:typeLabels count:countof(typeLabels)]];
        self.typeControl.segmentedControlStyle = UISegmentedControlStyleBar;
        self.typeControl.tintColor = os7 ? OS7_TINT_COLOR : SCOPE_BAR_COLOR;
        [self.typeControl addTarget:self action:@selector(valueDidChange) forControlEvents:UIControlEventValueChanged];
        self.matchControl = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:matchLabels count:countof(matchLabels)]];
        self.matchControl.segmentedControlStyle = UISegmentedControlStyleBar;
        self.matchControl.tintColor = os7 ? OS7_TINT_COLOR : SCOPE_BAR_COLOR;
        [self.matchControl addTarget:self action:@selector(valueDidChange) forControlEvents:UIControlEventValueChanged];
        CGRect typeRect = self.typeControl.frame;
        CGRect matchRect = self.matchControl.frame;
        NSInteger marginHeight = (NSInteger)((frame.size.height - typeRect.size.height - matchRect.size.height) / 3);
        typeRect.origin.x = SCOPE_BAR_HORIZONTAL_MARGIN;
        typeRect.origin.y = marginHeight;
        typeRect.size.width = frame.size.width - SCOPE_BAR_HORIZONTAL_MARGIN * 2;
        self.typeControl.frame = typeRect;
        [self addSubview:self.typeControl];
        matchRect.origin.x = SCOPE_BAR_HORIZONTAL_MARGIN;
        matchRect.origin.y = frame.size.height - marginHeight - matchRect.size.height;
        matchRect.size.width = frame.size.width - SCOPE_BAR_HORIZONTAL_MARGIN * 2;
        self.matchControl.frame = matchRect;
        [self addSubview:self.matchControl];
        [self setFilterType:DatabaseFilterTypeNone];
    }
    return self;
}

- (void)dealloc
{
    self.typeControl = nil;
    self.matchControl = nil;
}

- (DatabaseFilterType)recalcFilterType
{
    static DatabaseFilterType types[] = {
        DatabaseFilterTypeNone,
        DatabaseFilterTypeNone,
        DatabaseFilterTypePref,
        DatabaseFilterTypePref,
        DatabaseFilterTypeNameForward,
        DatabaseFilterTypeName,
        DatabaseFilterTypeYomiForward,
        DatabaseFilterTypeYomi,
        DatabaseFilterTypeLineForward,
        DatabaseFilterTypeLine,
        DatabaseFilterTypeDate,
        DatabaseFilterTypeNone,
    };
    int typeIndex = self.typeControl.selectedSegmentIndex;
    if(typeIndex < 0)   typeIndex = 0;
    int matchIndex = self.matchControl.selectedSegmentIndex > 0;
    return filterType_ = types[typeIndex * 2 + matchIndex];
}

- (DatabaseFilterType)filterType
{
    return filterType_;
}

- (void)setFilterType:(DatabaseFilterType)filterType
{
    int typeIndex, matchIndex;
    switch(filterType) {
        case DatabaseFilterTypeNameForward:
            typeIndex = TypeIndexName;
            matchIndex = MatchIndexForward;
            self.matchControl.enabled = YES;
            break;
        case DatabaseFilterTypeName:
            typeIndex = TypeIndexName;
            matchIndex = MatchIndexMatch;
            self.matchControl.enabled = YES;
            break;
        case DatabaseFilterTypeYomiForward:
            typeIndex = TypeIndexYomi;
            matchIndex = MatchIndexForward;
            self.matchControl.enabled = YES;
            break;
        case DatabaseFilterTypeYomi:
            typeIndex = TypeIndexYomi;
            matchIndex = MatchIndexMatch;
            self.matchControl.enabled = YES;
            break;
        case DatabaseFilterTypeLineForward:
            typeIndex = TypeIndexLine;
            matchIndex = MatchIndexForward;
            self.matchControl.enabled = YES;
            break;
        case DatabaseFilterTypeLine:
            typeIndex = TypeIndexLine;
            matchIndex = MatchIndexMatch;
            self.matchControl.enabled = YES;
            break;
        case DatabaseFilterTypePref:
            typeIndex = TypeIndexPref;
            matchIndex = self.matchControl.selectedSegmentIndex;
            self.matchControl.enabled = NO;
            break;
        case DatabaseFilterTypeDate:
            typeIndex = TypeIndexDate;
            matchIndex = MatchIndexMatch;
            self.matchControl.enabled = NO;
            break;
        default:
            typeIndex = TypeIndexNone;
            matchIndex = self.matchControl.selectedSegmentIndex;
            self.matchControl.enabled = NO;
            break;
    }
    self.typeControl.selectedSegmentIndex = typeIndex;
    self.matchControl.selectedSegmentIndex = matchIndex;
    filterType_ = filterType;
}

- (void)valueDidChange
{
    [self setFilterType:[self recalcFilterType]];
}

- (void)prepareAnimationWithShowing:(BOOL)showing
{
    if(showing) {
        self.hidden = NO;
    }
}

- (void)setAnimationWithShowing:(BOOL)showing
{
    CGRect rect = self.frame;
    if(showing) {
        rect.origin.y = originalOriginY + rect.size.height;
    } else {
        rect.origin.y = originalOriginY;
    }
    self.frame = rect;
}

- (void)finishAnimationWithShowing:(BOOL)showing
{
    if(!showing) {
        self.hidden = YES;
    }
}

@end
