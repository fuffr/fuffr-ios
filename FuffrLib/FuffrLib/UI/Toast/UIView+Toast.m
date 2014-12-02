//
//  UIView+Toast.m
//  Toast
//  Version 2.2
//
//  Copyright 2013 Charles Scalesse.
//

#import "UIView+Toast.h"
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

/*
 *  CONFIGURE THESE VALUES TO ADJUST LOOK & FEEL,
 *  DISPLAY DURATION, ETC.
 */

// general appearance
static const CGFloat FFR_CSToastMaxWidth            = 0.8;      // 80% of parent view width
static const CGFloat FFR_CSToastMaxHeight           = 0.8;      // 80% of parent view height
static const CGFloat FFR_CSToastHorizontalPadding   = 10.0;
static const CGFloat FFR_CSToastVerticalPadding     = 10.0;
static const CGFloat FFR_CSToastCornerRadius        = 10.0;
static const CGFloat FFR_CSToastOpacity             = 0.8;
static const CGFloat FFR_CSToastFontSize            = 16.0;
static const CGFloat FFR_CSToastMaxTitleLines       = 0;
static const CGFloat FFR_CSToastMaxMessageLines     = 0;
static const NSTimeInterval FFR_CSToastFadeDuration = 0.2;

// shadow appearance
static const CGFloat FFR_CSToastShadowOpacity       = 0.8;
static const CGFloat FFR_CSToastShadowRadius        = 6.0;
static const CGSize  FFR_CSToastShadowOffset        = { 4.0, 4.0 };
static const BOOL    FFR_CSToastDisplayShadow       = YES;

// display duration and position
static const NSString * FFR_CSToastDefaultPosition  = @"bottom";
static const NSTimeInterval FFR_CSToastDefaultDuration  = 3.0;

// image view size
static const CGFloat FFR_CSToastImageViewWidth      = 80.0;
static const CGFloat FFR_CSToastImageViewHeight     = 80.0;

// activity
static const CGFloat FFR_CSToastActivityWidth       = 100.0;
static const CGFloat FFR_CSToastActivityHeight      = 100.0;
static const NSString * FFR_CSToastActivityDefaultPosition = @"center";

// interaction
static const BOOL FFR_CSToastHidesOnTap             = YES;     // excludes activity views

// associative reference keys
static const NSString * FFR_CSToastTimerKey         = @"FFR_CSToastTimerKey";
static const NSString * FFR_CSToastActivityViewKey  = @"FFR_CSToastActivityViewKey";

@interface UIView (FFR_ToastPrivate)

- (void)ffr_hideToast:(UIView *)toast;
- (void)ffr_toastTimerDidFinish:(NSTimer *)timer;
- (void)ffr_handleToastTapped:(UITapGestureRecognizer *)recognizer;
- (CGPoint)ffr_centerPointForPosition:(id)position withToast:(UIView *)toast;
- (UIView *)ffr_viewForMessage:(NSString *)message title:(NSString *)title image:(UIImage *)image;
- (CGSize)ffr_sizeForString:(NSString *)string font:(UIFont *)font constrainedToSize:(CGSize)constrainedSize lineBreakMode:(NSLineBreakMode)lineBreakMode;

@end


@implementation UIView (FFR_Toast)

#pragma mark - Toast Methods

- (void)ffr_makeToast:(NSString *)message {
    [self ffr_makeToast:message duration:FFR_CSToastDefaultDuration position:FFR_CSToastDefaultPosition];
}

- (void)ffr_makeToast:(NSString *)message duration:(NSTimeInterval)duration position:(id)position {
    UIView *toast = [self ffr_viewForMessage:message title:nil image:nil];
    [self ffr_showToast:toast duration:duration position:position];  
}

- (void)ffr_makeToast:(NSString *)message duration:(NSTimeInterval)duration position:(id)position title:(NSString *)title {
    UIView *toast = [self ffr_viewForMessage:message title:title image:nil];
    [self ffr_showToast:toast duration:duration position:position];  
}

- (void)ffr_makeToast:(NSString *)message duration:(NSTimeInterval)duration position:(id)position image:(UIImage *)image {
    UIView *toast = [self ffr_viewForMessage:message title:nil image:image];
    [self ffr_showToast:toast duration:duration position:position];  
}

