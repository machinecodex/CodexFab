//
//  CodexFab
//
// XMDSAKeyGenerator.m
//
//  Licensed under CC Attribution License 3.0 <http://creativecommons.org/licenses/by/3.0/>
//
// Based on CocoaFob by Gleb Dolgich
// <http://github.com/gbd/cocoafob/tree/master>
//
//  Created by Alex Clarke on 10/06/09.
//  Copyright 2009 MachineCodex Software Australia. All rights reserved.
// <http://www.machinecodex.com>


#import "XMDSAKeyGenerator.h"
#import "NSString+PECrypt.h"
#import "NSData+PECrypt.h"
#import "NSString-Base64Extensions.h"
#import "XMArgumentKeys.h"


@implementation XMDSAKeyGenerator

@synthesize workingDirectory;


- (id) initWithWorkingDirectory:(NSString *)path
{
	self = [super init];
	if (self != nil) {

		self.workingDirectory = path;
	}
	return self;
}

- (NSString *)uuid
{
	CFUUIDRef uuidRef = CFUUIDCreate(NULL);
	CFStringRef uuidStringRef = CFUUIDCreateString(NULL, uuidRef);
	CFRelease(uuidRef);
	NSString *uuid = [NSString stringWithString:(NSString *)  
					  uuidStringRef];
	CFRelease(uuidStringRef);
	return uuid;
}

- (id) init {
	
	// an alternative to the NSTemporaryDirectory
	NSString *path = nil;
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	if ([paths count])
	{
		NSString *bundleName =
		[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
		NSString * guid = [self uuid];
		path = [[[paths objectAtIndex:0] stringByAppendingPathComponent:bundleName] stringByAppendingPathComponent:guid];
	}
	
	return [self initWithWorkingDirectory:path];
}


- (void) opensslTaskWithArguments:(NSArray *)arguments {
	
	NSString * launchPath = @"/usr/bin/";
	NSString * taskName = @"openssl";
	launchPath = [launchPath stringByAppendingString:taskName];

	NSTask *task=[[[NSTask alloc] init]autorelease];
	NSPipe *helpPipe=[NSPipe pipe];
	NSPipe *outPipe=[NSPipe pipe];
	
	[task setCurrentDirectoryPath:self.workingDirectory];
	NSLog(@"%@", [task currentDirectoryPath]);
	
	[task setStandardError:helpPipe];
	[task setStandardOutput:outPipe];
	[task setLaunchPath:launchPath];
	[task setArguments:arguments];
	NSLog(@"%@", task);
	
	[task launch];
	[task waitUntilExit];
	
	int status = [task terminationStatus];
	
	if (status ==0)
		NSLog(@"Task succeeded.");
	else
		NSLog(@"Task failed.");
}

- (id) DSAParameters {
	
	//	openssl dsaparam -out dsaparam.pem 512
		
	NSString * outFilePath = [self.workingDirectory stringByAppendingPathComponent:@"dsaparam.pem"];

	NSArray * arguments = [NSArray arrayWithObjects:
						   
						   @"dsaparam",
						   @"-out",
						   outFilePath,
						   @"512",
						   
						   nil ];
	
	[self opensslTaskWithArguments:arguments];
	
	return [NSString stringWithContentsOfFile:outFilePath];
}


- (id) unencryptedDSAPrivateKeyFromParameters:(NSString *)parameters {
	
	//     openssl gendsa -out privkey.pem dsaparam.pem
		
	NSString * inFilePath = [self.workingDirectory stringByAppendingPathComponent:@"dsaparam.pem"];
	NSString * outFilePath = [self.workingDirectory stringByAppendingPathComponent:@"privkey.pem"];
	
	NSArray * arguments = [NSArray arrayWithObjects:
						   
						   @"gendsa",
						   @"-out",
						   outFilePath,
						   inFilePath,
						   
						   nil ];
	
	[self opensslTaskWithArguments:arguments];
	
	return [NSString stringWithContentsOfFile:outFilePath];
}


- (id) DSAPublicKeyFromPrivateKey:(NSString *)privateKey {
	
	//	openssl dsa -in privkey.pem -pubout -out pubkey.pem
	
	NSString * inFilePath = [self.workingDirectory stringByAppendingPathComponent:@"privkey.pem"];
	NSString * outFilePath = [self.workingDirectory stringByAppendingPathComponent:@"pubkey.pem"];
	
	NSArray * arguments = [NSArray arrayWithObjects:
						   
						   @"dsa",
						   @"-in",
						   inFilePath,
						   @"-pubout", 
						   @"-out",
						   outFilePath,
						   
						   nil ];
	
	[self opensslTaskWithArguments:arguments];	
	return [NSString stringWithContentsOfFile:outFilePath];
}

@end

