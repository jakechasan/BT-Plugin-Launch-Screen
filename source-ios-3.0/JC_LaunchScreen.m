/*
 *	Copyright 2013, Jake Chasan, jakechasan.com
 *
 *	All rights reserved.
 *
 *	Redistribution and use in source and binary forms, with or without modification, are
 *	permitted provided that the following conditions are met:
 *
 *	Redistributions of source code must retain the above copyright notice which includes the
 *	name(s) of the copyright holders. It must also retain this list of conditions and the
 *	following disclaimer.
 *
 *	Redistributions in binary form must reproduce the above copyright notice, this list
 *	of conditions and the following disclaimer in the documentation and/or other materials
 *	provided with the distribution.
 *
 *	Neither the name of Jake Chasan, jakechasan.com nor the names of its contributors
 *	may be used to endorse or promote products derived from this software without specific
 *	prior written permission.
 *
 *	Some methods copyright David Book.
 *
 *	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 *	ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 *	WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 *	IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 *	INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 *	NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *	PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 *	WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 *	ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY
 *	OF SUCH DAMAGE.
 */

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "JSON.h"
#import "BT_application.h"
#import "BT_strings.h"
#import "BT_viewUtilities.h"
#import "BT_appDelegate.h"
#import "BT_item.h"
#import "BT_debugger.h"
#import "BT_fileManager.h"
#import "BT_color.h"
#import "BT_downloader.h"
#import "JC_LaunchScreen.h"

@implementation JC_LaunchScreen

//viewDidLoad
-(void)viewDidLoad
{
	[BT_debugger showIt:self theMessage:@"viewDidLoad"];
	[super viewDidLoad];
    
    int loadScreenBoolean = [[BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:@"launchScreen" defaultValue:@"0"] intValue];
    
    if(loadScreenBoolean==1)
    {
        bool waitForDate = true;

        //Check the Date - false does not show screen, true does show screen
        if([[BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:@"launchWaitForDate" defaultValue:@"0"] intValue] != 0)
        {
            waitForDate = [self shouldLaunchScreen];
        }
        
        if(waitForDate==true)
        {
            //Load Screen
            double launchScreenDelay = [[BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:@"launchScreenDelay" defaultValue:@"0.1"] doubleValue];
            if(launchScreenDelay<0.1)
            {
                launchScreenDelay = 0.1;
            }
            
            //For iOS Version Setting
            double iOSVersion = [[[UIDevice currentDevice] systemVersion] doubleValue];
            double iOSVersionSpecified = [[BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:@"iOSVersionLoad" defaultValue:@"0"] doubleValue];
            
            if(iOSVersionSpecified==0)
            {
                iOSVersionSpecified = iOSVersion;
            }
            
            [BT_debugger showIt:self theMessage:[NSString stringWithFormat:@"Device iOS Version: %g", iOSVersion]];
            [BT_debugger showIt:self theMessage:[NSString stringWithFormat:@"JSON iOS Version: %g", iOSVersionSpecified]];
            
            if(iOSVersion<iOSVersionSpecified)
            {
                [BT_debugger showIt:self theMessage:@"Initializing Load with iOS Version Settings"];
                [self performSelector:(@selector(launchScreeniOSVersion)) withObject:nil afterDelay:launchScreenDelay];
            }
            else
            {
                [BT_debugger showIt:self theMessage:@"Initializing Load with Normal Settings"];
                [self performSelector:(@selector(launchScreenNormal)) withObject:nil afterDelay:launchScreenDelay];
            }
        }
    }
    else
    {
        //Do nothing, no screen should load
    }
}

//view will appear
-(void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[BT_debugger showIt:self theMessage:@"viewWillAppear"];
    
    //flag this as the current screen
	BT_appDelegate *appDelegate = (BT_appDelegate *)[[UIApplication sharedApplication] delegate];
	appDelegate.rootApp.currentScreenData = self.screenData;
}

-(void)viewDidAppear:(BOOL)animated
{
    [self.navigationController popViewControllerAnimated:NO];
}