- (void)ffr_makeToast:(NSString *)message duration:(NSTimeInterval)duration  position:(id)position title:(NSString *)title image:(UIImage *)image {
    UIView *toast = [self ffr_viewForMessage:message title:title image:image];
    [self ffr_showToast:toast duration:duration position:position];  
}

- (void)ffr_showToast:(UIView *)toast {
    [self ffr_showToast:toast duration:FFR_CSToastDefaultDuration position:FFR_CSToastDefaultPosition];
}

- (void)ffr_showToast:(UIView *)toast duration:(NSTimeInterval)duration position:(id)point {
    toast.center = [self ffr_centerPointForPosition:point withToast:toast];
    toast.alpha = 0.0;
    
    if (FFR_CSToastHidesOnTap) {
        UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:toast action:@selector(ffr_handleToastTapped:)];
        [toast addGestureRecognizer:recognizer];
        toast.userInteractionEnabled = YES;
        toast.exclusiveTouch = YES;
    }
    
    [self addSubview:toast];
    
    [UIView animateWithDuration:FFR_CSToastFadeDuration
                          delay:0.0
                        options:(UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionAllowUserInteraction)
                     animations:^{
                         toast.alpha = 1.0;
                     } completion:^(BOOL finished) {
                         NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:duration target:self selector:@selector(ffr_toastTimerDidFinish:) userInfo:toast repeats:NO];
                         // associate the timer with the toast view
                         objc_setAssociatedObject (toast, &FFR_CSToastTimerKey, timer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                     }];
    
}

- (void)ffr_hideToast:(UIView *)toast {
    [UIView animateWithDuration:FFR_CSToastFadeDuration
                          delay:0.0
                        options:(UIViewAnimationOptionCurveEaseIn | UIViewAnimationOptionBeginFromCurrentState)
                     animations:^{
                         toast.alpha = 0.0;
                     } completion:^(BOOL finished) {
                         [toast removeFromSuperview];
                     }];
}

#pragma mark - Events

- (void)ffr_toastTimerDidFinish:(NSTimer *)timer {
    [self ffr_hideToast:(UIView *)timer.userInfo];
}

- (void)ffr_handleToastTapped:(UITapGestureRecognizer *)recognizer {
    NSTimer *timer = (NSTimer *)objc_getAssociatedObject(self, &FFR_CSToastTimerKey);
    [timer invalidate];
    
    [self ffr_hideToast:recognizer.view];
}

#pragma mark - Toast Activity Methods

- (void)ffr_makeToastActivity {
    [self ffr_makeToastActivity:FFR_CSToastActivityDefaultPosition];
}

- (void)ffr_makeToastActivity:(id)position {
    // sanity
    UIView *existingActivityView = (UIView *)objc_getAssociatedObject(self, &FFR_CSToastActivityViewKey);
    if (existingActivityView != nil) return;
    
    UIView *activityView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, FFR_CSToastActivityWidth, FFR_CSToastActivityHeight)];
    activityView.center = [self ffr_centerPointForPosition:position withToast:activityView];
    activityView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:FFR_CSToastOpacity];
    activityView.alpha = 0.0;
    activityView.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin);
    activityView.layer.cornerRadius = FFR_CSToastCornerRadius;
    
    if (FFR_CSToastDisplayShadow) {
        activityView.layer.shadowColor = [UIColor blackColor].CGColor;
        activityView.layer.shadowOpacity = FFR_CSToastShadowOpacity;
        activityView.layer.shadowRadius = FFR_CSToastShadowRadius;
        activityView.layer.shadowOffset = FFR_CSToastShadowOffset;
    }
    
    UIActivityIndicatorView *activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    activityIndicatorView.center = CGPointMake(activityView.bounds.size.width / 2, activityView.bounds.size.height / 2);
    [activityView addSubview:activityIndicatorView];
    [activityIndicatorView startAnimating];
    
    // associate the activity view with self
    objc_setAssociatedObject (self, &FFR_CSToastActivityViewKey, activityView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    [self addSubview:activityView];
    
    [UIView animateWithDuration:FFR_CSToastFadeDuration
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         activityView.alpha = 1.0;
                     } completion:nil];
}

