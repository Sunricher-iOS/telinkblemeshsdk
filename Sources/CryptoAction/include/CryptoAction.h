/********************************************************************************************************
 * @file     CryptoAction.h 
 *
 * @brief    for TLSR chips
 *
 * @author	 telink
 * @date     Sep. 30, 2010
 *
 * @par      Copyright (c) 2010, Telink Semiconductor (Shanghai) Co., Ltd.
 *           All rights reserved.
 *           
 *			 The information contained herein is confidential and proprietary property of Telink 
 * 		     Semiconductor (Shanghai) Co., Ltd. and is available under the terms 
 *			 of Commercial License Agreement between Telink Semiconductor (Shanghai) 
 *			 Co., Ltd. and the licensee in separate contract or the terms described here-in. 
 *           This heading MUST NOT be removed from this file.
 *
 * 			 Licensees are granted free, non-transferable use of the information in this 
 *			 file under Mutual Non-Disclosure Agreement. NO WARRENTY of ANY KIND is provided. 
 *           
 *******************************************************************************************************/
//
//  CryptoAction.h
//  TelinkBlue
//
//  Created by Green on 11/15/15.
//  Copyright (c) 2015 Green. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CryptoAction : NSObject

+(BOOL)getRandPro:(uint8_t *)prand Len:(int)len;

//prand  16字节随机数
//presult  16字节
+(BOOL)encryptPair:(NSString *)uName Pas:(NSString *)uPas Prand:(uint8_t *)prand PResult:(uint8_t *)presult;

+(BOOL)getSectionKey:(NSString *)uName Pas:(NSString *)uPas Prandm:(uint8_t *)prandm Prands:(uint8_t *)prands PResult:(uint8_t *)presult;

+(BOOL)encryptionPpacket:(uint8_t *)key Iv:(uint8_t *)iv Mic:(uint8_t *)mic MicLen:(int)mic_len Ps:(uint8_t *)ps Len:(int)len;

+(BOOL)decryptionPpacket:(uint8_t *)key Iv:(uint8_t *)iv Mic:(uint8_t *)mic MicLen:(int)mic_len Ps:(uint8_t *)ps Len:(int)len;

+(BOOL)getNetworkInfo:(uint8_t *)pcmd Opcode:(int)opcode Str:(NSString *)str Psk:(uint8_t *)psk;
+(BOOL)getNetworkInfoByte:(uint8_t *)pcmd Opcode:(int)opcode Str:(uint8_t *)str Psk:(uint8_t *)psk;

#pragma mark - Custom

+ (NSData *)pasterData:(NSData *)data mac:(uint32_t)mac sectionKey:(uint8_t *)sectionKey;

+ (NSData *)exeCMD:(NSData *)data mac:(uint32_t)mac sectionKey:(uint8_t *)sectionKey;

+ (NSData *)getNetworkName:(NSString *)name sectionKey:(uint8_t *)sectionKey;

+ (NSData *)getNetworkPassword:(NSString *)password sectionKey:(uint8_t *)sectionKey;

+ (NSData *)getNetworkLtk:(NSData *)bufferData sectionKey:(uint8_t *)sectionKey __attribute((deprecated("Use the getNetworkLtk instead.")));

/// isMesh: false
+ (NSData *)getNetworkLtk:(uint8_t *)sectionKey;

+ (NSData *)getNetworkLtk:(uint8_t *)sectionKey isMesh:(BOOL)isMesh;

+ (NSData *)getNetworkConfirm:(uint8_t *)sectionKey;

#pragma mark - OTA

+ (NSData *)getOtaData:(NSData *)data index:(int)index;

+ (NSData *)getOtaEndData:(int)index;

@end
