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

- (id) init {
	
	return [self initWithWorkingDirectory:@"/tmp/"];
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
		
	NSString * outFilePath = @"dsaparam.pem";

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
		
	NSString * outFilePath = @"privkey.pem";
	
	NSArray * arguments = [NSArray arrayWithObjects:
						   
						   @"gendsa",
						   @"-out",
						   outFilePath,
						   @"dsaparam.pem",
						   
						   nil ];
	
	[self opensslTaskWithArguments:arguments];
	
	return [NSString stringWithContentsOfFile:outFilePath];
}


- (id) DSAPublicKeyFromPrivateKey:(NSString *)privateKey {
	
	//	openssl dsa -in privkey.pem -pubout -out pubkey.pem
	
	NSString * outFilePath = @"pubkey.pem";
	
	NSArray * arguments = [NSArray arrayWithObjects:
						   
						   @"dsa",
						   @"-in",
						   @"privkey.pem",
						   @"-pubout", 
						   @"-out",
						   outFilePath,
						   
						   nil ];
	
	[self opensslTaskWithArguments:arguments];	
	return [NSString stringWithContentsOfFile:outFilePath];
}

@end

