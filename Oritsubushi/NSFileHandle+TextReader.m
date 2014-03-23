//
//  NSFileHandle+TextReader.m
//  Oritsubushi
//
//  Created by 泉美 米沢 on 11/12/14.
//  Copyright (c) 2011年 合資会社ダブルエスエフ. All rights reserved.
//

#import "NSFileHandle+TextReader.h"

static NSInteger CHUNK_SIZE = 1024;

@implementation NSFileHandle (TextReader)

-(NSString *) readLine
{
	NSString *result = nil;
	NSMutableData *lineData = [NSMutableData data];
    
	unsigned long long currentOffset = [self offsetInFile];
	unsigned long long endOffset = [self seekToEndOfFile];
	[self seekToFileOffset:currentOffset];
    
	NSData *endOfLine = [@"\n" dataUsingEncoding:NSUTF8StringEncoding];	 
    
	do {
		NSData *buffer = [self readDataOfLength:CHUNK_SIZE];
		if ([buffer length]==0) {
			break;
		}
        
		NSRange tmpLineRange = [buffer rangeOfData:endOfLine
                                           options:0
                                             range:NSMakeRange(0, [buffer length])];
        
		if (tmpLineRange.location != NSNotFound)
		{
			NSRange newLineRange = NSMakeRange(0, tmpLineRange.location+1);
			NSData *subdata = [buffer subdataWithRange:newLineRange];
			[lineData appendData:subdata];
            
			currentOffset += [subdata length];
			[self seekToFileOffset:currentOffset];
			break;
		}
		else
		{
			[lineData appendData:buffer];
            
			currentOffset += [buffer length];
			if (currentOffset >= endOffset)
			{
				[self seekToEndOfFile];
				break;
			}
			else
			{
				[self seekToFileOffset:currentOffset];
			}
		}
	} while(1);	   
    
	if ([lineData length]>0)
	{
		result = [[NSString alloc] initWithData:lineData
                                       encoding:NSUTF8StringEncoding];
	}
    
	return result;
}

@end
