/**
 * Copyright 2020 Helius Systems
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "PowerAuth.h"
#import "UIKit/UIKit.h"

#import <PowerAuth2/PowerAuthSDK.h>


@implementation PowerAuth

RCT_EXPORT_MODULE();

RCT_EXPORT_METHOD(createActivationWithActivationCode:(NSString*)activationCode
                  deviceName:(NSString*)deviceName
                  createActivationResolver:(RCTPromiseResolveBlock)resolve
                  createActivationRejecter:(RCTPromiseRejectBlock)reject) {
    
    [[PowerAuthSDK sharedInstance] createActivationWithName:deviceName activationCode:activationCode callback:^(PA2ActivationResult * _Nullable result, NSError * _Nullable error) {
        if (error == nil) {
            NSDictionary *response = @{
                @"activationFingerprint": @(result.activationFingerprint)
            };
            resolve(response);
        } else {
            reject(@"ERROR", error.localizedDescription, error);
        }
    }];
}

RCT_EXPORT_METHOD(createActivationWithIdentityAttributes:(NSDictionary*)identityAttributes
                  deviceName:(NSString*)deviceName
                  createActivationResolver:(RCTPromiseResolveBlock)resolve
                  createActivationRejecter:(RCTPromiseRejectBlock)reject) {
    
    [[PowerAuthSDK sharedInstance] createActivationWithName:deviceName identityAttributes:identityAttributes extras:nil callback:^(PA2ActivationResult * _Nullable result, NSError * _Nullable error) {
        if (error == nil) {
            NSDictionary *response = @{
                @"activationFingerprint": @(result.activationFingerprint)
            };
            resolve(response);
        } else {
            reject(@"ERROR", error.localizedDescription, error);
        }
    }];
}

RCT_EXPORT_METHOD(commitActivation:(NSString*)password
                  biometry:(BOOL)biometry
                  commitActivationResolver:(RCTPromiseResolveBlock)resolve
                  commitActivationRejecter:(RCTPromiseRejectBlock)reject) {
    
    PowerAuthAuthentication *auth = [[PowerAuthAuthentication alloc] init];
    auth.usePossession = true;
    auth.usePassword = password;
    auth.useBiometry = biometry;
    
    NSError* error = nil;
    bool success = [[PowerAuthSDK sharedInstance] commitActivationWithAuthentication:auth error:&error];
    
    if (success) {
        resolve(YES);
    } else {
        reject(@"ERROR", error.localizedDescription, error);
    }
    
}

RCT_EXPORT_METHOD(removeActivationLocal) {
    NSLog(@"REMOVED ACTIVATION");
    [[PowerAuthSDK sharedInstance] removeActivationLocal];
}

RCT_REMAP_METHOD(hasValidActivation,
                 hasValidActivationResolver:(RCTPromiseResolveBlock)resolve
                 hasValidActivationRejecter:(RCTPromiseRejectBlock)reject) {
    
    bool validActivation = [[PowerAuthSDK sharedInstance] hasValidActivation];
    
    if s(validActivation) {
        resolve(YES);
    } else {
        NSError *error = [NSError errorWithDomain:@"com.heliussystems.PowerauthReact" code:900001 userInfo:nil];
        reject(@"ERROR", @"No activation present on device", error);
    }
}

RCT_REMAP_METHOD(fetchActivationStatus,
                 fetchActivationStatusResolver: (RCTPromiseResolveBlock) resolve
                 fetchActivationStatusRejecter: (RCTPromiseRejectBlock) reject) {
    
    bool validActivation = [[PowerAuthSDK sharedInstance] hasValidActivation];
    
    NSLog(@"VALID ACTIVATION STATUS: %d\n", validActivation);
    
    if (!validActivation) {
        NSError *error = [NSError errorWithDomain:@"com.heliussystems.PowerauthReact" code:900001 userInfo:nil];
        reject(@"ERROR", @"No activation present on device", error);
        return;
    }
    
    [[PowerAuthSDK sharedInstance] fetchActivationStatusWithCallback:^(PA2ActivationStatus * _Nullable status, NSDictionary * _Nullable customObject, NSError * _Nullable error) {
        
        if (error == nil) {
            PA2ActivationState state = status.state;
            int currentFailCount = status.failCount;
            int maxAllowedFailCount = status.maxFailCount;
            int remainingFailCount = status.remainingAttempts
            
            NSDictionary *response = @{
                @"status": @(state),
                @"currentFailCount": @(currentFailCount),
                @"maxAllowedFailCount": @(maxAllowedFailCount),
                @"remainingFailCount" : @(remainingFailCount)
            };
            resolve(response);
        } else {
            // network error occured, report it to the user
            reject(@"ERROR", error.localizedDescription, error);
        }
    }];
}

RCT_EXPORT_METHOD(requestSignature:(NSString*)userPassword
                  withRequestmethod:(NSString*)requestMethod
                  withUriId:(NSString*)uriId
                  withRequestData:(NSData*)requestData
                  requestSignatureResolver:(RCTPromiseResolveBlock)resolve
                  requestSignature:(RCTPromiseRejectBlock)reject) {
    
    PowerAuthAuthentication *auth = [[PowerAuthAuthentication alloc] init];
    auth.usePossession = true;
    auth.usePassword = userPassword;
    auth.useBiometry = false;
    
    NSLog(@"Request data log: %@", requestData);
    
    NSError* errorMessage = nil;
    PA2AuthorizationHttpHeader* signature = [[PowerAuthSDK sharedInstance] requestSignatureWithAuthentication:auth method:requestMethod uriId:uriId body:requestData error: &errorMessage];
    
    if (error == nil) {
        NSDictionary *response = @{
            @"httpHeaderKey": signature.key,
            @"httpHeaderValue": signature.value
        };
        resolve(response);
    } else {
        reject(@"ERROR", error.localizedDescription, error);
    }
    
}

@end
