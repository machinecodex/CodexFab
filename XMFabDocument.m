//
//  CodexFab
//
// XMFabDocument.m
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
#import "CFobLicVerifier.h"
#import "CFobLicGenerator.h"
#import "XMArgumentKeys.h"
#import "XMDSAKeyGenerator.h"
#import "NSData+Base64Extensions.h"


@interface XMFabDocument (Private) 

- (void) registerAsObserver;

- (NSString *) workingDirectory;

- (NSString *) regCodeWithPrivateKey:(NSString *)privKey regName:(NSString *)regName;
- (BOOL) verifyRegCode:(NSString *)regCode forName:(NSString *)regName publicKey:(NSString *)pubKeyBase64;

- (void) updateCanGenerateDSA;
- (void) updateCanGenerateReg;
- (void) updateCanValidate;

- (void) generateLicenseURL;
- (NSString *) activationLinkHTML;

@end


@implementation XMFabDocument

@synthesize licenseURL;
@synthesize canValidate;
@synthesize canGenerateReg;
@synthesize canGenerateDSA;
@synthesize validationResult;
@synthesize code;
@synthesize userName;

#pragma mark -
#pragma mark Initialisation & dealloc

+ (void)registerDefaults {
	
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
	
	NSString * username = @"Test User";
	
	NSDictionary * appDefaults = [NSDictionary dictionaryWithObjectsAndKeys: 
								  
								  username, kXMRegName,
								  
								  nil];
	[defaults registerDefaults:appDefaults];	
}

+ (void) initialize {
	
	[self registerDefaults];
}

- (id)initWithType:(NSString *)typeName error:(NSError **)outError;
{
	// this method is invoked exactly once per document at the initial creation
	// of the document.  It will not be invoked when a document is opened after
	// being saved to disk.
	self = [super initWithType:typeName error:outError];
	if (self == nil)
		return nil;
	
	NSManagedObjectContext *managedObjectContext = [self managedObjectContext];
	
	// Create any singleton entities for the document
	[NSEntityDescription insertNewObjectForEntityForName:@"XMProduct"
								  inManagedObjectContext: managedObjectContext];	
	[NSEntityDescription insertNewObjectForEntityForName:@"XMPEM"
								  inManagedObjectContext: managedObjectContext];	

	[self updateCanGenerateDSA];
	
	return self;
}

- (id)init 
{
	self = [super init];
	if (self != nil) {
				
		self.canGenerateDSA = NO;
		self.canGenerateReg = NO;
		self.canValidate = NO;
	}
	return self;
}

