//
//  ViewController.m
//  FR-808
//
//  Created by Per-Olov Jernberg on 03/07/14.
//  Copyright (c) 2014 Per-Olov Jernberg. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVAudioPlayer.h>

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UILabel *statusText;
@property (weak, nonatomic) IBOutlet UIButton *button0;
@property (weak, nonatomic) IBOutlet UIButton *button1;
@property (weak, nonatomic) IBOutlet UIButton *button2;
@property (weak, nonatomic) IBOutlet UIButton *button3;
@property (weak, nonatomic) IBOutlet UIButton *button4;
@property (weak, nonatomic) IBOutlet UIButton *button5;
@property (weak, nonatomic) IBOutlet UIButton *button6;
@property (weak, nonatomic) IBOutlet UIButton *button7;
@property (strong, nonatomic) UIImage *baseButton;
@property (strong, nonatomic) UIImage *highlightButton;
@property (strong, nonatomic) AVAudioPlayer *sound0;
@property (strong, nonatomic) AVAudioPlayer *sound1;
@property (strong, nonatomic) AVAudioPlayer *sound2;
@property (strong, nonatomic) AVAudioPlayer *sound3;
@property (strong, nonatomic) AVAudioPlayer *sound4;
@property (strong, nonatomic) AVAudioPlayer *sound5;
@property (strong, nonatomic) AVAudioPlayer *sound6;
@property (strong, nonatomic) AVAudioPlayer *sound7;

@end

@implementation ViewController

- (IBAction)drum0Clicked:(id)sender {
    [self playSound:0];
}

- (IBAction)drum1Clicked:(id)sender {
    [self playSound:1];
}

- (IBAction)drum2Clicked:(id)sender {
    [self playSound:2];
}

- (IBAction)drum3Clicked:(id)sender {
    [self playSound:3];
}

- (IBAction)drum4Clicked:(id)sender {
    [self playSound:4];
}

- (IBAction)drum5Clicked:(id)sender {
    [self playSound:5];
}

- (IBAction)drum6Clicked:(id)sender {
    [self playSound:6];
}

- (IBAction)drum7Clicked:(id)sender {
    [self playSound:7];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupFuffr];

    self.baseButton = [UIImage imageNamed:@"button"];
    self.highlightButton = [UIImage imageNamed:@"buttonhighlight"];

    [self.button0 setImage:self.baseButton forState:UIControlStateNormal];
    
    [self.button1 setImage:self.baseButton forState:UIControlStateNormal];
    [self.button2 setImage:self.baseButton forState:UIControlStateNormal];
    [self.button3 setImage:self.baseButton forState:UIControlStateNormal];
    [self.button4 setImage:self.baseButton forState:UIControlStateNormal];
    [self.button5 setImage:self.baseButton forState:UIControlStateNormal];
    [self.button6 setImage:self.baseButton forState:UIControlStateNormal];
    [self.button7 setImage:self.baseButton forState:UIControlStateNormal];

    [self.button0 setImage:self.highlightButton forState:UIControlStateHighlighted];
    [self.button1 setImage:self.highlightButton forState:UIControlStateHighlighted];
    [self.button2 setImage:self.highlightButton forState:UIControlStateHighlighted];
    [self.button3 setImage:self.highlightButton forState:UIControlStateHighlighted];
    [self.button4 setImage:self.highlightButton forState:UIControlStateHighlighted];
    [self.button5 setImage:self.highlightButton forState:UIControlStateHighlighted];
    [self.button6 setImage:self.highlightButton forState:UIControlStateHighlighted];
    [self.button7 setImage:self.highlightButton forState:UIControlStateHighlighted];

    self.sound0 = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle]                                                                               pathForResource:@"sound0" ofType:@"wav"]] error:nil];

    self.sound1 = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle]                                                                               pathForResource:@"sound1" ofType:@"wav"]] error:nil];

    self.sound2 = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle]                                                                               pathForResource:@"sound2" ofType:@"wav"]] error:nil];

    self.sound3 = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle]                                                                               pathForResource:@"sound3" ofType:@"aif"]] error:nil];

    self.sound4 = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle]                                                                               pathForResource:@"sound4" ofType:@"wav"]] error:nil];

    self.sound5 = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle]                                                                               pathForResource:@"sound5" ofType:@"aif"]] error:nil];

    self.sound6 = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle]                                                                               pathForResource:@"sound6" ofType:@"wav"]] error:nil];

    self.sound7 = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle]                                                                               pathForResource:@"sound7" ofType:@"wav"]] error:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) showMessage:(NSString*)message
{
    self.statusText.text = message;
}


