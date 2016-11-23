//
// NavigationBar.h
// Cordova Plugin
//
// Created by Lifetime.com.eg Technical Team (Amr Hossam / Emad ElShafie)
// on 6 January 2016.
//
// Original work Copyright (c) 2016 Lifetime.com.eg. All rights reserved.
// Modified work Copyright (c) 2016 Evothings AB.
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

#import "NavigationBar.h"
#import <UIKit/UITabBar.h>
#import <QuartzCore/QuartzCore.h>

// For older versions of Cordova, you may have to use: #import "CDVDebug.h"
//#import <Cordova/CDVDebug.h>

@implementation NavigationBar
#ifndef __IPHONE_3_0
@synthesize webView;
#endif
@synthesize navBarController, drawervisible, draweritems, draweritemscount;
@synthesize currentAppURL, appMainUIVisible, appUIPage;

- (void) pluginInitialize {

    [[NSNotificationCenter defaultCenter] addObserver:self  selector:@selector(orientationChanged:)    name:UIDeviceOrientationDidChangeNotification  object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pageDidLoad:) name:CDVPageDidLoadNotification object:self.webView];

    UIWebView* uiwebview = ((UIWebView*)self.webView);

	//uiwebview.autoresizingMask = 0;

    drawervisible = 0;

	currentAppURL = NULL;
	appMainUIVisible = YES;
	appUIPage = @"connect";

    // -----------------------------------------------------------------------
    // This code block is the same for both the navigation and tab bar plugin!
    // -----------------------------------------------------------------------

    // The original web view frame must be retrieved here. On iPhone, it would be 0,0,320,460 for example. Since
    // Cordova seems to initialize plugins on the first call, there is a plugin method init() that has to be called
    // in order to make Cordova call *this* method. If someone forgets the init() call and uses the navigation bar
    // and tab bar plugins together, these values won't be the original web view frame and layout will be wrong.
    originalWebViewFrame = uiwebview.frame;
    UIApplication *app = [UIApplication sharedApplication];
/*
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    switch (orientation)
    {
        case UIInterfaceOrientationPortrait:
        case UIInterfaceOrientationPortraitUpsideDown:
            break;
        case UIInterfaceOrientationLandscapeLeft:
        case UIInterfaceOrientationLandscapeRight:
        {
            float statusBarHeight = 0;
            if(!app.statusBarHidden)
                statusBarHeight = MIN(app.statusBarFrame.size.width, app.statusBarFrame.size.height);

            originalWebViewFrame = CGRectMake(originalWebViewFrame.origin.y,
                                              originalWebViewFrame.origin.x,
                                              originalWebViewFrame.size.height + statusBarHeight,
                                              originalWebViewFrame.size.width - statusBarHeight);
            break;
        }
        default:
            NSLog(@"Unknown orientation: %d", orientation);
            break;
    }
*/
    //if (isAtLeast8) navBarHeight = 44.0f;
    navBarHeight = 64.0f;
    tabBarHeight = 49.0f;
    // -----------------------------------------------------------------------
}

/**
 * From interface CDVPlugin.
 * Called when the WebView navigates or refreshes.
 */
- (void) onReset
{
	  NSLog(@"onReset");
    [self correctWebViewFrame];
}

/*
- (void)handleOpenURL:(NSNotification*)notification
{
    // override to handle urls sent to your app
    // register your url schemes in your App-Info.plist

    NSLog(@"@@@ handleOpenURL notification: %@", notification);

    NSURL* url = [notification object];

    if ([url isKindOfClass:[NSURL class]]) {
 		NSLog(@"@@@ handleOpenURL url: %@", url);
    }
}
*/

- (void)pageDidLoad:(NSNotification*)notification
{
    // override to handle urls sent to your app
    // register your url schemes in your App-Info.plist

    //NSLog(@"@@@ pageDidLoad notification: %@", notification);
	//NSLog(@"@@@ pageDidLoad object: %@", [notification object]);
	UIWebView* webView = [notification object];
	//NSLog(@"@@@ pageDidLoad URL: %@", webView.request.URL.absoluteString);
	//NSLog(@"@@@ pageDidLoad mainDocumentURL: %@", webView.request.mainDocumentURL.absoluteString);

	NSURL* url = webView.request.URL;

	// Is the main UI visible?
	appMainUIVisible = url.fileURL;

	// Save the app URL if loaded from a server.
	if (!url.fileURL)
	{
		currentAppURL = url;
	}
}

