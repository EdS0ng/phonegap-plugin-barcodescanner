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
    
    UIView* video = [self createVideoView];
    self.videoLayer.zPosition = 0.0;
    [video.layer insertSublayer:self.videoLayer atIndex:0];
    [self.viewController.view addSubview:video];
    
    return YES;
}

-(UIView*) createVideoView {
    CGRect bounds = self.viewController.view.layer.bounds;
    CGFloat btnHeight = 50.0f;
    UIView* videoView = [[UIView alloc] initWithFrame:bounds];
    
    UIButton* cancel = [[UIButton alloc] initWithFrame:CGRectMake(0.0, bounds.size.height-btnHeight, bounds.size.width, btnHeight)];
    [cancel setTitleColor:videoView.tintColor forState:UIControlStateNormal];
    [cancel setTitle:@"Cancel" forState:UIControlStateNormal];
    [cancel setBackgroundColor:[UIColor colorWithWhite:1.0 alpha:1.0]];
    cancel.layer.zPosition = 5.0;
    
    [cancel addTarget:self action:@selector(cancelScan) forControlEvents:UIControlEventTouchUpInside];
    
    [videoView addSubview:cancel];
    
    return videoView;
}

-(void) cancelScan {
    [self stopReading];
    [self returnSuccessScanResult:@"" OrCancelled:@1];
}

-(void) stopReading {
    [self.session stopRunning];
    self.session = nil;
    
    for (UIView* subView in self.viewController.view.subviews) {
        if (![subView isKindOfClass:[UIWebView class]]) {
            [subView removeFromSuperview];
        }
    }
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
    [self returnSuccessScanResult:result OrCancelled:@0];
}

-(void) returnFailureMessage:(NSString*) error {
    if (self.callbackId != nil) {
        CDVPluginResult* scanResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error];
        [self.commandDelegate sendPluginResult:scanResult callbackId:self.callbackId];
    }
}

-(void) returnSuccessScanResult:(NSString* )result OrCancelled:(NSNumber*)cancelled {
    if (self.callbackId != nil ) {
        CDVPluginResult* scanResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:@{@"cancelled":cancelled, @"text":result}];
        [self.commandDelegate sendPluginResult:scanResult callbackId:self.callbackId];
    }
}

@end
