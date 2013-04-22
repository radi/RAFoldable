#import "RAFoldableView.h"
#import "CALayer+AGQuad.h"
#import <objc/runtime.h>

static inline CGFloat RAFoldableViewDragCoefficient () {
	#if TARGET_IPHONE_SIMULATOR
		CGFloat UIAnimationDragCoefficient(void);
		return UIAnimationDragCoefficient();
	#else
		return 1.0f;
	#endif
}

typedef struct {
  CGPoint position;
	CGRect bounds;
	CGRect contentsRect;
	AGQuad quadrilateral;
	const void * userInfo;
} RAFoldSegment;

typedef enum {
	RAFoldDirectionUnknown = 0,
	RAFoldDirectionVertical,
	RAFoldDirectionHorizontal
} RAFoldDirection;

@interface RAFoldableView ()
@property (nonatomic, readwrite, assign) RAFoldDirection lastFoldDirection;
@property (nonatomic, readonly, strong) UIView *containerView;
@end

@implementation RAFoldableView
@synthesize lastFoldDirection = _lastFoldDirection;
@synthesize containerView = _containerView;

- (id) initWithFrame:(CGRect)frame {
	
	self = [super initWithFrame:frame];
	if (self) {
		_pristineSize = frame.size;
		_lastFoldDirection = RAFoldDirectionHorizontal;
		_containerView = [[UIView alloc] initWithFrame:self.bounds];
		[self addSubview:_containerView];
		self.autoresizesSubviews = NO;
		self.clipsToBounds = YES;
		self.layer.anchorPoint = CGPointZero;
	}
	
	return self;
	
	
	
}

- (void) layoutSubviews {
	
	[super layoutSubviews];
	[self nudge];
	
	self.containerView.frame = [self convertRect:self.window.screen.applicationFrame fromView:nil];
	[self bringSubviewToFront:self.containerView];

}

- (void) nudge {
	
	NSUInteger numberOfSegments = 0;
	[self getFoldSegments:NULL WithCount:&numberOfSegments];
	RAFoldSegment *segments = malloc(numberOfSegments * sizeof(RAFoldSegment));
	[self getFoldSegments:segments WithCount:&numberOfSegments];
	
	NSMutableSet *removedSubviews = [NSMutableSet setWithArray:self.subviews];
	[removedSubviews removeObject:self.containerView];
	
	for (NSUInteger i = 0; i < numberOfSegments; i++) {
		
		RAFoldSegment segment = segments[i];
		UIView *view = [self viewWithTag:(i + 1)];
		if (view) {
			NSCParameterAssert(view != self);
			[removedSubviews removeObject:view];
		} else {
			view = [[UIView alloc] initWithFrame:segment.bounds];
			view.tag = (i + 1);
			view.layer.anchorPoint = CGPointZero;
			[self.containerView addSubview:view];
		}
		
		view.layer.contents = (id)self.image.CGImage;
		view.layer.contentsRect = segment.contentsRect;
		view.layer.position = segment.position;
		view.layer.bounds = segment.bounds;
		view.layer.transform = CATransform3DWithQuadFromBounds(segment.quadrilateral, view.layer.bounds);
		
		[view.layer removeAllAnimations];
		
	}
	
	for (UIView *view in removedSubviews)
		[view removeFromSuperview];
	
	free(segments);
	
}

- (void) willMoveToSuperview:(UIView *)newSuperview {

	[super willMoveToSuperview:newSuperview];
	
	if (newSuperview)
		self.pristineSize = newSuperview.bounds.size;

}

