#import <UIKit/UIKit.h>

#import "AylaAuthorization.h"
#import "AylaAuthProvider.h"
#import "AylaBaseAuthProvider.h"
#import "AylaCachedAuthProvider.h"
#import "AylaGoogleOAuthProvider.h"
#import "AylaIDPAuthProvider.h"
#import "AylaOAuthProvider.h"
#import "AylaPartnerAuthorization+Internal.h"
#import "AylaPartnerAuthorization.h"
#import "AylaUsernameAuthProvider.h"
#import "AylaWechatOAuthProvider.h"
#import "AylaAlertHistory.h"
#import "AylaCache.h"
#import "AylaContact.h"
#import "AylaDatapoint.h"
#import "AylaDatapointBatchRequest.h"
#import "AylaDatapointBatchResponse.h"
#import "AylaDatapointBlob.h"
#import "AylaDatum.h"
#import "AylaDefines.h"
#import "AylaDevice+Extensible.h"
#import "AylaDevice.h"
#import "AylaDeviceClassPlugin.h"
#import "AylaDeviceDetailProvider.h"
#import "AylaDeviceGateway.h"
#import "AylaDeviceListPlugin.h"
#import "AylaDeviceManager.h"
#import "AylaDeviceNode.h"
#import "AylaDeviceNotification.h"
#import "AylaDeviceNotificationApp.h"
#import "AylaEmailTemplate.h"
#import "AylaErrorUtils.h"
#import "AylaGrant.h"
#import "AylaHTTPClient.h"
#import "AylaLanSupportDevice.h"
#import "AylaLoginManager.h"
#import "AylaNetworks+Utils.h"
#import "AylaNetworks.h"
#import "AylaObject.h"
#import "AylaPlugin.h"
#import "AylaProfiler.h"
#import "AylaProperty.h"
#import "AylaPropertyTrigger.h"
#import "AylaPropertyTriggerApp.h"
#import "AylaRegistration.h"
#import "AylaRegistrationCandidate.h"
#import "AylaRole.h"
#import "AylaSchedule.h"
#import "AylaScheduleAction.h"
#import "AylaServiceApp.h"
#import "AylaSessionManager.h"
#import "AylaShare.h"
#import "AylaShareUserProfile.h"
#import "AylaSystemSettings.h"
#import "AylaSystemUtils.h"
#import "AylaTimeZone.h"
#import "AylaUser.h"
#import "AylaChange.h"
#import "AylaDeviceChange.h"
#import "AylaDeviceListChange.h"
#import "AylaFieldChange.h"
#import "AylaListChange.h"
#import "AylaPropertyChange.h"
#import "AylaConnectivity.h"
#import "AylaConnectTask.h"
#import "AylaGenericTask.h"
#import "AylaHTTPError.h"
#import "AylaHTTPTask.h"
#import "AylaJsonError.h"
#import "AylaLanError.h"
#import "AylaRequestError.h"
#import "AylaBLECandidate.h"
#import "AylaBLEDevice+Internal.h"
#import "AylaBLEDevice.h"
#import "AylaBLEDeviceManager+Internal.h"
#import "AylaBLEDeviceManager.h"
#import "AylaDeviceCommand.h"
#import "AylaLocalDevice.h"
#import "AylaLocalDeviceManager.h"
#import "AylaLocalOTACommand.h"
#import "AylaLocalProperty.h"
#import "AylaLocalRegistrationCandidate.h"
#import "AylaLog.h"
#import "AylaLogManager.h"
#import "AylaLANOTADevice.h"
#import "AylaOTAImageInfo.h"
#import "AylaDatapointParams.h"
#import "AylaNetworkInformation.h"
#import "AylaSetup.h"
#import "AylaSetupDevice.h"
#import "AylaSetupError.h"
#import "AylaWifiScanResults.h"
#import "AylaWifiStatus.h"

FOUNDATION_EXPORT double iOS_AylaSDKVersionNumber;
FOUNDATION_EXPORT const unsigned char iOS_AylaSDKVersionString[];

