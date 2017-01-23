/*
 *	Copyright 2013-2017 Jake Chasan
 *  Current Revision January 2017, v2.0
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
 *	The name of Jake Chasan, jakechasan.com, and the names of its contributors may not be
 *	used to endorse or promote products derived from this software without specific
 *	prior written permission, under any circumstances.
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
#import "BT_application.h"
#import "BT_strings.h"
#import "BT_viewUtilities.h"
#import "BT_item.h"
#import "BT_debugger.h"
#import "BT_fileManager.h"
#import "BT_color.h"
#import "BT_downloader.h"
#import "JC_LaunchScreen.h"

@implementation JC_LaunchScreen

//viewDidLoad
-(void)viewDidLoad{
	[BT_debugger showIt:self theMessage:@"viewDidLoad"];
	[super viewDidLoad];
    
    int loadScreenBoolean = [[BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:@"launchScreen" defaultValue:@"0"] intValue];
    
    if(loadScreenBoolean==1){
        bool waitForDate = true;

        //Check the Date - false does not show screen, true does show screen
        if([[BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:@"launchWaitForDate" defaultValue:@"0"] intValue] != 0){
            waitForDate = [self shouldLaunchScreen];
        }
        
        if(waitForDate==true){
            //Load Screen
            double launchScreenDelay = [[BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:@"launchScreenDelay" defaultValue:@"0.1"] doubleValue];
            if(launchScreenDelay<0.1){
                launchScreenDelay = 0.1;
            }
            
            [self performSelector:(@selector(launchScreen)) withObject:nil afterDelay:launchScreenDelay];
        }
    }
    else{
        //Do nothing, no screen should load
    }
}

//view will appear
-(void)viewWillAppear:(BOOL)animated{
	[super viewWillAppear:animated];
	[BT_debugger showIt:self theMessage:@"viewWillAppear"];
    
    //flag this as the current screen
	appDelegate.rootApp.currentScreenData = self.screenData;
}

-(void)viewDidAppear:(BOOL)animated{
    [self.navigationController popViewControllerAnimated:NO];
}

-(NSUInteger)dateParser:(NSString *)date{
    //Date Format must be MM-DD-YY
    int dateNumber = 0;
    @try {
        int i;
        for(i=0; i<date.length; i++){
            char c = [date characterAtIndex:(i)];
            NSString *intFromString = [NSString stringWithFormat:@"%c", c];
            if(c != '-'){
                dateNumber += [intFromString intValue];
                [BT_debugger showIt:self theMessage:[NSString stringWithFormat:@"Character: %c", c]];
                [BT_debugger showIt:self theMessage:[NSString stringWithFormat:@"dateNumber: %d", dateNumber]];
            }
        }
        [BT_debugger showIt:self theMessage:[NSString stringWithFormat:@"Number: %d", dateNumber]];
        return dateNumber;
    }
    @catch (NSException *exception){
        [BT_debugger showIt:self theMessage:@"Problem Parsing the Date"];
        //Date Should Never be Negative
        return false;
    }
    @finally{
    }
}

-(BOOL)shouldLaunchScreen{
    NSDate *dateNow = [[NSDate alloc] init];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
    [dateFormatter setDateFormat:@"MM-dd-yy"];
    NSString *dateString = [dateFormatter stringFromDate:dateNow];
    [BT_debugger showIt:self theMessage:[NSString stringWithFormat:@"Formatted dateNow: %@", dateString]];
    int dateNowNumber = (int)[self performSelector:@selector(dateParser:) withObject:dateString];

    NSString *dateSetString = [BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:@"launchDateSet" defaultValue:@""];
    if(dateSetString.length==0){
        [self showAlert:@"Configuration Error" theMessage:@"Please check your date settings" alertTag:0];
        return false;
    }
    int dateSetNumber = (int)[self performSelector:@selector(dateParser:) withObject:dateSetString];
    
    if(dateNowNumber>=dateSetNumber){
        //The Date has passed
        return true;
    }
    else if(dateNowNumber<dateSetNumber){
        //The Date has not passed
        NSString *alertTitle = [BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:@"launchDateAlertTitle" defaultValue:@"Check Back Later"];
        NSString *alertMessage = [BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:@"launchDateAlertMessage" defaultValue:@"This screen will be availible soon."];
        [self showAlert:alertTitle theMessage:alertMessage alertTag:0];
        return false;
    }
    else{
        //We should not be here, this default case should not occur
        return false;
    }
}

-(void)launchScreen{
    [BT_debugger showIt:self theMessage:@"Initiating Launch"];
    
    //For iOS Version Setting
    double iOSVersion = [[[UIDevice currentDevice] systemVersion] doubleValue];
    double iOSVersionSpecified = [[BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:@"iOSVersionLoad" defaultValue:@"0"] doubleValue];
    
    if(iOSVersionSpecified==0){
        iOSVersionSpecified = iOSVersion;
    }
    
    [BT_debugger showIt:self theMessage:[NSString stringWithFormat:@"Device iOS Version: %g", iOSVersion]];
    [BT_debugger showIt:self theMessage:[NSString stringWithFormat:@"JSON iOS Version: %g", iOSVersionSpecified]];
    
    NSString* iOSVersionString = @"";
    if(iOSVersion < iOSVersionSpecified){
        iOSVersionString = @"iOSVersion";
    }
    
    NSString* deviceTypeString = @"iPad";
    NSString* deviceSizeString = @"";
    
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone){
        deviceTypeString = @"iPhone";
        
        CGSize result = [[UIScreen mainScreen] bounds].size;
        if(result.height != 480){
            deviceSizeString = @"40";
        }
        else{
            deviceSizeString = @"35";
        }
    }
    
    NSString *loadScreenItemId = [BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:[NSString stringWithFormat:@"%@%@LoadScreenID%@", deviceTypeString, deviceSizeString, iOSVersionString] defaultValue:@""];
    NSString *loadScreenNickname = [BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:[NSString stringWithFormat:@"%@%@LoadScreenNickname%@", deviceTypeString, deviceSizeString, iOSVersionString] defaultValue:@""];
    NSString *transitionType = [BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:[NSString stringWithFormat:@"%@%@LoadScreenTransitionType%@", deviceTypeString, deviceSizeString, iOSVersionString] defaultValue:@""];
    
    [BT_debugger showIt:self theMessage:[NSString stringWithFormat:@"%@ %@ %@ Loaded", deviceTypeString, deviceSizeString, iOSVersionString]];
    
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
        
        NSMutableDictionary *tmpMutDictionary = [tmpDictionary mutableCopy];
        
        [tmpMenuItem setJsonVars:tmpMutDictionary];
        [tmpMenuItem setItemId:@"0"];
        
        //load the next screen
        [self handleTapToLoadScreen:screenObjectToLoad theMenuItemData:tmpMenuItem];
    }
    
    //should not ever get here unless a button didn't have a load screen...
    return;
}

@end