-(NSUInteger)dateParser:(NSString *)date
{
    //Date Format must be 11-22-33
    int dateNumber = 0;
    @try {
        int i;
        for(i=0; i<date.length; i++)
        {
            char c = [date characterAtIndex:(i)];
            NSString *intFromString = [NSString stringWithFormat:@"%c", c];
            if(c != '-')
            {
                dateNumber += [intFromString intValue];
                [BT_debugger showIt:self theMessage:[NSString stringWithFormat:@"Character: %c", c]];
                [BT_debugger showIt:self theMessage:[NSString stringWithFormat:@"dateNumber: %d", dateNumber]];
            }
        }
        [BT_debugger showIt:self theMessage:[NSString stringWithFormat:@"Number: %d", dateNumber]];
        return dateNumber;
    }
    @catch (NSException *exception) {
        [BT_debugger showIt:self theMessage:@"Problem Parsing the Date"];
        //Date Should Never be Negative
        return false;
    }
    @finally {
    }
}

-(BOOL)shouldLaunchScreen
{
    
    NSDate *dateNow = [[NSDate alloc] init];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
    [dateFormatter setDateFormat:@"MM-dd-yy"];
    NSString *dateString = [dateFormatter stringFromDate:dateNow];
    [BT_debugger showIt:self theMessage:[NSString stringWithFormat:@"Formatted dateNow: %@", dateString]];
    int dateNowNumber = (int)[self performSelector:@selector(dateParser:) withObject:dateString];

    NSString *dateSetString = [BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:@"launchDateSet" defaultValue:@""];
    if(dateSetString.length==0)
    {
        [self showAlert:@"Configuration Error" theMessage:@"Please check your date settings" alertTag:0];
        return false;
    }
    int dateSetNumber = (int)[self performSelector:@selector(dateParser:) withObject:dateSetString];
    
    if(dateNowNumber>=dateSetNumber)
    {
        //The Date has passed
        return true;
    }
    else if(dateNowNumber<dateSetNumber)
    {
        //The Date has not passed
        NSString *alertTitle = [BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:@"launchDateAlertTitle" defaultValue:@"Check Back Later"];
        NSString *alertMessage = [BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:@"launchDateAlertMessage" defaultValue:@"This screen will be availible soon."];
        [self showAlert:alertTitle theMessage:alertMessage alertTag:0];
        return false;
    }
    else
    {
        //We should not be here, this default case should not occur
        return false;
    }
}

