/*
 The MIT License (MIT)
 
 KWSwipePickerView - Copyright (c) 2013, Jeungwon An (kawoou@kawoou.kr)
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of
 this software and associated documentation files (the "Software"), to deal in
 the Software without restriction, including without limitation the rights to
 use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
 of the Software, and to permit persons to whom the Software is furnished to do
 so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 */

#import "KWSwipePickerView.h"

#define ToInt(number)           [number integerValue]
#define ToUInt(number)          [number unsignedIntegerValue]
#define IntNumber(number)       [NSNumber numberWithInteger:number]
#define UIntNumber(number)      [NSNumber numberWithUnsignedInteger:number]

// KWSwipePickerViewStatus ​​sorted from the highest privilege in lower privilege.
typedef NS_ENUM(NSInteger, KWSwipePickerViewStatus)
{
    KWSwipePickerViewStatusNone,
    KWSwipePickerViewStatusMove,
    KWSwipePickerViewStatusReplace,
    KWSwipePickerViewStatusDelete,
    KWSwipePickerViewStatusInsert
};

static const CGFloat kSwipePickerMoveListAnimationTime = 0.3f;
static const CGFloat kSwipePickerMoveBoxAnimationTime = 0.3f;
static const CGFloat kSwipePickerReplaceBoxAnimationTime = 0.3f;
static const CGFloat kSwipePickerDeleteBoxAnimationTime = 0.15f;
static const CGFloat kSwipePickerInsertBoxPauseTime = 0.1f;
static const CGFloat kSwipePickerSwipingAnimationTime = 0.5;

@interface KWSwipePickerView() <UIGestureRecognizerDelegate>
{
    BOOL                            _isBeginUpdates;
    CGPoint                         _contentCenter;
    
    CGFloat                         _globalPoint;
    CGFloat                         _gesturePoint;
    
    NSInteger                       _selectedIndex;
    NSInteger                       _commitSelectedIndex;
    NSInteger                       _insertMaxLength;
    
    CGImageRef                      _maskImage;
    
    UIView                          *_mainView;
    UIView                          *_listView;
    NSMutableArray                  *_valueArray;
    NSMutableArray                  *_statusArray;
    NSMutableArray                  *_viewArray;
    
    UIPanGestureRecognizer          *_panGestureRecognizer;
    UILongPressGestureRecognizer    *_longGestureRecognizer;
}

- (void)initialize;
- (void)handleGesture:(UIPanGestureRecognizer *)gesture;
- (void)boxTouchDown:(UIButton *)button withEvent:(UIEvent *)event;
- (void)boxTouchUpInside:(UIButton *)button withEvent:(UIEvent *)event;

- (void)animatedMoveAtIndex:(NSUInteger)index duration:(CGFloat)duration;
- (void)animatedDeleteAtIndex:(NSUInteger)index duration:(CGFloat)duration;
- (void)animatedReplaceAtIndex:(NSUInteger)index duration:(CGFloat)duration;
- (void)animatedAtIndex:(NSUInteger)index;

- (void)reorderObjects;

@end

@implementation KWSwipePickerView

#pragma mark - Properties
- (void)setFont:(UIFont *)font
{
    _font = font;
    for (UIButton *button in _viewArray)
    {
        ((UILabel *)[button subviews][0]).font = _font;
    }
}

- (void)setTextColor:(UIColor *)textColor
{
    _textColor = textColor;
    for (UIButton *button in _viewArray)
    {
        ((UILabel *)[button subviews][0]).textColor = _textColor;
    }
}

- (void)setBoxSize:(CGFloat)boxSize
{
    _boxSize = boxSize;
    [self setFrame:self.frame];
    
    for (NSUInteger i = 0; i < [_valueArray count]; i ++)
    {
        if(ToInt(_statusArray[i]) < KWSwipePickerViewStatusMove)
            _statusArray[i] = IntNumber(KWSwipePickerViewStatusMove);
    }
    [self reorderObjects];
}

- (void)setHorizonalMode:(BOOL)horizonalMode
{
    _horizonalMode = horizonalMode;
    [self setFrame:self.frame];
    
    for (NSUInteger i = 0; i < [_valueArray count]; i ++)
    {
        if(ToInt(_statusArray[i]) < KWSwipePickerViewStatusMove)
            _statusArray[i] = IntNumber(KWSwipePickerViewStatusMove);
    }
    [self reorderObjects];
}

