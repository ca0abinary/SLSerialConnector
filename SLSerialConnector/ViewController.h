//
//  ViewController.h
//  SLSerialConnector
//
//  Created by Jonathan DeMarks on 10/10/15.
//  Copyright (c) 2015 Jonathan DeMarks. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ViewController : NSViewController

@property (weak) IBOutlet NSTextFieldCell *LastCommandText;
@property (weak) IBOutlet NSMatrix *InputRadioGroup;
@property (weak) IBOutlet NSButtonCell *Camera1;
@property (weak) IBOutlet NSButtonCell *Camera2;
@property (weak) IBOutlet NSButtonCell *Media;
@property (weak) IBOutlet NSButtonCell *External;
@property (weak) IBOutlet NSButtonCell *Blackout;
@property (weak) IBOutlet NSComboBox *Device;

- (void)populateSerialPortComboBox;
- (void)outputSelectedInputToSwitchDevice:(int)inputNumber;

@end

