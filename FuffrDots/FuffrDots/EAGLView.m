//
//  EAGLView.m
//  openglcircle
//
//  Created by Jan Vantomme on 15/05/09.
//  Copyright Vormplus 2009. All rights reserved.
//



#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>
#import <FuffrLib/FFRTouchManager.h>

#import "EAGLView.h"

// import the Constants.h file so the functions to convert
// degrees to radians and to generate random numbers 
// will be available to use in this class
#import "Constants.h" 

#define USE_DEPTH_BUFFER 0

@implementation DotColor
@end

// A class extension to declare private methods
@interface EAGLView ()

@property (nonatomic, retain) EAGLContext *context;

- (BOOL) createFramebuffer;
- (void) destroyFramebuffer;

@end


@implementation EAGLView

@synthesize context;

GLfloat vertices[72];

// You must implement this method
+ (Class)layerClass {
	return [CAEAGLLayer class];
}


- (id)initWithFrame:(CGRect)frame
{
	if (self = [super initWithFrame:frame])
	{
		CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
		
		self.contentScaleFactor = [UIScreen mainScreen].scale;
		//CGSize displaySize = [[UIScreen mainScreen]currentMode].size;
		CGRect displayRect = [UIScreen mainScreen].bounds;
		
		eaglLayer.frame = displayRect;
		eaglLayer.opaque = YES;
		eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys : [NSNumber numberWithBool : NO],
										kEAGLDrawablePropertyRetainedBacking,
										kEAGLColorFormatRGBA8,
										kEAGLDrawablePropertyColorFormat, nil];
		
		context = [[EAGLContext alloc] initWithAPI : kEAGLRenderingAPIOpenGLES1];
		
		if (!context || ![EAGLContext setCurrentContext : context]) {
			return nil;
		}
		
		glGenFramebuffersOES(1, &viewFramebuffer);
		glGenRenderbuffersOES(1, &viewRenderbuffer);
		
		glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
		glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
		[context renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:(CAEAGLLayer *)self.layer];
		glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, viewRenderbuffer);
		
		glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &backingWidth);
		glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &backingHeight);
		
		glGenRenderbuffersOES(1, &depthRenderbuffer);
		glBindRenderbufferOES(GL_RENDERBUFFER_OES, depthRenderbuffer);
		glRenderbufferStorageOES(GL_RENDERBUFFER_OES, GL_DEPTH_COMPONENT16_OES, backingWidth, backingHeight);
		glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_DEPTH_ATTACHMENT_OES, GL_RENDERBUFFER_OES, depthRenderbuffer);
		
		// Set up vertices for a circle.
		for (int i = 0; i < 72; i += 2) {
			vertices[i]   = (cos(DEGREES_TO_RADIANS(i*10)) * 1);
			vertices[i+1] = (sin(DEGREES_TO_RADIANS(i*10)) * 1);
		}
	}
	return self;
}


- (void)drawView {
	NSLog(@"drawView");
	[EAGLContext setCurrentContext:context];
	
	glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
	glViewport(0, 0, backingWidth, backingHeight);
	
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	glOrthof(-1.0f, 1.0f, -1.5f, 1.5f, -1.0f, 1.0f);
	glMatrixMode(GL_MODELVIEW);

	glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
	glClear(GL_COLOR_BUFFER_BIT);
	
	glVertexPointer(2, GL_FLOAT, 0, vertices);
	glEnableClientState(GL_VERTEX_ARRAY);
	
	glColor4f(1.0f, 0.0f, 0.0f, 1.0f);
	
	glDrawArrays(GL_TRIANGLE_FAN, 0, 360);
	
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
	[context presentRenderbuffer:GL_RENDERBUFFER_OES];
}

- (void)drawViewWithTouches:(NSSet*)touches paintMode:(BOOL)paintModeOn dotColors:(NSMutableDictionary*)dotColors {
	//NSLog(@"drawViewWithTouches");
	[EAGLContext setCurrentContext:context];
	
	glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
	glViewport(0, 0, backingWidth, backingHeight);
	
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	glOrthof(0, backingWidth/2, 0, backingHeight/2, -1.0f, 1.0f);
	glMatrixMode(GL_MODELVIEW);
	
	//if(paintModeOn) {
		glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
		glClear(GL_COLOR_BUFFER_BIT);
	//}
	
	glVertexPointer(2, GL_FLOAT, 0, vertices);
	glEnableClientState(GL_VERTEX_ARRAY);
	
	for (FFRTouch* touch in touches)
	{
		if (touch.phase != FFRTouchPhaseEnded)
		{
			//++nTouches;
			
			DotColor* color = [dotColors objectForKey:
				[NSNumber numberWithInt: (int)touch.identifier]];
			if (color)
			{
				glColor4f(color.red, color.green, color.blue, 1.0f);
			}
			else
			{
    			glColor4f(0,0,0,1);
			}
			
			if (paintModeOn)
			{
            }
			else
			{
				// Draw a single circle.
				glPushMatrix();
				glTranslatef(touch.location.x, backingHeight/2 - touch.location.y, 0);
				glScalef(40, 40, 1);	//circleSize
				glDrawArrays(GL_TRIANGLE_FAN, 0, 36);
				glPopMatrix();
			}
		}
	}
	
	// fps counter
	static uint sFrameCount = 0, sFrameCountLastSecond = 0, sFPS;
	static time_t sLastSecondTimestamp = 0;

	sFrameCount++;
	uint fps = sFrameCount - sFrameCountLastSecond;
	time_t now = time(NULL);
	if(now != sLastSecondTimestamp) {
		sLastSecondTimestamp = now;
		sFrameCountLastSecond = sFrameCount;
		sFPS = fps;
		NSLog(@"FPS: %i", fps);
	}
	fps = sFPS;

	glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
	[context presentRenderbuffer:GL_RENDERBUFFER_OES];
}


- (void)layoutSubviews {
	[EAGLContext setCurrentContext:context];
	[self destroyFramebuffer];
	[self createFramebuffer];
	//[self drawView];
}


- (BOOL)createFramebuffer {
	
	glGenFramebuffersOES(1, &viewFramebuffer);
	glGenRenderbuffersOES(1, &viewRenderbuffer);
	
	glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
	[context renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:(CAEAGLLayer*)self.layer];
	glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, viewRenderbuffer);
	
	glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &backingWidth);
	glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &backingHeight);
	
	if (USE_DEPTH_BUFFER) {
		glGenRenderbuffersOES(1, &depthRenderbuffer);
		glBindRenderbufferOES(GL_RENDERBUFFER_OES, depthRenderbuffer);
		glRenderbufferStorageOES(GL_RENDERBUFFER_OES, GL_DEPTH_COMPONENT16_OES, backingWidth, backingHeight);
		glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_DEPTH_ATTACHMENT_OES, GL_RENDERBUFFER_OES, depthRenderbuffer);
	}
	
	if(glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES) != GL_FRAMEBUFFER_COMPLETE_OES) {
		NSLog(@"failed to make complete framebuffer object %x", glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES));
		return NO;
	}
	
	return YES;
}


- (void)destroyFramebuffer {
	
	glDeleteFramebuffersOES(1, &viewFramebuffer);
	viewFramebuffer = 0;
	glDeleteRenderbuffersOES(1, &viewRenderbuffer);
	viewRenderbuffer = 0;
	
	if(depthRenderbuffer) {
		glDeleteRenderbuffersOES(1, &depthRenderbuffer);
		depthRenderbuffer = 0;
	}
}

- (void)dealloc {
	
	if ([EAGLContext currentContext] == context) {
		[EAGLContext setCurrentContext:nil];
	}
}

@end