// Called from JS.
- (void)setupEvothingsViewerUI:(CDVInvokedUrlCommand*)command
{
  [navBarController navItem].title = @"Evothings Viewer";

	UIBarButtonItem *newButton = [self
								  makeButtonWithOptions:NULL
								  title:@"Menu"
								  imageName:NULL
								  actionOnSelf:@selector(DrawerTapped)];
	navBarController.navItem.leftBarButtonItem = newButton;
	navBarController.leftButton = newButton;

	[self
	 	setupDrawerWithItems: @[
								@[@"Connect",@"connect",@"", (id)[NSNull null]],
								@[@"Info",@"info",@"", (id)[NSNull null]],
								@[@"Settings",@"settings",@"", (id)[NSNull null]],
								@[@"Current App",@"currentapp",@"", (id)[NSNull null]]]
	 	buttonColor: NULL];

	[[navBarController navItem] setLeftBarButtonItem:[navBarController leftButton] animated:YES];

	[self showMainUI];
}

- (void)doDrawerCommand:(NSString*)commandName
{
	NSLog(@"@@@ doDrawerCommand: %@", commandName);

    // Alternative 1: Show external page.
	if ([commandName isEqualToString: @"currentapp"])
	{
		if (currentAppURL != NULL)
		{
	    appMainUIVisible = NO;
			[self showRemotePage: currentAppURL];
			return;
		}
	}

	if (!appMainUIVisible)
	{
      // Alternative 2: Load local page with Main UI.
	  appUIPage = commandName;
		[self showLocalPage: @"index"];	}
    else
    {
		// Alternative 3: Main UI loaded, show current page.
		appUIPage = commandName;

	  [self showMainUI];
	}
}

- (void) showMainUI
{
	appMainUIVisible = YES;

	if ([appUIPage isEqualToString: @"connect"])
	{
		[self callJS: @"app.showMain()"];
	}
	else if ([appUIPage isEqualToString: @"info"])
	{
		[self callJS: @"app.showInfo()"];
	}
	else if ([appUIPage isEqualToString: @"settings"])
	{
		[self callJS: @"app.showSettings()"];
	}
	else if ([appUIPage isEqualToString: @"currentapp"])
	{
		[self callJS: @"app.showNoApp()"];
	}
}

- (void) callJS: (NSString*)code
{
	UIWebView* uiwebview = ((UIWebView*)self.webView);
  	[uiwebview stringByEvaluatingJavaScriptFromString: code];
}

- (void) showLocalPage: (NSString*)pageName
{
	CDVViewController* viewController = (CDVViewController*) self.viewController;

	// Set URL to local start page.
	NSString* path = [[NSBundle mainBundle]
						  pathForResource: pageName
						  ofType: @"html"
						  inDirectory: viewController.wwwFolderName];
	NSURL* pageURL = [NSURL fileURLWithPath: path isDirectory: NO];


	// Load URL into web view.
	NSURLRequest* request = [NSURLRequest
								 requestWithURL: pageURL
								 cachePolicy: NSURLRequestUseProtocolCachePolicy
								 timeoutInterval: 20.0];
	[viewController.webViewEngine loadRequest: request];
}

- (void) showRemotePage: (NSURL*)url
{
	CDVViewController* viewController = (CDVViewController*) self.viewController;

	// Load URL into web view.
	NSURLRequest* request = [NSURLRequest
							 requestWithURL: url
							 cachePolicy: NSURLRequestUseProtocolCachePolicy
							 timeoutInterval: 20.0];
	[viewController.webViewEngine loadRequest: request];
}

