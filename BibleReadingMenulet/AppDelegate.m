//
//  AppDelegate.m
//  BibleReadingMenulet
//
//  Created by Yuji Hirose on 12/12/11.
//  Copyright (c) 2011 Yuji Hirose. All rights reserved.
//

#import "AppDelegate.h"
#import "SchedulePanelController.h"
#import "Utility.h"

@implementation AppDelegate

enum MenuTag
{
    ReadMenuTag = 0,
    SchoolMenuTag = 1,
    LanguageMenuTag = 2
};

- (void)setupScheduleFiles
{
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *resourcePath = [bundle resourcePath];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    for (NSString *fileName in [fileManager contentsOfDirectoryAtPath:resourcePath error:nil])
    {
        if ([fileName hasSuffix:@".csv"])
        {
            NSString *path = [[Utility appDirPath] stringByAppendingPathComponent:fileName];
            
            if (![fileManager fileExistsAtPath:path])
            {
                NSString *tmplPath = [resourcePath stringByAppendingPathComponent:fileName];
                
                [fileManager copyItemAtPath:tmplPath toPath:path error:nil];
            }   
        }
    }    
}

- (void)setupStatusMenuTitle
{
    if ([_schedule isComplete])
    {
        [_statusItem setTitle:@"Congratulations!!"];
    }
    else
    {
        NSString *range = [_schedule currentRange];        
        
        NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
        NSString *lang = [ud stringForKey:@"LANGUAGE"];
        
        NSString *vernacularRane = [_langInfo translateRange:range language:lang];
        
        [_statusItem setTitle:vernacularRane];
    }    
}

- (void)setupReadMenu
{
    NSMenuItem *menuRead = [_menu itemWithTag:ReadMenuTag];
    
    if (_schedule == nil)
    {
        return;
    }
    
    if ([_schedule isComplete])
    {
        [menuRead setSubmenu:nil];
    }
    else
    {
        NSString *range = [_schedule currentRange];        
        
        NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
        NSString *lang = [ud stringForKey:@"LANGUAGE"];

        NSMutableDictionary *prevProgress = [Utility getProgress:@"SCHEDULE_PROGRESS"];
        NSMutableDictionary *progress = [NSMutableDictionary dictionary];        
        
        _chapList = [_langInfo makeChapterListFromRange:range language:lang];
        
        NSMenu *menuChapters = [[NSMenu alloc] init];        
        
        int i = 0;
        for (NSDictionary *item in _chapList)
        {
            NSString *label = [item valueForKey:@"label"];
            NSString *bookChapId = [item valueForKey:@"bookChapId"];

            NSMenuItem *menuItem = [menuChapters addItemWithTitle:label
                                                           action:@selector(readAction:)
                                                    keyEquivalent:@""];
            
            [menuItem setTag:i];
            
            if ([prevProgress valueForKey:bookChapId])
            {
                [menuItem setState:NSOnState];
                [progress setValue:@YES forKey:bookChapId];
            }
            
            i++;
        }
        
        [menuRead setSubmenu:menuChapters];
        
        [Utility setProgress:progress type:@"SCHEDULE_PROGRESS"];
    }
}

- (NSString *)htmlDirPath {
    NSString *dirPath = [Utility appDirPath];
    return [dirPath stringByAppendingPathComponent:@"html"];
}

- (NSString *)htmlPathWithLanguage:(NSString *)lang book:(NSString *)book chapter:(NSNumber *)chap {
    NSString *dirPath = [self htmlDirPath];
    NSString *fileName = [NSString stringWithFormat:@"%@_%@_%@.html", book, chap, lang];
    return [dirPath stringByAppendingPathComponent:fileName];
}

- (NSString *)htmlTemplatePath {
    NSBundle *bundle = [NSBundle mainBundle];
    return [bundle pathForResource:@"Template" ofType:@"html"];
}

