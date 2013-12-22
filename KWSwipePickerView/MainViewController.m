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

#import "MainViewController.h"

@interface MainViewController ()

@end

@implementation MainViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        
        [self.view setBackgroundColor:[UIColor whiteColor]];
        
        _swipePickerView = [[KWSwipePickerView alloc] initWithFrame:CGRectMake(0, 0, 320, 100)];
        [_swipePickerView setBoxSize:50.0f];
        [_swipePickerView setDelegate:self];
        [_swipePickerView setHorizonalMode:YES];
        [_swipePickerView setTextColor:[UIColor whiteColor]];
        [_swipePickerView setBackgroundColor:[UIColor redColor]];
        [_swipePickerView insertBeforeOfIndex:0 withStrings:[NSArray arrayWithObjects:@"A", @"B", @"C", @"D", @"E", nil]];
        [self.view addSubview:_swipePickerView];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -
#pragma mark - KWSwipePickerViewDelegate
- (void)swipePicker:(KWSwipePickerView *)swipePicker didSelectIndex:(NSUInteger)index
{
    [swipePicker beginUpdates];
    if([[swipePicker stringAtIndex:index] isEqualToString:@"C"])
    {
        if([swipePicker count] <= 5)
        {
            [swipePicker insertBeforeOfIndex:index withStrings:[NSArray arrayWithObjects:@"1", @"2", @"3", @"4", nil]];
            [swipePicker insertAfterOfIndex:index withStrings:[NSArray arrayWithObjects:@"5", @"6", @"7", @"8", nil]];
        }
    }
    else if([swipePicker count] > 5)
    {
        [swipePicker removeStringsInRange:(NSRange){.location=2, .length=4}];
        [swipePicker removeStringsInRange:(NSRange){.location=7, .length=4}];
    }
    [swipePicker endUpdates];
}

@end
