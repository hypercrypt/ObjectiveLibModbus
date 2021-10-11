//
//  ObjectiveLibModbus.m
//  LibModbusTest
//
//  Created by Lars-Jørgen Kristiansen on 22.02.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

//#define modbusQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)

#import "ObjectiveLibModbus.h"

@interface ObjectiveLibModbus ()

@property (nonatomic, readonly) modbus_t *mb;
@property (nonatomic, readonly) dispatch_queue_t modbusQueue;

@end

@implementation ObjectiveLibModbus

- (instancetype)initWithTCP:(NSString *)ipAddress
                       port:(int)port
                     device:(int)device {
    
    if ((self = [self init]))
    {
        // your code here
        _modbusQueue = dispatch_queue_create("com.iModbus.modbusQueue", NULL);
        if ([self setupTCP:ipAddress port:port device:device])
            return self;
    }
    
    return NULL;
}

- (BOOL)setupTCP:(NSString *)ipAddress port:(int)port device:(int)device
{
	_ipAddress = ipAddress;
    _mb = modbus_new_tcp([ipAddress cStringUsingEncoding:NSASCIIStringEncoding], port);
    modbus_set_error_recovery(_mb, MODBUS_ERROR_RECOVERY_LINK | MODBUS_ERROR_RECOVERY_PROTOCOL);
    modbus_set_slave(_mb, device);
	return YES;
}

- (BOOL) connectWithError:(NSError **)error {
    int ret = modbus_connect(self.mb);
    if (ret == -1) {
        NSString *errorString = [NSString stringWithUTF8String:modbus_strerror(errno)];
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:errorString forKey:NSLocalizedDescriptionKey];
        // populate the error object with the details
        if (error) {
            *error = [NSError errorWithDomain:@"Modbus" code:errno userInfo:details];
        }
        return NO;
    }
    return YES;
}

- (void) connect:(void (^)(void))success failure:(void (^)(NSError *error))failure {
    dispatch_async(self.modbusQueue, ^{
        int ret = modbus_connect(self.mb);
        if (ret == -1) {
            NSString *errorString = [NSString stringWithUTF8String:modbus_strerror(errno)];
            NSMutableDictionary* details = [NSMutableDictionary dictionary];
            [details setValue:errorString forKey:NSLocalizedDescriptionKey];
            // populate the error object with the details
            NSError *error = [NSError errorWithDomain:@"Modbus" code:errno userInfo:details];
            dispatch_async(dispatch_get_main_queue(), ^{
                failure(error);
            });
        }
        else {
            dispatch_async(dispatch_get_main_queue(), ^{
                success();
            });
        }
    });
}

- (void) disconnect {
    modbus_close(self.mb);
}

- (void)writeType:(functionType)type
          address:(int)address
               to:(int)value
          success:(void (^)(void))success
          failure:(void (^)(NSError *error))failure
{
    switch (type)
    {
        case kBits: {
            [self writeBit:address to:value success:^{
                success();
            } failure:^(NSError *error) {
                failure(error);
            }];

        } break;
        
        case kRegisters: {
            [self writeRegister:address to:value success:^{
                success();
            } failure:^(NSError *error) {
                failure(error);
            }];
        } break;
            
        default: {
            NSString *errorString = @"Could not write. Function type is read only";
            NSMutableDictionary* details = [NSMutableDictionary dictionary];
            [details setValue:errorString forKey:NSLocalizedDescriptionKey];
            // populate the error object with the details
            NSError *error = [NSError errorWithDomain:@"Modbus" code:errno userInfo:details];
            failure(error);
        }
    }
}

