/********* Echo.m Cordova Plugin Implementation *******/

#import "EpsonPrint.h"
#import <Cordova/CDVPlugin.h>

@implementation EpsonPrint

- (void)printReceipt:(CDVInvokedUrlCommand*)command
{
	// run in a new thread
	[self.commandDelegate runInBackground:^{

		//get params
 		ip_address = [command.arguments objectAtIndex:0];
 		image_to_print = [command.arguments objectAtIndex:1];
 		printer_series = [command.arguments objectAtIndex:2];

        
        if([printer_series isEqualToString:@"TM-m10"]) {
            chosen_series = EPOS2_TM_M10;
        }
        else if([printer_series isEqualToString:@"TM-m30"]) {
            chosen_series = EPOS2_TM_M30;
        }
        else if([printer_series isEqualToString:@"TM-P20"]) {
            chosen_series = EPOS2_TM_P20;
        }
        else if([printer_series isEqualToString:@"TM-P60"]) {
            chosen_series = EPOS2_TM_P60;
        }
        else if([printer_series isEqualToString:@"TM-P60II"]) {
            chosen_series = EPOS2_TM_P60II;
        }
        else if([printer_series isEqualToString:@"TM-P80"]) {
            chosen_series = EPOS2_TM_P80;
        }
        else if([printer_series isEqualToString:@"TM-T20"]) {
            chosen_series = EPOS2_TM_T20;
        }
        else if([printer_series isEqualToString:@"TM-T60"]) {
            chosen_series = EPOS2_TM_T60;
        }
        else if([printer_series isEqualToString:@"TM-T70"]) {
            chosen_series = EPOS2_TM_T70;
        }
        else if([printer_series isEqualToString:@"TM-T82"]) {
            chosen_series = EPOS2_TM_T82;
        }
        else if([printer_series isEqualToString:@"TM-T83"]) {
            chosen_series = EPOS2_TM_T83;
        }
        else if([printer_series isEqualToString:@"TM-T88"]) {
            chosen_series = EPOS2_TM_T88;
        }
        else if([printer_series isEqualToString:@"TM-T90"]) {
            chosen_series = EPOS2_TM_T90;
        }
        else if([printer_series isEqualToString:@"TM-U220"]) {
            chosen_series = EPOS2_TM_U220;
        }
        else if([printer_series isEqualToString:@"TM-U330"]) {
            chosen_series = EPOS2_TM_U330;
        }
        else if([printer_series isEqualToString:@"TM-L90"]) {
            chosen_series = EPOS2_TM_L90;
        }
        else if([printer_series isEqualToString:@"TM-H6000"]) {
            chosen_series = EPOS2_TM_H6000;
        }
        else {
            chosen_series = EPOS2_TM_M10;
        }

 		CDVPluginResult* pluginResult = nil;

 		if ([ip_address length] > 0 && [image_to_print length] > 0) {

 			//create printer object
	        lang_ = EPOS2_MODEL_ANK;
			printer_ = [[Epos2Printer alloc] initWithPrinterSeries:chosen_series lang:lang_];

 			//try to print receipt
 			if(![self runPrintReceiptSequence]) {

		        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"error printing receipt"];
			    
 			}
 			else{
 				pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"print_success"];
 			}
 			[self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
 		}   

    }];
}
- (void)findPrinters:(CDVInvokedUrlCommand*)command{
	// run in a new thread
	[self.commandDelegate runInBackground:^{

        NSError *jsonError = nil;
        // store the printers
        found_printers = [command.arguments objectAtIndex:0];
        current_command = command;

        Epos2FilterOption *filterOption = nil;
        filterOption = [[Epos2FilterOption alloc] init]; 

        //make sure it is stopped
        int *result = EPOS2_SUCCESS;
        result = [Epos2Discovery stop];
        if (result != EPOS2_SUCCESS) {
        //Displays error messages
        } 
        result = [Epos2Discovery start:filterOption delegate:self];
        if (EPOS2_SUCCESS != result) {
            //there was an error
        }
    }];
}

-(void)stopSearch:(CDVInvokedUrlCommand*)command{
    [self.commandDelegate runInBackground:^{
        int *result = EPOS2_SUCCESS;
        result = [Epos2Discovery stop];
        if (result != EPOS2_SUCCESS) {
        //Displays error messages
        } 
        CDVPluginResult* pluginResult = nil;
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"print_success"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }]; 
}

- (void) onDiscovery:(Epos2DeviceInfo *)deviceInfo
{
    NSString *found_mac = [deviceInfo getMacAddress];
    bool new_printer = YES;
    for (NSDictionary *dic in found_printers){
        NSString *mac = (NSString*) [dic valueForKey:@"mac"];
        if([found_mac isEqualToString:mac]) {
            new_printer = NO;
            break;
        }
    }
    if(new_printer == YES) {
        //build printer packet
        NSString *target = [deviceInfo getTarget];
        NSString *printer_name = [deviceInfo getDeviceName];
        NSDictionary *jsonObj = [ [NSDictionary alloc]
                               initWithObjectsAndKeys :
                                 @"Epson", @"brand",
                                 target, @"target",
                                 printer_name, @"printer_name",
                                 found_mac, @"mac",
                                 nil
                            ];
        CDVPluginResult* pluginResult = nil;
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:jsonObj];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:current_command.callbackId];
    }
   
}

