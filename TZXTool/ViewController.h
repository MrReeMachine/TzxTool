//
//  ViewController.h
//  TZXTool
//
//  Created by Richard Baxter on 11/11/2019.
//  Copyright © 2019 OhCrikey!. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ViewController : NSViewController <NSTableViewDelegate, NSTableViewDataSource>



@property (weak) IBOutlet NSTextField *fileNameLabel;
@property (weak) IBOutlet NSTableView *tableView;
@property (weak) IBOutlet NSButton *rewindButton;
@property (weak) IBOutlet NSButton *skipBackButton;
@property (weak) IBOutlet NSButton *playPauseButton;
@property (weak) IBOutlet NSButton *skipForwardButton;
@property (weak) IBOutlet NSTextField *timeLabel;
@property (weak) IBOutlet NSTextField *volumeLabel;
@property (weak) IBOutlet NSSlider *volumeSlider;
@property (weak) IBOutlet NSSlider *timeSlider;



@end