- (NSInteger)selectedIndex
{
    return _commitSelectedIndex;
}

#pragma mark - Creation
- (id)init
{
    self = [super init];
    if (self)
    {
        [self initialize];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self initialize];
        [self setFrame:frame];
    }
    return self;
}

- (id)initWithArray:(NSArray *)array
{
    self = [super init];
    if (self)
    {
        [_valueArray addObjectsFromArray:array];
        [self initialize];
    }
    return self;
}

- (id)initWithObjects:(id)firstObj, ...
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    
    va_list args;
    va_start(args, firstObj);
    
    for (NSString *arg = firstObj; arg != nil; va_arg(args, NSString *))
    {
        [array addObject:arg];
    }
    
    va_end(args);
    
    return [self initWithArray:array];
}

#pragma mark - Methods

- (void)beginUpdates
{
    _isBeginUpdates = YES;
}

- (void)endUpdates
{
    if(_isBeginUpdates)
        [self reorderObjects];
    
    _isBeginUpdates = NO;
}

- (void)setSelectedIndex:(NSInteger)index animated:(BOOL)animated
{
    BOOL originalAnimated = _animated;
    _animated = animated;
    
    if(index < 0)
        index = 0;
    if(index >= [_valueArray count])
        index = [_valueArray count] - 1;
    
    _selectedIndex = index;
    _globalPoint = index * _boxSize;
    _gesturePoint = 0;
    
    if(_delegate &&
       [(id)_delegate
        respondsToSelector:@selector(swipePicker:willSelectIndex:)])
    {
        [_delegate swipePicker:self willSelectIndex:index];
    }
    
    if(!_isBeginUpdates)
        [self reorderObjects];
    
    if(_delegate &&
       [(id)_delegate
        respondsToSelector:@selector(swipePicker:didSelectIndex:)])
    {
        double delayInSeconds = 0.0f;
        if(_animated)
            delayInSeconds = kSwipePickerMoveListAnimationTime;
        
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW,
                        (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [_delegate swipePicker:self didSelectIndex:self.selectedIndex];
        });
    }
    
    _animated = originalAnimated;
}

- (NSUInteger)count
{
    return [_valueArray count];
}

- (void)addString:(NSString *)string
{
    [self insertAfterOfIndex:(_valueArray.count - 1)
                 withStrings:[NSArray arrayWithObject:string]];
}

- (void)insertString:(NSString *)string atIndex:(NSUInteger)index
{
    [self insertBeforeOfIndex:index
                  withStrings:[NSArray arrayWithObject:string]];
}

- (void)removeFirstObject
{
    [self removeStringAtIndex:0];
}

- (void)removeLastObject
{
    [self removeStringAtIndex:(_valueArray.count - 1)];
}

- (void)removeStringAtIndex:(NSUInteger)index
{
    [self removeStringsInRange:(NSRange){
        .location = index,
        .length = 1
    }];
}

- (void)replaceStringAtIndex:(NSUInteger)index withString:(NSString *)string
{
    [self replaceStringsInRange:(NSRange){
        .location = index,
        .length = 1
    } withStrings:[NSArray arrayWithObject:string]];
}

#pragma mark - Extended
- (NSArray *)strings
{
    return [[NSArray alloc] initWithArray:_valueArray copyItems:YES];
}

- (NSArray *)stringsInRange:(NSRange)range
{
    return [[NSArray alloc] initWithArray:
            [_valueArray objectsAtIndexes:
             [NSIndexSet indexSetWithIndexesInRange:range]] copyItems:YES];
}

- (NSString *)stringAtIndex:(NSUInteger)index
{
    return [[_valueArray objectAtIndex:index] copy];
}

- (NSArray *)indexesOfString:(NSString *)string
{
    return [self indexesOfString:string inRange:(NSRange){
        .location = 0,
        .length = [_valueArray count]
    }];
}

- (NSArray *)indexesOfString:(NSString *)string inRange:(NSRange)range
{
    NSMutableArray *indexesArray = [[NSMutableArray alloc] init];
    for (NSUInteger i = range.location; i < range.location + range.length; i ++)
    {
        NSString *inString = [_valueArray objectAtIndex:i];
        if([inString isEqualToString:string])
            [indexesArray addObject:UIntNumber(i)];
    }
    return indexesArray;
}

