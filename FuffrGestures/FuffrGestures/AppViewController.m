//
//  AppViewController.m
//  FuffrGestures
//
//  Created by Fuffr on 21/03/14.
//  Copyright (c) 2014 Fuffr. All rights reserved.
//

/*
 How to use: See instructions displayed on the screen.
 */

#import "AppViewController.h"

#import <FuffrLib/FFRTapGestureRecognizer.h>
#import <FuffrLib/FFRDoubleTapGestureRecognizer.h>
#import <FuffrLib/FFRLongPressGestureRecognizer.h>
#import <FuffrLib/FFRSwipeGestureRecognizer.h>
#import <FuffrLib/FFRPinchGestureRecognizer.h>
#import <FuffrLib/FFRPanGestureRecognizer.h>
#import <FuffrLib/FFRRotationGestureRecognizer.h>

@implementation AppViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self createMessageView];
    // Create an image view for drawing.
    self.imageView = [[UIImageView alloc] initWithFrame: self.view.bounds];
    self.imageView.autoresizingMask =
    UIViewAutoresizingFlexibleHeight |
    UIViewAutoresizingFlexibleWidth;
    
    [self.view addSubview:self.imageView];
    
    // Set background color.
    self.view.backgroundColor = [UIColor
                                 colorWithRed: 47/255.0
                                 green: 42/255.0
                                 blue: 32/255.0
                                 alpha: 1.0];
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleUITap:)];
    tapGestureRecognizer.delegate = self;
    [self.view addGestureRecognizer:tapGestureRecognizer];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear: animated];
    
    // Setup the fuffr connection and initialize some variables.
    [self setupFuffr];
    [self initializeRenderingParameters];
    [self drawImageView];
    [self startGravity];
    [self loadExplosionImageArray];
}

-(void)createMessageView
{
    self.messageView = [[UILabel alloc] initWithFrame: CGRectMake(10, 25, 300, 300)];
    self.messageView.textColor = [UIColor whiteColor];
    self.messageView.backgroundColor = [UIColor clearColor];
    self.messageView.userInteractionEnabled = NO;
    //self.messageView.autoresizingMask = UIViewAutoresizingNone;
    self.messageView.lineBreakMode = NSLineBreakByWordWrapping;
    self.messageView.numberOfLines = 0;
    self.messageView.text = @"";
    self.messageView.font = [UIFont fontWithName:@"GothamRounded-Book" size:19];
    [self.view addSubview: self.messageView];
}

-(void)showMessage:(NSString*)message
{
    self.messageView.text = message;
    self.messageView.frame = CGRectMake(10, 25, 300, 300);
    [self.messageView sizeToFit];
}

-(void)showInstructionMessage
{
    // Display the instruction text depending on the current active gestures.
    NSString *messageString;
    if (self.pinchRotateActive)
    {
        messageString = [NSString stringWithFormat:@"Right: Rotate to turn the image. \nLeft: Pinch to change size.\nBottom: Double tap to roll eyes.\nTop: Tap to change gestures."];
    }
    else
    {
        messageString = [NSString stringWithFormat:@"Right: Swipe up to jump. \nLeft: Pan to move around. \nBottom: Long press to explode.\nTop: Tap to change gestures."];
    }
    [self showMessage:messageString];
}

-(void)initializeRenderingParameters
{
    // Set the scale, rotation and offset to standard start values.
    
    self.baseScale = 1.0;
    self.currentScale = self.baseScale;
    
    self.baseRotation = 0.0;
    self.currentRotation = self.baseRotation;
    
    self.offsetSize = 80;
}

- (void)loadExplosionImageArray
{
    // Alloc the array and load it with all the Fuffr Guy animation images.
    self.explodeAnimationArray = [[NSMutableArray alloc] init];
    NSString *imageNameString = @"Fuffr Guy";
    for (int i = 2; i < 8; i++)
    {
        NSString *currentImageName = [imageNameString stringByAppendingString:[NSString stringWithFormat:@"%d.png", i]];
        [self.explodeAnimationArray addObject:[UIImage imageNamed:currentImageName]];
    }
}