// NOTE: Returned object is owned
-(UIBarButtonItem*)backgroundButtonFromImage:(NSString*)imageName title:(NSString*)title fixedMarginLeft:(float)fixedMarginLeft fixedMarginRight:(float)fixedMarginRight target:(id)target action:(SEL)action
{
    UIButton *backButton = [[UIButton alloc] init];
    UIImage *imgNormal = [UIImage imageNamed:imageName];

    // UIImage's resizableImageWithCapInsets method is only available from iOS 5.0. With earlier versions, the
    // stretchableImageWithLeftCapWidth is used which behaves a bit differently.
    if([imgNormal respondsToSelector:@selector(resizableImageWithCapInsets)])
        imgNormal = [imgNormal resizableImageWithCapInsets:UIEdgeInsetsMake(0, fixedMarginLeft, 0, fixedMarginRight)];
    else
        imgNormal = [imgNormal stretchableImageWithLeftCapWidth:MAX(fixedMarginLeft, fixedMarginRight) topCapHeight:0];

    [backButton setBackgroundImage:imgNormal forState:UIControlStateNormal];

    backButton.titleLabel.textColor = [UIColor whiteColor];
    backButton.titleLabel.font = [UIFont boldSystemFontOfSize:12.0f];
    backButton.titleLabel.textAlignment = UITextAlignmentCenter;

    CGSize textSize = [title sizeWithFont:backButton.titleLabel.font];

    float buttonWidth = MAX(imgNormal.size.width, textSize.width + fixedMarginLeft + fixedMarginRight);//imgNormal.size.width > (textSize.width + fixedMarginLeft + fixedMarginRight)
    //? imgNormal.size.width : (textSize.width + fixedMarginLeft + fixedMarginRight);
    backButton.frame = CGRectMake(0, 0, buttonWidth, imgNormal.size.height);

    CGFloat marginTopBottom = (backButton.frame.size.height - textSize.height) / 2;
    [backButton setTitleEdgeInsets:UIEdgeInsetsMake(marginTopBottom, fixedMarginLeft, marginTopBottom, fixedMarginRight)];

    [backButton setTitle:title forState:UIControlStateNormal];
    [backButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [backButton.titleLabel setFont:[UIFont boldSystemFontOfSize:12.0f]];

    UIBarButtonItem *backButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    [backButton addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];

    // imgNormal is autoreleased

    return backButtonItem;
}

-(void)correctWebViewFrame
{
    if(!navBar)
        return;

    const bool navBarShown = !navBar.hidden;

    // -----------------------------------------------------------------------------
    // IMPORTANT: Below code is the same in both the navigation and tab bar plugins!
    // -----------------------------------------------------------------------------

    CGRect screenBound = [[UIScreen mainScreen] bounds];
    CGSize screenSize = screenBound.size;

    CGFloat left = originalWebViewFrame.origin.x;
    CGFloat right = screenSize.width;
    CGFloat top = originalWebViewFrame.origin.y;
    CGFloat bottom = screenSize.height;
/*
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    switch (orientation)
    {
        case UIInterfaceOrientationPortrait:
        case UIInterfaceOrientationPortraitUpsideDown:
        // No need to change width/height from original frame
        break;
        case UIInterfaceOrientationLandscapeLeft:
        case UIInterfaceOrientationLandscapeRight:
        right = originalWebViewFrame.size.height;
        bottom = originalWebViewFrame.size.width;
        break;
        default:
        NSLog(@"Unknown orientation: %ld", (long)orientation);
        break;
    }
*/

    if(navBar.hidden == NO) {

        top += navBarHeight;
        NSLog(@"NAVBAR IS SHOWN");
    } else {
        top = 0;
        NSLog(@"NAVBAR IS HIDDEN");
    }

    CGRect webViewFrame = CGRectMake(left, top, right - left, bottom - top);
    [self.webView setFrame:webViewFrame];

    // -----------------------------------------------------------------------------

    // NOTE: Following part again for navigation bar plugin only

    if(navBar.hidden == NO)
    {
		//if(tabBarAtBottom)
            [navBar setFrame:CGRectMake(left, originalWebViewFrame.origin.y, right - left, navBarHeight)];
        //else
            //[navBar setFrame:CGRectMake(left, originalWebViewFrame.origin.y + tabBarHeight - 20.0f, right - left, navBarHeight)];
    }

    NSLog(@"CorrectView NavBar");
}

-(void) init:(CDVInvokedUrlCommand*)command
{
    // Dummy function, see initWithWebView
}

-(void) create:(CDVInvokedUrlCommand*)command
{
    NSLog(@"HRERE");
    if(navBar)
        return;

    navBarController = [[CDVNavigationBarController alloc] init];
    navBar = (UINavigationBar*)[navBarController view];

    navBar.barStyle = UIBarStyleBlackTranslucent;
    [navBar setTintColor:[UIColor whiteColor]];
    [navBar setBackgroundColor:[UIColor colorWithRed:218.0/255.0 green:33.0/255.0 blue:39.0/255.0 alpha:1.0]];
    //[navBar setBackgroundImage:[UIImage imageNamed:@"bg_new.png"] forBarMetrics:UIBarMetricsDefault];
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowColor = [UIColor colorWithRed:131.0/255.0 green:23.0/255.0 blue:78.0/255.0 alpha:1.0];
    shadow.shadowOffset = CGSizeMake(0, 2);
    shadow.shadowBlurRadius = 5;
    [navBar setTitleTextAttributes: [NSDictionary dictionaryWithObjectsAndKeys:
                                     [UIColor colorWithRed:245.0/255.0 green:245.0/255.0 blue:245.0/255.0 alpha:1.0], NSForegroundColorAttributeName,
                                     //shadow, NSShadowAttributeName,
                                     [UIFont fontWithName:@"Helvetica" size:18.0], NSFontAttributeName, nil]];

    [navBarController setDelegate:self];
    [[navBarController navItem] setLeftBarButtonItem:nil animated:NO];
    [[navBarController navItem] setRightBarButtonItem:nil animated:NO];
    [[navBarController view] setFrame:CGRectMake(0, 0, originalWebViewFrame.size.width, navBarHeight)];
    [[[self webView] superview] addSubview:[navBarController view]];
    [navBar setHidden:YES];

    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;

}

- (void)orientationChanged:(NSNotification *)notification{
	NSLog(@"orientationChanged");
    [self correctWebViewFrame];
}

///////////
// Title //
///////////

-(void) setTitle:(CDVInvokedUrlCommand*)command
{
    if(!navBar)
        return;

    NSLog(@"Set the title");
    NSString  *title = [command.arguments objectAtIndex:0];
    [navBarController navItem].title = title;

    // Reset otherwise overriding logo reference
    [navBarController navItem].titleView = NULL;
}

/////////////
// Buttons //
/////////////

- (void)hideLeftButton:(CDVInvokedUrlCommand*)command
{
    //NSLog(@"hereeee");
    //const NSDictionary *options = [command.arguments objectAtIndex:0];
    //bool animated = [[options objectForKey:@"animated"] boolValue];

    [[navBarController navItem] setLeftBarButtonItem:nil animated:YES];
}

- (void)hideRightButton:(CDVInvokedUrlCommand*)command
{
    //const NSDictionary *options = [command.arguments objectAtIndex:0];
    //bool animated = [[options objectForKey:@"animated"] boolValue];

    [[navBarController navItem] setRightBarButtonItem:nil animated:YES];
}

- (void)showLeftButton:(CDVInvokedUrlCommand*)command
{
    //const NSDictionary *options = [command.arguments objectAtIndex:0];
    //bool animated = [[options objectForKey:@"animated"] boolValue];

    [[navBarController navItem] setLeftBarButtonItem:[navBarController leftButton] animated:YES];
}

- (void)showRightButton:(CDVInvokedUrlCommand*)command
{
    //const NSDictionary *options = [command.arguments objectAtIndex:0];
    //bool animated = [[options objectForKey:@"animated"] boolValue];

    [[navBarController navItem] setRightBarButtonItem:[navBarController rightButton] animated:YES];
}

- (void)setupLeftButton:(CDVInvokedUrlCommand*)command
{
    NSLog(@"SetupLeftButton");

    NSString * title = [command argumentAtIndex:0];
    NSString * imageName = [command argumentAtIndex:1];
    NSDictionary *options = [command argumentAtIndex:2];

    UIBarButtonItem *newButton = [self makeButtonWithOptions:options title:title imageName:imageName actionOnSelf:@selector(leftButtonTapped)];
    navBarController.navItem.leftBarButtonItem = newButton;
    navBarController.leftButton = newButton;
}

-(void) leftButtonTapped
{
    UIWebView *uiwebview = nil;
    if ([self.webView isKindOfClass:[UIWebView class]]) {
        uiwebview = ((UIWebView*)self.webView);
    }

    NSString * jsCallBack = @"navbar.leftButtonTapped();";
    [uiwebview stringByEvaluatingJavaScriptFromString:jsCallBack];
}

- (void)setupRightButton:(CDVInvokedUrlCommand*)command
{

    NSLog(@"SetupLeftButton");

    NSString * title = [command argumentAtIndex:0];
    NSString * imageName = [command argumentAtIndex:1];
    NSDictionary *options = [command argumentAtIndex:2];

    UIBarButtonItem *newButton = [self makeButtonWithOptions:options title:title imageName:imageName actionOnSelf:@selector(rightButtonTapped)];
    navBarController.navItem.rightBarButtonItem = newButton;
    navBarController.rightButton = newButton;
}

-(void) rightButtonTapped
{
    UIWebView *uiwebview = nil;
    if ([self.webView isKindOfClass:[UIWebView class]]) {
        uiwebview = ((UIWebView*)self.webView);
    }
    NSString * jsCallBack = @"navbar.rightButtonTapped();";
    [uiwebview stringByEvaluatingJavaScriptFromString:jsCallBack];
}

// NOTE: Returned object is owned
- (UIBarButtonItem*)makeButtonWithOptions:(NSDictionary*)options title:(NSString*)title imageName:(NSString*)imageName actionOnSelf:(SEL)actionOnSelf
{
    NSNumber *useImageAsBackgroundOpt = [options objectForKey:@"useImageAsBackground"];
    float fixedMarginLeft = [[options objectForKey:@"fixedMarginLeft"] floatValue] ?: 13;
    float fixedMarginRight = [[options objectForKey:@"fixedMarginRight"] floatValue] ?: 13;
    bool useImageAsBackground = useImageAsBackgroundOpt ? [useImageAsBackgroundOpt boolValue] : false;

    if((title && [title length] > 0) || useImageAsBackground)
    {
        if(useImageAsBackground && imageName && [imageName length] > 0)
        {
            return [self backgroundButtonFromImage:imageName title:title
                                   fixedMarginLeft:fixedMarginLeft fixedMarginRight:fixedMarginRight
                                            target:self action:actionOnSelf];
        }
        else
        {
            // New Changes
            if ((![title  isEqual: @"Back"])) {

                return [[UIBarButtonItem alloc] initWithTitle:title style:UIBarButtonItemStylePlain target:self action:actionOnSelf ];


            } else {

                NSDictionary *attrs = @{ NSFontAttributeName : [UIFont systemFontOfSize:9] };

                UIButton *backButton = [[UIButton alloc] initWithFrame: CGRectMake(0, 0, 15.0f, 20.0f)];
                UIImage *backImage = [UIImage imageNamed:@"back2.png"];
                [backButton setBackgroundImage:backImage forState:UIControlStateNormal];
                //[backButton setTitle:@"Back" forState:UIControlStateNormal];
                [backButton setContentMode:UIViewContentModeScaleAspectFit];
                //[backButton setBackgroundColor:[UIColor blackColor]];
                [navBar addSubview:backButton];

                [backButton addTarget:self action:actionOnSelf forControlEvents:UIControlEventTouchUpInside];
                UIBarButtonItem *thenewbutton = [[UIBarButtonItem alloc] initWithCustomView:backButton];
                [thenewbutton setTitleTextAttributes:attrs forState:UIControlStateNormal];
                return thenewbutton;

                //return [[UIBarButtonItem alloc] initWithTitle:title style:UIBarButtonItemStylePlain target:self action:actionOnSelf ];
            }
            //
        }
    }
    else if (imageName && [imageName length] > 0)
    {
        UIBarButtonSystemItem systemItem = [NavigationBar getUIBarButtonSystemItemForString:imageName];

        if(systemItem != -1)
            return [[UIBarButtonItem alloc] initWithBarButtonSystemItem:systemItem target:self action:actionOnSelf];
        else
            return [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:imageName] style:UIBarButtonItemStylePlain target:self action:actionOnSelf];
    }
    else
    {
        // Fail silently
        NSLog(@"Invalid setup{Left/Right}Button parameters\n");
        return nil;
    }
}
///////////////////////////////
// Rest of useless functions //
///////////////////////////////

