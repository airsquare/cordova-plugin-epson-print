
#import <Cordova/CDVPlugin.h>
#import "ePOS2.h"

@interface EpsonPrint : CDVPlugin <Epos2DiscoveryDelegate>{

	Epos2Printer *printer_;
	NSString* ip_address;
	NSString* image_to_print;
	NSString* printer_series;
	int* chosen_series;
	int lang_;
	CDVInvokedUrlCommand* current_command;
	NSArray* found_printers;
}

- (void)printReceipt:(CDVInvokedUrlCommand*)command;
- (void)findPrinters:(CDVInvokedUrlCommand*)command;
- (void)stopSearch:(CDVInvokedUrlCommand*)command;
@end