- (NSString *)firstString
{
    return [[_valueArray firstObject] copy];
}

- (NSString *)lastString
{
    return [[_valueArray lastObject] copy];
}

- (void)removeAllStrings
{
    for (NSUInteger i = 0; i < [_valueArray count]; i ++)
    {
        if([_statusArray[i] integerValue] < KWSwipePickerViewStatusDelete)
            _statusArray[i] = IntNumber(KWSwipePickerViewStatusDelete);
    }
    
    if(!_isBeginUpdates)
        [self reorderObjects];
}

- (void)removeString:(NSString *)string
{
    [self removeString:string inRange:(NSRange){
        .location = 0,
        .length = [_valueArray count]
    }];
}

- (void)removeString:(NSString *)string inRange:(NSRange)range
{
    NSArray *indexes = [self indexesOfString:string inRange:range];
    if([indexes count] == 0) return;
    
    for (NSNumber *index in indexes)
    {
        NSUInteger i = [index unsignedIntegerValue];
        if(ToInt(_statusArray[i]) < KWSwipePickerViewStatusDelete)
            _statusArray[i] = IntNumber(KWSwipePickerViewStatusDelete);
    }
    for (NSUInteger i = ToUInt(indexes[0]); i < [_valueArray count]; i ++)
    {
        if(ToInt(_statusArray[i]) < KWSwipePickerViewStatusMove)
            _statusArray[i] = IntNumber(KWSwipePickerViewStatusMove);
    }
    
    if(!_isBeginUpdates)
        [self reorderObjects];
}

- (void)removeStringsInRange:(NSRange)range
{
    NSUInteger i;
    
    CGRect frame = _listView.frame;
    if(_horizonalMode)
        frame.size.width = _boxSize * ([_valueArray count] + range.length);
    else
        frame.size.height = _boxSize * ([_valueArray count] + range.length);
    _listView.frame = frame;
    
    if(_selectedIndex == -1)
    {
        _selectedIndex = 0;
    }
    else if(range.location <= _commitSelectedIndex)
    {
        if(_commitSelectedIndex <= range.location + range.length)
            _selectedIndex = range.location -
                             (_commitSelectedIndex - _selectedIndex) - 1;
        else
            _selectedIndex -= range.length;
        
        if(_selectedIndex < 0)
            _selectedIndex = 0;
    }
    _globalPoint = _selectedIndex * _boxSize;
    
    for (i = range.location; i < range.location + range.length; i ++)
    {
        if(ToInt(_statusArray[i]) < KWSwipePickerViewStatusDelete)
            _statusArray[i] = IntNumber(KWSwipePickerViewStatusDelete);
    }
    for (; i < [_valueArray count]; i ++)
    {
        if(ToInt(_statusArray[i]) < KWSwipePickerViewStatusMove)
            _statusArray[i] = IntNumber(KWSwipePickerViewStatusMove);
    }
    
    if(!_isBeginUpdates)
        [self reorderObjects];
}

- (void)replaceStringsInRange:(NSRange)range withStrings:(NSArray *)strings
{
    for (NSUInteger i = range.location; i < range.location + range.length; i ++)
    {
        _valueArray[i] = strings;
        if(ToInt(_statusArray[i]) < KWSwipePickerViewStatusReplace)
            _statusArray[i] = IntNumber(KWSwipePickerViewStatusReplace);
    }
    
    if(!_isBeginUpdates)
        [self reorderObjects];
}

- (void)insertBeforeOfIndex:(NSUInteger)index withStrings:(NSArray *)strings
{
    NSUInteger count = [strings count];
    NSUInteger prevLength = _selectedIndex - _commitSelectedIndex;
    CGRect frame = _listView.frame;
    if(_horizonalMode)
        frame.size.width = _boxSize * ([_valueArray count] + count);
    else
        frame.size.height = _boxSize * ([_valueArray count] + count);
    _listView.frame = frame;
    
    [_valueArray insertObjects:strings atIndexes:
     [NSIndexSet indexSetWithIndexesInRange:(NSRange){
        .location = index + prevLength,
        .length = count
    }]];
    
    if(_commitSelectedIndex == -1)
    {
        _selectedIndex = 0;
    }
    else if(index <= _commitSelectedIndex)
    {
        _selectedIndex += count;
        if(_selectedIndex >= [_valueArray count])
            _selectedIndex = [_valueArray count] - 1;
    }
    _globalPoint = _selectedIndex * _boxSize;
    
    NSUInteger i;
    for (i = 0; i < count; i ++)
    {
        [_statusArray insertObject:IntNumber(KWSwipePickerViewStatusInsert)
                           atIndex:(index + prevLength)];
    }
    for (i = index + count; i < [_valueArray count]; i ++)
    {
        if(ToInt(_statusArray[i]) < KWSwipePickerViewStatusMove)
            _statusArray[i] = IntNumber(KWSwipePickerViewStatusMove);
    }
    
    if(!_isBeginUpdates)
        [self reorderObjects];
}