+ (UIBarButtonSystemItem)getUIBarButtonSystemItemForString:(NSString*)imageName
{
    UIBarButtonSystemItem systemItem = -1;

    if([imageName isEqualToString:@"barButton:Action"])        systemItem = UIBarButtonSystemItemAction;
    else if([imageName isEqualToString:@"barButton:Add"])           systemItem = UIBarButtonSystemItemAdd;
    else if([imageName isEqualToString:@"barButton:Bookmarks"])     systemItem = UIBarButtonSystemItemBookmarks;
    else if([imageName isEqualToString:@"barButton:Camera"])        systemItem = UIBarButtonSystemItemCamera;
    else if([imageName isEqualToString:@"barButton:Cancel"])        systemItem = UIBarButtonSystemItemCancel;
    else if([imageName isEqualToString:@"barButton:Compose"])       systemItem = UIBarButtonSystemItemCompose;
    else if([imageName isEqualToString:@"barButton:Done"])          systemItem = UIBarButtonSystemItemDone;
    else if([imageName isEqualToString:@"barButton:Edit"])          systemItem = UIBarButtonSystemItemEdit;
    else if([imageName isEqualToString:@"barButton:FastForward"])   systemItem = UIBarButtonSystemItemFastForward;
    else if([imageName isEqualToString:@"barButton:FixedSpace"])    systemItem = UIBarButtonSystemItemFixedSpace;
    else if([imageName isEqualToString:@"barButton:FlexibleSpace"]) systemItem = UIBarButtonSystemItemFlexibleSpace;
    else if([imageName isEqualToString:@"barButton:Organize"])      systemItem = UIBarButtonSystemItemOrganize;
    else if([imageName isEqualToString:@"barButton:PageCurl"])      systemItem = UIBarButtonSystemItemPageCurl;
    else if([imageName isEqualToString:@"barButton:Pause"])         systemItem = UIBarButtonSystemItemPause;
    else if([imageName isEqualToString:@"barButton:Play"])          systemItem = UIBarButtonSystemItemPlay;
    else if([imageName isEqualToString:@"barButton:Redo"])          systemItem = UIBarButtonSystemItemRedo;
    else if([imageName isEqualToString:@"barButton:Refresh"])       systemItem = UIBarButtonSystemItemRefresh;
    else if([imageName isEqualToString:@"barButton:Reply"])         systemItem = UIBarButtonSystemItemReply;
    else if([imageName isEqualToString:@"barButton:Rewind"])        systemItem = UIBarButtonSystemItemRewind;
    else if([imageName isEqualToString:@"barButton:Save"])          systemItem = UIBarButtonSystemItemSave;
    else if([imageName isEqualToString:@"barButton:Search"])        systemItem = UIBarButtonSystemItemSearch;
    else if([imageName isEqualToString:@"barButton:Stop"])          systemItem = UIBarButtonSystemItemStop;
    else if([imageName isEqualToString:@"barButton:Trash"])         systemItem = UIBarButtonSystemItemTrash;
    else if([imageName isEqualToString:@"barButton:Undo"])          systemItem = UIBarButtonSystemItemUndo;

    return systemItem;
}