- (void)setupFuffr
{
    // The connection code to start looking for a fuffr device, and add gesture recognizers.
    [self connectToFuffr];
    [self setupGesturesPanSwipe];
}

- (void)connectToFuffr
{
    [self showMessage: @"Scanning for Fuffr..."];
    
    // Get a reference to the touch manager.
    FFRTouchManager* manager = [FFRTouchManager sharedManager];
    
    // Set active sides.
    [manager
     onFuffrConnected:
     ^{
         [manager useSensorService:
          ^{
              NSLog(@"Fuffr Connected");
              [self showMessage: @"Fuffr Connected"];
              
              [[FFRTouchManager sharedManager]
               enableSides: FFRSideTop | FFRSideLeft | FFRSideRight | FFRSideBottom
               touchesPerSide: @2 // Touches per side.
               ];
              
              [self
               performSelector: @selector(showInstructionMessage)
               withObject: nil
               afterDelay: 1.0];
          }];
     }
     onFuffrDisconnected:
     ^{
         NSLog(@"Fuffr Disconnected");
         self.messageView.hidden = NO;
         [self showMessage: @"Fuffr Disconnected"];
     }];
}

// Define gesture handlers.
- (void)setupGesturesPanSwipe
{
    // Get a reference to the touch manager.
    FFRTouchManager* manager = [FFRTouchManager sharedManager];
    
    // Remove any existing gestures.
    [manager removeAllGestureRecognizers];
    
    // Add gestures.
    FFRSwipeGestureRecognizer* swipeUp = [FFRSwipeGestureRecognizer new];
    swipeUp.side = FFRSideRight;
    swipeUp.direction = FFRSwipeGestureRecognizerDirectionUp;
    swipeUp.minimumDistance = 50.0;
    swipeUp.maximumDuration = 3.0;
    [swipeUp addTarget: self action: @selector(onSwipeUp:)];
    [manager addGestureRecognizer: swipeUp];
    
    FFRPanGestureRecognizer* panRecognizer = [FFRPanGestureRecognizer new];
    panRecognizer.side = FFRSideLeft;
    [panRecognizer addTarget: self action: @selector(onPan:)];
    [manager addGestureRecognizer: panRecognizer];
    
    FFRLongPressGestureRecognizer* longPress = [FFRLongPressGestureRecognizer new];
    longPress.side = FFRSideBottom;
    [longPress addTarget: self action: @selector(onLongPress:)];
    [manager addGestureRecognizer: longPress];
    
    FFRTapGestureRecognizer* tap = [FFRTapGestureRecognizer new];
    tap.side = FFRSideTop;
    [tap addTarget: self action: @selector(onTap:)];
    [manager addGestureRecognizer:tap];
    
    self.pinchRotateActive = NO;
}

// Define gesture handlers.
- (void)setupGesturesPinchRotate
{
    // Get a reference to the touch manager.
    FFRTouchManager* manager = [FFRTouchManager sharedManager];
    
    // Remove any existing gestures.
    [manager removeAllGestureRecognizers];
    
    // Add gestures.
    FFRPinchGestureRecognizer* pinch = [FFRPinchGestureRecognizer new];
    pinch.side = FFRSideLeft;
    [pinch addTarget: self action: @selector(onPinch:)];
    [manager addGestureRecognizer: pinch];
    
    FFRRotationGestureRecognizer* rotation = [FFRRotationGestureRecognizer new];
    rotation.side = FFRSideRight;
    [rotation addTarget: self action: @selector(onRotation:)];
    [manager addGestureRecognizer: rotation];
    
    FFRDoubleTapGestureRecognizer* dtap = [FFRDoubleTapGestureRecognizer new];
    dtap.side = FFRSideBottom;
    dtap.maximumDuration = 1.0;
    [dtap addTarget: self action: @selector(onDoubleTap:)];
    [manager addGestureRecognizer: dtap];
    
    FFRTapGestureRecognizer* tap = [FFRTapGestureRecognizer new];
    tap.side = FFRSideTop;
    [tap addTarget: self action: @selector(onTap:)];
    [manager addGestureRecognizer:tap];
    
    self.pinchRotateActive = YES;
}