- (void)readType:(functionType)type
    startAddress:(int)address
           count:(int)count
         success:(ObjectiveLibModbusReadSuccessBlock)success
         failure:(ObjectiveLibModbusErrorBlock)failure
{
    if (type == kInputBits) {
        [self readInputBitsFrom:address count:count success:^(NSArray *array) {
            success(array);
        } failure:^(NSError *error) {
            failure(error);
        }];
    }
    else if (type == kBits) {
        [self readBitsFrom:address count:count success:^(NSArray *array) {
            success(array);
        } failure:^(NSError *error) {
            failure(error);
        }];
    }
    else if (type == kInputRegisters) {
        [self readInputRegistersFrom:address count:count success:^(NSArray *array) {
            success(array);
        } failure:^(NSError *error) {
            failure(error);
        }];
    }
    else if (type == kRegisters) {
        [self readRegistersFrom:address count:count success:^(NSArray *array) {
            success(array);
        } failure:^(NSError *error) {
            failure(error);
        }];
    }
}

- (void)writeBit:(int)address
              to:(BOOL)status
         success:(void (^)(void))success
         failure:(void (^)(NSError *error))failure
{
    dispatch_async(self.modbusQueue, ^{
        if (modbus_write_bit(self.mb, address, status) >= 0)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                success();
            });
        }
        else {
            NSString *errorString = [NSString stringWithUTF8String:modbus_strerror(errno)];
            NSMutableDictionary* details = [NSMutableDictionary dictionary];
            [details setValue:errorString forKey:NSLocalizedDescriptionKey];
            // populate the error object with the details
            NSError *error = [NSError errorWithDomain:@"Modbus" code:errno userInfo:details];
            dispatch_async(dispatch_get_main_queue(), ^{
                failure(error);
            });
        }
    });
    
}

- (void)writeRegister:(int)address
                   to:(int)value
              success:(void (^)(void))success
              failure:(void (^)(NSError *error))failure
{
    dispatch_async(self.modbusQueue, ^{
        if(modbus_write_register(self.mb, address, value) >= 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                success();
            });
        }
        else {
            NSString *errorString = [NSString stringWithUTF8String:modbus_strerror(errno)];
            NSMutableDictionary* details = [NSMutableDictionary dictionary];
            [details setValue:errorString forKey:NSLocalizedDescriptionKey];
            // populate the error object with the details
            NSError *error = [NSError errorWithDomain:@"Modbus" code:errno userInfo:details];
            dispatch_async(dispatch_get_main_queue(), ^{
                failure(error);
            });
        }
    });
    
}

- (void)readBitsFrom:(int)startAddress
               count:(int)count
             success:(void (^)(NSArray *array))success
             failure:(void (^)(NSError *error))failure
{
    dispatch_async(self.modbusQueue, ^{
        
        uint8_t tab_reg[count*sizeof(uint8_t)];
        
        if (modbus_read_bits(self.mb, startAddress, count, tab_reg) >= 0)
        {
            NSMutableArray *returnArray = [NSMutableArray arrayWithCapacity:count];
            
            for (int i=0; i < count; i++)
            {
                [returnArray addObject:@(tab_reg[i])];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                success(returnArray);
            });
        }
        else
        {
            NSError *const error = [NSError errorWithDomain:@"Modbus" code:errno userInfo:@{
                NSLocalizedDescriptionKey: [NSString stringWithUTF8String:modbus_strerror(errno)]
            }];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                failure(error);
            });
        }
    });
}

- (void)readInputBitsFrom:(int)startAddress count:(int)count success:(void (^)(NSArray *array))success failure:(void (^)(NSError *error))failure {
    dispatch_async(self.modbusQueue, ^{
        
        uint8_t tab_reg[count*sizeof(uint8_t)];
        
        if (modbus_read_input_bits(self.mb, startAddress, count, tab_reg) >= 0) {
            NSMutableArray *returnArray = [NSMutableArray arrayWithCapacity:count];
            
            for(int i=0;i<count;i++)
            {
                [returnArray addObject:[NSNumber numberWithBool: tab_reg[i]]];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                success(returnArray);
            });
        }
        else {
            NSString *errorString = [NSString stringWithUTF8String:modbus_strerror(errno)];
            NSMutableDictionary* details = [NSMutableDictionary dictionary];
            [details setValue:errorString forKey:NSLocalizedDescriptionKey];
            // populate the error object with the details
            NSError *error = [NSError errorWithDomain:@"Modbus" code:errno userInfo:details];
            dispatch_async(dispatch_get_main_queue(), ^{
                failure(error);
            });
        }
        
    });
}

