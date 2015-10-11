//
//  ViewController.m
//  SLSerialConnector
//
//  Created by Jonathan DeMarks on 10/10/15.
//  Copyright (c) 2015 Jonathan DeMarks. All rights reserved.
//

#import "ViewController.h"
#import <asl.h>

@implementation ViewController

NSTimer *timer = NULL;

- (void)viewDidLoad {
    [super viewDidLoad];

    // Configure a timer to monitor the logs (250 ms poll)
    timer = [NSTimer scheduledTimerWithTimeInterval: 0.25 target:self selector:@selector(performPolledSearch) userInfo:nil repeats:true];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

bool isBlack = false;
int currentInput = 0;
NSString *lastMessageId = NULL;
- (void)performPolledSearch {
    // Setup the ASL query
    aslmsg m = asl_new(ASL_TYPE_QUERY);
    asl_set_query(m, ASL_KEY_SENDER, "SLStudio KH", ASL_QUERY_OP_EQUAL);
    if (lastMessageId != NULL) {
        asl_set_query(m, ASL_KEY_MSG_ID, [lastMessageId UTF8String], ASL_QUERY_OP_GREATER | ASL_QUERY_OP_NUMERIC);
    }
    
    // Scan new logs looking for input change messages
    int lastInput = -1;
    NSString *lastMessage = NULL;
    
    aslmsg msg;
    aslresponse r = asl_search(NULL, m);
    while (NULL != (msg = asl_next(r))) {
        lastMessage = [NSString stringWithCString:asl_get(msg, "Message") encoding:NSStringEncodingConversionAllowLossy];
        lastMessageId = [NSString stringWithCString:asl_get(msg, ASL_KEY_MSG_ID) encoding:NSStringEncodingConversionAllowLossy];
        if ([lastMessage rangeOfString:@"switchSource"].location != NSNotFound) {
            lastInput = atoi(&[lastMessage UTF8String][[lastMessage length]-1]);
        }
    }
    aslresponse_free(r);
    free(m);
    
    if (lastMessage != NULL) {
        [_LastCommandText setTitle:lastMessage];
    }
    
    if (lastInput > -1 && currentInput != lastInput) {
        [_Camera1 setState:FALSE];
        [_Camera2 setState:FALSE];
        [_Media setState:FALSE];
        [_External setState:FALSE];
        [_Blackout setState:FALSE];
        
        switch (lastInput) {
            case 0: [_Camera1 setState:TRUE]; break;
            case 1: [_Camera2 setState:TRUE]; break;
            case 2: [_Media setState:TRUE]; break;
            case 3: [_External setState:TRUE]; break;
            case 4: [_Blackout setState:TRUE]; break;
            default: break;
        }
        
        currentInput = lastInput;
        
        // Can set the hardware switcher here via a serial command (or what have you)
    }
}

@end
