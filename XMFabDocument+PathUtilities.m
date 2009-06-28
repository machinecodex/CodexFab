//
//  CodexFab
//
// XMFabDocument (PathUtilities)
//
//  Licensed under CC Attribution License 3.0 <http://creativecommons.org/licenses/by/3.0/>
//
// Based on CocoaFob by Gleb Dolgich
// <http://github.com/gbd/cocoafob/tree/master>
//
//  Created by Alex Clarke on 10/06/09.
//  Copyright 2009 MachineCodex Software Australia. All rights reserved.
// <http://www.machinecodex.com>


#import "XMFabDocument.h"


@implementation XMFabDocument (PathUtilities)

#pragma mark Paths

- (NSString *) existingPathAtPath:(NSString *)path {
	
	NSFileManager * fileManager = [NSFileManager defaultManager];
	
	if (![fileManager fileExistsAtPath:path isDirectory:NULL])
	{		
		if(![fileManager createDirectoryAtPath:path attributes:nil]) {
			
			NSLog(@"Error! Could not create directory");
		}
	}
	
	return path;
}

/**
 Returns the support folder for the application.  This code uses a folder named "CocoaFab" for
 the content, either in the NSApplicationSupportDirectory location or (if the
 former cannot be found), the system's temporary directory.
 */

- (NSString *) applicationSupportFolder {
	
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
	NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();
	NSString * appName = [[[NSBundle mainBundle] executablePath] lastPathComponent];
	return [self existingPathAtPath:[basePath stringByAppendingPathComponent:appName]];
}

- (NSString *) pathForProductNamed:(NSString *)prodName {
		
	NSString * currentProductPath = [[self productKeysPath] stringByAppendingPathComponent:prodName];
	
	NSDate *date = [NSDate date];
	NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
	[dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
	[dateFormatter setDateFormat:@"yyyyMMdd-HHmmss"];
	NSString *dateString = [dateFormatter stringFromDate:date];
	
	NSString * path = [self existingPathAtPath:currentProductPath]; // 
	return [self existingPathAtPath:[path stringByAppendingPathComponent:dateString]];	
}

- (NSString *) productKeysPath {
	
	NSString * applicationSupportFolder = [self applicationSupportFolder];
	return [self existingPathAtPath:[applicationSupportFolder stringByAppendingPathComponent:@"Product Keys"]];
}

- (NSString *) licenceKeysPath {
	
	NSString * applicationSupportFolder = [self applicationSupportFolder];
	return [self existingPathAtPath:[applicationSupportFolder stringByAppendingPathComponent:@"Generated Licences"]];
}

- (NSString *) licenceTemplatesPath {
	
	NSString * applicationSupportFolder = [self applicationSupportFolder];
	return [self existingPathAtPath:[applicationSupportFolder stringByAppendingPathComponent:@"Licence Templates"]];
}

@end
