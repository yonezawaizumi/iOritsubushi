//
//  Group.m
//  Oritsubushi
//
//  Created by 泉美 米沢 on 11/12/02.
//  Copyright (c) 2011年 合資会社ダブルエスエフ. All rights reserved.
//

#import "Group.h"
#import "FMDatabase.h"

@interface Group () {
    NSInteger total_;
    NSInteger completions_;
}

@end

@implementation Group

@synthesize code;
@synthesize title;

- (void)dealloc
{
    self.code = nil;
    self.title = nil;
}

- (NSString *)headerTitle {
    return self.title;
}

- (NSInteger)total
{
    return total_;
}

- (void)setTotal:(NSInteger)total
{
    total_ = total;
}

- (NSInteger)completions
{
    return completions_;
}

- (void)setCompletions:(NSInteger)completions
{
    completions_ = completions;
}

- (NSInteger)incompletions
{
    return total_ - completions_;
}

- (NSInteger)ratio
{
    return total_ ? completions_ * 1000 / total_ : -1;
}

- (NSString *)description
{
    NSInteger ratio_ = self.ratio;
    return ratio_ >= 0 ? [NSString stringWithFormat:NSLocalizedString(@"%d駅中 %d駅　%d.%d%%　残り%d駅", nil),
                          total_, completions_, ratio_ / 10, ratio_ % 10, self.incompletions] : nil;
}

+ (NSString *)statusIconNameWithCompletions:(NSInteger)completions total:(NSInteger)total
{
    return total ? (total == completions ? @"statusicon_comp" : @"statusicon_incomp") : @"statusicon_notload";
}

- (NSString *)statusIconName
{
    return [Group statusIconNameWithCompletions:completions_ total:total_];
}


@end