- (void) readRegistersFrom:(int)startAddress count:(int)count success:(void (^)(NSArray *array))success failure:(void (^)(NSError *error))failure {
    dispatch_async(self.modbusQueue, ^{
        
        uint16_t tab_reg[count*sizeof(uint16_t)];
        
        if (modbus_read_registers(self.mb, startAddress, count, tab_reg) >= 0) {
            NSMutableArray *returnArray = [NSMutableArray arrayWithCapacity:count];
            
            for(int i=0;i<count;i++)
            {
                [returnArray addObject:[NSNumber numberWithInt: tab_reg[i]]];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                success(returnArray);
            });
        }
        else {
            NSString *errorString = [NSString stringWithUTF8String:modbus_strerror(errno)];
            NSMutableDictionary* details = [NSMutableDictionary dictionary];
            [details setValue:errorString forKey:NSLocalizedDescriptionKey];
            // populate the error object with the details
            NSError *error = [NSError errorWithDomain:@"Modbus" code:errno userInfo:details];
            dispatch_async(dispatch_get_main_queue(), ^{
                failure(error);
            });
        }        
    });
}

- (void)readInputRegistersFrom:(int)startAddress
                         count:(int)count
                       success:(void (^)(NSArray *array))success
                       failure:(void (^)(NSError *error))failure
{
    dispatch_async(self.modbusQueue, ^{
        
        uint16_t tab_reg[count*sizeof(uint16_t)];
        
        if (modbus_read_input_registers(self.mb, startAddress, count, tab_reg) >= 0)
        {
            NSMutableArray *returnArray = [NSMutableArray arrayWithCapacity:count];
            
            for(int i=0;i<count;i++)
            {
                [returnArray addObject:[NSNumber numberWithInt: tab_reg[i]]];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                success(returnArray);
            });
        }
        else
        {
            NSString *errorString = [NSString stringWithUTF8String:modbus_strerror(errno)];
            NSMutableDictionary* details = [NSMutableDictionary dictionary];
            [details setValue:errorString forKey:NSLocalizedDescriptionKey];
            // populate the error object with the details
            NSError *error = [NSError errorWithDomain:@"Modbus" code:errno userInfo:details];
            dispatch_async(dispatch_get_main_queue(), ^{
                failure(error);
            });
        } 
    });
}

- (void)writeRegistersFromAndOn:(int)address
                       toValues:(NSArray *)numberArray
                        success:(void (^)(void))success
                        failure:(void (^)(NSError *error))failure
{
    NSParameterAssert(numberArray.count >= 0);
    NSParameterAssert(numberArray.count <= INT_MAX);
    
    dispatch_async(self.modbusQueue, ^{
        
        uint16_t valueArray[numberArray.count];
        
        for (int i = 0; i < numberArray.count; i++)
        {
            valueArray[i] = [numberArray[i] unsignedIntValue];
        }
          
        if (modbus_write_registers(self.mb, address, (int)numberArray.count, valueArray))
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                success();
            });
        }
        else
        {
            NSString *errorString = [NSString stringWithUTF8String:modbus_strerror(errno)];
            NSMutableDictionary *details = [NSMutableDictionary dictionary];
            [details setValue:errorString forKey:NSLocalizedDescriptionKey];
            // populate the error object with the details
            NSError *error = [NSError errorWithDomain:@"Modbus" code:errno userInfo:details];
            dispatch_async(dispatch_get_main_queue(), ^{
                failure(error);
            });
        }
    });
}

- (void)dealloc
{
    modbus_free(_mb);
}

@end