- (void)insertAfterOfIndex:(NSUInteger)index withStrings:(NSArray *)strings
{
    [self insertBeforeOfIndex:(index + 1) withStrings:strings];
}

#pragma mark - Override methods
- (void)dealloc
{
    if(_maskImage)
    {
        CGImageRelease(_maskImage);
        _maskImage = nil;
    }
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    [_mainView setFrame:frame];
    
    _contentCenter = CGPointMake(frame.size.width  * 0.5f,
                                 frame.size.height * 0.5f);
    if(_horizonalMode)
    {
        _listView.frame = CGRectMake(_selectedIndex * _boxSize,
                                     0,
                                     _boxSize * [_valueArray count],
                                     frame.size.height);
    }
    else
    {
        _listView.frame = CGRectMake(0,
                                     _selectedIndex * _boxSize,
                                     frame.size.width,
                                     _boxSize * [_valueArray count]);
    }
    
    if(_maskImage)
    {
        CGImageRelease(_maskImage);
        _maskImage = nil;
    }
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
    CGContextRef gc = CGBitmapContextCreate(NULL,
                                            frame.size.width,
                                            frame.size.height,
                                            8,
                                            frame.size.width,
                                            colorSpace,
                                            (uint32_t)kCGImageAlphaOnly);
    CGGradientRef gradient =
    CGGradientCreateWithColors(colorSpace,
                (__bridge CFArrayRef)
                [NSArray arrayWithObjects:
                (__bridge id)[UIColor colorWithWhite:1 alpha:0.3].CGColor,
                (__bridge id)[UIColor colorWithWhite:1 alpha:1].CGColor, nil],
                NULL);
    if(_horizonalMode)
    {
        CGFloat size = (frame.size.width - _boxSize) * 0.5f;
        CGContextDrawLinearGradient(gc,
                                    gradient,
                                    CGPointMake(0, 0),
                                    CGPointMake(size, 0),
                                    0);
        CGContextDrawLinearGradient(gc,
                                    gradient,
                                    CGPointMake(frame.size.width, 0),
                                    CGPointMake(frame.size.width - size, 0),
                                    0);
        CGContextSetAlpha(gc, 1);
        CGContextFillRect(gc, CGRectMake(size, 0, _boxSize, frame.size.height));
    }
    else
    {
        CGFloat size = (frame.size.height - _boxSize) * 0.5f;
        CGContextDrawLinearGradient(gc,
                                    gradient,
                                    CGPointMake(0, 0),
                                    CGPointMake(0, size),
                                    0);
        CGContextDrawLinearGradient(gc,
                                    gradient,
                                    CGPointMake(0, frame.size.height),
                                    CGPointMake(0, frame.size.height - size),
                                    0);
        CGContextSetAlpha(gc, 1);
        CGContextFillRect(gc, CGRectMake(0, size, frame.size.width, _boxSize));
    }
    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorSpace);
    
    _maskImage = CGBitmapContextCreateImage(gc);
    
    CALayer *layerMask = [CALayer layer];
    layerMask.frame = self.frame;
    layerMask.contents = (__bridge id)_maskImage;
    _mainView.layer.mask = layerMask;
    _mainView.layer.masksToBounds = YES;

    CGContextRelease(gc);
}