-(void)launchScreenNormal
{
    [BT_debugger showIt:self theMessage:@"Initiating Launch with Normal Settings"];
    
    //appDelegate
    BT_appDelegate *appDelegate = (BT_appDelegate *)[[UIApplication sharedApplication] delegate];
    
    NSString *loadScreenItemId = @"";
    NSString *loadScreenNickname = @"";
    NSString *transitionType = @"";
    
    //Normal Load, iOS Version Settings were not used
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
        CGSize result = [[UIScreen mainScreen] bounds].size;
        if(result.height == 480)
        {
            // iPhone 3.5 Inch
            //get possible itemId of the screen to load
            loadScreenItemId = [BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:@"iPhone35LoadScreenID" defaultValue:@""];
            
            //get possible nickname of the screen to load
            loadScreenNickname = [BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:@"iPhone35LoadScreenNickname" defaultValue:@""];
            
            //get possible transition type for screen to load
            transitionType = [BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:@"iPhone35LoadScreenTransitionType" defaultValue:@""];
            
            [BT_debugger showIt:self theMessage:@"iPhone 3.5 inch Loaded"];
        }
        if(result.height == 568)
        {
            // iPhone 4 Inch
            //get possible itemId of the screen to load
            loadScreenItemId = [BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:@"iPhone40LoadScreenID" defaultValue:@""];
            
            //get possible nickname of the screen to load
            loadScreenNickname = [BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:@"iPhone40LoadScreenNickname" defaultValue:@""];
            
            //get possible transition type for screen to load
            transitionType = [BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:@"iPhone40LoadScreenTransitionType" defaultValue:@""];
            
            if([loadScreenItemId isEqualToString:@""] || [loadScreenNickname isEqualToString:@""])
            {
                [BT_debugger showIt:self theMessage:@"No data provided for iPhone 4.0 inch, using iPhone 3.5 inch data."];
                // iPhone 3.5 Inch Data Loads
                //get possible itemId of the screen to load
                loadScreenItemId = [BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:@"iPhone35LoadScreenID" defaultValue:@""];
                
                //get possible nickname of the screen to load
                loadScreenNickname = [BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:@"iPhone35LoadScreenNickname" defaultValue:@""];
                
                //get possible transition type for screen to load
                transitionType = [BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:@"iPhone35LoadScreenTransitionType" defaultValue:@""];
            }
            [BT_debugger showIt:self theMessage:@"iPhone 4.0 inch Loaded"];
            
        }
    }
    else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        // iPad
        //get possible itemId of the screen to load
        loadScreenItemId = [BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:@"iPadLoadScreenID" defaultValue:@""];
        
        //get possible nickname of the screen to load
        loadScreenNickname = [BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:@"iPadLoadScreenNickname" defaultValue:@""];
        
        //get possible transition type for screen to load
        transitionType = [BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:@"iPadLoadScreenTransitionType" defaultValue:@""];
        
        [BT_debugger showIt:self theMessage:@"iPad Loaded"];
    }
    else
    {
        [BT_debugger showIt:self theMessage:@"Could Not Determine Screen Size"];
        [self showAlert:@"Could Not Determine Size" theMessage:@"Please check your iPhone or iPad." alertTag:0];
    }
    
    //possible screen to load...
    BT_item *screenObjectToLoad = nil;
    
    //bail if load screen = "none"
    if([loadScreenItemId isEqualToString:@"none"]){
        return;
    }
    
    //did we find a load screen itemId?
    if([loadScreenItemId length] > 1){
        screenObjectToLoad = [appDelegate.rootApp getScreenDataByItemId:loadScreenItemId];
    }else{
        if([loadScreenNickname length] > 1){
            screenObjectToLoad = [appDelegate.rootApp getScreenDataByNickname:loadScreenNickname];
        }else{
        }
    }
    
    //load next screen if it's not nil
    if(screenObjectToLoad != nil){
        
        //build a temp menu-item to pass to screen load method. We need this because the transition type is in the menu-item
        BT_item *tmpMenuItem = [[BT_item alloc] init];
        
        //build an NSDictionary of values for the jsonVars for the menu item...
        NSDictionary *tmpDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                       @"unused", @"itemId",
                                       transitionType, @"transitionType",
                                       nil];
        
        [tmpMenuItem setJsonVars:tmpDictionary];
        [tmpMenuItem setItemId:@"0"];
        
        //load the next screen
        
        /* NOTE
         
         We cannot use the parent classes handleTapToLoadScreen method because this view controller no longer
         has a navigation controller. self.navigationController is NIL here because we've already popped this
         view off the stack. We popped this view controller off the stack as soon as it appeared.
         
         This means that instead of using the built in handleTapToLoadScreen method we need to create our
         own method that find the app's navigation controller and asks it to push the next view.
         
         This all means that instead of calling handleTapToLoadScreen (which exists in the parent class)
         we are doing self.handleButtonTap. This "handleButtonTap" method exists in this file.
         
         */
        
        //handle button tap...
        [self handleButtonTap:screenObjectToLoad theMenuItemData:tmpMenuItem];
    }
    
    //should not ever get here unless a button didn't have a load screen...
    return;
}

