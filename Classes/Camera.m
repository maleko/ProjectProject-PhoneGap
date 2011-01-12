/*
 * PhoneGap is available under *either* the terms of the modified BSD license *or* the
 * MIT License (2008). See http://opensource.org/licenses/alphabetical for full text.
 * 
 * Copyright (c) 2005-2010, Nitobi Software Inc.
 * Copyright (c) 2010, IBM Corporation
 */

#import "Camera.h"
#import "NSData+Base64.h"
#import "Categories.h"
#import "PhonegapDelegate.h"
#import <MobileCoreServices/UTCoreTypes.h>

@implementation Camera

- (void) getPicture:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options
{
	NSUInteger argc = [arguments count];
	NSString* successCallback = nil, *errorCallback = nil;
	
	if (argc > 0) successCallback = [arguments objectAtIndex:0];
	if (argc > 1) errorCallback = [arguments objectAtIndex:1];
	
	if (argc < 1) {
		NSLog(@"Camera.getPicture: Missing 1st parameter.");
		return;
	}
	
	NSString* sourceTypeString = [options valueForKey:@"sourceType"];
	UIImagePickerControllerSourceType sourceType = UIImagePickerControllerSourceTypeCamera; // default
	if (sourceTypeString != nil) {
		sourceType = (UIImagePickerControllerSourceType)[sourceTypeString intValue];
	}

	bool hasCamera = [UIImagePickerController isSourceTypeAvailable:sourceType];
	if (!hasCamera) {
		NSLog(@"Camera.getPicture: source type %d not available.", sourceType);
		return;
	}

    bool allowEdit = [[options valueForKey:@"allowEdit"] boolValue];
	
	
	if (pickerController == nil) {
		pickerController = [[CameraPicker alloc] init];
	}
	
	pickerController.delegate = self;
	pickerController.sourceType = sourceType;
	pickerController.allowsEditing = allowEdit; // THIS IS ALL IT TAKES FOR CROPPING - jm
	pickerController.successCallback = successCallback;
	pickerController.errorCallback = errorCallback;
	pickerController.quality = [options integerValueForKey:@"quality" defaultValue:100 withRange:NSMakeRange(0, 100)];
	pickerController.returnType = (DestinationType)[options integerValueForKey:@"destinationType" defaultValue:0 withRange:NSMakeRange(0, 2)];
	
	[[super appViewController] presentModalViewController:pickerController animated:YES];
}

- (void)imagePickerController:(UIImagePickerController*)picker didFinishPickingMediaWithInfo:(NSDictionary*)info
{
	CameraPicker* cameraPicker = (CameraPicker*)picker;
	CGFloat quality = (double)cameraPicker.quality / 100.0; 
	
	[picker dismissModalViewControllerAnimated:YES];
	
	
	NSString* mediaType = [info objectForKey:UIImagePickerControllerMediaType];
	if ([mediaType isEqualToString:(NSString*)kUTTypeImage])
	{
		if (cameraPicker.successCallback) {
			
			NSString* jsString = NULL;
							// get the image
				UIImage* image = nil;
				if (cameraPicker.allowsEditing && [info objectForKey:UIImagePickerControllerEditedImage]){
					image = [info objectForKey:UIImagePickerControllerEditedImage];
				}else {
					image = [info objectForKey:UIImagePickerControllerOriginalImage];
				}
				NSData* data = UIImageJPEGRepresentation(image, quality);
				if (cameraPicker.returnType == DestinationTypeFileUri){
					
					// write to temp directory and reutrn URI
					// get the temp directory path
					NSString* docsPath = [[PhoneGapDelegate applicationDocumentsDirectory] stringByAppendingPathComponent: [PhoneGapDelegate tmpFolderName]];
					NSError* err = nil;
					NSFileManager* fileMgr = [[NSFileManager alloc] init]; //recommended by apple (vs [NSFileManager defaultManager]) to be theadsafe
					
					if ( [fileMgr fileExistsAtPath:docsPath] == NO ){ // check in case tmp dir got deleted
						[fileMgr createDirectoryAtPath:docsPath withIntermediateDirectories: NO attributes: nil error: nil];
					}
					// generate unique file name
					NSString* filePath;
					int i=1;
					do {
						filePath = [NSString stringWithFormat:@"%@/photo_%03d.jpg", docsPath, i++];
					} while([fileMgr fileExistsAtPath: filePath]);
					// save file
					if (![data writeToFile: filePath options: NSAtomicWrite error: &err]){
						jsString = [NSString stringWithFormat:@"%@(\"%@\");", cameraPicker.errorCallback, [err localizedDescription]];
					}else{	
						jsString = [NSString stringWithFormat:@"%@(\"%@\");", cameraPicker.successCallback, [NSURL fileURLWithPath: filePath]];
					}
					[fileMgr release];
				
				}else{
					jsString = [NSString stringWithFormat:@"%@(\"%@\");", cameraPicker.successCallback, [data base64EncodedString]];
				}
			[webView stringByEvaluatingJavaScriptFromString:jsString];
		}
	}
}
// older api calls newer didFinishPickingMediaWithInfo
- (void)imagePickerController:(UIImagePickerController*)picker didFinishPickingImage:(UIImage*)image editingInfo:(NSDictionary*)editingInfo
{
	NSDictionary* imageInfo = [NSDictionary dictionaryWithObject:image forKey:UIImagePickerControllerOriginalImage];
	[self imagePickerController:picker didFinishPickingMediaWithInfo: imageInfo];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController*)picker
{
	[picker dismissModalViewControllerAnimated:YES];
}

- (void) postImage:(UIImage*)anImage withFilename:(NSString*)filename toUrl:(NSURL*)url 
{
	NSString *boundary = @"----BOUNDARY_IS_I";

	NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
	[req setHTTPMethod:@"POST"];
	
	NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
	[req setValue:contentType forHTTPHeaderField:@"Content-type"];
	
	NSData *imageData = UIImagePNGRepresentation(anImage);
	
	// adding the body
	NSMutableData *postBody = [NSMutableData data];
	
	// first parameter an image
	[postBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"upload\"; filename=\"%@\"\r\n", filename] dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[@"Content-Type: image/png\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:imageData];
	
//	// second parameter information
//	[postBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
//	[postBody appendData:[@"Content-Disposition: form-data; name=\"some_other_name\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
//	[postBody appendData:[@"some_other_value" dataUsingEncoding:NSUTF8StringEncoding]];
//	[postBody appendData:[[NSString stringWithFormat:@"\r\n--%@--\r \n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	
	[req setHTTPBody:postBody];
	
	NSURLResponse* response;
	NSError* error;
	[NSURLConnection sendSynchronousRequest:req returningResponse:&response error:&error];

//  NSData* result = [NSURLConnection sendSynchronousRequest:req returningResponse:&response error:&error];
//	NSString * resultStr =  [[[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding] autorelease];
}


- (void) dealloc
{
	if (pickerController) {
		[pickerController release];
	}
	[super dealloc];
}

@end


@implementation CameraPicker

@synthesize quality, postUrl;
@synthesize returnType;
@synthesize successCallback;
@synthesize errorCallback;

- (void) dealloc
{
	if (successCallback) {
		[successCallback release];
	}
	if (errorCallback) {
		[errorCallback release];
	}
	
	[super dealloc];
}

@end