- (NSString *)setupHTMLFileWithLanguage:(NSString *)lang book:(NSString *)book chapter:(NSNumber *)chap
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // Copy HTML support files
    if (![fileManager fileExistsAtPath:[self htmlDirPath]])
    {
        NSBundle *bundle = [NSBundle mainBundle];
        NSString *srcPath = [[bundle resourcePath] stringByAppendingPathComponent:@"html"];
        
        NSString *dstPath = [self htmlDirPath];
        
        NSError *error;
        [fileManager moveItemAtPath:srcPath toPath:dstPath error:&error];
    }
    
    // Create a reading HTML file.
    NSString *path = [self htmlPathWithLanguage:lang
                                           book:book
                                        chapter:chap];
    
    if (![fileManager fileExistsAtPath:path])
    {
        NSString *urlStr = [_langInfo wolPageURLWithLanguage:lang
                                                        book:book
                                                     chapter:chap];
        if (urlStr == nil)
        {
            return nil;
        }
        
        NSURL *url = [NSURL URLWithString:urlStr];
        
        NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
        NSURLResponse *resp;
        NSError *err;
        
        NSData *data = [NSURLConnection sendSynchronousRequest:req
                                             returningResponse:&resp
                                                         error:&err];
        if (data == nil)
        {
            return nil;
        }
        
        NSString *nwtHTML = [[NSString alloc] initWithData:data
                                                  encoding:NSUTF8StringEncoding];
        
        NSString *tmplPath = [self htmlTemplatePath];
        
        NSString *tmpl = [NSString stringWithContentsOfFile:tmplPath
                                                   encoding:NSUTF8StringEncoding
                                                      error:nil];
        
        NSString *html = [NSString stringWithFormat:tmpl,
                          [Utility getTitleWol:nwtHTML],
                          [Utility getContentWol:nwtHTML],
                          lang,
                          @([_langInfo getBookNo:book]),
                          chap];
        
        [html writeToFile:path
               atomically:YES
                 encoding:NSUTF8StringEncoding
                    error:nil];
    }
    
    return path;
}

- (void)setupLanguageMenu
{    
    NSMenu *menuLangs = [[NSMenu alloc] init];

    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];

    NSString *currLangSymbol = [ud stringForKey:@"LANGUAGE"];
    
    int i = 0;
    for (NSDictionary* val in _langInfo.infoArray)
    {
        NSString *name = [val valueForKey:@"name"];
        NSString *symbol = [val valueForKey:@"symbol"];

        if ([symbol isEqualToString:@"*"])
            continue;
        
        NSMenuItem *menuItem = [menuLangs addItemWithTitle:name
                                                    action:@selector(langAction:)
                                             keyEquivalent:@""];
        
        [menuItem setState:[currLangSymbol isEqualToString:symbol] ? NSOnState : NSOffState];

        [menuItem setTag:i];
        
        i++;
    }    
    
    [[_menu itemWithTag:LanguageMenuTag] setSubmenu:menuLangs];    
}

- (void)setupSchoolMenu
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    NSString *lang = [ud stringForKey:@"LANGUAGE"];
    
    NSMutableDictionary *prevProgress = [Utility getProgress:@"SCHOOL_SCHEDULE_PROGRESS"];
    NSMutableDictionary *progress = [NSMutableDictionary dictionary];
    
    _chapListForSchool = [NSMutableArray array];
    NSMenu *menuChapters = [[NSMenu alloc] init];
    
    int i = 0;
    for (NSString *range in [Utility getRangesForSchool])
    {
        if (i != 0)
        {
            [menuChapters addItem:[NSMenuItem separatorItem]];
        }
        
        NSMutableArray *chapList = [_langInfo makeChapterListFromRange:range language:lang];
        
        for (NSDictionary *item in chapList)
        {
            NSString *label = [item valueForKey:@"label"];
            NSString *bookChapId = [item valueForKey:@"bookChapId"];
                        
            NSMenuItem *menuItem = [menuChapters addItemWithTitle:label
                                                           action:@selector(readActionForSchool:)
                                                    keyEquivalent:@""];
            
            [menuItem setTag:i];
            
            if ([prevProgress valueForKey:bookChapId])
            {
                [menuItem setState:NSOnState];
                [progress setValue:@YES forKey:bookChapId];
            }
            
            i++;
        }
        
        [_chapListForSchool addObjectsFromArray:chapList];
    }    
    
    [[_menu itemWithTag:SchoolMenuTag] setSubmenu:menuChapters];
    
    [Utility setProgress:progress type:@"SCHOOL_SCHEDULE_PROGRESS"];
}

