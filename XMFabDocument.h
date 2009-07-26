//
//  CodexFab
//
// XMFabDocument.h
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
#import <WebKit/WebKit.h>


@interface XMFabDocument : NSPersistentDocument {
	
	NSManagedObjectModel * managedObjectModel;
	
	IBOutlet WebView * webView;
	IBOutlet NSPanel * obfuscatorPanel;
	
	NSString * userName;
	NSString * code;
	NSString * validationResult;
	NSString * licenseURL;
	
	NSString * obfuscatedPublicKey;
	
	BOOL canGenerateDSA;
	BOOL canGenerateReg;
	BOOL canValidate;
}

@property (nonatomic, retain) NSString *licenseURL;
@property BOOL canValidate;
@property BOOL canGenerateReg;
@property BOOL canGenerateDSA;
@property (nonatomic, retain) NSString *validationResult;
@property (nonatomic, retain) NSString *code;
@property (nonatomic, retain) NSString *userName;

@property (nonatomic, retain) NSString *obfuscatedPublicKey;

- (NSManagedObjectModel *)managedObjectModel;

- (IBAction) generateDSA:(id)sender;
- (IBAction) generateRegCode:(id)sender;
- (IBAction) validateRegCode:(id)sender;	

- (id) product;
- (id) pem;

@end

@interface XMFabDocument (PathUtilities) 

- (NSString *)applicationSupportFolder;
- (NSString *) pathForProductNamed:(NSString *)name;
- (NSString *) productKeysPath;

@end


@interface XMFabDocument (PublicKeyObfuscation) 

- (IBAction) showObfusactorPanel:(id)sender;
- (IBAction) closeObfusactorPanel:(id)sender;
- (void)generateObfuscatedCode:(id)sender;
- (NSString *)obfuscatedCocoaCodeForPublicKey:(NSString*)publicKeyString;

@end






