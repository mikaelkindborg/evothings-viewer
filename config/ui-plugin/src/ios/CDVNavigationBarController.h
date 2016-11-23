//
//  CDVNavigationBarController.h
//  Cordova Plugin
//
//  Created by Lifetime.com.eg Technical Team (Amr Hossam / Emad ElShafie) on 6 January 2016.
//  Copyright (c) 2016 Lifetime.com.eg. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without restriction,
// including without limitation the rights to use, copy, modify,
// merge, publish, distribute, sublicense, and/or sell copies of
// the Software,and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
// IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
// DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
// OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR
// THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import <UIKit/UIKit.h>

@protocol CDVNavigationBarDelegate <NSObject>
-(void)leftButtonTapped;
-(void)rightButtonTapped;
@end

@interface CDVNavigationBarController : UIViewController{

    IBOutlet UIBarButtonItem * leftButton;
    IBOutlet UIBarButtonItem * rightButton;
    IBOutlet UINavigationItem * navItem;
    id<CDVNavigationBarDelegate>  delegate;

}

@property (nonatomic, retain) UINavigationItem * navItem;
@property (nonatomic, retain) UIBarButtonItem * leftButton;
@property (nonatomic, retain) UIBarButtonItem * rightButton;
@property (nonatomic, retain) id<CDVNavigationBarDelegate>  delegate;

-(IBAction)leftButtonTapped:(id)sender;
-(IBAction)rightButtonTapped:(id)sender;

@end