- (void) setupFuffr
{
    [self showMessage: @"Scanning for Fuffr..."];
    
    // Get a reference to the touch manager.
    FFRTouchManager* manager = [FFRTouchManager sharedManager];
    
    [manager onFuffrConnected:^{
         NSLog(@"Fuffr Connected");
         [self showMessage: @"Fuffr Connected"];
         [manager useSensorService:
          ^{
              // Sensor is available, set active sides.
              [[FFRTouchManager sharedManager]
               enableSides: FFRSideLeft | FFRSideRight | FFRSideTop | FFRSideBottom
               touchesPerSide: @5];
          }];
     }
     onFuffrDisconnected:
     ^{
         NSLog(@"Fuffr Disconnected");
         [self showMessage: @"Fuffr Disconnected"];
     }];
    
    // Register methods for touch events.
    [manager
     addTouchObserver: self
     touchBegan: @selector(touchesBegan:)
     touchMoved: @selector(touchesMoved:)
     touchEnded: @selector(touchesEnded:)
     sides: FFRSideLeft | FFRSideRight];
}

- (void) fuffrConnected
{
    NSLog(@"fuffrConnected");
}

- (void) playSound:(int) number {
    NSLog(@"playSound %d", number);
    self.statusText.text = [NSString stringWithFormat:@"Sound #%d", number+1];
    UIButton *b = nil;
    if (number == 0) b = self.button0;
    if (number == 1) b = self.button1;
    if (number == 2) b = self.button2;
    if (number == 3) b = self.button3;
    if (number == 4) b = self.button4;
    if (number == 5) b = self.button5;
    if (number == 6) b = self.button6;
    if (number == 7) b = self.button7;
    if (b != nil) {
        [b setImage:self.highlightButton forState:UIControlStateNormal];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.25 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [b setImage:self.baseButton forState:UIControlStateNormal];
        });
    }
    AVAudioPlayer *p = nil;
    if (number == 0) p = self.sound0;
    if (number == 1) p = self.sound1;
    if (number == 2) p = self.sound2;
    if (number == 3) p = self.sound3;
    if (number == 4) p = self.sound4;
    if (number == 5) p = self.sound5;
    if (number == 6) p = self.sound6;
    if (number == 7) p = self.sound7;
    [p stop];
    [p setCurrentTime:0];
    [p play];
}

- (void) touchesBegan: (NSSet*)touches
{
    for (FFRTouch* touch in touches)
    {
        NSLog(@"touch %d, %f, %f %@", touch.side, touch.normalizedLocation.x, touch.normalizedLocation.y, touch);
        
        bool left = (touch.normalizedLocation.x < 0.5);
        bool top = (touch.normalizedLocation.y < 0.5);

        if (touch.side == FFRSideLeft) {
            if (top) {
                [self playSound:(left ? 0 : 1)];
            } else {
                [self playSound:(left ? 4 : 5)];
            }
        }

        if (touch.side == FFRSideRight) {
            if (top) {
                [self playSound:(left ? 2 : 3)];
            } else {
                [self playSound:(left ? 6 : 7)];
            }
        }
    }
}

- (void) touchesMoved: (NSSet*)touches
{
}

- (void) touchesEnded: (NSSet*)touches
{
}


@end