- (void)setLeftButtonEnabled:(CDVInvokedUrlCommand*)command
{
    if(navBarController.navItem.leftBarButtonItem)
    {
        id enabled = [command.arguments objectAtIndex:0];
        navBarController.navItem.leftBarButtonItem.enabled = [enabled boolValue];
    }
}

- (void)setLeftButtonTint:(CDVInvokedUrlCommand*)command
{
    if(!navBarController.navItem.leftBarButtonItem)
        return;

    if(![navBarController.navItem.leftBarButtonItem respondsToSelector:@selector(setTintColor:)])
    {
        NSLog(@"setLeftButtonTint unsupported < iOS 5");
        return;
    }

    id tint = [command.arguments objectAtIndex:0];
    NSArray *rgba = [tint componentsSeparatedByString:@","];
    UIColor *tintColor = [UIColor colorWithRed:[[rgba objectAtIndex:0] intValue]/255.0f
                                         green:[[rgba objectAtIndex:1] intValue]/255.0f
                                          blue:[[rgba objectAtIndex:2] intValue]/255.0f
                                         alpha:[[rgba objectAtIndex:3] intValue]/255.0f];
    navBarController.navItem.leftBarButtonItem.tintColor = tintColor;
}

- (void)setLeftButtonTitle:(CDVInvokedUrlCommand*)command
{
    NSString *title = [command.arguments objectAtIndex:0];
    if(navBarController.navItem.leftBarButtonItem)
        navBarController.navItem.leftBarButtonItem.title = title;
}

