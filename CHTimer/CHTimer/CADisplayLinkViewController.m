//
//  CADisplayLinkViewController.m
//  CHTimer
//
//  Created by chenyuliang on 2019/4/12.
//  Copyright © 2019 didi. All rights reserved.
//

#import "CADisplayLinkViewController.h"
#import "CHTimerDisplay.h"


#define screenWidth  ([[UIScreen mainScreen] bounds].size.width)
#define screenHeight ([[UIScreen mainScreen] bounds].size.height)

#define barHeight  100

@interface CADisplayLinkViewController ()

@property (nonatomic, strong) CHDisplayLinkView *appleLinkView;

@property (nonatomic, strong) CADisplayLink *displayLink;

@property (nonatomic, assign) CFTimeInterval timeStamp;

@property (nonatomic, strong) UIButton *exit;

@property (nonatomic, assign) NSUInteger cout;

@end

@implementation CADisplayLinkViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _cout = 0;
    self.view.backgroundColor = [UIColor whiteColor];
    [self appleLinkView];
    [self exit];
    [self displayLink];
    [self startAnimation];
    // Do any additional setup after loading the view.
}

//displayLink 的应用
- (CHDisplayLinkView *)appleLinkView
{
    if (!_appleLinkView) {
        _appleLinkView = [[CHDisplayLinkView alloc] initWithFrame:CGRectMake(0, 0, screenWidth, barHeight + 200)];
        [self.view addSubview:_appleLinkView];
    }
    return _appleLinkView;
}

//跟NSTimer一样  也是强引用 self的  所以解决方法类似。
- (CADisplayLink *)displayLink
{
    if (!_displayLink) {
        _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateUI:)];
        _displayLink.paused = YES;
        [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    }
    return _displayLink;
}

- (UIButton *)exit
{
    if (!_exit) {
        _exit = [[UIButton alloc] initWithFrame:CGRectMake(screenWidth/2, 400, 40, 40)];
        _exit.backgroundColor = [UIColor redColor];
        [_exit addTarget:self action:@selector(quit) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:_exit];
    }
    return _exit;
}

- (void)quit
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)startAnimation{
    self.displayLink.paused = NO;
}
- (void)stopAnimation{
    self.displayLink.paused = YES;
    [self.displayLink invalidate];
    self.displayLink = nil;
}

- (void)updateUI:(CADisplayLink *)link
{
    _cout++;
    
    if (_timeStamp == 0) {
        _timeStamp = link.timestamp;
    }
    
    CFTimeInterval timePassed = link.timestamp - _timeStamp;
    
    if (timePassed >= 1.f) { //  fps == 一秒钟屏幕刷新的次数  / 运行的时间
        
        CGFloat fps = _cout / timePassed;
        
        [[CHTimerDisplay shareDisplay] display:[NSString stringWithFormat:@"fps :%ld",(long)_cout]];
        
        _timeStamp = link.timestamp;
        _cout = 0;
    }
    
}

-(void)dealloc
{
    [self stopAnimation];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end


@interface CHDisplayLinkView()
@property (nonatomic,assign) CGFloat referPointViewOriginX;
@property (nonatomic,assign) CGFloat referPointViewOriginY;
@property (nonatomic, strong) CAShapeLayer *barLayer;
@property (nonatomic, strong) UIView *referPointView;

@property (nonatomic, strong)  CADisplayLink *displayLink;
@property (nonatomic, assign) BOOL isAnimating;

@end


@implementation CHDisplayLinkView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [[UIColor grayColor] colorWithAlphaComponent:0.5];
        [self addObserver];
        [self addSubView];
        [self addPanAction];
        [self addDisplayLink];
    }
    return self;
}

- (void)addObserver
{
    [self addObserver:self forKeyPath:@"referPointViewOriginX" options:NSKeyValueObservingOptionNew context:nil];
    [self addObserver:self forKeyPath:@"referPointViewOriginY" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"referPointViewOriginX"] ||
        [keyPath isEqualToString:@"referPointViewOriginY"]) {
        [self updateBarLayer];
    }
}

- (void)addSubView
{
    [self barLayer];
    [self referPointView];
    self.referPointViewOriginX = screenWidth/2;
    self.referPointViewOriginY = barHeight;
    
}

- (CAShapeLayer *)barLayer
{
    if (!_barLayer) {
        _barLayer = [CAShapeLayer layer];
        _barLayer.fillColor = [UIColor redColor].CGColor;
        [self.layer addSublayer:_barLayer];
    }
    return _barLayer;
}

- (UIView *)referPointView
{
    if (!_referPointView) {
        _referPointView = [[UIView alloc] initWithFrame:CGRectMake(screenWidth/2, barHeight, 3, 3)];
        _referPointView.backgroundColor = [UIColor blackColor];
        [self addSubview:_referPointView];
    }
    return _referPointView;
}

- (void)addPanAction
{
    _isAnimating = NO;
    UIPanGestureRecognizer *panGes = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanAction:)];
    [self addGestureRecognizer:panGes];
}

- (void)addDisplayLink
{
    _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(useDisplayLinkcalPath)];
    [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    _displayLink.paused = YES;
}
#pragma updateLayer

- (void)handlePanAction:(UIPanGestureRecognizer *)panGes
{
    if(!_isAnimating)
    {
        if (panGes.state == UIGestureRecognizerStateChanged) {
            CGPoint point = [panGes locationInView:self];
            
            self.referPointViewOriginX = point.x;
            self.referPointViewOriginY = point.y;
            _referPointView.frame = CGRectMake(_referPointViewOriginX, _referPointViewOriginY, 3, 3);
        }
        else if (panGes.state == UIGestureRecognizerStateEnded ||
                panGes.state == UIGestureRecognizerStateCancelled ||
                panGes.state == UIGestureRecognizerStateFailed )
        {
            _isAnimating = YES;
            _displayLink.paused = NO;
            
            //弹簧动画
            [UIView animateWithDuration:1.0
                                  delay:0.0
                 usingSpringWithDamping:0.3
                  initialSpringVelocity:0.0
                                options:UIViewAnimationOptionCurveEaseIn
                             animations:^{
                                 _referPointView.frame = CGRectMake(screenWidth/2, barHeight, 3, 3);
                 } completion:^(BOOL finished) {
                     if (finished) {
                         _displayLink.paused = YES;
                          _isAnimating = NO;
                     }
                 }];
        }
        
    }
}

- (void)updateBarLayer
{
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(0, 0)];
    [path addLineToPoint:CGPointMake(screenWidth, 0)];
    [path addLineToPoint:CGPointMake(screenWidth, barHeight)];
    [path addQuadCurveToPoint:CGPointMake(0, barHeight) controlPoint:CGPointMake(_referPointViewOriginX, _referPointViewOriginY)];
    [path closePath];
    _barLayer.path = path.CGPath;
}


- (void)useDisplayLinkcalPath
{
    CALayer *layer = _referPointView.layer.presentationLayer;
    self.referPointViewOriginX = layer.position.x;
    self.referPointViewOriginY = layer.position.y;
}


- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"referPointViewOriginX"];
    [self removeObserver:self forKeyPath:@"referPointViewOriginY"];
}

@end
