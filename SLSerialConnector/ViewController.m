//
//  ViewController.m
//  SLSerialConnector
//
//  Created by Jonathan DeMarks on 10/10/15.
//  Copyright (c) 2015 Jonathan DeMarks. All rights reserved.
//

#import "ViewController.h"
#import <asl.h>
#include <sys/ioctl.h>
#include <termios.h>
#include <IOKit/serial/IOSerialKeys.h>

@implementation ViewController

NSTimer *timer = NULL;

- (void)viewDidLoad {
    [super viewDidLoad];

    // Configure a timer to monitor the logs (250 ms poll)
    timer = [NSTimer scheduledTimerWithTimeInterval: 0.2 target:self selector:@selector(performPolledSearch) userInfo:nil repeats:true];
    
    [self populateSerialPortComboBox];
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
            case 0: [_Camera1 setState:TRUE];
                [self outputSelectedInputToSwitchDevice:3]; break;
            case 1: [_Camera2 setState:TRUE];
                [self outputSelectedInputToSwitchDevice:4]; break;
            case 2: [_Media setState:TRUE];
                [self outputSelectedInputToSwitchDevice:7]; break;
            case 3: [_External setState:TRUE];
                [self outputSelectedInputToSwitchDevice:2]; break;
            case 4: [_Blackout setState:TRUE];
                [self outputSelectedInputToSwitchDevice:7]; break;
            default: break;
        }
        
        currentInput = lastInput;
    }
}

- (void)populateSerialPortComboBox {
    int index = 0, indexOfSerialPort = -1;
    io_object_t serialPort;
    io_iterator_t serialPortIterator;
    
    // ask for all the serial ports
    IOServiceGetMatchingServices(
                                 kIOMasterPortDefault,
                                 IOServiceMatching(kIOSerialBSDServiceValue),
                                 &serialPortIterator);
    
    // loop through all the serial ports
    [_Device removeAllItems];
    while ((serialPort = IOIteratorNext(serialPortIterator))) {
        CFTypeRef bsdPathAsCFString = IORegistryEntryCreateCFProperty(serialPort,
                                        CFSTR(kIOCalloutDeviceKey),
                                        kCFAllocatorDefault,
                                        0);
        if (bsdPathAsCFString) {
            if (CFStringFind(bsdPathAsCFString, CFSTR("usbserial"), kCFCompareBackwards).location > -1) {
                indexOfSerialPort = index;
            }
            [_Device addItemWithObjectValue: (__bridge NSString *)bsdPathAsCFString];
            CFRelease(bsdPathAsCFString);
        }

        IOObjectRelease(serialPort);
        index++;
    }
    
    IOObjectRelease(serialPortIterator);
    if (indexOfSerialPort > -1) [_Device selectItemAtIndex:indexOfSerialPort];
}

int fd = -1;
- (void)outputSelectedInputToSwitchDevice:(int)inputNumber {
    if (fd == -1) {
        // open the serial like POSIX C
        fd = open([(NSString *)[_Device objectValueOfSelectedItem] cStringUsingEncoding:NSASCIIStringEncoding], O_WRONLY | O_NOCTTY | O_NONBLOCK);
        
        /* set the other settings (in this case, 9600 8N1) */
        struct termios original, settings;
        tcgetattr(fd, &original);
        cfmakeraw(&settings);
        ioctl(fd, IOSSIOSPEED, B9600);
    }
    if (fd == -1) return;
    
    // Build output string
    char output[4];
    sprintf(output, "%u!\r\n", inputNumber);

    // Send the channel change event over the serial port
    write(fd, &output, sizeof(output));
    tcdrain(fd);
}

@end
