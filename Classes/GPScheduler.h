//
//  UpdateScheduler.h
//  Cube Patterns 3
//
//  Created by Anton Holmberg on 2012-12-15.
//  Copyright (c) 2012 Anton Holmberg. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

@interface GPScheduler : NSObject

+ (GPScheduler *)defaultScheduler;

- (void)scheduleUpdates:(id)obj;
- (void)unscheduleUpdates:(id)obj;

- (void)update:(GLKViewController *)vc;

@end