- (void)setupUserDefaults
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
    
    defaults[@"LANGUAGE"] = @"e";
    defaults[@"SCHEDULE"] = @"Schedule.csv";
    defaults[@"PROGRESS"] = @"progress.xml";
    
    [ud registerDefaults:defaults];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self setupUserDefaults];
    [self setupScheduleFiles];

    // Create the application directory
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:[Utility appDirPath]])
    {
        [fileManager createDirectoryAtPath:[Utility appDirPath]
               withIntermediateDirectories:YES
                                attributes:nil
                                     error:nil];
    }
    
    // Register event observers
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(setupStatusMenuTitle) name:@"currentRangeChanged" object:nil];
    [nc addObserver:self selector:@selector(setupStatusMenuTitle) name:@"languageChanged" object:nil];
    
    // Make menulet
    _statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [_statusItem setMenu:_menu];
    [_statusItem setHighlightMode:YES];    
    [_menu setDelegate:self];
    
    _langInfo = [LanguageInformation instance];
    _schedule = [[Schedule alloc] initWithPath:[Utility schedulePath]];
    
    [self setupStatusMenuTitle];
}

- (void)read:(id)sender chapterList:(NSMutableArray *)chapList type:(NSString *)type
{
    NSInteger i = [sender tag];
    NSDictionary *item = chapList[i];

    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *progress = [Utility getProgress:type];
  
    [progress setValue:@YES forKey:[item valueForKey:@"bookChapId"]];
    [Utility setProgress:progress type:type];

    NSString *book = [item valueForKey:@"book"];
    NSNumber *chap = [item valueForKey:@"chap"];    
    NSString *lang = [ud stringForKey:@"LANGUAGE"];

    NSString *urlStr = [self setupHTMLFileWithLanguage:lang
                                                  book:book
                                               chapter:chap];

    NSURL *url = nil;
    
    if (urlStr)
    {
        url = [NSURL fileURLWithPath:urlStr];
    }
    else
    {
        urlStr = [_langInfo pageURLWithLanguage:lang
                                           book:book
                                        chapter:chap];
        
        url = [NSURL URLWithString:urlStr];
    }

    if (url == nil)
    {
        NSRunAlertPanel(NSLocalizedString(@"OPEN_ERR_TTL", @"Title for Open error"),
                        NSLocalizedString(@"OPEN_ERR_MSG", @"Message for open error"),
                        @"OK", nil, nil);
        
        return;
    }
    
    [[NSWorkspace sharedWorkspace] openURL:url];
}

- (IBAction)readAction:(id)sender
{
    [self read:sender chapterList:_chapList type:@"SCHEDULE_PROGRESS"];
}

- (IBAction)readActionForSchool:(id)sender
{
    [self read:sender chapterList:_chapListForSchool type:@"SCHOOL_SCHEDULE_PROGRESS"];
}

- (IBAction)langAction:(id)sender
{
    NSInteger i = [sender tag];
    NSDictionary *item = (_langInfo.infoArray)[i];
    
    NSString *lang = [item valueForKey:@"symbol"];
    
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud setObject:lang forKey:@"LANGUAGE"];
    [ud synchronize];
    
    NSNotification *n = [NSNotification notificationWithName:@"languageChanged" object:self];
    [[NSNotificationCenter defaultCenter] postNotification:n];
}

- (IBAction)markAsReadAction:(id)sender
{
    [_schedule markAsRead];
}

- (IBAction)quitAction:(id)sender
{
    [NSApp terminate:self];
}

- (IBAction)showSchedulePanel:(id)sender
{
    if (!_schedulePanelController)
    {
        _schedulePanelController = [[SchedulePanelController alloc] initWithSchedule:_schedule];
    }
    
    [NSApp activateIgnoringOtherApps:YES];
    [_schedulePanelController showWindow:self];
    [[_schedulePanelController window] makeKeyAndOrderFront:self];
}

- (void)menuWillOpen:(NSMenu *)menu
{
    // Update language info and schedule.
    _langInfo = [LanguageInformation instance];
    _schedule = [[Schedule alloc] initWithPath:[Utility schedulePath]];
    
    [self setupStatusMenuTitle];
    [self setupReadMenu];
    [self setupLanguageMenu];
    [self setupSchoolMenu];
}

@end