- (void)ffr_hideToastActivity {
    UIView *existingActivityView = (UIView *)objc_getAssociatedObject(self, &FFR_CSToastActivityViewKey);
    if (existingActivityView != nil) {
        [UIView animateWithDuration:FFR_CSToastFadeDuration
                              delay:0.0
                            options:(UIViewAnimationOptionCurveEaseIn | UIViewAnimationOptionBeginFromCurrentState)
                         animations:^{
                             existingActivityView.alpha = 0.0;
                         } completion:^(BOOL finished) {
                             [existingActivityView removeFromSuperview];
                             objc_setAssociatedObject (self, &FFR_CSToastActivityViewKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                         }];
    }
}

#pragma mark - Helpers

- (CGPoint)ffr_centerPointForPosition:(id)point withToast:(UIView *)toast {
    if([point isKindOfClass:[NSString class]]) {
        // convert string literals @"top", @"bottom", @"center", or any point wrapped in an NSValue object into a CGPoint
        if([point caseInsensitiveCompare:@"top"] == NSOrderedSame) {
            return CGPointMake(self.bounds.size.width/2, (toast.frame.size.height / 2) + FFR_CSToastVerticalPadding);
        } else if([point caseInsensitiveCompare:@"bottom"] == NSOrderedSame) {
            return CGPointMake(self.bounds.size.width/2, (self.bounds.size.height - (toast.frame.size.height / 2)) - FFR_CSToastVerticalPadding);
        } else if([point caseInsensitiveCompare:@"center"] == NSOrderedSame) {
            return CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
        }
    } else if ([point isKindOfClass:[NSValue class]]) {
        return [point CGPointValue];
    }
    
    NSLog(@"Warning: Invalid position for toast.");
    return [self ffr_centerPointForPosition:FFR_CSToastDefaultPosition withToast:toast];
}

- (CGSize)ffr_sizeForString:(NSString *)string font:(UIFont *)font constrainedToSize:(CGSize)constrainedSize lineBreakMode:(NSLineBreakMode)lineBreakMode {
    if ([string respondsToSelector:@selector(boundingRectWithSize:options:attributes:context:)]) {
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.lineBreakMode = lineBreakMode;
        NSDictionary *attributes = @{NSFontAttributeName:font, NSParagraphStyleAttributeName:paragraphStyle};
        CGRect boundingRect = [string boundingRectWithSize:constrainedSize options:NSStringDrawingUsesLineFragmentOrigin attributes:attributes context:nil];
        return CGSizeMake(ceilf(boundingRect.size.width), ceilf(boundingRect.size.height));
    }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return [string sizeWithFont:font constrainedToSize:constrainedSize lineBreakMode:lineBreakMode];
#pragma clang diagnostic pop
}

- (UIView *)ffr_viewForMessage:(NSString *)message title:(NSString *)title image:(UIImage *)image {
    // sanity
    if((message == nil) && (title == nil) && (image == nil)) return nil;

    // dynamically build a toast view with any combination of message, title, & image.
    UILabel *messageLabel = nil;
    UILabel *titleLabel = nil;
    UIImageView *imageView = nil;
    
    // create the parent view
    UIView *wrapperView = [[UIView alloc] init];
    wrapperView.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin);
    wrapperView.layer.cornerRadius = FFR_CSToastCornerRadius;
    
    if (FFR_CSToastDisplayShadow) {
        wrapperView.layer.shadowColor = [UIColor blackColor].CGColor;
        wrapperView.layer.shadowOpacity = FFR_CSToastShadowOpacity;
        wrapperView.layer.shadowRadius = FFR_CSToastShadowRadius;
        wrapperView.layer.shadowOffset = FFR_CSToastShadowOffset;
    }

    wrapperView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:FFR_CSToastOpacity];
    
    if(image != nil) {
        imageView = [[UIImageView alloc] initWithImage:image];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView.frame = CGRectMake(FFR_CSToastHorizontalPadding, FFR_CSToastVerticalPadding, FFR_CSToastImageViewWidth, FFR_CSToastImageViewHeight);
    }
    
    CGFloat imageWidth, imageHeight, imageLeft;
    
    // the imageView frame values will be used to size & position the other views
    if(imageView != nil) {
        imageWidth = imageView.bounds.size.width;
        imageHeight = imageView.bounds.size.height;
        imageLeft = FFR_CSToastHorizontalPadding;
    } else {
        imageWidth = imageHeight = imageLeft = 0.0;
    }
    
    if (title != nil) {
        titleLabel = [[UILabel alloc] init];
        titleLabel.numberOfLines = FFR_CSToastMaxTitleLines;
        titleLabel.font = [UIFont boldSystemFontOfSize:FFR_CSToastFontSize];
        titleLabel.textAlignment = NSTextAlignmentLeft;
        titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
        titleLabel.textColor = [UIColor whiteColor];
        titleLabel.backgroundColor = [UIColor clearColor];
        titleLabel.alpha = 1.0;
        titleLabel.text = title;
        
        // size the title label according to the length of the text
        CGSize maxSizeTitle = CGSizeMake((self.bounds.size.width * FFR_CSToastMaxWidth) - imageWidth, self.bounds.size.height * FFR_CSToastMaxHeight);
        CGSize expectedSizeTitle = [self ffr_sizeForString:title font:titleLabel.font constrainedToSize:maxSizeTitle lineBreakMode:titleLabel.lineBreakMode];
        titleLabel.frame = CGRectMake(0.0, 0.0, expectedSizeTitle.width, expectedSizeTitle.height);
    }
    
    if (message != nil) {
        messageLabel = [[UILabel alloc] init];
        messageLabel.numberOfLines = FFR_CSToastMaxMessageLines;
        messageLabel.font = [UIFont systemFontOfSize:FFR_CSToastFontSize];
        messageLabel.lineBreakMode = NSLineBreakByWordWrapping;
        messageLabel.textColor = [UIColor whiteColor];
        messageLabel.backgroundColor = [UIColor clearColor];
        messageLabel.alpha = 1.0;
        messageLabel.text = message;
        
        // size the message label according to the length of the text
        CGSize maxSizeMessage = CGSizeMake((self.bounds.size.width * FFR_CSToastMaxWidth) - imageWidth, self.bounds.size.height * FFR_CSToastMaxHeight);
        CGSize expectedSizeMessage = [self ffr_sizeForString:message font:messageLabel.font constrainedToSize:maxSizeMessage lineBreakMode:messageLabel.lineBreakMode];
        messageLabel.frame = CGRectMake(0.0, 0.0, expectedSizeMessage.width, expectedSizeMessage.height);
    }
    
    // titleLabel frame values
    CGFloat titleWidth, titleHeight, titleTop, titleLeft;
    
    if(titleLabel != nil) {
        titleWidth = titleLabel.bounds.size.width;
        titleHeight = titleLabel.bounds.size.height;
        titleTop = FFR_CSToastVerticalPadding;
        titleLeft = imageLeft + imageWidth + FFR_CSToastHorizontalPadding;
    } else {
        titleWidth = titleHeight = titleTop = titleLeft = 0.0;
    }
    
    // messageLabel frame values
    CGFloat messageWidth, messageHeight, messageLeft, messageTop;

    if(messageLabel != nil) {
        messageWidth = messageLabel.bounds.size.width;
        messageHeight = messageLabel.bounds.size.height;
        messageLeft = imageLeft + imageWidth + FFR_CSToastHorizontalPadding;
        messageTop = titleTop + titleHeight + FFR_CSToastVerticalPadding;
    } else {
        messageWidth = messageHeight = messageLeft = messageTop = 0.0;
    }

    CGFloat longerWidth = MAX(titleWidth, messageWidth);
    CGFloat longerLeft = MAX(titleLeft, messageLeft);
    
    // wrapper width uses the longerWidth or the image width, whatever is larger. same logic applies to the wrapper height
    CGFloat wrapperWidth = MAX((imageWidth + (FFR_CSToastHorizontalPadding * 2)), (longerLeft + longerWidth + FFR_CSToastHorizontalPadding));    
    CGFloat wrapperHeight = MAX((messageTop + messageHeight + FFR_CSToastVerticalPadding), (imageHeight + (FFR_CSToastVerticalPadding * 2)));
                         
    wrapperView.frame = CGRectMake(0.0, 0.0, wrapperWidth, wrapperHeight);
    
    if(titleLabel != nil) {
        titleLabel.frame = CGRectMake(titleLeft, titleTop, titleWidth, titleHeight);
        [wrapperView addSubview:titleLabel];
    }
    
    if(messageLabel != nil) {
        messageLabel.frame = CGRectMake(messageLeft, messageTop, messageWidth, messageHeight);
        [wrapperView addSubview:messageLabel];
    }
    
    if(imageView != nil) {
        [wrapperView addSubview:imageView];
    }
        
    return wrapperView;
}

@end
