/********************************************************************************************************
 * @file     CryptoAction.m 
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
//  CryptoAction.m
//  TelinkBlue
//
//  Created by Green on 11/15/15.
//  Copyright (c) 2015 Green. All rights reserved.
//

#import "CryptoAction.h"
#include "CryptoUtil.h"

#define random(x) (rand()%x)
#define MaxSnValue  0xffffff

//创建特定的ltkBuffer数组，[0xc0,0xc1,0xc2,0xc3,0xc4,0xc5,0xc6,0xc7,0xd8,0xd9,0xda,0xdb,0xdc,0xdd,0xde,0xf0,0x00,0x00,0x00,0x00]
#define GetLTKBuffer  \
Byte ltkBuffer[20]; \
memset(ltkBuffer, 0, 20); \
for (int j=0; j<16; j++) { \
if (j<8) { \
ltkBuffer[j] = 0xc0+j; \
}else{ \
ltkBuffer[j] = 0xd0+j; \
} \
}

static int snNo = 0;

@implementation CryptoAction

+(BOOL)getRandPro:(uint8_t *)prand Len:(int)len
{
    srand((int)time(0));
    memset(prand, 0, len);
    for (int i=0;i<len;i++)
        prand[i]=(uint8_t)random(255);
    
    return YES;
}

+(BOOL)encryptPair:(NSString *)uName Pas:(NSString *)uPas Prand:(uint8_t *)prand PResult:(uint8_t *)presult
{
    unsigned char *tmpNetworkName=(unsigned char *)[uName cStringUsingEncoding:NSUTF8StringEncoding];
    unsigned char *tmpPassword=(unsigned char *)[uPas cStringUsingEncoding:NSUTF8StringEncoding];
    
    unsigned char		pNetworkName[16];
    unsigned char		pPassword[16];
    
    memset(pNetworkName, 0, 16);
    memset(pPassword, 0, 16);
    
    memcpy(pNetworkName, tmpNetworkName, strlen((char *)tmpNetworkName));
    memcpy(pPassword, tmpPassword, strlen((char *)tmpPassword));
    
    unsigned char sk[16], d[16], r[16];
    int i;
    for (i=0; i<16; i++)
    {
        d[i] = pNetworkName[i] ^ pPassword[i];
    }
    memcpy (sk, prand, 8);
    memset (sk + 8, 0, 8);
    aes_att_encryption (sk, d, r);
    memcpy (presult, prand, 8);
    memcpy (presult+8, r, 8);
    
    if (!(memcmp (prand, presult, 16)))
        return YES;
    
    return NO;
}

+(BOOL)getSectionKey:(NSString *)uName Pas:(NSString *)uPas Prandm:(uint8_t *)prandm Prands:(uint8_t *)prands PResult:(uint8_t *)presult
{
    unsigned char *tmpNetworkName=(unsigned char *)[uName cStringUsingEncoding:NSUTF8StringEncoding];
    unsigned char *tmpPassword=(unsigned char *)[uPas cStringUsingEncoding:NSUTF8StringEncoding];
    
    unsigned char		pNetworkName[16];
    unsigned char		pPassword[16];
    
    memset(pNetworkName, 0, 16);
    memset(pPassword, 0, 16);
    
    memcpy(pNetworkName, tmpNetworkName, strlen((char *)tmpNetworkName));
    memcpy(pPassword, tmpPassword, strlen((char *)tmpPassword));
    
    unsigned char sk[16], d[16], r[16];
    int i;
    for (i=0; i<16; i++)
    {
        d[i] = pNetworkName[i] ^ pPassword[i];
    }
    memcpy (sk, prandm, 8);
    memcpy (sk + 8, prands, 8);
    aes_att_encryption (d, sk, r);
    memcpy (presult, r, 16);
    
    return YES;
}


+(BOOL)encryptionPpacket:(uint8_t *)key Iv:(uint8_t *)iv Mic:(uint8_t *)mic MicLen:(int)mic_len Ps:(uint8_t *)ps Len:(int)len
{
    uint8_t	e[16], r[16], i;
    ///////////// calculate mic ///////////////////////
    memset (r, 0, 16);
    memcpy (r, iv, 8);
    r[8] = len;
    aes_att_encryption (key, r, r);
        for (i=0; i<len; i++)
    {
        r[i & 15] ^= ps[i];
        
        if ((i&15) == 15 || i == len - 1)
        {
            aes_att_encryption (key, r, r);
        }
    }
    for (i=0; i<mic_len; i++)
    {
        mic[i] = r[i];
    }
    ///////////////// calculate enc ////////////////////////
    memset (r, 0, 16);
    memcpy (r+1, iv, 8);
    for (i=0; i<len; i++)
    {
        if ((i&15) == 0)
        {
            aes_att_encryption (key, r, e);
            r[0]++;
        }
        ps[i] ^= e[i & 15];
    }
    return YES;
}


+(BOOL)decryptionPpacket:(uint8_t *)key Iv:(uint8_t *)iv Mic:(uint8_t *)mic MicLen:(int)mic_len Ps:(uint8_t *)ps Len:(int)len
{
    uint8_t	e[16], r[16], i;
    
    ///////////////// calculate enc ////////////////////////
    memset (r, 0, 16);
    memcpy (r+1, iv, 8);
    for (i=0; i<len; i++)
    {
        if ((i&15) == 0)
        {
            aes_att_encryption (key, r, e);
            r[0]++;
        }
        ps[i] ^= e[i & 15];
    }
    
    ///////////// calculate mic ///////////////////////
    memset (r, 0, 16);
    memcpy (r, iv, 8);
    r[8] = len;
    aes_att_encryption (key, r, r);
    
    for (i=0; i<len; i++)
    {
        r[i & 15] ^= ps[i];
        
        if ((i&15) == 15 || i == len - 1)
        {
            aes_att_encryption (key, r, r);
        }
    }
    
    for (i=0; i<mic_len; i++)
    {
        if (mic[i] != r[i])
        {
            return NO;			//Failed
        }
    }
    return YES;
}


+(BOOL)getNetworkInfo:(uint8_t *)pcmd Opcode:(int)opcode Str:(NSString *)str Psk:(uint8_t *)psk
{
    unsigned char *tmpNetworkName=(unsigned char *)[str cStringUsingEncoding:NSUTF8StringEncoding];
    
    unsigned char		pNetworkName[16];
    
    memset(pNetworkName, 0, 16);
    
    memcpy(pNetworkName, tmpNetworkName, strlen((char *)tmpNetworkName));
    
    pcmd[0] = opcode;
    aes_att_encryption (psk, pNetworkName, pcmd + 1);
    return YES;
}


+(BOOL)getNetworkInfoByte:(uint8_t *)pcmd Opcode:(int)opcode Str:(uint8_t *)str Psk:(uint8_t *)psk
{
    pcmd[0] = opcode;
    aes_att_encryption (psk, str, pcmd + 1);
    return 17;
}

#pragma mark - Custom

+ (NSData *)pasterData:(NSData *)data mac:(uint32_t)mac sectionKey:(uint8_t *)sectionKey {
    
    uint8_t *buffer = (uint8_t *)data.bytes;
    int len = (int)data.length;
    
    uint8_t sec_ivm[8];
    uint32_t tempMac=mac;
    
    sec_ivm[0]=(tempMac>>0) & 0xff;
    sec_ivm[1]=(tempMac>>8) & 0xff;
    sec_ivm[2]=(tempMac>>16) & 0xff;
    
    memcpy(sec_ivm+3, buffer, 5);
    
    if (!(buffer[0]==0 && buffer[1]==0 && buffer[2]==0))
    {
        if ([CryptoAction decryptionPpacket:sectionKey Iv:sec_ivm Mic:buffer+5 MicLen:2 Ps:buffer+7 Len:13]){
            NSLog(@"decryption success.");
        }else{
            NSLog(@"decryption fail.");
        }
    }
    
    return [NSData dataWithBytes:buffer length:len];
}

+ (NSData *)exeCMD:(Byte *)cmd mac:(uint32_t)mac sectionKey:(uint8_t *)sectionKey len:(int)len {
    
    uint8_t buffer[20];
    uint8_t sec_ivm[8];
    
    memset(buffer, 0, 20);
    memcpy(buffer, cmd, len);
    memset(sec_ivm, 0,8);
    
    [self getNextSnNo];
    buffer[0]=snNo & 0xff;
    buffer[1]=(snNo>>8) & 0xff;
    buffer[2]=(snNo>>16) & 0xff;
    
    uint32_t tempMac=mac;
    
    sec_ivm[0]=tempMac & 0xff;
    sec_ivm[1]=(tempMac>>8) & 0xff;
    sec_ivm[2]=(tempMac>>16) & 0xff;
    sec_ivm[3]=(tempMac>>24) & 0xff;
    
    sec_ivm[4]=1;
    sec_ivm[5]=buffer[0];
    sec_ivm[6]=buffer[1];
    sec_ivm[7]=buffer[2];
    [CryptoAction encryptionPpacket:sectionKey Iv:sec_ivm Mic:buffer+3 MicLen:2 Ps:buffer+5 Len:15];
    return [NSData dataWithBytes:buffer length:20];
}

+ (NSData *)exeCMD:(NSData *)data mac:(uint32_t)mac sectionKey:(uint8_t *)sectionKey {
    
    return [self exeCMD:(uint8_t *)data.bytes mac:mac sectionKey:sectionKey len:(int)data.length];
}

+ (int)getNextSnNo{
    
    if (snNo == 0) {
        snNo = (rand() % 0xffffff);
    }
    
    snNo++;
    if (snNo>MaxSnValue)
        snNo=1;
    return snNo;
}

+ (NSData *)getNetworkName:(NSString *)name sectionKey:(uint8_t *)sectionKey {
    
    uint8_t buffer[20];
    memset(buffer, 0, 20);
    [self getNetworkInfo:buffer Opcode:4 Str:name Psk:sectionKey];
    
    return [NSData dataWithBytes:buffer length:20];
}

+ (NSData *)getNetworkPassword:(NSString *)password sectionKey:(uint8_t *)sectionKey {
    
    uint8_t buffer[20];
    memset(buffer, 0, 20);
    [self getNetworkInfo:buffer Opcode:5 Str:password Psk:sectionKey];
    
    return [NSData dataWithBytes:buffer length:20];
}

+ (NSData *)getNetworkLtk:(NSData *)bufferData sectionKey:(uint8_t *)sectionKey {
    
    uint8_t tempbuffer[20];
    memset(tempbuffer, 0, 20);
    GetLTKBuffer;
    memset(tempbuffer, ltkBuffer, 20);
    
    uint8_t buffer[20];
    memset(buffer, 0, 20);
    NSUInteger len = bufferData.length;
    memset(buffer, bufferData.bytes, len);
    
    [self getNetworkInfoByte:buffer Opcode:6 Str:tempbuffer Psk:sectionKey];
    return [NSData dataWithBytes:buffer length:20];
}

+ (NSData *)getNetworkLtk:(uint8_t *)sectionKey isMesh:(BOOL)isMesh {
    
    GetLTKBuffer;
    uint8_t buffer[20];
    
    [self getNetworkInfoByte:buffer Opcode:6 Str:ltkBuffer Psk:sectionKey];
    if (isMesh) {
        buffer[17] = 0x01;
    }
    return [NSData dataWithBytes:buffer length:20];
}

+ (NSData *)getNetworkConfirm:(uint8_t *)sectionKey {
    
    uint8_t buffer[20];
    memset(buffer, 0, 20);
    [self getNetworkInfo:buffer Opcode:7 Str:@"" Psk:sectionKey];
    
    return [NSData dataWithBytes:buffer length:20];
}

#pragma mark - OTA

+ (NSData *)getOtaData:(NSData *)data index:(int)index {
    
    BOOL isEnd = data.length == 0;
    int countIndex = index;
    Byte *tempBytes = (Byte *)[data bytes];
    Byte resultBytes[20];
    
    memset(resultBytes, 0xff, 20);
    memcpy(resultBytes, &countIndex, 2);
    memcpy(resultBytes+2, tempBytes, data.length);
    uint16_t crc = crc16(resultBytes, isEnd ? 2 : 18);
    memcpy(isEnd ? (resultBytes + 2) : (resultBytes+18), &crc, 2);
    NSData *writeData = [NSData dataWithBytes:resultBytes length:isEnd ? 4 : 20];
    return writeData;
}

+ (NSData *)getOtaEndData:(int)index {
    
    Byte resultBytes[4];
    
    memset(resultBytes, 0xff, 4);
    memcpy(resultBytes, &index, 2);
    uint16_t crc = crc16(resultBytes, 2);
    memcpy(resultBytes+2, &crc, 2);
    NSData *writeData = [NSData dataWithBytes:resultBytes length:4];
    return writeData;
}

extern unsigned short crc16 (unsigned char *pD, int len)
{
    static unsigned short poly[2]={0, 0xa001};              //0x8005 <==> 0xa001
    unsigned short crc = 0xffff;
    int i,j;
    for(j=len; j>0; j--)
    {
        unsigned char ds = *pD++;
        for(i=0; i<8; i++)
        {
            crc = (crc >> 1) ^ poly[(crc ^ ds ) & 1];
            ds = ds >> 1;
        }
    }
    return crc;
}

@end
