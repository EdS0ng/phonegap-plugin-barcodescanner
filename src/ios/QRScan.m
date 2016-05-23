//
//  QRScan.m
//  QRScanner
//
//  Created by Demo Mac on 5/20/16.
//
//

#import "QRScan.h"

@interface QRScan ()

@property AVCaptureSession * session;
@property AVCaptureVideoPreviewLayer* videoLayer;
@property NSString* callbackId;

@end


@implementation QRScan

-(void) scan:(CDVInvokedUrlCommand *)command {
    self.callbackId = command.callbackId;
    
    if ([self setupNewCaptureSession]) {
        [self.session startRunning];
    }
    
}

-(BOOL) setupNewCaptureSession {
    NSError* error;
    self.session = [[AVCaptureSession alloc] init];
    
    AVCaptureDevice* device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    AVCaptureDeviceInput* input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    AVCaptureMetadataOutput* output = [[AVCaptureMetadataOutput alloc] init];
    
    if (!input) {
        NSLog(@"%@", [error localizedDescription]);
        NSString* errorMsg = [NSString stringWithFormat:@"%@", [error localizedDescription]];
        [self returnFailureMessage:errorMsg];
        return NO;
    }
    
    [self.session addInput:input];
    [self.session addOutput:output];
    
    
    dispatch_queue_t dispatch;
    dispatch = dispatch_queue_create("queue", NULL);
    [output setMetadataObjectsDelegate:self queue:dispatch];
    [output setMetadataObjectTypes:@[AVMetadataObjectTypeQRCode]];
    
    self.videoLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    [self.videoLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [self.videoLayer setFrame:self.viewController.view.layer.bounds];
    [self.viewController.view.layer addSublayer:self.videoLayer];
    
    
    return YES;
}

-(void) stopReading {
    [self.session stopRunning];
    self.session = nil;
    
    [self.videoLayer removeFromSuperlayer];
}

-(void) captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    if (metadataObjects != nil && [metadataObjects count] > 0) {
        AVMetadataMachineReadableCodeObject* metadata = metadataObjects[0];
        if ([metadata.type isEqualToString:AVMetadataObjectTypeQRCode]) {
            NSLog(@"%@", metadata.stringValue);
            
            [self performSelectorOnMainThread:@selector(stopReading) withObject:nil waitUntilDone:YES];
            [self returnSuccessScanResult:metadata.stringValue];
        }else {
            [self returnFailureMessage:@"Invalid Type of Code, QR Only"];
        }
    }else {
        [self returnFailureMessage:@"Problem Reading QR Code"];
    }
}

-(void) returnSuccessScanResult:(NSString*) result {
    if (self.callbackId != nil) {
        CDVPluginResult * scanResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:result];
        [self.commandDelegate sendPluginResult:scanResult callbackId:self.callbackId];
    }
}

-(void) returnFailureMessage:(NSString*) error {
    if (self.callbackId != nil) {
        CDVPluginResult* scanResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error];
        [self.commandDelegate sendPluginResult:scanResult callbackId:self.callbackId];
    }
}

@end
