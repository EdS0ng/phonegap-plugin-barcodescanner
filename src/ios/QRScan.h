//
//  QRScan.h
//  QRScanner
//
//  Created by Demo Mac on 5/20/16.
//
//

#import <Cordova/CDV.h>
#import <AVFoundation/AVFoundation.h>

@interface QRScan : CDVPlugin <AVCaptureMetadataOutputObjectsDelegate>

-(void) scan:(CDVInvokedUrlCommand*) command;



@end
