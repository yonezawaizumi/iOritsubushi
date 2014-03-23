//
//  NSFileHandle+TextReader.h
//  Oritsubushi
//
//  Created by 泉美 米沢 on 11/12/14.
//  Copyright (c) 2011年 合資会社ダブルエスエフ. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSFileHandle (TextReader)

- (NSString *)readLine;

@end
