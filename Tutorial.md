# Fuffr Tutorial

Start developing cool apps for the Fuffr! This tutorial gets you going.

Current release of Fuffr is targeted for iOS devices. Android support will follow.

## What you need

To develop Fuffr apps, you need:

* Basic knowledge of Objective-C and iOS development.
* A Mac running a recent version of Xcode.
* An iPhone 5/5C/5S running iOS 7 or higher. (You can also use iPhone 4S, but Fuffr is designed for the iPhone 5 form factor.)
* Please note that you cannot run Fuffr apps in the iOS Simulator, because it lacks support for BLE (Bluetooth Low Energy) needed to connect to Fuffr.
* The source code for the Fuffr library and the example apps (available on GitHub).
* Fuffr hardware (contact hello@fuffr.com for information on availability).

## Get the source code

You have two options:

Install Git and clone the Fuffr GitHub repository using the command:

    git clone git@github.com:fuffr/fuffr-code.git

Download the code as a zip-file by clicking **Download ZIP** on [GitHub](https://github.com/fuffr/fuffr-code).

## Run the example apps

The quickest way to get started is by exploring the example apps:

The quickest way to get started is by exploring the example apps:

[**FuffrHello**](https://github.com/fuffr/fuffr-ios/tree/master/FuffrHello) - This is a minimal example that shows how to control two circles using the left and right sensor arrays. This example uses a single touch interaction style for each side.

[**FuffrDots**](https://github.com/fuffr/fuffr-ios/tree/master/FuffrDots) - A minimal example that illustrates how to access multi touch data. For each touch point, a circle is drawn.

[**FuffrMap**](https://github.com/fuffr/fuffr-ios/tree/master/FuffrMap) - Example app that show how to navigate Apple maps with Fuffr. Use right side finger to pan (scroll) across the map, and the left side finger to zoom the map with up/down movements.

[**FuffrBox**](https://github.com/fuffr/fuffr-ios/tree/master/FuffrBox) - This app is a Fuffr browser that enables you to write applications in JavaScript. The JavaScript part of the API, along with some examples, is found in the folder [**FuffrJS**](https://github.com/fuffr/fuffr-ios/tree/master/FuffrJS) and pass touch events to an app written in HTML/JS. The file [**fuffr.js**](https://github.com/fuffr/fuffr-ios/tree/master/FuffrJS/fuffr.js) contains the JavaScript API for the Fuffr.

## Add the FuffrLib to your own app

**You only need to read the following if you wish to use Fuffr with your existing apps. The examples that comes with Fuffr are already set up properly.**

**FuffrLib** is an Xcode library you can add to your own iOS applications.

Follow these steps to include the library into you app:

Open your application in Xcode.

Make sure that no other application that includes FuffrLib is open in Xcode.

From the Finder, drag and drop the file **FuffrLib.xcodeproj** into the Xcode Project Navigator.

Select your project (the topmost entry) in the Project Navigator and select tab **Build Settings**.

Under **Search Paths/Header Search Paths**, enter the following in the Debug and Release fields (make sure to include also the quote marks):

    "$(TARGET_BUILD_DIR)/usr/local/lib/include" "$(OBJROOT)/UninstalledProducts/include" "$(BUILT_PRODUCTS_DIR)"

Under **Linking/Other Linker Flags**, enter the following in the Debug and Release fields:

    -ObjC

Next select tab **Build Phases**.

Under **Target Dependencies**, click **+** (plus) and add **FuffrLib**.

* Under **Link Binary With Libraries**, click **+** (plus) and add **libFuffrLib.a**.

For more information about using libraries, see the [iOS Developer Library Documentation](https://developer.apple.com/library/ios/technotes/iOSStaticLibraries/Articles/configuration.html#//apple_ref/doc/uid/TP40012554-CH3-SW1).

## The Fuffr Touch API

An overview of classes and methods provided by the Fuffr API.

### Class overview

The following classes contain functionality needed by most applications:

Class **FFRTouchManager** ([FuffrLib/FFRTouchManager.h](https://github.com/fuffr/fuffr-ios/blob/master/FuffrLib/FuffrLib/Touch/FFRTouchManager.h)) contains methods for connecting to Fuffr and for observing touch events. This is a singleton, the system creates and maintains the single instance of this class.

Class **FFRTouch** ([FuffrLib/FFRTouch.h](https://github.com/fuffr/fuffr-ios/blob/master/FuffrLib/FuffrLib/Touch/FFRTouch.h)) represents touches, with information like the touch coordinate and which side that generated the event.

Enum **FFRCaseSide** ([FuffrLib/FFRTouch.h](https://github.com/fuffr/fuffr-ios/blob/master/FuffrLib/FuffrLib/Touch/FFRTouch.h)) has constants that represent each side: **FFRSideTop**, **FFRSideBottom**, **FFRSideLeft**, **FFRSideRight**.

### Connection events and enabling Fuffr

Fuffr uses BLE (Bluetooth Low Energy) to communicate with the app. The library automatically scans for Fuffr devices and connects to the one closest to the mobile running the app. The RSSI (signal strength) is used to determine which Fuffr devices is closest, if there are multiple devices within scanning range.

The connection process takes a couple of seconds.

Early on in the app loading cycle, you should register a connection block. This block is called when a connection is establised. Yoy can also register a disconnect block.

When a connection is made, you can enable the Fuffr by specifying which sides are to be active and the number of touches per side.

The following code snippet shows how to obtain a reference to the **FFRTouchManager** and register a connect block that enables the left and right side, with 1 touch point per side:

    FFRTouchManager* manager = [FFRTouchManager sharedManager];

    [manager
        onFuffrConnected:
        ^{
            NSLog(@"Fuffr Connected");
            [manager useSensorService:
            ^{
                NSLog(@"Touch Sensors Ready");
                // Set active sides and number of touches per side.
                [[FFRTouchManager sharedManager]
                    enableSides: FFRSideLeft | FFRSideRight
                    touchesPerSide: @1];
            }];
        }
        onFuffrDisconnected:
        ^{
            NSLog(@"Fuffr Disconnected");
        }];

The enableSides: parameter is one or more side values bit-or:ed together.

The touchesPerSide: parameter range from 0 to 5, and sets the number of touches a side can have. All sides get the same number of touches. Setting this value to zero puts the Fuffr into power-saving mode.

Currently it takes about a second for the setting to take effect.

It is also possible to call onFuffrConnected: and onFuffrDisconnected: separately, as in this example:

    FFRTouchManager* manager = [FFRTouchManager sharedManager];

    [manager
        onFuffrConnected:
        ^{
        	NSLog(@"Fuffr Connected");
            [manager useSensorService:
            ^{
                // Set active sides and number of touches per side.
                [[FFRTouchManager sharedManager]
                    enableSides: FFRSideLeft | FFRSideRight
                    touchesPerSide: @1];
            }];
        }];

    [manager
        onFuffrDisconnected:
        ^{
            NSLog(@"Fuffr Disconnected");
        }];

### Registering touch observers

To observe touch events, the application registers methods with the **FFRTouchManager**. Here is an example that registers touch methods for the right side:

    [manager
        addTouchObserver: self
        touchBegan: @selector(touchRightBegan:)
        touchMoved: @selector(touchRightMoved:)
        touchEnded: @selector(touchRightEnded:)
        sides: FFRSideRight];

Note that the side parameter can consist of side values bit-or:ed together. For example, to capture touch infomation on all sides, use:

    FFRSideLeft | FFRSideRight | FFRSideTop | FFRSideBottom

### Receiving touch events

The methods registered to receive touch events takes one parameter, an **NSSet** that contains one or more **FFRTouch** objects. This is an example that logs the normalized coordinates of each touch instance:

    - (void) touchRightBegan: (NSSet*)touches
    {
        for (FFRTouch* touch in touches)
        {
            NSLog(@"Touch norm.x: %.02f norm.y: %.02f",
                touch.normalizedLocation.x,
                touch.normalizedLocation.y);
        }
    }

### Removing touch observers

To remove a specific touch observer, use removeTouchObserver:

    [manager removeTouchObserver: self];

To remove all touch observers, use removeAllTouchObserversAndTouchBlocks:

    [manager removeAllTouchObserversAndTouchBlocks];

Note that this will also remove any registered touch blocks!

### Using blocks for touch events

As an alternative to specifying a touch observer and selectors, you can use blocks to capture touches. Here is an example:

    [manager
        addTouchMovedBlock: ^(NSSet* touches)
        {
            for (FFRTouch* touch in touches)
            {
                NSLog(@"Touch norm.x: %.02f norm.y: %.02f",
                    touch.normalizedLocation.x,
                    touch.normalizedLocation.y);
            }
        }
        sides: FFRSideRight];

The methods available for adding touch blocks are:

* addTouchBeganBlock:sides:
* addTouchMovedBlock:sides:
* addTouchEndedBlock:sides:

The side parameter can consist of side values bit-or:ed together (see example above).

### Removing touch blocks

To remove a specific touch block, use removeTouchBlock:

    [manager removeTouchBlock: touchBlockId];

The touchBlockId is a int value returned by the addTouch*Block: methods.

To remove all touch blocks, use removeAllTouchObserversAndTouchBlocks:

    [manager removeAllTouchObserversAndTouchBlocks];

Note that this will also remove any registered touch observers!

### Power saving when going into background mode

To preserve battery of the Fuffr, you can disconnect it when the app is going into background and reconnect when going to the foreground. Here is an example that shows how to do this, this code goes into your AppDelegate class:

    - (void)applicationWillResignActive:(UIApplication *)application
    {
        [[FFRTouchManager sharedManager] disconnectFuffr];
    }

    - (void)applicationDidBecomeActive:(UIApplication *)application
    {
        [[FFRTouchManager sharedManager] reconnectFuffr];
    }

Disconnecting from the Fuffr means it will turn itself off after a while, and the user must reactivate it by pressing the "announce" button once the app is back in foreground.

Another way to save battery time is to set the number of touch points per side to zero, as discussed above. This puts the Fuffr into power saving mode, but does not turn off the device, so it still consumes some battery.

## The Gesture API

The FuffrLib library has a gesture API that facilitates using common gestures in your application.

### Gesture types

The following gesture recognizers are available in the library:

* FFRPanGestureRecognizer
* FFRPinchGestureRecognizer
* FFRRotationGestureRecognizer
* FFRTapGestureRecognizer
* FFRDoubleTapGestureRecognizer
* FFRLongPressGestureRecognizer
* FFRSwipeGestureRecognizer

Below follows example for how to use these gestures.

Common for all examples is that you use the FFRTouchManager instance to add gestures:

    FFRTouchManager* manager = [FFRTouchManager sharedManager];

All gestures use the principle of calling a selector on a target object when the gesture is recognized.

### FFRPanGestureRecognizer

Here is an example of how to setup the pan recognizer:

    FFRPanGestureRecognizer* pan = [FFRPanGestureRecognizer new];
    pan.side = FFRSideRight;
    [pan addTarget: self action: @selector(onPan:)];
    [manager addGestureRecognizer: pan];

Method called when a panning gesture occurs:

    -(void) onPan: (FFRPanGestureRecognizer*)gesture
    {
        NSLog(@"onPan: %f %f",
            gesture.translation.width,
            gesture.translation.height);
    }

Possible values of **gesture.state**:

** FFRGestureRecognizerStateBegan - gesture started
** FFRGestureRecognizerStateChanged - gesture value has been updated
** FFRGestureRecognizerStateEnded - gesture has ended

Note that the width and height of the translation is relative to the original touch point that started the gesture (they are not delta values).

### FFRPinchGestureRecognizer

Here is how to setup the pinch recognizer:

    FFRPinchGestureRecognizer* pinch = [FFRPinchGestureRecognizer new];
    pinch.side = FFRSideRight;
    [pinch addTarget: self action: @selector(onPinch:)];
    [manager addGestureRecognizer: pinch];

This method is called when a gesture occurs:

    -(void) onPinch: (FFRPinchGestureRecognizer*)gesture
    {
        NSLog(@"onPinch: %f", gesture.scale);
    }

The scale value is based on the distance between the original touch points that started the gesture (it is not a delta value).

Possible values of **gesture.state**:

** FFRGestureRecognizerStateBegan - gesture started
** FFRGestureRecognizerStateChanged - gesture value has been updated
** FFRGestureRecognizerStateEnded - gesture has ended

### FFRRotationGestureRecognizer

Here is an example of how to setup the rotation recognizer:

    FFRRotationGestureRecognizer* rotation = [FFRRotationGestureRecognizer new];
    rotation.side = FFRSideRight;
    [rotation addTarget: self action: @selector(onRotation:)];
    [manager addGestureRecognizer: rotation];

Method called when a gesture occurs:

    -(void) onRotation: (FFRRotationGestureRecognizer*)gesture
    {
        NSLog(@"onRotation: %f", gesture.rotation);
    }

The rotation value is based on the angle between the original touch points that started the gesture (it is not a delta value). The angle is given in radians.

Possible values of **gesture.state**:

** FFRGestureRecognizerStateBegan - gesture started
** FFRGestureRecognizerStateChanged - gesture value has been updated
** FFRGestureRecognizerStateEnded - gesture has ended

### FFRTapGestureRecognizer

Example of how to setup the tap recognizer:

    FFRTapGestureRecognizer* tap = [FFRTapGestureRecognizer new];
    tap.side = FFRSideTop | FFRSideBottom;
    tap.maximumDistance = 50.0;
    tap.maximumDuration = 0.5; // 0.5 seconds.
    [tap addTarget: self action: @selector(onTap:)];
    [manager addGestureRecognizer: tap];

Example of method called when a tap gesture occurs:

    -(void) onTap: (FFRTapGestureRecognizer*)gesture
    {
        NSLog(@"onTap");
    }

### FFRDoubleTapGestureRecognizer

Example of how to setup the double tap recognizer:

    FFRDoubleTapGestureRecognizer* dtap = [FFRDoubleTapGestureRecognizer new];
    dtap.side = FFRSideTop | FFRSideBottom;
    dtap.maximumDistance = 100.0;
    dtap.maximumDuration = 1.5; // 1.5 seconds.
    [dtap addTarget: self action: @selector(onDoubleTap:)];
    [manager addGestureRecognizer: dtap];

Example of method called when a double tap occurs:

    -(void) onTap: (FFRDoubleTapGestureRecognizer*)gesture
    {
        NSLog(@"onDoubleTap");
    }

### FFRLongPressGestureRecognizer

Example of how to setup the long press recognizer:

    FFRLongPressGestureRecognizer* longPress = [FFRLongPressGestureRecognizer new];
    longPress.side = FFRSideTop | FFRSideBottom;
    longPress.maximumDistance = 50.0;
    longPress.minimumDuration = 1.0; // 1 second.
    [longPress addTarget: self action: @selector(onLongPress:)];
    [manager addGestureRecognizer: longPress];

Example of method called when a long press occurs:

    -(void) onLongPress: (FFRLongPressGestureRecognizer*)gesture
    {
        NSLog(@"onLongPress");
    }

### FFRSwipeGestureRecognizer

This is an example of how to setup a swipe left gesture recognizer:

    FFRSwipeGestureRecognizer* swipeLeft = [FFRSwipeGestureRecognizer new];
    swipeLeft.side = FFRSideLeft | FFRSideRight;
    swipeLeft.direction = FFRSwipeGestureRecognizerDirectionLeft;
    swipeLeft.minimumDistance = 200.0;
    swipeLeft.maximumDuration = 1.0; // 1 second.
    [swipeLeft addTarget: self action: @selector(onSwipeLeft:)];
    [manager addGestureRecognizer: swipeLeft];

Possible values for direction are:

* FFRSwipeGestureRecognizerDirectionLeft
* FFRSwipeGestureRecognizerDirectionRight
* FFRSwipeGestureRecognizerDirectionUp
* FFRSwipeGestureRecognizerDirectionDown

Method called when swipe occurs:

    -(void) onSwipeLeft: (FFRSwipeGestureRecognizer*)gesture
    {
        NSLog(@"onSwipeLeft");
    }

### Removing gesture recognizers

To remove a specific gesture recognizer, use removeGestureRecognizer:

    [manager removeGestureRecognizer: swipeLeft];

To remove all gesture recognizers, use removeAllGestureRecognizers:

    [manager removeAllGestureRecognizers];

## Provide feedback

Let us know what you think! We would love to hear about the Fuffr apps you create. Let us know about your work, what you think Fuffr, the API, and please report any bugs you encounter.

Contact: hello@fuffr.com