#pragma mark - Private methods
- (void)initialize
{
    /* Variables */
    /// Delegate
    _delegate = nil;
    
    /// Objects information
    _font = [UIFont boldSystemFontOfSize:42];
    _textColor = [UIColor whiteColor];
    
    /// Position information
    _globalPoint = 0.0f;
    _gesturePoint = 0.0f;
    
    /// Custom information
    _animated = YES;
    _isBeginUpdates = NO;
    _contentCenter = CGPointMake(0, 0);
    
    _boxSize = 78;
    _horizonalMode = NO;
    _selectedIndex = -1;
    
    /* View */
    _maskImage = nil;
    
    _mainView = [[UIView alloc] init];
    _listView = [[UIView alloc] init];
    _valueArray = [[NSMutableArray alloc] init];
    _statusArray = [[NSMutableArray alloc] init];
    _viewArray = [[NSMutableArray alloc] init];
    [_mainView addSubview:_listView];
    [self addSubview:_mainView];
    [self setOpaque:NO];
    [self setClipsToBounds:YES];
    
    /* Gesture recognizer */
    _panGestureRecognizer = [[UIPanGestureRecognizer alloc] init];
    _longGestureRecognizer = [[UILongPressGestureRecognizer alloc] init];
    [_panGestureRecognizer addTarget:self
                              action:@selector(handleGesture:)];
    [_longGestureRecognizer addTarget:self
                               action:@selector(handleGesture:)];
    [self addGestureRecognizer:_panGestureRecognizer];
    [self addGestureRecognizer:_longGestureRecognizer];
}

- (void)handleGesture:(UIPanGestureRecognizer *)gesture
{
    static CGPoint lastTranslate;   // the last value
    static CGPoint prevTranslate;   // the value before that one
    static NSTimeInterval lastTime;
    static NSTimeInterval prevTime;
    
    if([gesture isKindOfClass:[UILongPressGestureRecognizer class]])
        return;
    
    UIGestureRecognizerState state = [gesture state];
    CGPoint translation = [gesture translationInView:self];
    
    /// Gesture began
    if(state == UIGestureRecognizerStateBegan)
    {
        if(_delegate &&
           [(id)_delegate respondsToSelector:
            @selector(didTouchDownInSwipePicker:)])
        {
            [_delegate didTouchDownInSwipePicker:self];
        }
        
        lastTime = [NSDate timeIntervalSinceReferenceDate];
        lastTranslate = translation;
        prevTime = lastTime;
        prevTranslate = lastTranslate;
    }
    
    /// Gesture changed
    else if(state == UIGestureRecognizerStateChanged)
    {
        if(_horizonalMode)
            _gesturePoint += translation.x;
        else
            _gesturePoint += translation.y;
        [self reorderObjects];
        
        [gesture setTranslation:CGPointZero inView:self];
        
        prevTime = lastTime;
        prevTranslate = lastTranslate;
        lastTime = [NSDate timeIntervalSinceReferenceDate];
        lastTranslate = translation;
    }
    
    /// Gesture ended
    else if(state == UIGestureRecognizerStateEnded ||
            state == UIGestureRecognizerStateCancelled)
    {
        gesture.enabled = YES;
        CGPoint swipeVelocity = CGPointZero;
        
        NSTimeInterval seconds =
            [NSDate timeIntervalSinceReferenceDate] - prevTime;
        if (seconds != 0.0f)
        {
            swipeVelocity =
                CGPointMake((translation.x - prevTranslate.x) / seconds,
                            (translation.y - prevTranslate.y) / seconds);
        }
        
        float inertiaSeconds = kSwipePickerSwipingAnimationTime;
        {
            CGFloat pos = -_boxSize * 0.5f;
            if(_horizonalMode)
            {
                pos += _contentCenter.x - _listView.frame.origin.x;
                pos += translation.x + swipeVelocity.x * inertiaSeconds;
            }
            else
            {
                pos += _contentCenter.y - _listView.frame.origin.y;
                pos += translation.y + swipeVelocity.y * inertiaSeconds;
            }
            
            NSInteger row = round(pos / _boxSize);
            if(row < 0) row = 0;
            else if(row >= [_valueArray count]) row = [_valueArray count] - 1;
            
            [self setSelectedIndex:row animated:YES];
        }
        
        if(_delegate &&
           [(id)_delegate respondsToSelector:
            @selector(didTouchUpInsideInSwipePicker:)])
        {
            [_delegate didTouchUpInsideInSwipePicker:self];
        }
    }
    [UIView setAnimationDelegate:self];
}

- (void)boxTouchDown:(UIButton *)button withEvent:(UIEvent *)event
{
    if(_delegate &&
       [(id)_delegate respondsToSelector:
        @selector(didTouchDownInSwipePicker:)])
    {
        [_delegate didTouchDownInSwipePicker:self];
    }
}

