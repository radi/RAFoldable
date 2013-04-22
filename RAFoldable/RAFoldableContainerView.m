#import "RAFoldableContainerView.h"
#import "RAFoldableView.h"

@interface RAFoldableContainerView () <UIGestureRecognizerDelegate>
@property (nonatomic, readwrite, assign) CGPoint fromLocation;
@property (nonatomic, readwrite, assign) CGPoint toLocation;
@property (nonatomic, readwrite, assign) BOOL foundChippingEdge;
@property (nonatomic, readwrite, assign) CGRectEdge chippingEdge;
@end

@implementation RAFoldableContainerView
@synthesize foldableView = _foldableView;
@synthesize fromLocation = _fromLocation;
@synthesize toLocation = _toLocation;
@synthesize foundChippingEdge = _foundChippingEdge;
@synthesize chippingEdge = _chippingEdge;

- (id) initWithFrame:(CGRect)frame {
	
	self = [super initWithFrame:frame];
	if (self) {
		
		self.foldableView.frame = self.bounds;
		[self addSubview:self.foldableView];
		[self addGestureRecognizer:self.panGestureRecognizer];

		_fromLocation = (CGPoint){ NAN, NAN };
		_toLocation = (CGPoint){ NAN, NAN };
		_foundChippingEdge = NO;
		_chippingEdge = CGRectMinYEdge; // garbage if !foundChippingEdge

	}
	
	return self;
	
}

- (UIPanGestureRecognizer *) panGestureRecognizer {

	UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
	panGestureRecognizer.delegate = self;
	
	return panGestureRecognizer;
	
}

- (RAFoldableView *) foldableView {

	if (!_foldableView) {

		_foldableView = [RAFoldableView new];
		_foldableView.backgroundColor = [UIColor clearColor];
		
	}
	
	return _foldableView;
	
}

- (BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
	
	CGRect bounds = gestureRecognizer.view.bounds;
	CGPoint location = [touch locationInView:gestureRecognizer.view];
	return ((!CGRectContainsPoint(CGRectInset(bounds, 32, 32), location))
		&& (CGRectContainsPoint(CGRectInset(bounds, -32, -32), location)));

}

- (void) handlePan:(UIPanGestureRecognizer *)panGestureRecognizer {
	
	UIView * const view = panGestureRecognizer.view;
	CGPoint const translation = [panGestureRecognizer translationInView:view];
	
	self.toLocation = [panGestureRecognizer locationInView:view];
	
	switch (panGestureRecognizer.state) {
		
		case UIGestureRecognizerStateBegan: {
			self.fromLocation = self.toLocation;
		}
		
		case UIGestureRecognizerStateChanged: {
			
			if (!self.foundChippingEdge) {
				
				CGFloat const distance = sqrtf(powf(translation.x, 2) + powf(translation.y, 2));
				BOOL const tolerable = 32.0f <= distance;
				if (tolerable) {
					
					BOOL const vertical = fabsf(translation.x) < fabsf(translation.y);
					BOOL const horizontal = fabsf(translation.x) > fabsf(translation.y);
					
					BOOL const pullingUp = translation.y < 0.0f;
					BOOL const pullingDown = translation.y > 0.0f;
					BOOL const pullingLeft = translation.x < 0.0f;
					BOOL const pullingRight = translation.x > 0.0f;
					
					BOOL const fromTop = self.fromLocation.y < CGRectGetMidY(view.bounds);
					BOOL const fromBottom = self.fromLocation.y > CGRectGetMidY(view.bounds);
					BOOL const fromLeft = self.fromLocation.x < CGRectGetMidX(view.bounds);
					BOOL const fromRight = self.fromLocation.x > CGRectGetMidX(view.bounds);
					
					BOOL cases[] = (BOOL[]){
						[CGRectMinXEdge] = horizontal && pullingRight && fromLeft,
						[CGRectMinYEdge] = vertical && pullingDown && fromTop,
						[CGRectMaxXEdge] = horizontal && pullingLeft && fromRight,
						[CGRectMaxYEdge] = vertical && pullingUp && fromBottom
					};
					
					for (CGRectEdge edge = CGRectMinXEdge; edge <= CGRectMaxYEdge; edge++) {
						
						if (cases[edge]) {
							self.chippingEdge = edge;
							self.foundChippingEdge = YES;
							break;
						}
						
					}
					
				}
				
			} else {
				
				CGRect slice = CGRectNull;
				CGRect remainder = CGRectNull;
				CGFloat const spacing = 16.0f;
				
				CGFloat distance = ((CGFloat[]){
					[CGRectMinXEdge] = MAX(0, MIN(fabsf(translation.x), CGRectGetWidth(view.bounds) - spacing)),
					[CGRectMinYEdge] = MAX(0, MIN(fabsf(translation.y), CGRectGetHeight(view.bounds) - spacing)),
					[CGRectMaxXEdge] = MAX(0, MIN(fabsf(translation.x), CGRectGetWidth(view.bounds) - spacing)),
					[CGRectMaxYEdge] = MAX(0, MIN(fabsf(translation.y), CGRectGetHeight(view.bounds) - spacing))
				})[self.chippingEdge];
				
				CGRectDivide(view.bounds, &remainder, &slice, roundf(distance), self.chippingEdge);
				
				self.foldableView.frame = slice;
				
			} // if (!haveFoundChippingEdge)
			
			break;
			
		}	// case UIGestureRecognizerStateChanged
		
		default: {
			
			self.foundChippingEdge = NO;
			
			[UIView animateWithDuration:0.3f delay:0.0f options:UIViewAnimationOptionLayoutSubviews|UIViewAnimationOptionCurveLinear animations:^{
			
				self.foldableView.frame = self.bounds;
				
			} completion:^(BOOL finished) {
				
				[self.foldableView setNeedsLayout];
				
			}];
			
			break;
			
		}
	}
	
}

@end