- (void)setRightButtonEnabled:(CDVInvokedUrlCommand*)command
{
    if(navBarController.navItem.rightBarButtonItem)
    {
        id enabled = [command.arguments objectAtIndex:0];
        navBarController.navItem.rightBarButtonItem.enabled = [enabled boolValue];
    }
}

- (void)setRightButtonTint:(CDVInvokedUrlCommand*)command
{
    if(!navBarController.navItem.rightBarButtonItem)
        return;

    if(![navBarController.navItem.rightBarButtonItem respondsToSelector:@selector(setTintColor:)])
    {
        NSLog(@"setRightButtonTint unsupported < iOS 5");
        return;
    }

    id tint = [command.arguments objectAtIndex:0];
    NSArray *rgba = [tint componentsSeparatedByString:@","];
    UIColor *tintColor = [UIColor colorWithRed:[[rgba objectAtIndex:0] intValue]/255.0f
                                         green:[[rgba objectAtIndex:1] intValue]/255.0f
                                          blue:[[rgba objectAtIndex:2] intValue]/255.0f
                                         alpha:[[rgba objectAtIndex:3] intValue]/255.0f];
    navBarController.navItem.rightBarButtonItem.tintColor = tintColor;
}

- (void)setRightButtonTitle:(CDVInvokedUrlCommand*)command
{
    NSString *title = [command.arguments objectAtIndex:0];
    if(navBarController.navItem.rightBarButtonItem)
        navBarController.navItem.rightBarButtonItem.title = title;
}

-(void) show:(CDVInvokedUrlCommand*)command
{
    NSLog(@"Showing NabBar");
    if (!navBar)
        [self create:nil];

    if ([navBar isHidden])
    {
        [navBar setHidden:NO];
        [self correctWebViewFrame];
    }
}