-(void)onPan:(FFRPanGestureRecognizer*)gesture
{
    if (gesture.state == FFRGestureRecognizerStateBegan)
    {
        // Go directly to the start point of our FFRTouch.
        self.startPoint = gesture.touch.location;
        [self animateMoveImageView:self.startPoint];
        self.paning = YES;
    }
    
    else if (gesture.state == FFRGestureRecognizerStateChanged)
    {
        // Panning is relative to the base translation.
        CGPoint p = CGPointZero;
        
        p.x += gesture.translation.width;
        p.y += gesture.translation.height;
        
        CGPoint newPos = CGPointMake(self.startPoint.x + p.x, self.startPoint.y + p.y);
        
        // constrain the image inside the view
        if (newPos.x > self.view.frame.size.width) newPos.x = self.view.frame.size.width;
        if (newPos.x < 0) newPos.x = 0;
        if (newPos.y > self.view.frame.size.height) newPos.y = self.view.frame.size.height;
        if (newPos.y < 0) newPos.y = 0;
        
        [self animateMoveImageView:newPos];
        
    }
    else if (gesture.state == FFRGestureRecognizerStateEnded)
    {
        self.fuffrGuyFlight = 0;
        self.paning = NO;
    }
}

- (void)onSwipeUp:(FFRSwipeGestureRecognizer *)gesture
{
    // Add a force upwards that will dimish with time, and animate the image with a rotation.
    self.fuffrGuyFlight = 15;
    
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    animation.fromValue = @(0);
    animation.toValue = @(2*M_PI);
    animation.duration = 0.65f;
    [self.imageView.layer addAnimation:animation forKey:@"rotation"];
}

- (void)onLongPress:(FFRLongPressGestureRecognizer *)gesture
{
    // Start the explode animation. Restrictions so the user can't change gesture recognizers or start a new explosion until
    // the running animation is done.
    if (!self.longPressCooldown)
    {
        self.longPressCooldown = YES;
        self.tapCooldown = YES;
        [self stopGravity];
        [self animateExplosion];
        [self performSelector:@selector(removeLongPressCooldown) withObject:self afterDelay:4.0];
        [self performSelector:@selector(removeTapCooldown) withObject:self afterDelay:4.0];
    }
}

- (void)removeLongPressCooldown
{
    self.longPressCooldown = NO;
}

- (void)onPinch:(FFRPinchGestureRecognizer*)gesture
{
    // Resize the image and add max and min restrictions for the scaling.
    if (gesture.state == FFRGestureRecognizerStateChanged)
    {
        CGFloat scale = self.baseScale * gesture.scale;
        scale = MIN(scale, 3);
        scale = MAX(scale, 0.5);
        self.currentScale = scale;
    }
    else if (gesture.state == FFRGestureRecognizerStateEnded)
    {
        self.baseScale = self.currentScale;
    }
    [self resizeImage];
}

- (void)onRotation:(FFRRotationGestureRecognizer*)gesture
{
    // Rotate the image. Multiply the current gesture rotation by 2 in order to increase the rash
    if (gesture.state == FFRGestureRecognizerStateChanged)
    {
        CGFloat rotation = self.baseRotation - (gesture.rotation * 2);
        self.currentRotation = rotation;
    }
    else if (gesture.state == FFRGestureRecognizerStateEnded)
    {
        self.baseRotation = self.currentRotation;
    }
    self.imageView.transform = CGAffineTransformMakeRotation(self.currentRotation);
}