- (void)boxTouchUpInside:(UIButton *)button withEvent:(UIEvent *)event
{
    if(_horizonalMode)
    {
        [self setSelectedIndex:(button.frame.origin.x / _boxSize)
                      animated:YES];
    }
    else
    {
        [self setSelectedIndex:(button.frame.origin.y / _boxSize)
                      animated:YES];
    }
    
    if(_delegate &&
       [(id)_delegate respondsToSelector:
        @selector(didTouchUpInsideInSwipePicker:)])
    {
        [_delegate didTouchUpInsideInSwipePicker:self];
    }
}

- (void)animatedMoveAtIndex:(NSUInteger)index duration:(CGFloat)duration
{
    KWSwipePickerViewStatus status = ToInt(_statusArray[index]);
    
    if(status == KWSwipePickerViewStatusInsert)
    {
        CGFloat delay =
            abs((int)(index - _selectedIndex)) / _insertMaxLength *
            kSwipePickerMoveListAnimationTime +
            kSwipePickerInsertBoxPauseTime;
        
        if(_animated)
        {
            [UIView animateWithDuration:duration
                                  delay:delay
                                options:UIViewAnimationOptionCurveEaseInOut
                             animations:^{
                                 ((UIButton *)_viewArray[index]).alpha = 1.0f;
                             }
                             completion:nil];
        }
        else
        {
            ((UIButton *)_viewArray[index]).alpha = 1.0f;
        }
    }
    
    if(_animated)
    {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:duration];
    }
    
    UIButton *boxView = _viewArray[index];
    if(_horizonalMode)
    {
        boxView.frame = CGRectMake(index * _boxSize, 0,
                                   _boxSize, _listView.frame.size.height);
    }
    else
    {
        boxView.frame = CGRectMake(0, index * _boxSize,
                                   _listView.frame.size.width, _boxSize);
    }
    
    UILabel *textLabel = [boxView subviews][0];
    [textLabel setFrame:CGRectMake(0, 0,
                                   boxView.frame.size.width,
                                   boxView.frame.size.height)];
    
    if(_animated)
    {
        [UIView commitAnimations];
    }
    
    _statusArray[index] = IntNumber(KWSwipePickerViewStatusNone);
}

- (void)animatedDeleteAtIndex:(NSUInteger)index duration:(CGFloat)duration
{
    UIButton *boxView = _viewArray[index];
    if(_animated)
    {
        [UIView animateWithDuration:duration
                         animations:^{
                             boxView.alpha = 0.0f;
                         } completion:^(BOOL finished){
                             [boxView removeFromSuperview];
                         }];
    }
    else
    {
        [boxView removeFromSuperview];
    }
    
    [_valueArray removeObjectAtIndex:index];
    [_statusArray removeObjectAtIndex:index];
    [_viewArray removeObjectAtIndex:index];
}

- (void)animatedReplaceAtIndex:(NSUInteger)index duration:(CGFloat)duration
{
    KWSwipePickerViewStatus status = ToInt(_statusArray[index]);
    
    if(status == KWSwipePickerViewStatusInsert)
    {
        UIButton *boxView = [[UIButton alloc] init];
        NSInteger animationIndex = index;
        if(index > _selectedIndex)
            animationIndex = index - _selectedIndex;
        
        if(_horizonalMode)
        {
            boxView.frame = CGRectMake(animationIndex * _boxSize, 0,
                                       _boxSize, _listView.frame.size.height);
        }
        else
        {
            boxView.frame = CGRectMake(0, animationIndex * _boxSize,
                                       _listView.frame.size.width, _boxSize);
        }
        boxView.alpha = 0.0f;
        
        UILabel *textLabel = [[UILabel alloc] init];
        [textLabel setFrame:CGRectMake(0, 0,
                                       boxView.frame.size.width,
                                       boxView.frame.size.height)];
        [textLabel setTextAlignment:NSTextAlignmentCenter];
        [textLabel setFont:_font];
        [textLabel setTextColor:_textColor];
        [textLabel setBackgroundColor:[UIColor clearColor]];
        [boxView addSubview:textLabel];
        
        [_listView addSubview:boxView];
        [_viewArray insertObject:boxView atIndex:index];
        
        [boxView addTarget:self
                    action:@selector(boxTouchDown:withEvent:)
          forControlEvents:UIControlEventTouchDown];
        [boxView addTarget:self
                    action:@selector(boxTouchUpInside:withEvent:)
          forControlEvents:UIControlEventTouchUpInside];
    }
    
    if(_animated)
    {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:duration];
    }
    
    ((UILabel *)[_viewArray[index] subviews][0]).text = _valueArray[index];
    
    if(_animated)
    {
        [UIView commitAnimations];
    }
}

