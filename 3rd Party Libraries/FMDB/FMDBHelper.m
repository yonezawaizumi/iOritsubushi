//
//  FMDBHelper.m
//  VccPlaceNavigator
//
//  Created by vcc_air02 on 11/06/27.
//  Copyright 2011 バーチャルコミュニケーションズ株式会社. All rights reserved.
//

#import "FMDatabase.h"
#import "FMDBHelper.h"


@implementation FMDBHelper

+ (NSString *)getWritablePath:(NSString *)databaseFileName
{
    NSArray  *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return [documentsDirectory stringByAppendingPathComponent:databaseFileName];    
}

+ (NSError *)prepareDatabase:(NSString *)databaseFileName writableDBPath:(NSString *)writableDBPath userVersion:(NSInteger)userVersion fileCopied:(BOOL *)copied
{
    NSError *error = nil;	
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if([fileManager fileExistsAtPath:writableDBPath]) {
        if(!userVersion) {
            if(copied) {
                *copied = NO;
            }
            return nil;
        }
        FMDatabase *database = [FMDatabase databaseWithPath:writableDBPath];
        if(database && [database open]) {
            FMResultSet *result = [database executeQuery:@"PRAGMA user_version;"];
            NSInteger currentUserVersion = result && [result next] ? [result intForColumnIndex:0] : 0;
            [result close];
            [database close];
            if(currentUserVersion >= userVersion) {
                if(copied) {
                    *copied = NO;
                }
                return nil;
            }
        }
        [fileManager removeItemAtPath:writableDBPath error:NULL];
    }
    NSString *defaultDBPath = [[NSBundle mainBundle] pathForResource:databaseFileName ofType:nil];
    if([fileManager copyItemAtPath:defaultDBPath toPath:writableDBPath error:&error]) {
        if(copied) {
            *copied = YES;
        }
        return nil;
    } else {
        return error;
    }
}

@end
