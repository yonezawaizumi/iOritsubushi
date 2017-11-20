//
//  FMDBHelper.h
//  VccPlaceNavigator
//
//  Created by vcc_air02 on 11/06/27.
//  Copyright 2011 バーチャルコミュニケーションズ株式会社. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FMDBHelper : NSObject

+ (NSString *)getWritablePath:(NSString *)databaseFileName;
+ (NSError *)prepareDatabase:(NSString *)databaseFileName writableDBPath:(NSString *)writableDBPath userVersion:(NSInteger)userVersion fileCopied:(BOOL *)copied;
+ (NSError *)moveOldDatabase:(NSString *)databaseFileName;

@end
