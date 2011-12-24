//
//  LanguageInformation.h
//  BibleReadingMenulet
//
//  Created by Yuji Hirose on 12/22/11.
//  Copyright (c) 2011 Yuji Hirose. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LanguageInformation : NSObject

@property (nonatomic, strong, readonly) NSArray *infoArray;

- (NSString *)pageURLWithLanguage:(NSString *)lang book:(NSString*)book chapter:(NSNumber *)chap;
- (NSString *)mp3URLWithLanguage:(NSString *)lang book:(NSString*)book chapter:(NSNumber *)chap;
- (NSArray *)makeChapterListFromRange:(NSString *)range language:(NSString *)lang;
- (NSString *)translateRange:(NSString *)str language:(NSString *)lang;

@end