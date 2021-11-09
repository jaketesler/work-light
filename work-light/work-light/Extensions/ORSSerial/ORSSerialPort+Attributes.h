//
//  ORSSerialPort+Attributes.h
//  work-light
//
//  Created by Jake Tesler on 11/2/21.
//

#ifndef ORSSerialPort_Attributes_h
#define ORSSerialPort_Attributes_h

#import "ORSSerialPort.h"

@interface ORSSerialPort (Attributes)

@property (nonatomic, readonly) NSDictionary *ioDeviceAttributes;
@property (nonatomic, readonly) NSNumber *vendorID;
@property (nonatomic, readonly) NSNumber *productID;

@end

#endif /* ORSSerialPort_Attributes_h */