+ (void) getFoldSegments:(RAFoldSegment[])outSegments withPristineSize:(CGSize)pristineSize foldDirection:(RAFoldDirection)direction inBounds:(CGRect)bounds count:(NSUInteger *)outCount {
	
	NSUInteger const numberOfSegments = 8;
	
	if (outCount)
		*outCount = numberOfSegments;
	
	if (!outSegments)
		return;
	
	CGSize (^CGSizeDivide)(CGSize, CGFloat, CGFloat) = ^ (CGSize size, CGFloat dX, CGFloat dY) {
		return (CGSize) { size.width / dX, size.height / dY };
	};
	
	CGSize (^CGSizeFloor)(CGSize) = ^ (CGSize size) {
		return (CGSize) { floorf(size.width), floorf(size.height) };
	};
	
	CGPoint (^CGSizeMultiply)(CGSize, CGFloat, CGFloat) = ^ (CGSize size, CGFloat dX, CGFloat dY) {
		return (CGPoint) { size.width * dX, size.height * dY };
	};
	
	switch (direction) {
		
		case RAFoldDirectionUnknown:
		case RAFoldDirectionHorizontal: {
			
			for (NSUInteger i = 0; i < numberOfSegments; i++) {
			
				CGSize const pristineSliceSize = CGSizeDivide(pristineSize, numberOfSegments, 1);
				CGSize const visibleSliceSize = CGSizeFloor(CGSizeDivide(bounds.size, numberOfSegments, 1));
				CGFloat const pristineBreadth = pristineSliceSize.width;
				CGFloat visibleBreadth = visibleSliceSize.width;
				if (i == (numberOfSegments - 1)) {
					visibleBreadth += bounds.size.width - visibleSliceSize.width * numberOfSegments;
				}
				CGFloat const compression = (1.0f - (visibleBreadth / pristineBreadth)) * 32.0f;
				CGRect const sliceBounds = (CGRect){ CGPointZero, visibleBreadth, visibleSliceSize.height };
				
				AGQuad quad = AGQuadMakeWithCGRect(sliceBounds);
				if (i % 2) {
					quad.tl.y += compression;
					quad.bl.y -= compression;
				} else {
					quad.tr.y += compression;
					quad.br.y -= compression;
				}
				
				outSegments[i] = (RAFoldSegment){
					CGSizeMultiply(visibleSliceSize, i, 0.0f),
					sliceBounds,
					(CGRect) { i / (CGFloat)numberOfSegments, 0.0f, 1.0f / (CGFloat)numberOfSegments, 1.0f },
					quad
				};
			}
			
			break;
			
		}
		
		case RAFoldDirectionVertical: {
		
			CGSize const pristineSliceSize = CGSizeDivide(pristineSize, 1, numberOfSegments);
			CGSize const visibleSlizeSize = CGSizeDivide(bounds.size, 1, numberOfSegments);
			CGFloat const pristineBreadth = pristineSliceSize.height;
			CGFloat const visibleBreadth = visibleSlizeSize.height;
			CGFloat const compression = (1.0f - (visibleBreadth / pristineBreadth)) * 32.0f;
			CGRect const sliceBounds = (CGRect){ CGPointZero, visibleSlizeSize };
			
			for (NSUInteger i = 0; i < numberOfSegments; i++) {
				
				AGQuad quad = AGQuadMakeWithCGRect(sliceBounds);
				if (i % 2) {
					quad.tl.x += compression;
					quad.tr.x -= compression;
				} else {
					quad.bl.x += compression;
					quad.br.x -= compression;
				}
				
				quad.tl.y -= 0.5f;
				quad.tr.y -= 0.5f;
				quad.bl.y += 0.5f;
				quad.br.y += 0.5f;
				
				outSegments[i] = (RAFoldSegment){
					CGSizeMultiply(visibleSlizeSize, 0.0f, i),
					sliceBounds,
					(CGRect) { 0.0f, i / (CGFloat)numberOfSegments, 1.0f, 1.0f / (CGFloat)numberOfSegments },
					quad
				};
				
			}
			
			break;
			
		}
		
	}
	
}

- (void) getFoldSegments:(RAFoldSegment[])outSegments WithCount:(NSUInteger *)outCount {
	
	self.lastFoldDirection = (self.pristineSize.width > CGRectGetWidth(self.bounds))
		? RAFoldDirectionHorizontal
		: (self.pristineSize.height > CGRectGetHeight(self.bounds))
			? RAFoldDirectionVertical :
				self.lastFoldDirection;
	
	CGRect const layerFrame = ((CALayer *)(self.layer.presentationLayer ?: self.layer)).frame;
	CGRect const bounds = (CGRect){
		roundf(layerFrame.origin.x),
		roundf(layerFrame.origin.y),
		roundf(layerFrame.size.width),
		roundf(layerFrame.size.height)
	};
	
	[[self class] getFoldSegments:outSegments withPristineSize:self.pristineSize foldDirection:self.lastFoldDirection inBounds:bounds count:outCount];
	
	if (outCount && outSegments) {
		for (int i = 0; i < *outCount; i++) {
			outSegments[i].position.x += bounds.origin.x;
			outSegments[i].position.y += bounds.origin.y;
		}
	}
	
}

@end