- (void)animatedAtIndex:(NSUInteger)index
{
    KWSwipePickerViewStatus status = ToInt(_statusArray[index]);
    switch (status)
    {
        case KWSwipePickerViewStatusDelete:
            [self animatedDeleteAtIndex:index
                               duration:kSwipePickerDeleteBoxAnimationTime];
            break;
            
        case KWSwipePickerViewStatusReplace:
        case KWSwipePickerViewStatusInsert:
            [self animatedReplaceAtIndex:index
                                duration:kSwipePickerReplaceBoxAnimationTime];
            
        default:
            [self animatedMoveAtIndex:index
                             duration:kSwipePickerMoveBoxAnimationTime];
    }
}

- (void)reorderObjects
{
    NSUInteger i;
    BOOL firstInsert = NO;
    BOOL originalAnimated = _animated;
    CGFloat newPoint = -_globalPoint + _gesturePoint;
    if(newPoint > 0)
    {
        if(_horizonalMode)
        {
            newPoint = _contentCenter.x *
                sin(newPoint / _contentCenter.x * 0.5f * 1.570796f);
        }
        else
        {
            newPoint = _contentCenter.y *
                sin(newPoint / _contentCenter.y * 0.5f * 1.570796f);
        }
        newPoint *= 0.8;
    }
    if(_horizonalMode)
    {
        if(newPoint < -_listView.frame.size.width + _boxSize)
        {
            newPoint = -_listView.frame.size.width + _boxSize - newPoint;
            newPoint = _contentCenter.x *
                sin(newPoint / _contentCenter.x * 0.5f * 1.570796f);
            newPoint = -_listView.frame.size.width - newPoint;
            newPoint *= 0.8;
        }
    }
    else
    {
        if(newPoint < -_listView.frame.size.height + _boxSize)
        {
            newPoint = -_listView.frame.size.height + _boxSize - newPoint;
            newPoint = _contentCenter.y *
                sin(newPoint / _contentCenter.y * 0.5f * 1.570796f);
            newPoint = -_listView.frame.size.height - newPoint;
            newPoint *= 0.8;
        }
    }
    
    CGFloat position = newPoint - (_boxSize * 0.5f);
    
    for (i = 0; i < [_statusArray count]; i ++)
    {
        if(ToInt(_statusArray[i]) != KWSwipePickerViewStatusInsert)
            break;
    }
    if(i == [_statusArray count])
    {
        firstInsert = YES;
        _animated = NO;
    }
    
    _insertMaxLength = 0;
    if(_selectedIndex != -1)
    {
        for (i = _selectedIndex; i > 0; i --)
        {
            NSUInteger index = i - 1;
            if(ToInt(_statusArray[index]) == KWSwipePickerViewStatusInsert)
                _insertMaxLength = _selectedIndex - index;
        }
        for (i = _selectedIndex + _insertMaxLength; i < [_statusArray count]; i ++)
        {
            if(ToInt(_statusArray[i]) == KWSwipePickerViewStatusInsert)
                _insertMaxLength = i - _selectedIndex;
        }
    }
    
    if(_animated)
    {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:kSwipePickerMoveListAnimationTime];
    }
    if(_horizonalMode)
    {
        [_listView setFrame:CGRectMake(_contentCenter.x + position,
                                       _listView.frame.origin.y,
                                       _listView.frame.size.width,
                                       _listView.frame.size.height)];
    }
    else
    {
        [_listView setFrame:CGRectMake(_listView.frame.origin.x,
                                       _contentCenter.y + position,
                                       _listView.frame.size.width,
                                       _listView.frame.size.height)];
    }
    if(_animated)
    {
        [UIView commitAnimations];
    }
    
    for (i = 0; i < [_valueArray count]; i ++)
    {
        NSInteger status = ToInt(_statusArray[i]);
        [self animatedAtIndex:i];
        if(status == KWSwipePickerViewStatusDelete) i --;
    }
    
    if(firstInsert)
        _animated = originalAnimated;
    
    _commitSelectedIndex = _selectedIndex;
}

@end