-(void)launchScreeniOSVersion
{
    [BT_debugger showIt:self theMessage:@"Initiating Launch with iOS Version Settings"];
    
    //appDelegate
    BT_appDelegate *appDelegate = (BT_appDelegate *)[[UIApplication sharedApplication] delegate];
    
    NSString *loadScreenItemId = @"";
    NSString *loadScreenNickname = @"";
    NSString *transitionType = @"";
    
    //iOS Version Settings were used
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
        CGSize result = [[UIScreen mainScreen] bounds].size;
        if(result.height == 480)
        {
            // iPhone 3.5 Inch
            //get possible itemId of the screen to load
            loadScreenItemId = [BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:@"iPhone35LoadScreenIDiOSVersion" defaultValue:@""];
            
            //get possible nickname of the screen to load
            loadScreenNickname = [BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:@"iPhone35LoadScreenNicknameiOSVersion" defaultValue:@""];
            
            //get possible transition type for screen to load
            transitionType = [BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:@"iPhone35LoadScreenTransitionTypeiOSVersion" defaultValue:@""];
            
            [BT_debugger showIt:self theMessage:@"iPhone 3.5 inch Loaded"];
        }
        if(result.height == 568)
        {
            // iPhone 4 Inch
            //get possible itemId of the screen to load
            loadScreenItemId = [BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:@"iPhone40LoadScreenIDiOSVersion" defaultValue:@""];
            
            //get possible nickname of the screen to load
            loadScreenNickname = [BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:@"iPhone40LoadScreenNicknameiOSVersion" defaultValue:@""];
            
            //get possible transition type for screen to load
            transitionType = [BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:@"iPhone40LoadScreenTransitionTypeiOSVersion" defaultValue:@""];
            
            if([loadScreenItemId isEqualToString:@""] || [loadScreenNickname isEqualToString:@""])
            {
                [BT_debugger showIt:self theMessage:@"No data provided for iPhone 4.0 inch, using iPhone 3.5 inch data."];
                // iPhone 3.5 Inch Data Loads
                //get possible itemId of the screen to load
                loadScreenItemId = [BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:@"iPhone35LoadScreenIDiOSVersion" defaultValue:@""];
                
                //get possible nickname of the screen to load
                loadScreenNickname = [BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:@"iPhone35LoadScreenNicknameiOSVersion" defaultValue:@""];
                
                //get possible transition type for screen to load
                transitionType = [BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:@"iPhone35LoadScreenTransitionTypeiOSVersion" defaultValue:@""];
            }
            [BT_debugger showIt:self theMessage:@"iPhone 4.0 inch Loaded"];
        }
    }
    else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        // iPad
        //get possible itemId of the screen to load
        loadScreenItemId = [BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:@"iPadLoadScreenID" defaultValue:@""];
        
        //get possible nickname of the screen to load
        loadScreenNickname = [BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:@"iPadLoadScreenNickname" defaultValue:@""];
        
        //get possible transition type for screen to load
        transitionType = [BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:@"iPadLoadScreenTransitionType" defaultValue:@""];
        
        [BT_debugger showIt:self theMessage:@"iPad Loaded"];
    }
    else
    {
        [BT_debugger showIt:self theMessage:@"Could Not Determine Screen Size"];
        [self showAlert:@"Could Not Determine Size" theMessage:@"Please check your iPhone or iPad." alertTag:0];
    }
    
    //possible screen to load...
    BT_item *screenObjectToLoad = nil;
    
    //bail if load screen = "none"
    if([loadScreenItemId isEqualToString:@"none"]){
        return;
    }
    
    //did we find a load screen itemId?
    if([loadScreenItemId length] > 1){
        screenObjectToLoad = [appDelegate.rootApp getScreenDataByItemId:loadScreenItemId];
    }else{
        if([loadScreenNickname length] > 1){
            screenObjectToLoad = [appDelegate.rootApp getScreenDataByNickname:loadScreenNickname];
        }else{
        }
    }
    
    //load next screen if it's not nil
    if(screenObjectToLoad != nil){
        
        //build a temp menu-item to pass to screen load method. We need this because the transition type is in the menu-item
        BT_item *tmpMenuItem = [[BT_item alloc] init];
        
        //build an NSDictionary of values for the jsonVars for the menu item...
        NSDictionary *tmpDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                       @"unused", @"itemId",
                                       transitionType, @"transitionType",
                                       nil];
        
        [tmpMenuItem setJsonVars:tmpDictionary];
        [tmpMenuItem setItemId:@"0"];
        
        
        /* NOTE
         
         We cannot use the parent classes handleTapToLoadScreen method because this view controller no longer
         has a navigation controller. self.navigationController is NIL here because we've already popped this
         view off the stack. We popped this view controller off the stack as soon as it appeared.
         
         This means that instead of using the built in handleTapToLoadScreen method we need to create our
         own method that find the app's navigation controller and asks it to push the next view.
         
         This all means that instead of calling handleTapToLoadScreen (which exists in the parent class)
         we are doing self.handleButtonTap. This "handleButtonTap" method exists in this file.
         
         */
        
        //handle button tap...
        [self handleButtonTap:screenObjectToLoad theMenuItemData:tmpMenuItem];
        
        
    }
    
    //should not ever get here unless a button didn't have a load screen...
    return;
}

