# Ayla Mobile SDK for iOS
### Quickly build iOS applications to connect to the Ayla Networks cloud.
The [Ayla Mobile SDK for iOS](https://github.com/AylaNetworks/iOS_AylaSDK_Public) provides iOS application developers with a way to easily interact with the Ayla Cloud Service and connected devices. It allows developers to focus on the app details instead of data management or network communication, leading to a faster time to market and a more solid application.

1. [Getting Started](#getting-started)
    - [CocoaPods](#cocoapods)
    - [Integration](#integration)
        - [Add the SDK to your Podfile](#add-the-sdk-to-your-podfile)
        - [Creating a local copy](#creating-a-local-copy)
        - [Link a local copy of the SDK into your application](#link-a-local-copy-of-the-sdk-into-your-application)
2. [Project Information](#project-information)
    - [Xcode Build Targets](#xcode-build-targets)
    - [Documentation](#documentation)
    - [Unit Tests](#unit-tests)
    - [Dependencies](#dependencies)
    - [Contribute your code](#contribute-your-code)
    - [Requirements](#requirements)
3. [Release Notes](#release-notes)

# Getting Started

## CocoaPods
Working with the Ayla SDK requires the use of [CocoaPods](https://cocoapods.org) 1.0.1 or higher for dependency management.
If you do not already have [CocoaPods](https://cocoapods.org), you must install it first using Terminal. (*Note*: Depending on your local configuration, you may need to install CocoaPods using `sudo`): 

```console
gem install cocoapods
```

## Integration

### Add the SDK to your Podfile

Using [CocoaPods](http://cocoapods.org/), you can quickly integrate the Ayla SDK into your own application by adding it to your `Podfile`:

```ruby
platform :ios, '8.4'
use_frameworks!

target 'MyApp' do
    pod 'iOS_AylaSDK',
    :git => 'https://github.com/AylaNetworks/iOS_AylaSDK_Public.git'
end
```

### Creating a local copy

You can clone a local copy of the SDK source (for running unit tests or installing documentation, for example). To do so, the following steps should be run in Terminal.

1. Clone the repository into your working directory:

```console
git clone https://github.com/AylaNetworks/iOS_AylaSDK_Public
```
    
2. Then run the following command within the SDK folder: 

```console
pod install
```

Once the Pods have been installed correctly, CocoaPods will generate a `iOS_AylaSDK.xcworkspace` file.  
When opening the Ayla SDK in Xcode, be sure to _only open the .xcworkspace_ file.


### Link a local copy of the SDK into your application

If you keep a [local working copy](#creating-a-local-copy) of the Ayla SDK and would like to use that in your application instead of the remote pod, you can make a change in your application's Podfile to accomplish that:

```ruby
platform :ios, '8.4'
use_frameworks!

target 'MyApp' do
    pod 'iOS_AylaSDK',
    #:git => 'https://github.com/AylaNetworks/iOS_AylaSDK_Public.git'
    :path => '~/path_to/iOS_AylaSDK'
end
``` 

# Project Information
## Xcode Build targets
The `iOS_AylaSDK.xcworkspace` file includes four build targets: 

- iOS\_AylaSDK 
- iOS\_AylaSDKTests
- Documentation
- UniversalLib\_iOS\_AylaSDK
    - This target can be used to build a Universal Static Library for use on simulator(x86\_64/i386) and iphone(arm7/arm64).

## Documentation
The Ayla SDK is documented using [appledoc](https://github.com/tomaz/appledoc/). This program may be installed by compiling [from source](https://github.com/tomaz/appledoc/), or by using [Homebrew](http://brew.sh) (`brew install appledoc`). 

With appledoc installed, you may run the 'Documentation' target within the `iOS_AylaSDK.xcworkspace` file to compile and install the Ayla SDK docset. This will open an interactive HTML-based API guide for the Ayla SDK and allow for SDK-related inline help within Xcode. 

## Unit Tests
iOS\_AylaSDKTests requires a valid Ayla user credential to access the service. Edit the `TestContants.h` file and include the relevant account information for your setup before running unit tests. 

## Dependencies

- AFNetworking ([License](https://github.com/AFNetworking/AFNetworking/blob/master/LICENSE))
- CocoaAsyncSocket ([License](https://github.com/robbiehanson/CocoaAsyncSocket/wiki/License))
- CocoaHTTPServer ([License](https://github.com/robbiehanson/CocoaHTTPServer/blob/master/LICENSE.txt))
- SocketRocket ([License](https://github.com/square/SocketRocket/blob/master/LICENSE))
- OCMock ([License](https://github.com/erikdoe/ocmock/blob/master/License.txt))
- OHHTTPStubs ([License](https://github.com/AliSoftware/OHHTTPStubs/blob/master/LICENSE))

## Contribute your code
If you would like to contribute your own code change to our project, please submit pull requests against the ["incoming" branch on Github](https://github.com/AylaNetworks/iOS_AylaSDK_Public/tree/incoming). We will review and approve your pull requests if appropriate.

## Requirements
 - [CocoaPods](http://cocoapods.org) 1.0.1 or higher
 - [Xcode 8.3](https://developer.apple.com/xcode/downloads/) or higher
 - iOS 8.4 or higher

## Important note on ATS:
To ensure communications can be established between your app and the device over LAN (Required to perform WiFi Setup, some Registration types and also LAN Mode) you should add the NSAllowsLocalNetworking key set to YES inside the NSAppTransportSecurity Dictionary in the Info.plist file of your project in addition to NSAllowsArbitraryLoads if it exists.

    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsLocalNetworking</key>
        <true/>
        <key>NSAllowsArbitraryLoads</key>
        <true/>
    </dict>

## Add the required key to Info.plist of your app
With the new local device support (AKA Phone as a Gateway), iOS requires an update to the applications Info.plist file.
Add the NSBluetoothPeripheralUsageDescription key with a corresponding string value explaining to the apps use of this Bluetooth.

<key>NSBluetoothPeripheralUsageDescription</key>
	<string>Requesting access to Bluetooth to manage nearby compatible devices.</string>
or
<key>NSBluetoothPeripheralUsageDescription</key>
	<string>This application does not use Bluetooth.</string>

## Version of major build tools used
Xcode: 8.3.2
CocoaPods: 1.2.0

# Release Notes

v5.6.00    2017-06-15
------

- Local Device
  - New local device OTA
  - New local device developer guide
- Mobile DSS (websocket)
  - Version 2 support includes datapoint, datapointAck, connectivity, and location subscription types
  - Requires cloud side enablement - contact Customer Success
- New OAuth  Wechat Support
  - Currently limited to one application per OEM
- Setup, registration, and LAN mode improvements
- New app notes for WeChat
- New SDK Architecture diagrams

v5.5.00    2017-03-31
------

New & Improved
- Google OAuth2 Support
  - Replaces Webview OAuth which has been deprecated by Google
  - See app note in /doc folder
- Local Device alpha
- PII improvements and clean up
- Improved registration token handling
- On-boarding support for secure devices
- New API to fetch datapoint history
- Support for AMAP & Aura 5.5
- New support for iPhone7 running iOS 10.3

Bug Fixes & Chores
- Google OAuth2 Support
  - Replaces Webview OAuth with new AylaGoogleOAuthProvider class methods
- App Notes (in /doc folder)
  - Wi-Fi Setup
  - Registration
  - LAN Mode
  - Google OAuth2
- Improved debug info in logs and email preamble
- Don't assign new lanIP if lan mode is active
- Improved updateScheduleActions appleDoc
- Improved assignation for lastUpdateSource
- SWIFT support improvements
- Use the captive network API to find information about the SSID (no longer deprecated!)
- adds nickname to parameters returned by toJSON
- improved registration candidate handling
- Include all previous hot fixes

v5.4.01    2017-03-16
------
- Add public version of podspec

v5.4.00    2017-01-30
------
New & Improved
- New support for iPhone7 running iOS 10.2+
- New file preview support in AylaDatapointBlob class
- New support for different devices with the same LAN IP Addresses (on different LANs)
- Improved deviceManager tracking post device registration
- Improved deviceManager tracking after a device error response
- Adds a step during connectToNewDevice:failure: to determine setup device LAN IP via trace route
- Attempts to disable AP mode from device after it has connected to a WiFi hotspot

Bug Fixes & Chores
- Returns the AylaWifiStatus object result of connectDeviceToServiceWithSSID
- Add Datapoint.echo support
- Fixes "notify" set always to 1 regardless of the count of outstanding commands in queue
- disables LAN mode for received shares
- Include all previous hot fixes

v5.3.01    2016-11-7
------
- improve device push notification

v5.3.00    2016-10-20
------
New & Improved
- Support for AMAP & Aura 5.3.00
- New iOS 10 support
- New 4.x to 5.x SDK transition guide
- New API for Notification/Alert History
- Retrieve all notifications sent for a given device
- New SDK Universal static library build target
- New API for SSO Sign-out support
- New API WiFi Setup state listener

Bug Fixes & Chores
- Improved Discovery operation
- More and improved unit tests
- Improved AylaSSO support through AuthProvider Class
- All 5.2.xx hot-fixes

v5.2.00    2016-08-22
------
New & Improved:
- Support for AMAP & Aura 5.2.00
- Support for new LAN OTA platform feature

Bug Fixes & Chores:
- Improved Schedule and ScheduleAction object creation
- Make sure to notify if timestamps change as well as datapoint values
- mDSS Heartbeat Support
- improvements for Offline Mode support
- Extended default network timeout by 2 seconds
- Improved authentication and session manager support
- Improved AylaSSO support through AuthProvider Class
- All 5.1.xx hot-fixes

v5.1.00    2016-06-27
------
New Features:
- Offline (LAN-only) support using cached device information
- Blob (opaque file) datapoint support
- Generic Gateway and Node support
- Ayla Log Service support
- Improved handling of Baidu push notifications
- Update account email address / password support
- Setup improvements

Enhancements and Bug Fixes:
- Improved contact and notification integration
- Fixes to property trigger management APIs
- Fixes to schedule management APIs
- Device sharing fixes
- Improved error messaging

v5.0.01    2016-05-24
------
- improve device listener notification
- improve device manager polling and listener
- expose property value API

v5.0.00    2016-04-22
------
- initial release