-(void) hide:(CDVInvokedUrlCommand*)command
{
    if (navBar && ![navBar isHidden])
    {
        [navBar setHidden:YES];
        [self correctWebViewFrame];
    }
}

/**
 * Resize the navigation bar (this should be called on orientation change)
 * This is important in playing together with the tab bar plugin, especially because the tab bar can be placed on top
 * or at the bottom, so the navigation bar bounds also need to be changed.
 */
- (void)resize:(CDVInvokedUrlCommand*)command
{
	NSLog(@"resize");
    [self correctWebViewFrame];
}

-(void) setLogo:(CDVInvokedUrlCommand*)command
{
    NSString *logoURL = [command.arguments objectAtIndex:0];
    UIImage *image = nil;

    if (logoURL && ![logoURL  isEqual: @""])
    {
        if ([logoURL hasPrefix:@"http://"] || [logoURL hasPrefix:@"https://"])
        {
            NSData * data = [NSData dataWithContentsOfURL:[NSURL URLWithString:logoURL]];
            image = [UIImage imageWithData:data];
        }
        else
            image = [UIImage imageNamed:logoURL];

        if (image)
        {
            UIImageView * view = [[UIImageView alloc] initWithImage:image];
            [view setContentMode:UIViewContentModeScaleAspectFit];
            [view setBounds: CGRectMake(0, 0, 100, 30)];
            [[navBarController navItem] setTitleView:view];
        }
    }
}


// New Update for Drawer

-(void) setupDrawer:(CDVInvokedUrlCommand *)command
{
	NSArray* items = [command.arguments objectAtIndex:0];
	NSString *buttoncolor = [command.arguments objectAtIndex:1];
	[self setupDrawerWithItems: items buttonColor: buttoncolor];
}

-(void) setupDrawerWithItems: (NSArray*)items buttonColor: (NSString*)buttoncolor
{
    CGRect webViewBounds = self.webView.bounds;
	draweritems = items;
    draweritemscount = (int) draweritems.count;

    if (!drawerview) drawerview = [[UIView alloc] initWithFrame:CGRectMake(-240, 64, 240, webViewBounds.size.height)];
    NSLog(@"Drawer Ready");
    drawerview.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5f];

// Evothings modificaton: Don't use drawer button. Use left button instead.
/*
    Drawing the button of drawer
    UIButton *drawerButton = [[UIButton alloc] initWithFrame: CGRectMake(0, 0, 24.0f, 18.0f)];
	UIImage *backImage = [UIImage imageNamed:@"drawer.png"];
    [drawerButton setBackgroundImage:backImage forState:UIControlStateNormal];
    [drawerButton setContentMode:UIViewContentModeScaleAspectFit];
    [navBar addSubview:drawerButton];

    UIView *overlay = [[UIView alloc] initWithFrame:[drawerButton frame]];
    UIImageView *maskImageView = [[UIImageView alloc] initWithImage:backImage];
    [maskImageView setFrame:[overlay bounds]];
    [[overlay layer] setMask:[maskImageView layer]];

    if (buttoncolor == (id)[NSNull null] || buttoncolor.length == 0 ) {

        [overlay setBackgroundColor:[UIColor blackColor]];

    } else {

        UIColor *buttoncolorHEX = [self getUIColorObjectFromHexString:buttoncolor alpha:1];
        [overlay setBackgroundColor:buttoncolorHEX];

    }


    [drawerButton addSubview:overlay];
    overlay.userInteractionEnabled = NO;

    [drawerButton addTarget:self action:@selector(DrawerTapped) forControlEvents:UIControlEventTouchUpInside];

    UIBarButtonItem *thenewbutton = [[UIBarButtonItem alloc] initWithCustomView:drawerButton];

    navBarController.navItem.leftBarButtonItem = thenewbutton;
    navBarController.leftButton = thenewbutton;
*/
    if (!_tableView) {

        _tableView = [[UITableView alloc] initWithFrame:drawerview.bounds style:UITableViewStylePlain];
        [self.tableView setDelegate:self];
        [self.tableView setDataSource:self];
        [self.tableView setOpaque:NO];
        [self.tableView setBackgroundColor:[UIColor clearColor]];
        self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 320.0f, 0.0f)];
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        [self.tableView setSeparatorColor:[UIColor whiteColor]];
        [drawerview addSubview:self.tableView];

    } else [self.tableView reloadData];
    [ [ [ self viewController ] view ] addSubview:drawerview];
}

-(void) DrawerTapped
{

    if (drawervisible == 0) {

        [self showDrawer];

    } else {
        [self hideDrawer];
    }

}

