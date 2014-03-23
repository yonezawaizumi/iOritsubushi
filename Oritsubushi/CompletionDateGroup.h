//
//  CompletionDateGroup.h
//  Oritsubushi
//
//  Created by よねざわいずみ on 12/10/09.
//  Copyright (c) 2012年 合資会社ダブルエスエフ. All rights reserved.
//

#import "Group.h"

@interface CompletionDateGroup : Group

@property(nonatomic,strong,readonly) NSString *cellTitle;

+ (BOOL)completionDateRangeWithSearchKeyword:(NSString *)searchKeyword range:(NSRange *)range;

@end

