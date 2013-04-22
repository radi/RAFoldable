#import "AGGeometryKit.h"
#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>
#import <RANudgable/RANudgableView.h>

@interface RAFoldableView : RANudgableView

@property (nonatomic, readwrite, strong) UIImage *image;
@property (nonatomic, readwrite, assign) CGSize pristineSize;
@property (nonatomic, readwrite, assign) CGRect blindsRect;

@end