-(void) showDrawer
{
    drawervisible = 1;
    [UIView animateWithDuration:0.3f animations:^{
        drawerview.frame = CGRectOffset(drawerview.frame, 240, 0);
    }];

    UIWebView *uiwebview = nil;
    if ([self.webView isKindOfClass:[UIWebView class]]) {
        uiwebview = ((UIWebView*)self.webView);
    }

    uiwebview.userInteractionEnabled = NO;

}

-(void) hideDrawer
{
    drawervisible = 0;
    [UIView animateWithDuration:0.3f animations:^{
        drawerview.frame = CGRectOffset(drawerview.frame, -240, 0);
    }];

    UIWebView *uiwebview = nil;
    if ([self.webView isKindOfClass:[UIWebView class]]) {
        uiwebview = ((UIWebView*)self.webView);
    }

    uiwebview.userInteractionEnabled = YES;

}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (draweritemscount > 0) return draweritemscount;
    else return 0;

}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";

    UITableViewCell *cell = (UITableViewCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    if (cell == nil) {

        cell = [[NavigationBarTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        [cell setSelectionStyle:UITableViewCellSelectionStyleBlue];

    }

    for (int i = 0; i < [draweritems count]; i++)
    {
        if(indexPath.row == i) {

            NSArray *currentitem = [draweritems objectAtIndex: i];
            NSString *itemtitle = [currentitem objectAtIndex:0];
            NSString *itemlogo = [currentitem objectAtIndex:2];
            NSString *itembadge = [currentitem objectAtIndex:3];

            [cell.textLabel setText:itemtitle];

            // Adding item image
            if (itemlogo == (id)[NSNull null] || itemlogo.length == 0 ) {

                cell.imageView.image = nil;

            } else {

                cell.imageView.image = [UIImage imageNamed:itemlogo];

            }

            // Adding item badge
            if (itembadge == (id)[NSNull null] || itembadge.length == 0 ) {

                [cell setAccessoryType:UITableViewCellAccessoryNone];

            } else {

                UILabel *accesoryBadge = [[UILabel alloc] init];
                NSString *string = itembadge;
                accesoryBadge.text = string;
                accesoryBadge.textColor = [UIColor whiteColor];
                accesoryBadge.textAlignment = NSTextAlignmentCenter;
                accesoryBadge.layer.cornerRadius = 2;
                //accesoryBadge.backgroundColor = [UIColor redColor];
                accesoryBadge.clipsToBounds = true;
                [accesoryBadge setFont:[UIFont fontWithName:@"Helvetica" size:10.0]];

                accesoryBadge.frame = CGRectMake(0, 0, 50, 20);
                [accesoryBadge sizeToFit];
                cell.accessoryView = accesoryBadge;

            }

        }
    }

    return cell;
}

-(NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    return @"";
}

-(UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{

    return nil;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 0.0;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 55.0;
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    return 0.0;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

    UIWebView *uiwebview = nil;
    if ([self.webView isKindOfClass:[UIWebView class]]) {
        uiwebview = ((UIWebView*)self.webView);
    }

    for (int i = 0; i < [draweritems count]; i++)
    {
        if(indexPath.row == i) {

            NSArray *currentitem = [draweritems objectAtIndex: i];
            NSString *itemurl = [currentitem objectAtIndex:1];

			// Evothings modification. We cannot use JS code for this, since it is controlled
			// by the user's application.

			// Call a function natively to show different pages of the app.
			[self doDrawerCommand: itemurl];

			// Original code.
            //NSString * jsCallBack = [NSString stringWithFormat:@"window.location.href='%@'", itemurl];
            //[uiwebview stringByEvaluatingJavaScriptFromString:jsCallBack];

            [self hideDrawer];
        }
    }

    [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (UIColor *)getUIColorObjectFromHexString:(NSString *)hexStr alpha:(CGFloat)alpha
{
    // Convert hex string to an integer
    unsigned int hexint = [self intFromHexString:hexStr];

    // Create color object, specifying alpha as well
    UIColor *color =
    [UIColor colorWithRed:((CGFloat) ((hexint & 0xFF0000) >> 16))/255
                    green:((CGFloat) ((hexint & 0xFF00) >> 8))/255
                     blue:((CGFloat) (hexint & 0xFF))/255
                    alpha:alpha];

    return color;
}

- (unsigned int)intFromHexString:(NSString *)hexStr
{
    unsigned int hexInt = 0;

    // Create scanner
    NSScanner *scanner = [NSScanner scannerWithString:hexStr];

    // Tell scanner to skip the # character
    [scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@"#"]];

    // Scan hex value
    [scanner scanHexInt:&hexInt];

    return hexInt;
}

@end
