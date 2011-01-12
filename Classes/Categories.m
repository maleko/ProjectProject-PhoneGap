/*
 * PhoneGap is available under *either* the terms of the modified BSD license *or* the
 * MIT License (2008). See http://opensource.org/licenses/alphabetical for full text.
 * 
 * Copyright (c) 2005-2010, Nitobi Software Inc.
 */


#import "Categories.h"
#import <math.h>

@implementation NSMutableDictionary(NSDictionary_Extension)

- (bool) existsValue:(NSString*)expectedValue forKey:(NSString*)key
{
	id val = [self valueForKey:key];
	bool exists = false;
	if (val != nil) {
		exists = [(NSString*)val compare:expectedValue options:NSCaseInsensitiveSearch] == 0;
	}
	
	return exists;
}

- (NSUInteger) integerValueForKey:(NSString*)key  defaultValue:(NSUInteger)defaultValue withRange:(NSRange)range
{
	NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
	[numberFormatter setRoundingMode:NSNumberFormatterRoundCeiling];
	
	NSUInteger value = defaultValue;
	
	id val = [self valueForKey:key];
	if (val != nil) {
		NSNumber* number = [numberFormatter numberFromString:(NSString*)val];
		value = [number unsignedIntValue];
	}
	
	[numberFormatter release];
	
	// min, max checks
	value = MAX(range.location, value);
	value = MIN(range.length, value);
	
	return value;
}

@end

