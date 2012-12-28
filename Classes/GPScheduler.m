//
//  UpdateScheduler.m
//  GLKit++
//
//  Created by Anton Holmberg on 2012-12-15.
//  Copyright (c) 2012 Anton Holmberg. All rights reserved.
//

#import "GPScheduler.h"

@interface GPScheduler ()

@property NSMutableArray *scheduledObjects;

@end

@implementation GPScheduler

static GPScheduler *SHARED_INSTANCE;

+ (GPScheduler *)defaultScheduler {
    if(!SHARED_INSTANCE) {
        SHARED_INSTANCE = [[GPScheduler alloc] init];
    }
    return SHARED_INSTANCE;
}

- (id)init {
    if(self = [super init]) {
        self.scheduledObjects = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)scheduleUpdates:(id)obj {
    [self.scheduledObjects addObject:obj];
}

- (void)unscheduleUpdates:(id)obj {
    [self.scheduledObjects removeObject:obj];
}

- (void)update:(GLKViewController *)vc {
    
    for(id obj in [self.scheduledObjects copy]) {
        [obj update:vc];
    };
}

@end
