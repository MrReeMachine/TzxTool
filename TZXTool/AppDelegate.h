//
//  AppDelegate.h
//  TZXTool
//
//  Created by Richard Baxter on 11/11/2019.
//  Copyright © 2019 OhCrikey!. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CoreData/CoreData.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (readonly, strong) NSPersistentContainer *persistentContainer;


@end