//handleButtonTap...
-(void)handleButtonTap:(BT_item *)theScreenData theMenuItemData:(BT_item *)theMenuItemData{
	[BT_debugger showIt:self message:[NSString stringWithFormat:@"handleButtonTap (super) loading nickname: \"%@\" itemId: %@ itemType: %@", [theScreenData itemNickname], [theScreenData itemId], [theScreenData itemType]]];
	
	//if the loadScreenItemId == "none".....
	if([[BT_strings getJsonPropertyValue:theMenuItemData.jsonVars nameOfProperty:@"loadScreenWithItemId" defaultValue:@""] isEqualToString:@"none"]){
		return;
	}
	
	//find the nav controller
	BT_appDelegate *appDelegate = (BT_appDelegate *)[[UIApplication sharedApplication] delegate];
	
    
	//if the screen we are loading requires a login, we can't continue unless the user is logged in.
	//assume that the screen does not require a login.
	BOOL allowNextScreen = TRUE;
	if([[BT_strings getJsonPropertyValue:theScreenData.jsonVars nameOfProperty:@"loginRequired" defaultValue:@"0"] isEqualToString:@"1"]){
		if(![[appDelegate.rootUser userIsLoggedIn] isEqualToString:@"1"]){
			allowNextScreen = FALSE;
		}
	}
	
	//show password protected message or continue...
	if(!allowNextScreen){
        
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"loginRequired",@"~ Login Required ~")
                                                            message:NSLocalizedString(@"loginRequiredMessage", @"You are not logged in. A login is required to access this screen.")
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"ok", "OK")
                                                  otherButtonTitles:nil];
		[alertView setTag:101];
		[alertView show];
		
		//bail
		return;
        
	}
	if(allowNextScreen){
        
		//play a possible sound effect attached to the menu/button
		if([[BT_strings getJsonPropertyValue:theMenuItemData.jsonVars nameOfProperty:@"soundEffectFileName" defaultValue:@""] length] > 3){
			[appDelegate playSoundEffect:[BT_strings getJsonPropertyValue:theMenuItemData.jsonVars nameOfProperty:@"soundEffectFileName" defaultValue:@""]];
		}
		
		//if the screen we are coming from has an audio track, it may have "audioStopsOnScreenExit"...
		if([[BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:@"audioStopsOnScreenExit" defaultValue:@""] isEqualToString:@"1"]){
			[BT_debugger showIt:self message:[NSString stringWithFormat:@"stopping audio on screen exit for screen with itemId:%@", [self.screenData itemId]]];
			if(appDelegate.audioPlayer != nil){
				[appDelegate.audioPlayer stopAudio];
			}
		}
		
		//remember previous menu item before setting current menu item...
		[appDelegate.rootApp setPreviousMenuItemData:[appDelegate.rootApp currentMenuItemData]];
		
		//remember this  menu item as current...
		[appDelegate.rootApp setCurrentMenuItemData:theMenuItemData];
        
		//remember current screen object...
		[appDelegate.rootApp setCurrentScreenData:theScreenData];
        
		//remember previous screen object...
		[appDelegate.rootApp setPreviousScreenData:self.screenData];
        
        
		//some screens aren't screens at all! Like "Call Us" and "Email Us" item. In these cases, we only
		//trigger a method and do not load a BT_screen view controller.
		
		//place call
		if([[theScreenData itemType] isEqualToString:@"BT_screen_call"] ||
           [[theScreenData itemType] isEqualToString:@"BT_placeCall"]){
            
			if([appDelegate.rootDevice canMakePhoneCalls]){
                
				//trigger the place-call method
				[self placeCallWithScreenData:theScreenData];
                
			}else{
                
				//show error message
				UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"callsNotSupportedTitle",@"Calls Not Supported")
                                                                    message:NSLocalizedString(@"callsNotSupportedMessage", @"Placing calls is not supported on this device.")
                                                                   delegate:nil
                                                          cancelButtonTitle:NSLocalizedString(@"ok", "OK")
                                                          otherButtonTitles:nil];
				[alertView setTag:102];
				[alertView show];
			}
			
			//bail
			return;
		}
		
		//send email or share email
		if([[theScreenData itemType] isEqualToString:@"BT_screen_email"] ||
           [[theScreenData itemType] isEqualToString:@"BT_sendEmail"] ||
           [[theScreenData itemType] isEqualToString:@"BT_shareEmail"] ||
           [[theScreenData itemType] isEqualToString:@"BT_screen_shareEmail"]){
            
			if([appDelegate.rootDevice canSendEmails]){
                
				//trigger the email method
				[self sendEmailWithScreenData:theScreenData imageAttachment:nil imageAttachmentName:nil];
                
			}else{
                
				//show error message
				UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"emailsNotSupportedTitle",@"Email Not Supported")
                                                                    message:NSLocalizedString(@"emailsNotSupportedMessage", @"Sending eamils is not supported on this device.")
                                                                   delegate:nil
                                                          cancelButtonTitle:NSLocalizedString(@"ok", "OK")
                                                          otherButtonTitles:nil];
				[alertView setTag:103];
				[alertView show];
				
			}
            
			//bail
			return;
            
		}
        
		//send SMS or share SMS
		if([[theScreenData itemType] isEqualToString:@"BT_screen_sms"] ||
           [[theScreenData itemType] isEqualToString:@"BT_sendSms"] ||
           [[theScreenData itemType] isEqualToString:@"BT_sendSMS"] ||
           [[theScreenData itemType] isEqualToString:@"BT_shareSms"] ||
           [[theScreenData itemType] isEqualToString:@"BT_shareSMS"] ||
           [[theScreenData itemType] isEqualToString:@"BT_screen_shareSms"]){
            
			if([appDelegate.rootDevice canSendSMS]){
                
				//trigger the SMS method
				[self sendTextMessageWithScreenData:theScreenData];
                
			}else{
                
				//show error message
				UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"textMessageNotSupportedTitle", "SMS Not Supported")
                                                                    message:NSLocalizedString(@"textMessageNotSupportedMessage",  "Sending SMS / Text messages is not supported on this device.")
                                                                   delegate:nil
                                                          cancelButtonTitle:NSLocalizedString(@"ok", "OK")
                                                          otherButtonTitles:nil];
				[alertView setTag:104];
				[alertView show];
			}
			
			//bail
			return;
            
		}
        
		//BT_screen_video
		if([[theScreenData itemType] isEqualToString:@"BT_screen_video"]){
			
			NSString *localFileName = [BT_strings getJsonPropertyValue:theScreenData.jsonVars nameOfProperty:@"localFileName" defaultValue:@""];
			NSString *dataURL = [BT_strings getJsonPropertyValue:theScreenData.jsonVars nameOfProperty:@"dataURL" defaultValue:@""];
			NSURL *escapedUrl = nil;
			
			/*
             video file
             --------------------------------
             a)	No dataURL is provided in the screen data - use the localFileName configured in the screen data
             b)	A dataURL is provided, check for local copy, download if not available
             
             */
			if([dataURL length] < 3){
				if([localFileName length] > 3){
					if([BT_fileManager doesFileExistInBundle:localFileName]){
						NSString *rootPath = [[NSBundle mainBundle] resourcePath];
						NSString *filePath = [rootPath stringByAppendingPathComponent:localFileName];
						escapedUrl = [NSURL fileURLWithPath:filePath isDirectory:NO];
					}
				}
			}else{
				//merge possible varialbes in url
				dataURL = [BT_strings mergeBTVariablesInString:dataURL];
				escapedUrl = [NSURL URLWithString:[dataURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
			}
			
			// iPhone 3.2 > requires adding the movie players view as a subView as described here...
			//developer.apple.com/iphone/library/releasenotes/General/RN-iPhoneSDK-4_0/index.html
			if(escapedUrl != nil){
                
				if([[[UIDevice currentDevice] systemVersion] doubleValue] >= 3.2) {
					
					//NSLog(@"Embedding video WITH subView..");
					[BT_debugger showIt:self message:[NSString stringWithFormat:@"Embedding video WITH subView..%@", @""]];
					MPMoviePlayerViewController *moviePlayerController = [[MPMoviePlayerViewController alloc] initWithContentURL:escapedUrl];
					[moviePlayerController setModalTransitionStyle:UIModalTransitionStyleCrossDissolve];
					[self.navigationController presentModalViewController:moviePlayerController animated:YES];
					
				}else{
                    
					[BT_debugger showIt:self message:[NSString stringWithFormat:@"Embedding video WITHOUT subView..%@", @""]];
					//init moviePlayer...with iPhone OS 3.2 or earlier player
					MPMoviePlayerController *moviePlayer = [[MPMoviePlayerController alloc] initWithContentURL:escapedUrl];
					moviePlayer.scalingMode = MPMovieScalingModeAspectFill;
					moviePlayer.scalingMode = MPMovieScalingModeNone;
					
					[self.navigationController.visibleViewController.view addSubview:[moviePlayer view]];
					[moviePlayer play];
                    
				}
				
				
				
			}
			//bail
			return;
		}//end if video
		
		//BT_screen_launchNativeApp
		if([[theScreenData itemType] isEqualToString:@"BT_screen_launchNativeApp"] ||
           [[theScreenData itemType] isEqualToString:@"BT_launchNativeApp"]){
			/*
             Launching native app requires an "appType" and a "dataURL"
             App Types:	browser, youTube, googleMaps, musicStore, appStore, mail, dialer, sms
             */
			NSString *appToLaunch = [BT_strings getJsonPropertyValue:theScreenData.jsonVars nameOfProperty:@"appToLaunch" defaultValue:@""];
			NSString *dataURL = [BT_strings getJsonPropertyValue:theScreenData.jsonVars nameOfProperty:@"dataURL" defaultValue:@""];
			NSString *encodedURL = @"";
			NSString *alertTitle = @"";
			NSString *alertMessage = @"";
			if([dataURL length] > 1){
				encodedURL =  [dataURL stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
			}
			if([appToLaunch length] > 1 && [encodedURL length] > 3){
				
				//browser, musicStore, appStore
				if([appToLaunch isEqualToString:@"browser"] || [appToLaunch isEqualToString:@"googleMaps"]
                   || [appToLaunch isEqualToString:@"musicStore"] || [appToLaunch isEqualToString:@"appStore"]
                   || [appToLaunch isEqualToString:@"youTube"]){
					[[UIApplication sharedApplication] openURL:[NSURL URLWithString:encodedURL]];
				}
				
				//google maps
				if([appToLaunch isEqualToString:@"googleMaps"]){
					NSString *toAddress = [NSString stringWithFormat:@"http://maps.google.com/maps?q=%@", encodedURL];
					[[UIApplication sharedApplication] openURL:[NSURL URLWithString:toAddress]];
				}
				
				//mail
				if([appToLaunch isEqualToString:@"mail"]){
					if([appDelegate.rootDevice canSendEmails]){
						NSString *emailAddress = [NSString stringWithFormat:@"mailto:%@", encodedURL];
						[[UIApplication sharedApplication] openURL:[NSURL URLWithString:emailAddress]];
					}else{
						alertTitle = NSLocalizedString(@"emailsNotSupportedTitle", "Email Not Supported");
						alertMessage = NSLocalizedString(@"emailsNotSupportedMessage", "Sending emails is not supported on this device");
					}
				}
                
				//dialer
				if([appToLaunch isEqualToString:@"dialer"]){
					if([appDelegate.rootDevice canMakePhoneCalls]){
						NSString *phoneNumber = [NSString stringWithFormat:@"tel://%@", encodedURL];
						[[UIApplication sharedApplication] openURL:[NSURL URLWithString:phoneNumber]];
					}else{
						alertTitle = NSLocalizedString(@"callsNotSupportedTitle", "Calls Not Supported");
						alertMessage = NSLocalizedString(@"emailsNotSupportedTitle", "Placing calls is not supported on this device");
					}
				}
                
				//sms
				if([appToLaunch isEqualToString:@"sms"]){
					if([appDelegate.rootDevice canSendSMS]){
						NSString *smsAddress = [NSString stringWithFormat:@"sms:%@", encodedURL];
						[[UIApplication sharedApplication] openURL:[NSURL URLWithString:smsAddress]];
					}else{
						alertTitle = NSLocalizedString(@"textMessageNotSupportedTitle", "SMS Not Supported");
						alertMessage = NSLocalizedString(@"textMessageNotSupportedMessage", "Sending SMS / Text messages is not supported on this device");
					}
				}
                
                
				//book store URL
				if([appToLaunch isEqualToString:@"bookStore"]){
                    NSString *iBooksAddress = [NSString stringWithFormat:@"itms-books:%@", encodedURL];
                    if([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:iBooksAddress]]) {
						[[UIApplication sharedApplication] openURL:[NSURL URLWithString:iBooksAddress]];
					}else{
						alertTitle = NSLocalizedString(@"customURLSchemeNotSupported", "Can't Open Application");
						alertMessage = NSLocalizedString(@"customURLSchemeNotSupportedMessage", "This device cannot open the application with this URL Scheme");
					}
        		}
                
                
				//customURLScheme
				if([appToLaunch isEqualToString:@"customURLScheme"]){
					if([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:encodedURL]]) {
						[[UIApplication sharedApplication] openURL:[NSURL URLWithString:encodedURL]];
					}else{
						alertTitle = NSLocalizedString(@"customURLSchemeNotSupported", "Can't Open Application");
						alertMessage = NSLocalizedString(@"customURLSchemeNotSupportedMessage", "This device cannot open the application with this URL Scheme");
					}
				}
				
				//show alert?
				if([alertMessage length] > 3){
					UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:alertTitle
                                                                        message:alertMessage
                                                                       delegate:nil
                                                              cancelButtonTitle:NSLocalizedString(@"ok", "OK")
                                                              otherButtonTitles:nil];
					[alertView setTag:105];
					[alertView show];
				}
				
                
			}//dataURL, encodedURL length
            
			//bail
			return;
            
		}//end if launching native app
        
        
		////////////////////////////////////////////////////////////////////////
		//if we are here, we are loading a new screen object
        UIViewController *theNextViewController = [appDelegate.rootApp getViewControllerForScreen:theScreenData];
        if(theNextViewController != nil){
            
            
			//if the screen we are loading has an audio track, spawn a new thread to load it...
			if([[BT_strings getJsonPropertyValue:theScreenData.jsonVars nameOfProperty:@"audioFileName" defaultValue:@""] length] > 3 || [[BT_strings getJsonPropertyValue:theScreenData.jsonVars nameOfProperty:@"audioFileURL" defaultValue:@""] length] > 3){
				
				if([[BT_strings getJsonPropertyValue:theScreenData.jsonVars nameOfProperty:@"audioFileName" defaultValue:@""] length] > 3){
					[BT_debugger showIt:self message:[NSString stringWithFormat:@"this screen uses a background sound from the project bundle: %@", [BT_strings getJsonPropertyValue:theScreenData.jsonVars nameOfProperty:@"audioFileName" defaultValue:@""]]];
				}else{
					[BT_debugger showIt:self message:[NSString stringWithFormat:@"this screen uses a background sound from a URL: %@", [BT_strings getJsonPropertyValue:theScreenData.jsonVars nameOfProperty:@"audioFileURL" defaultValue:@""]]];
				}
				
				//load audio for this screen in another thread
				[NSThread detachNewThreadSelector: @selector(loadAudioForScreen:) toTarget:appDelegate withObject:theScreenData];
                
			}
            
			//always hide the lower tab-bar when screens transition in unless it's overridden
			BOOL hideBottomBar = FALSE;
			if([[BT_strings getJsonPropertyValue:appDelegate.rootApp.rootTheme.jsonVars nameOfProperty:@"hideBottomTabBarWhenScreenLoads" defaultValue:@""] isEqualToString:@"1"]){
				hideBottomBar = TRUE;
			}
			if([[BT_strings getJsonPropertyValue:theScreenData.jsonVars nameOfProperty:@"hideBottomTabBarWhenScreenLoads" defaultValue:@""] length] > 0){
				if([[BT_strings getJsonPropertyValue:theScreenData.jsonVars nameOfProperty:@"hideBottomTabBarWhenScreenLoads" defaultValue:@"1"] isEqualToString:@"0"]){
					hideBottomBar = FALSE;
				}else{
					hideBottomBar = TRUE;
				}
			}
			
			//always hide the bottom tab-bar for quiz screens
			if([[theScreenData itemType] isEqualToString:@"BT_screen_quiz"]){
				hideBottomBar = TRUE;
			}
            
			//hide bottom bar if needed
			[theNextViewController setHidesBottomBarWhenPushed:hideBottomBar];
			
			//always hide the "back" button. A custom button is added in BT_viewUtilities.configureBackgroundAndNavBar
			[theNextViewController.navigationItem setHidesBackButton:TRUE];
            
            //tabbed app's handle pushing views different than non-tabbed apps...
            if([appDelegate.rootApp.tabs count] < 1){
                
                //non-tabbed app, ask rootApp's view controller to push the next view...
                [appDelegate.rootApp.rootNavController pushViewController:theNextViewController animated:YES];
                
            }else{
                
                //ask the navigation controller for the selected tab to push the next view...
                BT_navController *selNavController = (BT_navController *)[appDelegate.rootApp.rootTabBarController selectedViewController];
                [selNavController pushViewController:theNextViewController animated:TRUE];
                
            }
            
            
        }//theNextViewController...
	}//allowNextScreen
}
    
@end