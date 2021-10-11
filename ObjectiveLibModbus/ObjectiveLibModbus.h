//
//  ObjectiveLibModbus.h
//  LibModbusTest
//
//  Created by Lars-Jørgen Kristiansen on 22.02.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

@import Foundation;
#import "modbus.h"

//! Project version number for ObjectiveLibModbus.
FOUNDATION_EXPORT double ObjectiveLibModbusVersionNumber;

//! Project version string for ObjectiveLibModbus.
FOUNDATION_EXPORT const unsigned char ObjectiveLibModbusVersionString[];


typedef enum {
    kInputBits,
    kBits,
    kInputRegisters,
    kRegisters
} functionType;

typedef void(^ObjectiveLibModbusErrorBlock)(NSError *error);
typedef void(^ObjectiveLibModbusWriteSuccessBlock)(void);
typedef void(^ObjectiveLibModbusReadSuccessBlock)(NSArray *array);

@interface ObjectiveLibModbus : NSObject

@property (strong, nonatomic) NSString *ipAddress;

- (instancetype)initWithTCP:(NSString *)ipAddress
                       port:(int)port
                     device:(int)device;

- (BOOL)setupTCP:(NSString *)ipAddress
            port:(int)port
          device:(int)device;

- (BOOL)connectWithError:(NSError **)error;

- (void)connect:(void (^)(void))success
        failure:(ObjectiveLibModbusErrorBlock)failure;

- (void)disconnect;


- (void)writeType:(functionType)type
          address:(int)address
               to:(int)value
          success:(ObjectiveLibModbusWriteSuccessBlock)success
          failure:(ObjectiveLibModbusErrorBlock)failure;

- (void)readType:(functionType)type
    startAddress:(int)address
           count:(int)count
         success:(ObjectiveLibModbusReadSuccessBlock)success
         failure:(ObjectiveLibModbusErrorBlock)failure;

- (void)writeBit:(int)address
              to:(BOOL)status
         success:(ObjectiveLibModbusWriteSuccessBlock)success
         failure:(ObjectiveLibModbusErrorBlock)failure;

- (void)writeRegister:(int)address
                   to:(int)value
              success:(ObjectiveLibModbusWriteSuccessBlock)success
              failure:(ObjectiveLibModbusErrorBlock)failure;

- (void)readBitsFrom:(int)startAddress
               count:(int)count
             success:(ObjectiveLibModbusReadSuccessBlock)success
             failure:(ObjectiveLibModbusErrorBlock)failure;

- (void)readInputBitsFrom:(int)startAddress
                    count:(int)count
                  success:(ObjectiveLibModbusReadSuccessBlock)success
                  failure:(ObjectiveLibModbusErrorBlock)failure;

- (void)readRegistersFrom:(int)startAddress
                    count:(int)count
                  success:(ObjectiveLibModbusReadSuccessBlock)success
                  failure:(ObjectiveLibModbusErrorBlock)failure;

- (void)readInputRegistersFrom:(int)startAddress
                         count:(int)count
                       success:(ObjectiveLibModbusReadSuccessBlock)success
                       failure:(ObjectiveLibModbusErrorBlock)failure;

- (void)writeRegistersFromAndOn:(int)address
                       toValues:(NSArray *)numberArray
                        success:(ObjectiveLibModbusWriteSuccessBlock)success
                        failure:(ObjectiveLibModbusErrorBlock)failure;

@end
