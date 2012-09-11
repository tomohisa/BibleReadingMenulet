//
//  BRMNSComboBox.m
//  BibleReadingMenulet
//
//  Created by Tomohisa Takaoka on 9/5/12.
//  Copyright (c) 2012 Yuji Hirose. All rights reserved.
//

#import "BRMNSComboBox.h"

@implementation BRMNSComboBox

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

-(void) awakeFromNib {
    [super awakeFromNib];
    
    for (int i=0; i<self.numberOfItems; i++) {
        id obj = [self itemObjectValueAtIndex:i];
        NSString *str = NSLocalizedString(obj, nil);
        if ([str compare:obj]) {
            [self insertItemWithObjectValue:str atIndex:i];
            [self removeItemWithObjectValue:obj];
        }
    }
}

@end