- (void)onTap:(FFRTapGestureRecognizer*)gesture
{
    // Change the gesture recognizers and reset the image and transform parameters.
    if (!self.tapCooldown)
    {
        self.tapCooldown = YES;
        if (self.pinchRotateActive)
        {
            self.fuffrGuyFlight = 0;
            [self initializeRenderingParameters];
            [self drawImageView];
            [self setupGesturesPanSwipe];
            [self startGravity];
            [self showInstructionMessage];
        }
        else
        {
            [self stopGravity];
            self.paning = NO;
            [self initializeRenderingParameters];
            [self drawImageView];
            [self setupGesturesPinchRotate];
            [self showInstructionMessage];
        }
        [self performSelector:@selector(removeTapCooldown) withObject:nil afterDelay:0.5];
    }
}

- (void)removeTapCooldown
{
    self.tapCooldown = NO;
}

- (void)onDoubleTap:(FFRDoubleTapGestureRecognizer*)gesture
{
    [self animateRollingEyes];
}

- (void) handleUITap: (UITapGestureRecognizer *)recognizer
{
    // Hide and show help and status text. For demonstrate purposes.
    self.messageView.hidden = (!self.messageView.hidden);
}

- (void)drawImageView
{
    // Drawing the view.
    CGFloat imageSize = 200;
    self.imageView.transform = CGAffineTransformIdentity;
    self.imageView.frame = CGRectMake(0,0,imageSize,imageSize);
    self.imageView.image = [UIImage imageNamed:@"Fuffr Guy.png"];
    self.imageView.center = self.view.center;
}

- (void)resizeImage
{
    CGFloat imageSize = 200;
    imageSize = imageSize * self.currentScale;
    self.imageView.transform = CGAffineTransformIdentity;
    self.imageView.frame = CGRectMake(0,0,imageSize,imageSize);
    self.imageView.center = self.view.center;
    self.imageView.transform = CGAffineTransformMakeRotation(self.currentRotation);
}

- (void)animateMoveImageView:(CGPoint) newPos
{
    // Make the movement of the imageView smooth. This adds a delay.
    CABasicAnimation *movementAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
    movementAnimation.duration = 0.1;
    movementAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    [self.imageView setCenter:newPos];
    [self.imageView.layer addAnimation:movementAnimation forKey:@"slide"];
}

- (void)animateExplosion
{
    // Animate the fuffr guy explosion. Remove gravity during the start phase and reset the image after the animation.
    [UIView animateWithDuration:1.5 animations:
     ^{
         self.imageView.transform = CGAffineTransformMakeScale(2, 2);
         self.imageView.center = CGPointMake(self.imageView.center.x, self.imageView.center.y - 80.0);
     }
                     completion:^(BOOL finished)
    {
         self.imageView.image = [UIImage imageNamed:@"Fuffr Guy7.png"];
         self.imageView.animationImages = self.explodeAnimationArray;
         self.imageView.animationDuration = 0.2;
         self.imageView.animationRepeatCount = 1;
         [self.imageView startAnimating];
         self.offsetSize = -55;
         [self performSelector:@selector(startGravity) withObject:nil afterDelay:0.2];
         [self performSelector:@selector(drawImageView) withObject:nil afterDelay:2];
         [self performSelector:@selector(initializeRenderingParameters) withObject:nil afterDelay:2];
     }];
}

- (void)startGravity
{
    // Starts gravity. Simple timer that keeps draging the image downwards.
    self.fuffrGuyMovement = [NSTimer
                             scheduledTimerWithTimeInterval:0.02
                             target:self
                             selector:@selector(fuffrGuyMoving)
                             userInfo:nil
                             repeats:YES];
}

