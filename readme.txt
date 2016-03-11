The Launch Screen plugin is ideal for an app developer who wants the customization of launching different plugins based on the user's device. This plugin allows the developer to configure which screen loads for iPhone 3.5 inch, iPhone 4.0 inch, and iPad. The developer can also configure a setting which loads different screens based on the iOS version the user is running. This plugin can also be configured to load no screen, which is ideal for "Lite" apps or apps which use list menus, however, do not want the rows leading to another screen. For best results, use the "fade" transition when loading this plugin.

Features:
-Load a Different Screen on iPhone 3.5 inch, iPhone 4.0 inch, and iPad
-Delay the loading of a screen
-Lock a screen until a specified date
--Configure Alert information to show until this date
-Allow no screen to load

Version History:
v1.0-Initial Release of Plugin
v1.1-Fixed problem loading screens on BT3.0 Core
	-Fixed a typo in the control panel

iOS Project
------------------------
JC_LaunchScreen.h
JC_LaunchScreen.m

Android Project
------------------------
This plugin is not compatible with Android.


JSON Data
------------------------
{
 "itemId": "11223344",
 "itemType": "JC_LaunchScreen",
 "itemNickname": "Launch Screen",
 "launchScreen": "1",
 "iPhone35LoadScreenNickname": "Screen 1",
 "iPhone35LoadScreenID": "10293847",
 "iPhone40LoadScreenNickname": "Screen 2",
 "iPhone40LoadScreenID": "01928374",
 "iPadLoadScreenNickname": "Screen 3",
 "iPadLoadScreenID": "56473829",
 "launchScreenDelay": "0.1",
 "iOSVersionLoad": "7.0",
 "iPhone35LoadScreenNicknameiOSVersion": "Screen 4",
 "iPhone35LoadScreenIDiOSVersion": "7869504",
 "iPhone40LoadScreenNicknameiOSVersion": "Screen 5",
 "iPhone40LoadScreenIDiOSVersion": "3425167",
 "iPadLoadScreenNicknameiOSVersion": "Screen 6",
 "iPadLoadScreenIDiOSVersion": "6758152"
 "launchWaitForDate": "1",
 "launchDateSet": "12-24-13",
 "launchDateAlertTitle": "Title",
 "launchDateAlertMessage": "Message"
}