- (NSString *)windowNibName 
{
    return @"MyDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)windowController 
{
    [super windowControllerDidLoadNib:windowController];
    // user interface preparation code

	id product = [self product];

	NSManagedObjectContext * managedObjectContext = [self managedObjectContext];
	[managedObjectContext refreshObject:product mergeChanges:YES];

	[product setValue:[self pem] forKey:@"PEM"];
	
	NSLog(@"%@", [self pem]);
	NSLog(@"%@", product);
	
	// clear the undo manager and change count for the document such that
	// newly opened documents start with zero unsaved changes
	[managedObjectContext processPendingChanges];
	[[managedObjectContext undoManager] removeAllActions];
	[self updateChangeCount:NSChangeCleared];
	
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
	
	self.userName = [defaults valueForKey:kXMRegName];
	self.code = [defaults valueForKey:kXMRegCode];
	
	[self registerAsObserver];
	
	NSLog(@"Initial load");
}

#pragma mark -
#pragma mark UI Actions

- (IBAction) generateDSA:(id)sender {
	
	id pem = [self pem];

	NSString * path = [self workingDirectory];
	XMDSAKeyGenerator * keyGen = [[[XMDSAKeyGenerator alloc] initWithWorkingDirectory:path] autorelease];
				
	NSString * params = [keyGen DSAParameters];
	[pem setValue:params forKey:@"parameters"];
		
	NSString * privKey = [keyGen unencryptedDSAPrivateKeyFromParameters:params];
	[pem setValue:privKey forKey:@"privateKey"];
	
	NSString * pubKey = [keyGen DSAPublicKeyFromPrivateKey:privKey];
	[pem setValue:pubKey forKey:@"publicKey"];
}

- (IBAction) generateRegCode:(id)sender {
	
	NSString * prodCode = [[self product] valueForKey:@"productCode"];

	// Here we match CocoaFob's licensekey.rb "productname,username" format
	NSString * regName = [NSString stringWithFormat:@"%@,%@", prodCode, self.userName];

	NSString * privateKey = [[self pem] valueForKey:@"privateKey"];
	
	if (regName && privateKey) {

		self.code = [self regCodeWithPrivateKey:privateKey regName:regName];
	}	
	
	[self generateLicenseURL];
	self.validationResult = @"";
}

- (IBAction) validateRegCode:(id)sender {
	
	NSString * prodCode = [[self product] valueForKey:@"productCode"];

	// Here we match CocoaFob's licensekey.rb "productname,username" format
	NSString * regName = [NSString stringWithFormat:@"%@,%@", prodCode, self.userName];
	
	NSString * regCode = self.code;
	NSString * publicKey = [[self pem] valueForKey:@"publicKey"];
	
	BOOL result = [self verifyRegCode:regCode forName:regName publicKey:publicKey];
	
	if (result) {
		
		self.validationResult = @"License valid";
	}
	else {
		
		self.validationResult = @"License invalid";
	}
	self.canValidate = NO;
}

#pragma mark -
#pragma mark Key Generation and Validation

- (NSString *) regCodeWithPrivateKey:(NSString *)privKey regName:(NSString *)regName 
{
	if (!privKey || !regName)
		return nil;
	
	CFobLicGenerator *generator = [CFobLicGenerator generatorWithPrivateKey:privKey];
	generator.regName = regName;
	
	NSLog(@"generator %@ %@", regName, privKey);
	
	if (![generator generate]) {
		
		return nil;		
	}
	
	return generator.regCode;
}

- (BOOL) verifyRegCode:(NSString *)regCode forName:(NSString *)regName publicKey:(NSString *)pubKey {
	
	CFobLicVerifier *verifier = [CFobLicVerifier verifierWithPublicKey:pubKey];
	verifier.regName = regName;
	verifier.regCode = regCode;
	
	if ([verifier verify])
		return YES;
	
	return NO;	
}


#pragma mark -
#pragma mark Utilities 

- (NSString *) documentTitle {
	
	NSString * docName = [[self product] valueForKey:@"name"];
	if ([docName length]) {
		
		return docName;
	}
		
	return @"Untitled Product";
}

- (NSString *) workingDirectory {
	
	NSString * docName = [self documentTitle];
		
	return [self pathForProductNamed:docName];
}

- (void) updateCanValidate {
	
	BOOL hasRegCode = [[self valueForKey:@"code"] length];
	
	if (hasRegCode) {
		
		self.canValidate = YES;
	}	
	else {
		
		self.canValidate = NO;
	}	
}

- (void) updateCanGenerateDSA {
	
	BOOL hasName = [[[self product] valueForKey:@"name"] length];
	BOOL hasProdCode = [[[self product] valueForKey:@"productCode"] length];

	if (!hasName || !hasProdCode) {
		
		self.canGenerateDSA = NO;
		return;
	}	

	BOOL hasParams = [[[self pem] valueForKey:@"parameters"] length];
	BOOL hasPrivateKey = [[[self pem] valueForKey:@"privateKey"] length];
	BOOL hasPublicKey = [[[self pem] valueForKey:@"publicKey"] length];
	
	if (hasParams || hasPrivateKey || hasPublicKey) {
		
		self.canGenerateDSA = NO;
		return;
	}	
		
	self.canGenerateDSA = YES;
}

- (void) updateCanGenerateReg {
	
	BOOL hasParams = [[[self pem] valueForKey:@"parameters"] length];
	BOOL hasPrivateKey = [[[self pem] valueForKey:@"privateKey"] length];
	BOOL hasPublicKey = [[[self pem] valueForKey:@"publicKey"] length];
	
	if (hasParams || hasPrivateKey || hasPublicKey) {
		
		self.canGenerateReg = YES;
	}	
	else {

		self.canGenerateReg = NO;
	}	
}

- (id) entityByName:(NSString *) name {
	
	NSFetchRequest *fetchRequest = [[[NSFetchRequest alloc] init] autorelease];
	[fetchRequest setEntity: [[managedObjectModel entitiesByName] valueForKey: name]];
	
	NSArray *items = [[self managedObjectContext] executeFetchRequest: fetchRequest error:nil];
	
	id item = nil;
	
	if ([items count]) {
		
		item =  [items objectAtIndex:0];
	}
	
	return item;	
}

- (id) product {
	
	return [self entityByName:@"XMProduct"];	
}

- (id) pem {
	
	return [self entityByName:@"XMPEM"];
}

- (void) updateActivationLink:(id)sender {
	
	[[webView mainFrame] loadHTMLString:[self activationLinkHTML] baseURL:[NSURL URLWithString:@"file:///"]];
}

- (void) generateLicenseURL {
	
	NSData * name = [[self userName] dataUsingEncoding:NSUTF8StringEncoding];
	NSString * nameB64 = [name encodeBase64];
	NSString * scheme = [[self product] valueForKey:@"licenseURLScheme"];
	NSString * licenseCode = self.code;
	
	self.licenseURL = [NSString stringWithFormat:@"%@://%@/%@", scheme, nameB64, licenseCode];
	
	[self updateActivationLink:self];
}

- (NSString *) activationLinkHTML  {
	
	NSString * url = self.licenseURL;
	NSString * stylePath = [[NSBundle mainBundle] pathForResource:@"style" ofType:@"css"];
	
	NSString * style = [NSString stringWithFormat:@"<link href=\"%@\" rel=\"stylesheet\" type=\"text/css\"/>", stylePath];

	NSString * html = [NSString stringWithFormat:@"<html><head>%@</head><body><a href=\"%@\">ACTIVATE NOW<a></body></html>", style, url];
	
	NSLog(@"%@", html);
	return html;
}

#pragma mark -
#pragma mark KVO

- (void)registerAsObserver {
	
	[self addObserver:self forKeyPath:@"code" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:nil];
	
	[[self pem] addObserver:self forKeyPath:@"parameters" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:nil];
	[[self pem] addObserver:self forKeyPath:@"publicKey" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:nil];
	[[self pem] addObserver:self forKeyPath:@"privateKey" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:nil];
	
	[[self product] addObserver:self forKeyPath:@"name" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:nil];
	[[self product] addObserver:self forKeyPath:@"productCode" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath  ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	
	if ([keyPath isEqual:@"parameters"] || [keyPath isEqual:@"publicKey"] || [keyPath isEqual:@"privateKey"]) {
		
		[self updateCanGenerateDSA];
		[self updateCanGenerateReg];
	}
	
	if ([keyPath isEqual:@"code"]) {
		
		[self updateCanValidate];
	}
	if ([keyPath isEqual:@"productCode"] || [keyPath isEqual:@"name"]) {
		
		[self updateCanGenerateDSA];
		[self updateCanGenerateReg];
	}
}

#pragma mark -
#pragma mark Core Data

- (NSManagedObjectModel *)managedObjectModel {
	
	if (managedObjectModel != nil) {
		return managedObjectModel;
	}
	
	managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles:nil] retain];    
	return managedObjectModel;	
}

@end

