//
//  CodexFab
//
// XMDSAKeyGenerator.h
//
//  Licensed under CC Attribution License 3.0 <http://creativecommons.org/licenses/by/3.0/>
//
// Based on CocoaFob by Gleb Dolgich
// <http://github.com/gbd/cocoafob/tree/master>
//
//  Created by Alex Clarke on 10/06/09.
//  Copyright 2009 MachineCodex Software Australia. All rights reserved.
// <http://www.machinecodex.com>


#import <Cocoa/Cocoa.h>


@interface XMDSAKeyGenerator : NSObject {

	NSString * workingDirectory;
}

@property (nonatomic, retain) NSString *workingDirectory;

- (id) initWithWorkingDirectory:(NSString *)path;

- (id) DSAParameters;
- (id) unencryptedDSAPrivateKeyFromParameters:(NSString *)parameters;
- (id) DSAPublicKeyFromPrivateKey:(NSString *)privateKey;

@end

