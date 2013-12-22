/*
 The MIT License (MIT)
 
 KWSwipePickerView - Copyright (c) 2013, Jeungwon An (kawoou@kawoou.kr)
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of
 this software and associated documentation files (the "Software"), to deal in
 the Software without restriction, including without limitation the rights to
 use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
 of the Software, and to permit persons to whom the Software is furnished to do
 so, subject to the following condi tions:
 
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

#import <UIKit/UIKit.h>

@protocol KWSwipePickerViewDelegate;

#pragma mark - Properties
@interface KWSwipePickerView : UIView

@property (nonatomic, strong)   id<KWSwipePickerViewDelegate> delegate;

@property (nonatomic, retain)   UIFont *font;
@property (nonatomic, retain)   UIColor *textColor;

@property (nonatomic, assign)   CGFloat boxSize;
@property (nonatomic, assign)   BOOL horizonalMode;

@property (readonly)            NSInteger selectedIndex;

@end

#pragma mark - Methods
@interface KWSwipePickerView (KWSwipePickerViewMethods)

- (void)beginUpdates;
- (void)endUpdates;

- (void)setSelectedIndex:(NSInteger)index animated:(BOOL)animated;

- (NSUInteger)count;
- (void)addString:(NSString *)string;
- (void)insertString:(NSString *)string atIndex:(NSUInteger)index;
- (void)removeFirstObject;
- (void)removeLastObject;
- (void)removeStringAtIndex:(NSUInteger)index;
- (void)replaceStringAtIndex:(NSUInteger)index withString:(NSString *)string;

@end

#pragma mark - Extended
@interface KWSwipePickerView (KWSwipePickerViewExtended)

- (NSArray *)strings;
- (NSArray *)stringsInRange:(NSRange)range;
- (NSString *)stringAtIndex:(NSUInteger)index;
- (NSArray *)indexesOfString:(NSString *)string;
- (NSArray *)indexesOfString:(NSString *)string inRange:(NSRange)range;
- (NSString *)firstString;
- (NSString *)lastString;

- (void)removeAllStrings;
- (void)removeString:(NSString *)string;
- (void)removeString:(NSString *)string inRange:(NSRange)range;
- (void)removeStringsInRange:(NSRange)range;
- (void)replaceStringsInRange:(NSRange)range withStrings:(NSArray *)strings;
- (void)insertBeforeOfIndex:(NSUInteger)index withStrings:(NSArray *)strings;
- (void)insertAfterOfIndex:(NSUInteger)index withStrings:(NSArray *)strings;

@end

#pragma mark - Creation
@interface KWSwipePickerView (KWSwipePickerViewCreation)

- (id)init;
- (id)initWithFrame:(CGRect)frame;
- (id)initWithArray:(NSArray *)array;
- (id)initWithObjects:(id)firstObj, ... NS_REQUIRES_NIL_TERMINATION;

@end

#pragma mark - Delegate
@protocol KWSwipePickerViewDelegate

@optional

- (void)didTouchUpInsideInSwipePicker:(KWSwipePickerView *)swipePicker;
- (void)didTouchDownInSwipePicker:(KWSwipePickerView *)swipePicker;

- (void)swipePicker:(KWSwipePickerView *)swipePicker
     didSelectIndex:(NSUInteger)index;
- (void)swipePicker:(KWSwipePickerView *)swipePicker
    willSelectIndex:(NSUInteger)index;

@end