- (void)animateRollingEyes
{
    // Animate rolling eyes. This adds two temporary ImageViews, one for each eye. Transform the new imageViews so they fit the current active image.
    // Set new Anchor Points so they rotate correctly. Remove gesture recognizers during animation.
    [[FFRTouchManager sharedManager] removeAllGestureRecognizers];
    CGFloat imageSize = 200;
    imageSize = imageSize * self.currentScale;
    
    self.rightEyeImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0,0,imageSize,imageSize)];
    self.rightEyeImageView.image = [UIImage imageNamed:@"Fuffr Guy Right Eye.png"];
    
    self.leftEyeImageView= [[UIImageView alloc] initWithFrame:CGRectMake(0,0,imageSize,imageSize)];
    self.leftEyeImageView.image = [UIImage imageNamed:@"Fuffr Guy Left Eye.png"];
    
    self.leftEyeImageView.center = self.view.center;
    self.rightEyeImageView.center = self.view.center;
    
    self.leftEyeImageView.transform = CGAffineTransformMakeRotation(self.currentRotation);
    self.rightEyeImageView.transform = CGAffineTransformMakeRotation(self.currentRotation);
    
    [self setAnchorPoint:CGPointMake(596.0/1536.0, 717.0/1536.0) forView:self.leftEyeImageView];
    [self setAnchorPoint:CGPointMake(938.0/1536.0, 717.0/1536.0) forView:self.rightEyeImageView];
    
    [self.view addSubview:self.rightEyeImageView];
    [self.view addSubview:self.leftEyeImageView];
    
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    animation.fromValue = @(self.currentRotation);
    animation.toValue = @(self.currentRotation+4*M_PI);
    animation.duration = 1.0f;
    
    [self.rightEyeImageView.layer addAnimation:animation forKey:@"rotation"];
    
    animation.fromValue = @(self.currentRotation);
    animation.toValue = @(self.currentRotation+-4*M_PI);
    animation.duration = 1.0f;
    
    [self.leftEyeImageView.layer addAnimation:animation forKey:@"rotation"];
    
    [self performSelector:@selector(endRollingEyeAnimation) withObject:nil afterDelay:1.2];
}

- (void)endRollingEyeAnimation
{
    // Removes the temporary imageViews (the rotating eyes) and setup the gesture recognizers again.
    [self.rightEyeImageView removeFromSuperview];
    [self.leftEyeImageView removeFromSuperview];
    self.leftEyeImageView = nil;
    self.rightEyeImageView = nil;
    [self setupGesturesPinchRotate];
}

-(void)setAnchorPoint:(CGPoint)anchorPoint forView:(UIView *)view
{
    // Set new Anchor Point without moving the image in the view.
    CGPoint newPoint = CGPointMake(view.bounds.size.width * anchorPoint.x,
                                   view.bounds.size.height * anchorPoint.y);
    CGPoint oldPoint = CGPointMake(view.bounds.size.width * view.layer.anchorPoint.x,
                                   view.bounds.size.height * view.layer.anchorPoint.y);
    
    newPoint = CGPointApplyAffineTransform(newPoint, view.transform);
    oldPoint = CGPointApplyAffineTransform(oldPoint, view.transform);
    
    CGPoint position = view.layer.position;
    
    position.x -= oldPoint.x;
    position.x += newPoint.x;
    
    position.y -= oldPoint.y;
    position.y += newPoint.y;
    
    view.layer.position = position;
    view.layer.anchorPoint = anchorPoint;
}

- (void)stopGravity
{
    [self.fuffrGuyMovement invalidate];
    self.fuffrGuyMovement = nil;
    self.fuffrGuyFlight = 0;
}

- (void)fuffrGuyMoving
{
    // Gravity function. Make sure he stays on the bottom of the screen.
    if (!self.paning)
    {
        CGPoint newPos = CGPointMake(self.imageView.center.x, self.imageView.center.y - self.fuffrGuyFlight);
        if ((newPos.y+self.offsetSize > self.view.frame.size.height))
            self.imageView.center = CGPointMake(self.imageView.center.x, self.view.frame.size.height-self.offsetSize);
        else
            self.imageView.center = newPos;
        self.fuffrGuyFlight -= 1;
        
        if (self.fuffrGuyFlight < -15)
        {
            self.fuffrGuyFlight = -15;
        }
    }
}

@end