- (BOOL)runPrintReceiptSequence
{
    if (![self initializeObject]) {
        return NO;
    }

    if (![self createReceiptData]) {
        [self finalizeObject];
        return NO;
    }

    if (![self printData]) {
        [self finalizeObject];
        return NO;
    }

    return YES;
}

- (BOOL)createReceiptData
{
    int result = EPOS2_SUCCESS;

    if (printer_ == nil) {
        return NO;
    }
    // convert to a UIImage
	NSData *data = [[NSData alloc]initWithBase64EncodedString:image_to_print options:NSDataBase64DecodingIgnoreUnknownCharacters];
	UIImage *image_ready = [UIImage imageWithData:data];

	//rezise to 75 percent
	int new_width = (int) (image_ready.size.width * 0.75);
	int new_height = (int) (image_ready.size.height * 0.75);
	CGRect rect = CGRectMake(0,0,new_width,new_height);
    UIGraphicsBeginImageContext( rect.size );
    [image_ready drawInRect:rect];
    UIImage *picture1 = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    NSData *imageData = UIImagePNGRepresentation(picture1);
    UIImage *img=[UIImage imageWithData:imageData];
    image_ready = img;

    if (image_ready == nil) {
        return NO;
    }

    result = [printer_ addTextAlign:EPOS2_ALIGN_CENTER];
    if (result != EPOS2_SUCCESS) {
        //there was an error
        return NO;
    }

    result = [printer_ addImage:image_ready x:0 y:0
              width:image_ready.size.width
              height:image_ready.size.height
              color:EPOS2_COLOR_1
              mode:EPOS2_MODE_MONO
              halftone:EPOS2_HALFTONE_DITHER
              brightness:EPOS2_PARAM_DEFAULT
              compress:EPOS2_COMPRESS_AUTO];

    if (result != EPOS2_SUCCESS) {
        // there was an image
        return NO;
    }

    result = [printer_ addFeedLine:1];
    if (result != EPOS2_SUCCESS) {
        return NO;
    }

    result = [printer_ addCut:EPOS2_CUT_FEED];
    if (result != EPOS2_SUCCESS) {
        return NO;
    }

    return YES;
}

- (BOOL)printData
{
    int result = EPOS2_SUCCESS;

    Epos2PrinterStatusInfo *status = nil;

    if (printer_ == nil) {
        return NO;
    }

    if (![self connectPrinter]) {
        return NO;
    }

    status = [printer_ getStatus];

    if (![self isPrintable:status]) {
        // there was an error
        [printer_ disconnect];
        return NO;
    }

    result = [printer_ sendData:EPOS2_PARAM_DEFAULT];
    if (result != EPOS2_SUCCESS) {
        // there was an error
        [printer_ disconnect];
        return NO;
    }

    return YES;
}

- (BOOL)initializeObject
{
    printer_ = [[Epos2Printer alloc] initWithPrinterSeries:chosen_series lang:lang_];

    if (printer_ == nil) {
    	// there was an error
        return NO;
    }

    [printer_ setReceiveEventDelegate:self];

    return YES;
}

- (void)finalizeObject
{
    if (printer_ == nil) {
        return;
    }

    [printer_ clearCommandBuffer];

    [printer_ setReceiveEventDelegate:nil];

    printer_ = nil;
}

-(BOOL)connectPrinter
{
    int result = EPOS2_SUCCESS;

    if (printer_ == nil) {
        return NO;
    }

    result = [printer_ connect:ip_address timeout:EPOS2_PARAM_DEFAULT];
    if (result != EPOS2_SUCCESS) {
        return NO;
    }

    result = [printer_ beginTransaction];
    if (result != EPOS2_SUCCESS) {
        [printer_ disconnect];
        return NO;
    }

    return YES;
}

- (void)disconnectPrinter
{
    int result = EPOS2_SUCCESS;

    if (printer_ == nil) {
        return;
    }

    result = [printer_ endTransaction];
    if (result != EPOS2_SUCCESS) {
        //there was an error
    }

    result = [printer_ disconnect];
    if (result != EPOS2_SUCCESS) {
        //there was an error
    }

    [self finalizeObject];
}

- (BOOL)isPrintable:(Epos2PrinterStatusInfo *)status
{
    if (status == nil) {
        return NO;
    }

    if (status.connection == EPOS2_FALSE) {
        return NO;
    }
    else if (status.online == EPOS2_FALSE) {
        return NO;
    }
    else {
        ;//print available
    }

    return YES;
}

- (void) onPtrReceive:(Epos2Printer *)printerObj code:(int)code status:(Epos2PrinterStatusInfo *)status printJobId:(NSString *)printJobId
{
    [self performSelectorInBackground:@selector(disconnectPrinter) withObject:nil];
}

@end