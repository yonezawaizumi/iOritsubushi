//
//  DatabaseVersion.h
//  Oritsubushi
//
//  Created by 泉美 米沢 on 12/01/14.
//  Copyright (c) 2012年 合資会社ダブルエスエフ. All rights reserved.
//

#ifndef Oritsubushi_DatabaseVersion_h
#define Oritsubushi_DatabaseVersion_h

#define DATABASE_USER_VERSION           140

typedef struct Duplicater {
    int version;
    int newKey;
    int oldKey;
    int oldKey2;
    int oldKey3;
} Duplicater;

extern Duplicater duplicaters[];

#endif
