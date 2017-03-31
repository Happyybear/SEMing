//
//  HYExplainManager.m
//  HYSEM
//
//  Created by xlc on 16/11/15.
//  Copyright © 2016年 WGM. All rights reserved.
//

#import "HYExplainManager.h"
#import "DeviceModel.h"
#import "DataModel.h"
#import "DateModel.h"
@implementation HYExplainManager
{
    NSMutableArray * arr;
}
+ (id)shareManager
{
    static HYExplainManager *manager = nil;
    if (manager == nil) {
        manager = [[HYExplainManager alloc]init];

    }
    return manager;
}

+(UIButton *)createButtonWithFrame:(CGRect)frame title:(NSString *)title titleColor:(UIColor *)titleColor imageName:(NSString *)imageName backgroundImageName:(NSString *)backgroundImageName target:(id)target selector:(SEL)selector
{
    UIButton * button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = frame;
    //设置标题
    [button setTitle:title forState:UIControlStateNormal];
    //设置标题颜色
    [button setTitleColor:titleColor forState:UIControlStateNormal];
    //设置图片
    [button setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
    //设置背景图片
    [button setBackgroundImage:[UIImage imageNamed:backgroundImageName] forState:UIControlStateNormal];
    //添加点击事件
    [button addTarget:target action:selector forControlEvents:UIControlEventTouchUpInside];
    
    button.backgroundColor = [UIColor clearColor];
    
    button.selected = NO;
    return button;
}////////////////////////////////////////////////////////////////////////
////功能：Q/GDW376->1-2009报文帧校验
////参数：返回1-正确  返回0-错误
////////////////////////////////////////////////////////////////////////
static unsigned int TSR376_Checkout(unsigned char* pBuf, unsigned int nLen)
{
    unsigned int i,pt,len;
    unsigned char cs;
    //try
    //{
    
    /*  0  1  2  3  4  5   6   7  8  9  10 11 ->->->->->->-> */
    /* 68 L1 L2 L1 L2 68 ctrl A1 A2 A3 A4 A5 USERDATA CS 16 */
    
    /* 0-校验报文最小长度 */
    if(nLen<16)  return 0;
    /* 1-校验报头两个68H */
    if((pBuf[0]!=0x68)||(pBuf[5]!=0x68))
    {
        return 0;
    }
    /* 2-校验两个长度L */
    if((pBuf[1]!=pBuf[3])||(pBuf[2]!=pBuf[4]))
    {
        return 0;
    }
    /* 3-校验国网09标识 */
    if((pBuf[1]&0x02)!=0x02)
    {
        return 0;
    }
    /* 4-校验帧的完整 */
    len=(((unsigned int)pBuf[2]<<6)|(pBuf[1]>>2))+8;
    if(len>nLen)
    {
        return 0;
    }
    /* 5-校验结束符16H */
    pt=len-1;
    if(pBuf[pt]!=0x16)
    {
        return 0;
    }
    /* 6-校验CS */
    cs=0;
    pt=len-2;
    for(i=0;i<(len-8);i++)
    {
        cs+=pBuf[6+i];
    }
    if(cs!=pBuf[pt])
    {
        return 0;
    }
    /* 7-地址匹配 */
    for(i=0;i<5;i++)
    {
        ;
    }
    //}
    // catch(...)
    //{
    //  TraceMessageText("GW09_Checkout",1);
    // return 0;
    //}
    /* 校验正确 */
    return 1;
}

// Buf0[]; // 新接收的
// Buffer[4096]
// i = 0; len = 0;
// unsigned char *buf;
// for (8 < (nLen-i)) {
//    int iPos = func(&Buffer[i], nLen, buf, len)
//    if (1 == iPos)
//    {
//    // 解析
//    }else if (0 == iPos) {
//    // 存储不够长度的帧
//    }

//    // i += len;
// }

- (unsigned int)TSR376_Get_All_frame:(unsigned char *)pBuf :(int)nLen :(unsigned char *)rBuf :(int *)rLen
{
    int len, index;
    index = 0;
    while (8 < (nLen-index)) { // 接收的数据不足头部时未考虑
        if ((0x68 == pBuf[index]) && (0x68 == pBuf[index+5])) {
            //一个完整帧的长度
            len=(((unsigned int)pBuf[index+2]<<6)|(pBuf[index+1]>>2));
            unsigned int len0 = (((unsigned int)pBuf[index+4]<<6)|(pBuf[index+3]>>2));
#pragma mark --数据中有俩个相同的长度字段
            if (len != len0) {
                index+=6;
                return -2;
                // 出错
            }
            if (len+2 > (nLen-index-6)) {
                // 未接受完
                
                //copy内存
                memcpy(rBuf, &pBuf[index], nLen-index);
                *rLen = nLen-index;
//                NSMutableString *strMsg = [NSMutableString string];
//                NSString *strTemp;
//                for (int k = 0; k<*rLen; k++) {
//                    strTemp = [NSString stringWithFormat:@"%02x ",pBuf[index+k]];
//                    [strMsg appendString:[NSString stringWithFormat:@"%@",strTemp]];
//                }
//                NSLog(@"%@",strMsg);
                return 0;
            }
            rBuf = &pBuf[index];
            *rLen = len+8;
            index -= (len+8);
            return 1;
        }else{
            //NSLog(@"if");
            index++;
        }
        //NSLog(@"while");
    }
    
    return -1;

}

#pragma mark -- 得到功能AFN
- (unsigned int)TSR376_Get_AFN_Frame:(unsigned char*)pBuf
{
    unsigned int  pn[8],Fn[8],pnLen,FnLen;
    pnLen=GetPn(pBuf[14],pBuf[15],&pn[0]);
    FnLen=GetFn(pBuf[16],pBuf[17],&Fn[0]);
    if (pBuf[12] == 0x00) {
        switch (Fn[0]) {
            case 1:
                //全部确认
                return 0;
                break;
            case 2:
                //全部否认
                return 1;
                break;
            case 3:
                //数据单元标识确认和否认:对收到报文中的全部数据单元标识进行逐个确认/否认
                return 2;
                break;
            case 4:
                //验证码过期否认
                return 3;
                break;
            case 9:
                //用户验证ID
                return 4;
                break;
            default:
                break;
        }
    }else if (pBuf[12] == 0x12){
        switch (Fn[0]) {
            case 1:
                //用户档案
                return 5;
                break;
            case 2:
                //群档案
                return 6;
                break;
            case 3:
                //单位档案
                return 7;
                break;
            case 4:
                //线路档案
                return 8;
                break;
            case 5:
                //站档案
                return 9;
                break;
            case 6:
                //终端档案
                return 10;
                break;
            case 7:
                //组档案
                return 11;
                break;
            case 8:
                //设备档案
                return 12;
                break;
            default:
                break;
        }
    }else if (pBuf[12] == 0x0D){
        //请求2类数据
        return 13;
    }
    
    return 0;
}


static Byte GetPn(Byte data1,Byte data2,unsigned int *pBuf)
{
    Byte i,j;
    Byte m[8];
    unsigned int  base;
    
    i=0;
    j=0;
    base=(data2-1)*8;
    
    if(data1==0x00&&data2==0x00)
    { pBuf[i]=0;return 1;}
    else
    {
        for(i=1;i<=8;i++)
        {
            if(data1&0x01)
            {m[j]=i;j++;}
            data1=data1>>1;
        }
        for(i=0;i<8;i++)
            pBuf[i]=base+m[i];
    }
    return j;
}

/**
 * @brief  Get Fn
 * @param  data1 data2 *pBuf
 * @retval *pBuf data len
 */
static Byte GetFn(Byte data1,Byte data2,unsigned int *pBuf)
{
    Byte i,j;
    Byte m[8];
    unsigned int  base;
    
    i=0;
    j=0;
    
    base=data2*8;
    
    if(data1==0x00&&data2==0x00)
    { pBuf[i]=0;return 1;}
    else
    {
        for(i=1;i<=8;i++)
        {
            if(data1&0x01)
            {m[j]=i;j++;}
            data1=data1>>1;
        }
        for(i=0;i<8;i++)
            pBuf[i]=base+m[i];
    }
    return j;
}

void static SetFn(unsigned int * pData,unsigned char len,unsigned char *data1,unsigned char *data2)
{
    unsigned char n,m;
    int i;
    
    m=0;
    m=0;
    
    if(pData[0]%8==0)
    {
        *data2=pData[0]/8-1;
        *data1=0x80;
    }
    else
    {
        *data2=pData[0]/8;
        for(i=0;i<len;i++)
        {
            if (pData[i] % 8 != 0)
                n=pData[i]%8-1;
            else
                n=7;
            m|=(0x01<<n);
        }
        *data1=m;
    }
    return ;
}
void static Setpn(unsigned int * pData,unsigned char len,unsigned char *data1,unsigned char *data2)
{
    
    unsigned char n,m;
    int i;
    
    m=0;
    n=0;
    
    if(pData[0]%8==0)
    {
        *data2=pData[0]/8;
        *data1=0x80;
    }
    else
    {
        *data2=pData[0]/8+1;
        for(i=0;i<len;i++)
        {
            if (pData[i] % 8 != 0)
                n=pData[i]%8-1;
            else
                n=7;
            m|=(0x01<<n);
        }
        *data1=m;
    }
}


//////////////////////////////////////////////////////////////////////
//功能：Q/GDW376->1-2009报文帧校验
//参数：返回1-正确  返回0-错误
//////////////////////////////////////////////////////////////////////
- (unsigned int)GW09_Checkout:(unsigned char*)pBuf :(unsigned int)nLen
{
    unsigned int i,pt,len;
    unsigned char cs;
    //try
    //{
    /*  0  1  2  3  4  5   6   7  8  9  10 11 ->->->->->->-> */
    /* 68 L1 L2 L1 L2 68 ctrl A1 A2 A3 A4 A5 USERDATA CS 16 */
    
    /* 0-校验报文最小长度 */
    if(nLen<16)  return 0;
    /* 1-校验报头两个68H */
    if((pBuf[0]!=0x68)||(pBuf[5]!=0x68))
    {
        return 0;
    }
    /* 2-校验两个长度L */
    if((pBuf[1]!=pBuf[3])||(pBuf[2]!=pBuf[4]))
    {
        return 0;
    }
    /* 3-校验国网09标识 */
    if((pBuf[1]&0x02)!=0x02)
    {
        return 0;
    }
    /* 4-校验帧的完整 */
    len=(((unsigned int)pBuf[2]<<6)|(pBuf[1]>>2))+8;
    if(len>nLen)
    {
        return 0;
    }
    /* 5-校验结束符16H */
    pt=len-1;
    if(pBuf[pt]!=0x16)
    {
        return 0;
    }
    /* 6-校验CS */
    cs=0;
    pt=len-2;
    for(i=0;i<(len-8);i++)
    {
        cs+=pBuf[6+i];
    }
    if(cs!=pBuf[pt])
    {
        return 0;
    }
    /* 7-地址匹配 */
    for(i=0;i<5;i++)
    {
        ;
    }
    //}
    // catch(...)
    //{
    //  TraceMessageText("GW09_Checkout",1);
    // return 0;
    //}
    /* 校验正确 */
    return 1;
}

int static BYTEToInt(Byte *In_Data)
{
    int value = 0;
    NSMutableString *string = [NSMutableString stringWithFormat:@"%.2x",In_Data[3]];
    [string appendFormat:@"%.2x",In_Data[2]];
    [string appendFormat:@"%.2x.",In_Data[1]];
    [string appendFormat:@"%.2x",In_Data[0]];
    value = [string intValue];
    return value;
}

int static BYTEToINT(Byte *In_Data)
{
    int value = 0;
    value = (int)((int)(In_Data[0] & 0xFF)
                  | ((int)(In_Data[1] & 0xFF) << 8)
                  | ((int)(In_Data[2] & 0xFF) << 16)
                  | ((int)(In_Data[3] & 0xFF) << 24)
                  );
    
    return value;
}
void static INTToBYTE(int value,Byte *Out_Data)
{
    Out_Data[0] = (Byte)(value&0xFF);
    Out_Data[1] = (Byte)((value>>8)&0xFF);
    Out_Data[2] = (Byte)((value>>16)&0xFF);
    Out_Data[3] = (Byte)((value>>24)&0xFF);
}

static UInt64 BYTEToUINT64(Byte *In_Data)
{
    UInt64  value = 0;
    value = (UInt64)((UInt64)(In_Data[0] & 0xFF)
                     | ((UInt64)(In_Data[1] & 0xFF) << 8)
                     | ((UInt64)(In_Data[2] & 0xFF) << 16)
                     | ((UInt64)(In_Data[3] & 0xFF) << 24)
                     | ((UInt64)(In_Data[4] & 0xFF) << 32)
                     | ((UInt64)(In_Data[5] & 0xFF) << 40)
                     | ((UInt64)(In_Data[6] & 0xFF) << 48)
                     | ((UInt64)(In_Data[7] & 0xFF) << 56)
                     ); 
    
    return value;  
}

/**
 * 将UINT64数值转换为占8个字节的byte数组，本方法适用于(低位在前，高位在后)的顺序。 和BYTEToUINT64（）配套使用
 * @param value
 *            要转换的UINT64值
 * @return byte数组
 */
void UINT64ToBYTE(UInt64 value,Byte *Out_Data)
{
    Out_Data[0] = (Byte)(value&0xFF);
    Out_Data[1] = (Byte)((value>>8)&0xFF);
    Out_Data[2] = (Byte)((value>>16)&0xFF);
    Out_Data[3] = (Byte)((value>>24)&0xFF);
    Out_Data[4] = (Byte)((value>>32)&0xFF);
    Out_Data[5] = (Byte)((value>>40)&0xFF);
    Out_Data[6] = (Byte)((value>>48)&0xFF);
    Out_Data[7] = (Byte)((value>>56)&0xFF);
}

int intTobcd(int num)
{
    int bcdout = 0 ;
    if(num > 99999999)
        return 0 ;
    
    int temp = num ;
    bcdout = bcdout + (temp/10000000 << 28) ;
    temp = temp % 10000000 ;
    
    bcdout = bcdout + (temp/1000000 << 24) ;
    temp = temp % 1000000 ;
    
    bcdout = bcdout + (temp/100000 << 20) ;
    temp = temp % 100000 ;
    
    bcdout = bcdout + (temp/10000 << 16) ;
    temp = temp % 10000 ;
    
    bcdout = bcdout + (temp/1000 << 12) ;
    temp = temp % 1000 ;
    
    bcdout = bcdout + (temp/100 << 8) ;
    temp = temp % 100 ;
    
    bcdout = bcdout + (temp/10 << 4) ;
    bcdout = bcdout + temp % 10 ;
    
    NSLog(@"%d",bcdout);
    return bcdout;
}


unsigned char BCDToHex(int tt)
{
    unsigned char hex;
    unsigned int h;
    unsigned int l;
    
    h = tt / 10;
    l = tt % 10;
    
    hex = h * 16 + l;
    
    return hex;
}


/*
 功能：把终端地址字符串转换为5个字节
 */

- (Byte *)TerminalAddrToByte:(NSString *)string
{
    // NSString --> hex
    //NSString *string = @"1a1b1c1d";
    const char *buf = [string UTF8String];
    NSMutableData *data = [NSMutableData data];
    if (buf)
    {
        uint32_t len = strlen(buf);
        
        char singleNumberString[3] = {'\0', '\0', '\0'};
        uint32_t singleNumber = 0;
        for(uint32_t i = 0 ; i < len; i+=2)
        {
            if ( ((i+1) < len) && isxdigit(buf[i]) && (isxdigit(buf[i+1])) )
            {
                singleNumberString[0] = buf[i];
                singleNumberString[1] = buf[i + 1];
                sscanf(singleNumberString, "%x", &singleNumber);
                uint8_t tmp = (uint8_t)(singleNumber & 0x000000FF);
                [data appendBytes:(void *)(&tmp)length:1];
            }
            else
            {
                break;
            }
        }
    }
    Byte *dataByte = NULL;
    Byte *bytes = (Byte *)[data bytes];
    dataByte[2] = bytes[4];
    dataByte[3] = bytes[3];
    dataByte[0] = bytes[2];
    dataByte[1] = bytes[1];
    dataByte[4] = bytes[0];
    return dataByte;
    
}

int TerminalAddrToByte(NSString *str,Byte *OutBuf)
{
    OutBuf[2] = BCDToHex([[str substringWithRange:NSMakeRange(8, 2)]intValue]);
    OutBuf[3] = BCDToHex([[str substringWithRange:NSMakeRange(6, 2)] intValue]);
    OutBuf[0] = BCDToHex([[str substringWithRange:NSMakeRange(4, 2)] intValue]);
    OutBuf[1] = BCDToHex([[str substringWithRange:NSMakeRange(2, 2)] intValue]);
    OutBuf[4] = (Byte)2;
    return 5;
}


void ByteToTerminalAddr(Byte *InBuf,NSMutableString **string)
{
    *string = [NSMutableString stringWithFormat:@"%.2x",InBuf[4]];
    //[*string appendFormat:@"%.2x",InBuf[4]];
    [*string appendFormat:@"%.2x",InBuf[1]];
    [*string appendFormat:@"%.2x",InBuf[0]];
    [*string appendFormat:@"%.2x",InBuf[3]];
    [*string appendFormat:@"%.2x",InBuf[2]];

}


void ByteToAckTerminalAddr(Byte *InBuf,NSMutableString **string)
{
    *string = [NSMutableString stringWithFormat:@"%.2x",InBuf[0]];
    //[*string appendFormat:@"%.2x",InBuf[4]];
    [*string appendFormat:@"%.2x",InBuf[1]];
    [*string appendFormat:@"%.2x",InBuf[2]];
    [*string appendFormat:@"%.2x",InBuf[3]];
    [*string appendFormat:@"%.2x",InBuf[4]];
    
}
/*
 功能：把SIM字符串转换为11个字节
 */
int SIMToByte(NSString *str,Byte *OutBuf)
{
    const char *buf = [str UTF8String];
    NSMutableData *data = [NSMutableData data];
    if (buf)
    {
        uint32_t len = strlen(buf);
        
        char singleNumberString[3] = {'\0', '\0', '\0'};
        uint32_t singleNumber = 0;
        for(uint32_t i = 0 ; i < len; i+=2)
        {
            if ( ((i+1) < len) && isxdigit(buf[i]) && (isxdigit(buf[i+1])) )
            {
                singleNumberString[0] = buf[i];
                singleNumberString[1] = buf[i + 1];
                sscanf(singleNumberString, "%x", &singleNumber);
                uint8_t tmp = (uint8_t)(singleNumber & 0x000000FF);
                [data appendBytes:(void *)(&tmp)length:1];
            }
            else
            {
                break;
            }
        }
    }
    Byte *bytes = (Byte *)[data bytes];
    for (int i = 1; i<11; i++) {
        OutBuf[i] = 48 + bytes[10-i];
    }
    return 11;
}

//- (NSString *)ByteToSIM:(Byte *)InBuf
//{
//    NSMutableString *string = [NSMutableString stringWithFormat:@"%.2x",InBuf[10]];
//    NSLog(@"%@",string);
//    for (int i=0;i<10;i++)
//    {
//        [string appendFormat:@"%.2x",InBuf[9-i]];
//    }
//    NSLog(@"%@",string);
//    return string;
//}


void ByteToSIM(Byte *InBuf,NSMutableString *str)
{
    for (int i=0;i<10;i++)
    {
        [str appendFormat:@"%.2x",InBuf[9-i]];
    }

}

/*
 功能:字符串转NSData
 */
void strToData(NSString *str,NSMutableData *data)
{
    const char *buf = [str UTF8String];
    if (buf)
    {
        uint32_t len = strlen(buf);
        
        char singleNumberString[3] = {'\0', '\0', '\0'};
        uint32_t singleNumber = 0;
        for(uint32_t i = 0 ; i < len; i+=2)
        {
            if ( ((i+1) < len) && isxdigit(buf[i]) && (isxdigit(buf[i+1])) )
            {
                singleNumberString[0] = buf[i];
                singleNumberString[1] = buf[i + 1];
                sscanf(singleNumberString, "%x", &singleNumber);
                uint8_t tmp = (uint8_t)(singleNumber & 0x000000FF);
                [data appendBytes:(void *)(&tmp)length:1];
            }
            else
            {
                break;
            }
        }
    }

}



 //功能：把IP字符串转换为4个字节 192.168.001.015==> 15 1 168 192

//int IPToByte(NSString *str,Byte *OutBuf)
//{
//    NSArray *arr = [str componentsSeparatedByString:@"."];
//    OutBuf[0] = (Byte)[arr[3] integerValue];
//    OutBuf[1] = (Byte)[arr[2] integerValue];
//    OutBuf[2] = (Byte)[arr[1] integerValue];
//    OutBuf[3] = (Byte)[arr[0] integerValue];
//    return 4;
//}
//
void ByteToIP(Byte *InBuf,NSMutableString **str)
{
    [*str appendFormat:@"%d",InBuf[3]];
    [*str appendFormat:@"%d",InBuf[2]];
    [*str appendFormat:@"%d",InBuf[1]];
    [*str appendFormat:@"%d",InBuf[0]];
}
//
//
//
//// 功能：12 字符的字符串和6个字节 转换
//int str12To6Byte(NSString  *str,Byte *OutBuf)
//{
//    OutBuf[0] = BCDToHex(atoi(str->Right(2)));
//    OutBuf[1] = BCDToHex(atoi(str->Mid(8,2)));
//    OutBuf[2] = BCDToHex(atoi(str->Mid(6,2)));
//    OutBuf[3] = BCDToHex(atoi(str->Mid(4,2)));
//    OutBuf[4] = BCDToHex(atoi(str->Mid(2,2)));
//    OutBuf[5] = BCDToHex(atoi(str->Left(2)));
//    return 6;
//}
void Byte6To12str(Byte *InBuf,NSMutableString **str)
{
    [*str appendFormat:@"%.2x",InBuf[5]];
    [*str appendFormat:@"%.2x",InBuf[4]];
    [*str appendFormat:@"%.2x",InBuf[3]];
    [*str appendFormat:@"%.2x",InBuf[2]];
    [*str appendFormat:@"%.2x",InBuf[1]];
    [*str appendFormat:@"%.2x",InBuf[0]];
}

//判断字符串是否包含0~9的字符
BOOL isPureInt(NSString *string)
{
    NSScanner* scan = [NSScanner scannerWithString:string];
    int val;
    return [scan scanInt:&val] && [scan isAtEnd];
}


////*********************************************************************************************************
//#include <boost/locale.hpp>
/*
 功能： 字符串转成 UTF8字节
 str： 要转的字符串
 OutBuf：转好后的缓冲区
 返回：非零：转成的缓冲区的长度
 0：转换失败
 */
int CStringAToUTF8(NSString *str,Byte *OutBuf)
{
    //std::string uft8= std::locale::conv::to_utf<char>(str,"GBK");
    //CStringA strA=uft8.c_str();
    return CStringToBYTE(str,OutBuf);
    //return strA;
}

int CStringToBYTE(NSString *strData,Byte *Out_Data)
{
    //Byte _nameBuf[100];
    int index = 0;
    NSStringEncoding enc = CFStringConvertEncodingToNSStringEncoding(NSUTF16BigEndianStringEncoding);
    NSData *data = [strData dataUsingEncoding:enc];
    Byte *byte = (Byte *)[data bytes];
    int b = -1;
    for (int i = 0; i<[data length]; i++) {
        if (i%2 == 1) {
            b++;
            index++;
            Out_Data[b] = byte[i];
        }
    }
    b++;
//    const char *ch;
//    int j,m_nlen;
//    m_nlen = sizeof(strData)-1;
//    NSString *a=[strData substringFromIndex:m_nlen];
//    ch = [a UTF8String];
//    for(j=0;j<m_nlen;j++)
//    {
//        Out_Data[j]=ch[j];//单位名称
//    }
    Out_Data[b++] = '\0';
    return b;
}

/*
 功能：  UTF8字节 转换成字符串
 InBuf： 要转的字符串缓冲区
 Inlen： 要转换的缓冲长度
 返回：非空： 转换好后的字符串
 空：   转换失败
 */


void UTF8ToCStringA(Byte *InBuf,int Inlen,NSString **str_Out )
{
    NSStringEncoding enc = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
    NSData *nameData = [NSData dataWithBytes:InBuf length:Inlen];
    *str_Out = [[NSString alloc]initWithData:nameData encoding:enc];
    
}

-(NSData*)stringToByte:(NSString*)string
{
    NSString *hexString=[[string uppercaseString] stringByReplacingOccurrencesOfString:@" " withString:@""];
    if ([hexString length]%2!=0) {
        return nil;
    }
    Byte tempbyt[1]={0};
    NSMutableData* bytes=[NSMutableData data];
    for(int i=0;i<[hexString length];i++)
    {
        unichar hex_char1 = [hexString characterAtIndex:i]; ////两位16进制数中的第一位(高位*16)
        int int_ch1;
        if(hex_char1 >= '0' && hex_char1 <='9')
            int_ch1 = (hex_char1-48)*16;   //// 0 的Ascll - 48
        else if(hex_char1 >= 'A' && hex_char1 <='F')
            int_ch1 = (hex_char1-55)*16; //// A 的Ascll - 65
        else
            return nil;
        i++;
        
        unichar hex_char2 = [hexString characterAtIndex:i]; ///两位16进制数中的第二位(低位)
        int int_ch2;
        if(hex_char2 >= '0' && hex_char2 <='9')
            int_ch2 = (hex_char2-48); //// 0 的Ascll - 48
        else if(hex_char2 >= 'A' && hex_char2 <='F')
            int_ch2 = hex_char2-55; //// A 的Ascll - 65
        else
            return nil;
        
        tempbyt[0] = int_ch1+int_ch2;  ///将转化后的数放入Byte数组里
        [bytes appendBytes:tempbyt length:1];
    }
    return bytes;
}


//组帧过程中添加帧头帧尾
static unsigned int  TSRGW2015_ADDFrameStartEnd1(unsigned char *m_Inaddr,unsigned char *OutBufData,unsigned nlen)
{
    
    unsigned int len,k;
    
    OutBufData[7] = m_Inaddr[0];
    OutBufData[8] = m_Inaddr[1];
    OutBufData[9] = m_Inaddr[2];
    OutBufData[10] = m_Inaddr[3];
    OutBufData[11] = 0x02;
    
    OutBufData[nlen]=0;
    len = nlen-6;
    for(k=0;k<len;k++)
    {
        OutBufData[nlen]+=OutBufData[6+k];
    }
    nlen++;
    OutBufData[nlen++]=0x16;
    len=nlen-8;
    OutBufData[0] =0x68;
    OutBufData[1] =(len<<2)|0x02;
    OutBufData[2] =len>>6;
    OutBufData[3] =(len<<2)|0x02;
    OutBufData[4] =len>>6;
    OutBufData[5] =0x68; 
    return nlen;
}

//手机app外层帧
int TSRAPP_ADDFrameStartEnd(Byte * fame_buf,int len,Byte fame_type,UInt64 usr_id)
{
    int i = 0;
    Byte cs = 0;
    fame_buf[i++] = 0xAA;
    fame_buf[i++] = (Byte)(len & 0xFF);
    fame_buf[i++] = (Byte)((len>>8) & 0xFF);
    fame_buf[i++] =  fame_type;
    UINT64ToBYTE(usr_id,&fame_buf[i]);//生成用户id
    i += 8;
    
    for (int j = 0; j < 7; j ++)
    {
        cs += fame_buf[1+j];
    }
    
    fame_buf[i++] = cs;
    fame_buf[i++] = 0xAA;
    fame_buf[i+len] = 0x16;
    
    return (i + len + 1);
    
}

//登录
- (int)TSR376_Get_Land_Fame:(unsigned char *)m_Inaddr :(NSString *)strUsrName :(NSString *)strUsrPW :(unsigned char*)OutBufData
{
    int len;
    unsigned int Fn=1;
    //Byte * Buf;
    unsigned char* Buf;
    Buf = &OutBufData[14];//前面14个值用来加入app层的规约
    
    Buf[6] =0x49;    //控制域
    Buf[12]=0x02;    //AFN登录时位线路检测
    Buf[13]=0x60;    //SEQ
    len = 14;
    Buf[len++] = 0;
    Buf[len++] = 0;
    //上面两个buf是数据单元标识即Pn
    SetFn(&Fn,1,&Buf[len],&Buf[len+1]);
    len += 2;
    
    int n = 2,strlen;
    
    strlen = CStringAToUTF8(strUsrName,&Buf[len+n+1]);
    Buf[len+n] = strlen;
    n += (strlen + 1);
    strlen = CStringAToUTF8(strUsrPW,&Buf[len+n+1]);
    Buf[len+n] = strlen;
    n += (strlen + 1);
    //这里n表示用户名密码的登录模块如0c 00     01 33 31 36 00       04 33 31 36 00
    Buf[len+n] = 0x00;//判定终端是APP还是PC
    Buf[len] = (Byte)(n & 0xFF);//buf[14]SEQ
    Buf[len+1] = (Byte)((n>>8) & 0xFF);
    len += n;
//   这里len是TSR应用数据的长度但和结束字符
    len = TSRGW2015_ADDFrameStartEnd1(m_Inaddr,Buf,len+1);
    len = TSRAPP_ADDFrameStartEnd(OutBufData,len,0,0);
    
    return len;
}

- (int)TSR376_Analysis_Land_return:(unsigned char *)in_bufer :(int)bufer_len
{
    unsigned int i,len;
    
    if(!TSR376_Checkout(in_bufer,bufer_len))
    {
        //错误帧
        return 1;
    }
    len=((unsigned int)in_bufer[2]<<6)|(in_bufer[1]>>2);
    if(in_bufer[12] != 0x00)
    {
        //AFN错误
        return 2;
    }
    //判断附加域中是否带事件计数器
#warning <#message#>
    if (in_bufer[6] & 0x20)//控制域
    {
        len -= 2;
    }
    
    if(in_bufer[13]&0x80)//SEQ
    {
        len -= 6;
    }
    i = 14;
    if((in_bufer[i] == 0)&&(in_bufer[i+1] ==0)&&(in_bufer[i+3] ==0x01)&&(in_bufer[i+2] &0x01))//登录确认帧
    {
        i += 4;
        UInt64 UserID = BYTEToUINT64(&in_bufer[i]);
        i += 8;
        Byte UserType = in_bufer[i++];
        i += 1;
        UInt64 Check_ID = BYTEToINT(&in_bufer[i]);
        i += 8;
        HYUserModel *model = [[HYUserModel alloc]init];
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        Byte out_data[8];
        UINT64ToBYTE(Check_ID, out_data);
        [defaults setObject:[NSData dataWithBytes:out_data length:sizeof(out_data)] forKey:@"sureID"];
        [defaults synchronize];
        model.user_ID = UserID;         //userID
        model.check_ID = Check_ID;      //checkID
        model.user_type = UserType;     //用户类型
        HYSingleManager *manager = [HYSingleManager sharedManager];
        manager.user = model;
        
    }else if((in_bufer[i] == 0)&&(in_bufer[i+1] ==0)&&(in_bufer[i+3] ==0x00)&&(in_bufer[i+2] &0x01))//普通确认帧
    {
        return 3;
    }else if((in_bufer[i] == 0)&&(in_bufer[i+1] ==0)&&(in_bufer[i+3] ==0x00)&&(in_bufer[i+2] &0x02))//否认帧
    {
        //否认帧
        return 4;
    }
    
    return 0;
}


//获取用户信息
#pragma mark --获取用户信息
- (int)TSR376_GetACK_UsrInfFame:(unsigned char *)m_Inaddr :(UInt64)Usr_ID :(UInt64)Usr_checkID :(unsigned char *)OutBufData
{
    int len;
    unsigned int Fn=1;
    unsigned int Pn[1]={5};
    Byte * Buf;
    Buf = &OutBufData[14];
    Buf[6] =0x4B;    //Ctrl
    Buf[12]=0x12;    //APN
    Buf[13]=0x60;    //SEQ
    len = 14;
    Setpn(&Pn[0],1,&Buf[len],&Buf[len+1]);
    len += 2;
    SetFn(&Fn,1,&Buf[len],&Buf[len+1]);
    len += 2;
    UINT64ToBYTE(Usr_ID,&Buf[len]);//数据单元存储
    len += 8;
    len = TSRGW2015_ADDFrameStartEnd1(m_Inaddr,Buf,len);
    len = TSRAPP_ADDFrameStartEnd(OutBufData,len,3,Usr_checkID);
    return len;
}

- (int)TSR376_Analysis_UsrInf:(unsigned char *)in_bufer :(int)bufer_len :(UInt64)Usr_ID :(int)iEnd
{
    unsigned int i,nLen;
    Byte frin,*pBuf;
    unsigned int  pn[8],Fn[8],pnLen,FnLen,n,m;
    if(!TSR376_Checkout(in_bufer,bufer_len))
    {
        return 1;
    }
    
    nLen=((unsigned int)in_bufer[2]<<6)|(in_bufer[1]>>2);
    //判断附加域中是否带事件计数器
    if (in_bufer[6] & 0x20)
    {
        nLen -= 2;
    }
    if (0x12 != in_bufer[12])
    {
        return 6;
    }
    //判断是否多帧
    frin = in_bufer[13];
    switch(frin&0x60)
    {
        case  0x00:
        case	0x40:
            iEnd = 1;
            break;
        case	0x20:
        case	0x60:
            iEnd = 0;
            break;
        default:
            return -3;
    }
    //判断是否有时间标签
    if(frin&0x80)
    {
        nLen -= 6;
    }
    
    pBuf=&in_bufer[14];
    for(i=0;i<(nLen-8);)
    {
        //获取数据类型
        pnLen=GetPn(pBuf[i],pBuf[i+1],&pn[0]);
        FnLen=GetFn(pBuf[i+2],pBuf[i+3],&Fn[0]);
        i+=4;
        if ((1!=FnLen)||(1 != Fn[0]))
        {
            return 2;
        }
        UInt64 UserID = BYTEToUINT64(&pBuf[i]);
        i += 8;
        if (Usr_ID != UserID)
        {
            return 3;
        }
        int datalen = (unsigned int)(pBuf[i]&0xFF)|((unsigned int)((pBuf[i+1]&0xFF)<<8));
        i += 2;
        HYSingleManager *manager = [HYSingleManager sharedManager];
        HYUserModel *user = [[HYUserModel alloc]init];
        for (n=0;n<pnLen;n++)
        {
            switch(pn[n])//判断Pn
            {
                case 5:
                {
                    
                    UInt64 Obj_ID = 0;
                    Byte str_len = 0;
                    NSString *strName;
                    m = (unsigned int)(pBuf[i]&0xFF)|((unsigned int)((pBuf[i+1]&0xFF)<<8));
                    i += 2;
                    NSMutableArray *arr = [NSMutableArray array];
                    for (unsigned int j=0;j<m;j++)
                    {
                        Obj_ID = BYTEToUINT64(&pBuf[i]);
                        i += 8;
                        str_len = pBuf[i++];
                        UTF8ToCStringA(&pBuf[i],str_len,&strName);
                        i += str_len;
                        [arr addObject:[NSString stringWithFormat:@"%llu",Obj_ID]];
//                        NSString * a2 = [NSString stringWithFormat:@"%llu",Obj_ID];
                    }
                    user.children = [NSMutableArray arrayWithArray:arr];
                    break;
                }
                default:
                {
                    return 4;
                }
                
            }
        }
#pragma mark  --存储初始化
        manager.obj_dict = [NSMutableDictionary dictionary];
        [manager.obj_dict setObject:user forKey:[NSString stringWithFormat:@"%llu",UserID]];
    }
    return 0;
}


//获取单位信息
- (int)TSR376_GetACK_CompanyInfFame:(unsigned char *)m_Inaddr Company_ID:(UInt64)Company_ID Usr_checkID:(UInt64)Usr_checkID OutBufData:(unsigned char *)OutBufData
{
    int len;
    unsigned int Fn=3;
    unsigned int Pn[6]={1,2,4,5,6,7};
    Byte * Buf;
    Buf = &OutBufData[14];
    Buf[6] =0x4B;    //Ctrl
    Buf[12]=0x12;    //APN
    Buf[13]=0x60;    //SEQ
    len = 14;
    Setpn(&Pn[0],6,&Buf[len],&Buf[len+1]);
    len += 2;
    SetFn(&Fn,1,&Buf[len],&Buf[len+1]);
    len += 2;
    UINT64ToBYTE(Company_ID,&Buf[len]);
    len += 8;
    len = TSRGW2015_ADDFrameStartEnd1(m_Inaddr,Buf,len);
    len = TSRAPP_ADDFrameStartEnd(OutBufData,len,3,Usr_checkID);
    return len;
}
-(int)TSR376_Analysis_CompanyInf:(unsigned char *)in_bufer bufer_len:(int)bufer_len Company_ID:(UInt64)Company_ID iEnd:(int)iEnd
{
    unsigned int i,nLen;
    Byte frin,*pBuf;
    unsigned int  pn[8],Fn[8],pnLen,FnLen,n,m;
    if(!TSR376_Checkout(in_bufer,bufer_len))
    {
        return 1;
    }
    if (0x12 != in_bufer[12])
    {
        return 6;
    }
    nLen=((unsigned int)in_bufer[2]<<6)|(in_bufer[1]>>2);
    //判断附加域中是否带事件计数器
    if (in_bufer[6] & 0x20)
    {
        nLen -= 2;
    }
    
    //判断是否多帧
    frin = in_bufer[13];
    switch(frin&0x60)
    {
        case  0x00:
        case	0x40:
            iEnd = 1;
            break;
        case	0x20:
        case	0x60:
            iEnd = 0;
            break;
        default:
            return -3;
    }
    //判断是否有时间标签
    if(frin&0x80)
    {
        nLen -= 6;
    }
    
    pBuf=&in_bufer[14];
    HYSingleManager *manager = [HYSingleManager sharedManager];
    CCompanyModel *company = [[CCompanyModel alloc]init];
    for(i=0;i<(nLen-8);)
    {
        //获取数据类型
        pnLen=GetPn(pBuf[i],pBuf[i+1],&pn[0]);
        FnLen=GetFn(pBuf[i+2],pBuf[i+3],&Fn[0]);
        i+=4;
        if ((1!=FnLen)||(3 != Fn[0]))
        {
            return 2;
        }
        UInt64 ID = BYTEToUINT64(&pBuf[i]);
        i += 8;
//        if (Company_ID != ID)
//        {
//            return 3;
//        }
        int datalen = (unsigned int)(pBuf[i]&0xFF)|((unsigned int)((pBuf[i+1]&0xFF)<<8));//单位单元数据块长度
        i += 2;
        for (n=0;n<pnLen;n++)
        {
            switch(pn[n])
            {
                case 1://单位ID
                {
                    UInt64 company_ID = BYTEToUINT64(&pBuf[i]);
                    company.strID = company_ID;
                    i += 8;
                    break;
                }
                case 2://单位名字
                {
                    NSString *strName;
                    Byte str_len = 0 ;
                    str_len = pBuf[i++];
//                    int a = (Byte*)pBuf[24];
                    UTF8ToCStringA(&pBuf[i],str_len,&strName);
                    i += str_len;
                    company.name = strName;
                    break;
                }
                case 3://所属群ID
                {
                    UInt64 Group_ID = BYTEToUINT64(&pBuf[i]);
                    i += 8;

                    break;
                }
                case 4://界面显示位置
                {
                    int UI_ID = BYTEToINT(&pBuf[i]);
                    i += 4;
                    
                    break;
                }
                case 5: //单位下线路
                {
                    UInt64 Obj_ID = 0;
                    Byte str_len = 0;
                    NSString *strName;
                    m = (unsigned int)(pBuf[i]&0xFF)|((unsigned int)((pBuf[i+1]&0xFF)<<8));
                    i += 2;
                    NSMutableArray *array = [NSMutableArray array];
                    for (unsigned int j=0;j<m;j++)
                    {
                        Obj_ID = BYTEToUINT64(&pBuf[i]);
                        i += 8;
                        str_len = pBuf[i++];
                        UTF8ToCStringA(&pBuf[i],str_len,&strName);
                        i += str_len;
                        [array addObject:[NSString stringWithFormat:@"%llu",Obj_ID]];
                    }
                    company.children = [NSMutableArray arrayWithArray:array];
                    break;
                }
                case 6: //单位下站(终端)
                {
                    UInt64 Obj_ID = 0;
                    Byte str_len = 0;
                    NSString *strName;
                    m = (unsigned int)(pBuf[i]&0xFF)|((unsigned int)((pBuf[i+1]&0xFF)<<8));
                    i += 2;
                    NSMutableArray *array = [NSMutableArray array];
                    for (unsigned int j=0;j<m;j++)
                    {
                        Obj_ID = BYTEToUINT64(&pBuf[i]);
                        i += 8;
                        str_len = pBuf[i++];
                        UTF8ToCStringA(&pBuf[i],str_len,&strName);
                        i += str_len;
                        [array addObject:[NSString stringWithFormat:@"%llu",Obj_ID]];
                    }
                    company.children1 = [NSMutableArray arrayWithArray:array];
                    break;
                }
                case 7: //单位下 终端
                {
                    UInt64 Obj_ID = 0;
                    Byte str_len = 0;
                    NSString *strName;
                    m = (unsigned int)(pBuf[i]&0xFF)|((unsigned int)((pBuf[i+1]&0xFF)<<8));
                    i += 2;
                    for (unsigned int j=0;j<m;j++)
                    {
                        Obj_ID = BYTEToUINT64(&pBuf[i]);
                        i += 8;
                        str_len = pBuf[i++];
                        UTF8ToCStringA(&pBuf[i],str_len,&strName);
                        i += str_len;
                        
                        
                    }
                    
                    break;
                }
                default:
                {
                    return 4;
                }
            }
        }
    }
    [manager.obj_dict setObject:company forKey:[company UInt64ToString:company.strID]];
    return 0;
}

//获取线路信息
- (int)TSR376_GetACK_LineInfFame:(unsigned char *)m_Inaddr Company_ID:(UInt64)Company_ID Line_ID:(UInt64)Line_ID Usr_check_ID:(UInt64)Usr_checkID OutBufData:(unsigned char *)OutBufData
{
    int len;
    unsigned int Fn=4;
    unsigned int Pn[4]={1,2,5,8};
    Byte * Buf;
    Buf = &OutBufData[14];
    Buf[6] =0x4B;    //Ctrl
    Buf[12]=0x12;    //APN 
    Buf[13]=0x60;    //SEQ
    len = 14;
    Setpn(&Pn[0],4,&Buf[len],&Buf[len+1]);
    len += 2;
    SetFn(&Fn,1,&Buf[len],&Buf[len+1]);
    len += 2;
    
    UINT64ToBYTE(Company_ID,&Buf[len]);
    len += 8;
    
    UINT64ToBYTE(Line_ID,&Buf[len]);
    len += 8;
    
    len = TSRGW2015_ADDFrameStartEnd1(m_Inaddr,Buf,len);
    len = TSRAPP_ADDFrameStartEnd(OutBufData,len,3,Usr_checkID);
    return len;	
}
- (int)TSR376_Analysis_LineInf:(unsigned char *)in_bufer bufer_len:(int)bufer_len Company_ID:(UInt64)  Company_ID Line_ID:(UInt64)Line_ID iEnd:(int)iEnd
{
    unsigned int i,nLen;
    Byte frin,*pBuf;
    unsigned int  pn[8],Fn[8],pnLen,FnLen,n,m;  
    if(!TSR376_Checkout(in_bufer,bufer_len))
    {
        return 1;
    }
    if (0x12 != in_bufer[12])
    {
        return 6;
    }
    nLen=((unsigned int)in_bufer[2]<<6)|(in_bufer[1]>>2);
    //判断附加域中是否带事件计数器
    if (in_bufer[6] & 0x20)
    {
        nLen -= 2;
    }
    
    //判断是否多帧
    frin = in_bufer[13];
    switch(frin&0x60)
    {
        case  0x00:
        case	0x40:
            iEnd = 1;
            break;
        case	0x20: 
        case	0x60:
            iEnd = 0;
            break;
        default:
            return -3;
    }
    //判断是否有时间标签
    if(frin&0x80)
    {
        nLen -= 6;
    }
    
    pBuf=&in_bufer[14];
    HYSingleManager *mange = [HYSingleManager sharedManager];
    CTransitModel *model = [[CTransitModel alloc]init];
    for(i=0;i<(nLen-8);)
    {
        //获取数据类型
        pnLen=GetPn(pBuf[i],pBuf[i+1],&pn[0]);
        FnLen=GetFn(pBuf[i+2],pBuf[i+3],&Fn[0]);
        i+=4;
        if ((1!=FnLen)||(4 != Fn[0]))
        {
            return 2;
        }
        UInt64 ID = BYTEToUINT64(&pBuf[i]);
        i += 8;
//        if (Company_ID != ID)
//        {
//            return 3;
//        }
        
        ID = BYTEToUINT64(&pBuf[i]);
        i += 8;
//        if (Line_ID != ID)
//        {
//            return 5;
//        }
        int datalen = (unsigned int)(pBuf[i]&0xFF)|((unsigned int)((pBuf[i+1]&0xFF)<<8));
        i += 2;
        for (n=0;n<pnLen;n++)
        {
            switch(pn[n])
            {
                case 1:
                {
                    //线ID
                    UInt64 Obj_ID = 0;
                    Obj_ID = BYTEToUINT64(&pBuf[i]);
                    i += 8;
                    model.strID = Obj_ID;
                    break;
                }
                case 2:
                {
                    //线名称长度,线名称字符串
                    Byte str_len = 0;
                    NSString *strName;
                    str_len = pBuf[i++];
                    UTF8ToCStringA(&pBuf[i],str_len,&strName);
                    model.name = strName;
                    i+=str_len;
                    break;
                }
                case 5:
                {
                    //上级节点ID,这个解析了没用
                    UInt64 Obj_ID = 0;
                    Obj_ID = BYTEToUINT64(&pBuf[i]);
                    i += 8;
                    break;
                }
                case 8: //站下组
                {
                    UInt64 Obj_ID = 0;
                    Byte str_len = 0;
                    NSString *strName;
                    m = (unsigned int)(pBuf[i]&0xFF)|((unsigned int)((pBuf[i+1]&0xFF)<<8));
                    i += 2;
                    NSMutableArray *arr = [NSMutableArray array];
                    for (unsigned int j=0;j<m;j++)
                    {
                        Obj_ID = BYTEToUINT64(&pBuf[i]);
                        i += 8;
                        str_len = pBuf[i++];
                        UTF8ToCStringA(&pBuf[i],str_len,&strName);
                        i += str_len;
                        [arr addObject:[NSString stringWithFormat:@"%llu",Obj_ID]];
                    }
                    model.children = arr;
                    break;
                }
                default:
                {
                    return 4;
                }
            }
        }
    }
    [mange.obj_dict setObject:model forKey:[model UInt64ToString:model.strID]];
    return 0;
}

//获取终端信息
- (int)TSR376_GetACK_TerminalInfFame:(unsigned char *)m_Inaddr Company_ID:(UInt64)Company_ID Terminal_ID:(UInt64)Terminal_ID Usr_checkID:(UInt64)Usr_checkID OutBufData:(unsigned char *)OutBufData
{
    int len;
    unsigned int Fn=6;
    unsigned int Pn[7]={1,2,4,5,6,7,8};
    unsigned int Pn1[2]={9,10};
    Byte * Buf;
    Buf = &OutBufData[14];
    Buf[6] =0x4B;    //Ctrl
    Buf[12]=0x12;    //APN
    Buf[13]=0x60;    //SEQ
    len = 14;
    
    
    Setpn(&Pn[0],7,&Buf[len],&Buf[len+1]);
    len += 2;
    SetFn(&Fn,1,&Buf[len],&Buf[len+1]);
    len += 2;
    UINT64ToBYTE(Company_ID,&Buf[len]);
    len += 8;
    UINT64ToBYTE(Terminal_ID,&Buf[len]);
    len += 8;
    
    Setpn(&Pn1[0],2,&Buf[len],&Buf[len+1]);
    len += 2;
    SetFn(&Fn,1,&Buf[len],&Buf[len+1]);
    len += 2;
    UINT64ToBYTE(Company_ID,&Buf[len]);
    len += 8;
    UINT64ToBYTE(Terminal_ID,&Buf[len]);
    len += 8;
    
    len = TSRGW2015_ADDFrameStartEnd1(m_Inaddr,Buf,len);
    len = TSRAPP_ADDFrameStartEnd(OutBufData,len,3,Usr_checkID);
    return len;
}
- (int)TSR376_Analysis_TerminalInf:(unsigned char *)in_bufer bufer_len:(int)bufer_len Company_ID:(UInt64)Company_ID Terminal_ID:(UInt64) Terminal_ID iEnd:(int) iEnd
{
    unsigned int i,nLen;
    Byte frin,*pBuf;
    unsigned int  pn[8],Fn[8],pnLen,FnLen,n,m;
    if(!TSR376_Checkout(in_bufer,bufer_len))
    {
        return 1;
    }
    if (0x12 != in_bufer[12])
    {
        return 6;
    }
    nLen=((unsigned int)in_bufer[2]<<6)|(in_bufer[1]>>2);
    //判断附加域中是否带事件计数器
    if (in_bufer[6] & 0x20)
    {
        nLen -= 2;
    }
    
    //判断是否多帧
    frin = in_bufer[13];
    switch(frin&0x60)
    {
        case  0x00:
        case	0x40:
            iEnd = 1;
            break;
        case	0x20:
        case	0x60:
            iEnd = 0;
            break;
        default:
            return -3;
    }
    //判断是否有时间标签
    if(frin&0x80)
    {
        nLen -= 6;
    }
    
    pBuf=&in_bufer[14];
    HYSingleManager *manger = [HYSingleManager sharedManager];
    CTerminalModel *model = [[CTerminalModel alloc]init];
    for(i=0;i<(nLen-8);)
    {
        //获取数据类型
        pnLen=GetPn(pBuf[i],pBuf[i+1],&pn[0]);
        FnLen=GetFn(pBuf[i+2],pBuf[i+3],&Fn[0]);
        i+=4;
        if ((1!=FnLen)||(6 != Fn[0]))
        {
            return 2;
        }
        UInt64 ID = BYTEToUINT64(&pBuf[i]);
        i += 8;
//        if (Company_ID != ID)
//        {
//            return 3;
//        }
        
        ID = BYTEToUINT64(&pBuf[i]);
        i += 8;
//        if (Terminal_ID != ID)
//        {
//            return 5;
//        }
        int datalen = (unsigned int)(pBuf[i]&0xFF)|((unsigned int)((pBuf[i+1]&0xFF)<<8));
        i += 2;
        for (n=0;n<pnLen;n++)
        {
            switch(pn[n])
            {
                case 1:
                {
                    //终端ID
                    UInt64 Obj_ID = 0;
                    Obj_ID = BYTEToUINT64(&pBuf[i]);
                    i += 8;
                    model.strID = Obj_ID;
                    break;
                }
                case 2:
                {
                    //终端名称长度,终端名称字符串
                    Byte str_len = 0;
                    NSString *strName;
                    str_len = pBuf[i++];
                    UTF8ToCStringA(&pBuf[i],str_len,&strName);
                    model.name = strName;
                    i+=str_len;
                    break;
                }
                case 4://界面显示位置
                {
                    int UI_ID = BYTEToINT(&pBuf[i]);
                    i += 4;
//                    bson::bo o=BSON("4"<<toString(UI_ID));
//                    v.push_back(o);
                    break;
                }
                case 5: //终端地址x
                {
                    NSMutableString *strAddr;
                    ByteToTerminalAddr(&pBuf[i],&strAddr);
                    i += 5;
                    model.term_ID = strAddr;
                    break;
                }
                case 6: //SIM卡号
                {
                    NSMutableString *strSIM;
                    ByteToSIM(&pBuf[i],strSIM);
                    i += 11;

                    break;
                }
                case 7: //终端IP
                {
                    NSMutableString *strIP = [NSMutableString string];
                    ByteToIP(&pBuf[i],&strIP);
                    i += 4;

                    break;
                }
                case 8: //终端端口
                {
                    int nPort = (unsigned int)(pBuf[i]&0xFF)|((unsigned int)((pBuf[i+1]&0xFF)<<8));
                    i += 2;

                    break;
                }
                case 9: //终端类型
                {
                    Byte byType = pBuf[i++];

                    break;
                }
                case 10: //终端下测量点
                {
                    UInt64 Obj_ID = 0;
                    Byte str_len = 0;
                    NSString *strName;
                    m = (unsigned int)(pBuf[i]&0xFF)|((unsigned int)((pBuf[i+1]&0xFF)<<8));
                    i += 2;
                    NSMutableArray *arr = [NSMutableArray array];
                    for (unsigned int j=0;j<m;j++)
                    {
                        Obj_ID = BYTEToUINT64(&pBuf[i]);
                        i += 8;
                        str_len = pBuf[i++];
                        UTF8ToCStringA(&pBuf[i],str_len,&strName);
                        i += str_len;
                        [arr addObject:[NSString stringWithFormat:@"%llu",Obj_ID]];
                    }
                    model.children = arr;
                    break;
                }
                default:
                {
                    return 4;
                }
            }
        }
    }
    [manger.obj_dict setObject:model forKey:[model UInt64ToString:model.strID]];
    return 0;
}

//获取组信息
- (int)TSR376_GetACK_SetInfFame:(unsigned char *)m_Inaddr Company_ID:(UInt64)Company_ID Set_ID:(UInt64)Set_ID Usr_CheckID:(UInt64)Usr_checkID OutBufData:(unsigned char *)OutBufData
{
    int len;
    unsigned int Fn=7;
    unsigned int Pn[4]={1,2,7,8};
    Byte * Buf;
    Buf = &OutBufData[14];
    Buf[6] =0x4B;    //Ctrl
    Buf[12]=0x12;    //APN
    Buf[13]=0x60;    //SEQ
    len = 14;
    
    
    Setpn(&Pn[0],4,&Buf[len],&Buf[len+1]);
    len += 2;
    SetFn(&Fn,1,&Buf[len],&Buf[len+1]);
    len += 2;
    UINT64ToBYTE(Company_ID,&Buf[len]);
    len += 8;
    UINT64ToBYTE(Set_ID,&Buf[len]);
    len += 8;
    
    len = TSRGW2015_ADDFrameStartEnd1(m_Inaddr,Buf,len);
    len = TSRAPP_ADDFrameStartEnd(OutBufData,len,3,Usr_checkID);
    return len;
}
- (int)TSR376_Analysis_SetInf:(unsigned char *)in_bufer bufer_len:(int)bufer_len Company_ID:(UInt64)Company_ID Set_ID:(UInt64)Set_ID iEnd:(int)iEnd
{
    unsigned int i,nLen;
    Byte frin,*pBuf;
    unsigned int  pn[8],Fn[8],pnLen,FnLen,n,m;
    if(!TSR376_Checkout(in_bufer,bufer_len))
    {
        return 1;
    }
    if (0x12 != in_bufer[12])
    {
        return 6;
    }
    nLen=((unsigned int)in_bufer[2]<<6)|(in_bufer[1]>>2);
    //判断附加域中是否带事件计数器
    if (in_bufer[6] & 0x20)
    {
        nLen -= 2;
    }
    
    //判断是否多帧
    frin = in_bufer[13];
    switch(frin&0x60)
    {
        case  0x00:
        case	0x40:
            iEnd = 1;
            break;
        case	0x20:
        case	0x60:
            iEnd = 0;
            break;
        default:
            return -3;
    }
    //判断是否有时间标签
    if(frin&0x80)
    {
        nLen -= 6;
    }
    
    pBuf=&in_bufer[14];
    HYSingleManager *manager = [HYSingleManager sharedManager];
    CSetModel *model = [[CSetModel alloc]init];
    for(i=0;i<(nLen-8);)
    {
        //获取数据类型
        pnLen=GetPn(pBuf[i],pBuf[i+1],&pn[0]);
        FnLen=GetFn(pBuf[i+2],pBuf[i+3],&Fn[0]);
        i+=4;
        if ((1!=FnLen)||(7 != Fn[0]))
        {
            return 2;
        }
        UInt64 ID = BYTEToUINT64(&pBuf[i]);
        i += 8;
//        if (Company_ID != ID)
//        {
//            return 3;
//        }
        
        ID = BYTEToUINT64(&pBuf[i]);
        i += 8;
//        if (Set_ID != ID)
//        {
//            return 5;
//        }
        int datalen = (unsigned int)(pBuf[i]&0xFF)|((unsigned int)((pBuf[i+1]&0xFF)<<8));
        i += 2;
        
        for (n=0;n<pnLen;n++)
        {
            switch(pn[n])
            {
                case 1://组ID
                {
                    UInt64 Obj_ID = 0;
                    Obj_ID = BYTEToUINT64(&pBuf[i]);
                    i += 8;
                    model.strID = Obj_ID;
                    break;
                }
                case 2://组名字
                {
                    Byte str_len = 0;
                    NSString *strName;
                    str_len = pBuf[i++];
                    UTF8ToCStringA(&pBuf[i],str_len,&strName);
                    model.name = strName;
                    i+=str_len;
                    break;
                }
                case 7://界面显示位置
                {
                    int UI_ID = BYTEToINT(&pBuf[i]);
                    i += 4;
                    break;
                }
                case 8: //组下设备
                {
                    UInt64 Obj_ID = 0;
                    Byte str_len = 0;
                    NSString *strName;
                    m = (unsigned int)(pBuf[i]&0xFF)|((unsigned int)((pBuf[i+1]&0xFF)<<8));
                    i += 2;
                    NSMutableArray *array = [NSMutableArray array];
                    for (unsigned int j=0;j<m;j++)
                    {
                        Obj_ID = BYTEToUINT64(&pBuf[i]);
                        i += 8;
                        str_len = pBuf[i++];
                        UTF8ToCStringA(&pBuf[i],str_len,&strName);
                        i += str_len;
                        [array addObject:[NSString stringWithFormat:@"%llu",Obj_ID]];
                    }
                    model.children = array;
                    break;
                }
                default:
                {
                    return 4;
                }
            }
        }
    }
    [manager.obj_dict setObject:model forKey:[model UInt64ToString:model.strID]];
    return 0;
}

//获取测量点信息
- (int)TSR376_GetACK_MPPowerInfFame:(unsigned char *)m_Inaddr Company_ID:(UInt64)Company_ID MPPower_ID:(UInt64)MPPower_ID Usr_check_ID:(UInt64)Usr_checkID OutBufData:(unsigned char *)OutBufData
{
    int len;
    unsigned int Fn=8;
    unsigned int Pn1[2]={1,2};
    unsigned int Pn2[3]={10,13,14};
    unsigned int Pn3[2]={23,24};
    
    Byte * Buf;
    Buf = &OutBufData[14];
    Buf[6] =0x4B;    //Ctrl
    Buf[12]=0x12;    //APN
    Buf[13]=0x60;    //SEQ
    len = 14;
    
    
    Setpn(&Pn1[0],2,&Buf[len],&Buf[len+1]);
    len += 2;
    SetFn(&Fn,1,&Buf[len],&Buf[len+1]);
    len += 2;
    UINT64ToBYTE(Company_ID,&Buf[len]);
    len += 8;
    UINT64ToBYTE(MPPower_ID,&Buf[len]);
    len += 8;
    
    Setpn(&Pn2[0],3,&Buf[len],&Buf[len+1]);
    len += 2;
    SetFn(&Fn,1,&Buf[len],&Buf[len+1]);
    len += 2;
    UINT64ToBYTE(Company_ID,&Buf[len]);
    len += 8;
    UINT64ToBYTE(MPPower_ID,&Buf[len]);
    len += 8;
    
    Setpn(&Pn3[0],2,&Buf[len],&Buf[len+1]);
    len += 2;
    SetFn(&Fn,1,&Buf[len],&Buf[len+1]);
    len += 2;
    UINT64ToBYTE(Company_ID,&Buf[len]);
    len += 8;
    UINT64ToBYTE(MPPower_ID,&Buf[len]);
    len += 8;
    
    len = TSRGW2015_ADDFrameStartEnd1(m_Inaddr,Buf,len);
    len = TSRAPP_ADDFrameStartEnd(OutBufData,len,3,Usr_checkID);
    return len;
}
- (int)TSR376_Analysis_MPPowerInf:(unsigned char *)in_bufer bufer_len:(int)bufer_len Company_ID:(UInt64)Company_ID MPPower_ID:(UInt64)MPPower_ID iEnd:(int)iEnd
{
    unsigned int i,nLen;
    Byte frin,*pBuf;
    unsigned int  pn[8],Fn[8],pnLen,FnLen,n;
    if(!TSR376_Checkout(in_bufer,bufer_len))
    {
        return 1;
    }
    if (0x12 != in_bufer[12])
    {
        return 6;
    }
    nLen=((unsigned int)in_bufer[2]<<6)|(in_bufer[1]>>2);
    //判断附加域中是否带事件计数器
    if (in_bufer[6] & 0x20)
    {
        nLen -= 2;
    }
    
    //判断是否多帧
    frin = in_bufer[13];
    switch(frin&0x60)
    {
        case  0x00:
        case	0x40:
            iEnd = 1;
            break;
        case	0x20:
        case	0x60:
            iEnd = 0;
            break;
        default:
            return -3;
    }
    //判断是否有时间标签
    if(frin&0x80)
    {
        nLen -= 6;
    }
    
    pBuf=&in_bufer[14];
    HYSingleManager *manager = [HYSingleManager sharedManager];
    CMPModel *model = [[CMPModel alloc]init];
    for(i=0;i<(nLen-8);)
    {
        //获取数据类型
        pnLen=GetPn(pBuf[i],pBuf[i+1],&pn[0]);
        FnLen=GetFn(pBuf[i+2],pBuf[i+3],&Fn[0]);
        i+=4;
        if ((1!=FnLen)||(8 != Fn[0]))
        {
            return 2;
        }
        UInt64 ID = BYTEToUINT64(&pBuf[i]);
        i += 8;
//        if (Company_ID != ID)
//        {
//            return 3;
//        }
        
        ID = BYTEToUINT64(&pBuf[i]);
        i += 8;
//        if (MPPower_ID != ID)
//        {
//            return 5;
//        }
        int datalen = (unsigned int)(pBuf[i]&0xFF)|((unsigned int)((pBuf[i+1]&0xFF)<<8));
        i += 2;
        
        for (n=0;n<pnLen;n++)
        {
            switch(pn[n])
            {
                case 1:
                {
                    //设备ID
                    UInt64 Obj_ID = 0;
                    Obj_ID = BYTEToUINT64(&pBuf[i]);
                    i += 8;
                    model.strID = Obj_ID;
                    break;
                }
                case 2: //设备名称
                {
                    int str_len = pBuf[i++];
                    NSString *strName;
                    UTF8ToCStringA(&pBuf[i],str_len,&strName);
                    i += str_len;
                    model.name = strName;
                    break;
                }
                case 4://界面显示位置
                {
                    int UI_ID = BYTEToINT(&pBuf[i]);
                    i += 4;
                    break;
                }
                case 8: //SIM卡号
                {
                    NSMutableString *strSIM;
                    ByteToSIM(&pBuf[i],strSIM); 
                    i += 11;
                    break;
                }
                case 9: //设备类型
                {
                    Byte byType = pBuf[i++];
                    break;
                }
                case 10: //测量点序号
                {
                    int nPort = (unsigned int)(pBuf[i]&0xFF)|((unsigned int)((pBuf[i+1]&0xFF)<<8));
                    i += 2;
                    model.mp_point = nPort;
                    break;
                }
                case 11: //通讯速率及端口
                {
                    Byte byT = pBuf[i++];
                    break;
                }
                case 12: //通信协议类型
                {
                    Byte byT = pBuf[i++];
                    break;
                }
                case 13: //通信地址
                {
                    NSMutableString *strTemp = [NSMutableString string];
                    
                    Byte6To12str(&pBuf[i],&strTemp);
                    i += 6;
                    model.mp_csAddr = strTemp;
                    break;
                }
                case 14: //通信密码
                {
                    NSString *strTemp;
                    model.mp_csPass = strTemp;
                    i += 6;

                    
                    break;
                }
                case 15: //电费个数
                {
                    Byte byT = pBuf[i++];
//                    bson::bo o=BSON("15"<<toString(byT));
//                    v.push_back(o);
                    break;
                }
                case 16: //整数位和小数数
                {
                    Byte byT = pBuf[i++];
//                    bson::bo o=BSON("16"<<toString(byT));
//                    v.push_back(o);
                    break;
                }
                case 17: //所属采集器地址
                {
                    NSString *strTemp;
                    
                    Byte6To12str(&pBuf[i],&strTemp);
                    i += 6;
                    model.mp_collectAddr = strTemp;
                    break;
                }
                case 18: //用户大类，用户小类
                {
                    Byte byT = pBuf[i++];
//                    bson::bo o=BSON("16"<<toString(byT));
//                    v.push_back(o);
                    break;
                }
                case 19: //用户名称
                {
                    int str_len = pBuf[i++];
                    NSString *strName;
                    UTF8ToCStringA(&pBuf[i],str_len,&strName);
                    i += str_len;
                    
                    //添加输出处理
                    
                    //  v
//                    string s=strName.GetBuffer(0);
//                    bson::bo o=BSON("19"<<s);
//                    v.push_back(o);
                    break;
                }
                case 20: //设备角色
                {
                    Byte byT = pBuf[i++];
//                    bson::bo o=BSON("20"<<toString(byT));
//                    v.push_back(o);
                    break;
                }
                case 23: //CT
                {
                    int CT = BYTEToInt(&pBuf[i]);
                    model.mp_CT = CT;
                    i += 4;
                    break;
                }
                case 24: //PT
                {
                    int PT = BYTEToInt(&pBuf[i]);
                    model.mp_PT = PT;
                    i += 4;
                    break;
                }
                default:
                {
                    return 4;
                }
            }
        }
    }
     [manager.obj_dict setObject:model forKey:[model UInt64ToString:model.strID]];
    return 0;
}

- (int)TSR376_GetACK_TableCodeInfFame:(NSString *)m_Inaddr mp_pointArr:(unsigned int *)mp_pointArr mp_pointNum:(int)mp_pointNum Usr_checkID:(UInt64)Usr_checkID OurBufData:(unsigned char *)OutBufData
{
    int len;
    int l;
    unsigned int Fn = 97;
    Byte * Buf;
    Buf = &OutBufData[14];
    Buf[6] = 0x4B;   //Ctrl
    Buf[12] = 0x0D;  //APN
    Buf[13] = 0x70;  //SEQ
    len = 14;
    Setpn(&mp_pointArr[0],mp_pointNum, &Buf[len], &Buf[len+1]);
    len += 2;
    SetFn(&Fn, 1, &Buf[len], &Buf[len+1]);
    len += 2;
    NSDate *currentDate = [NSDate date];//获取当前时间，日期
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"YY/MM/dd/HH/mm"];
    NSTimeInterval  oneDay = 24*60*60*1;  //1天的长度
    NSDate *theDate;
    theDate = [currentDate initWithTimeIntervalSinceNow: -oneDay*2 ];
    NSString *dateString = [dateFormatter stringFromDate:theDate];
    NSArray *arr = [dateString componentsSeparatedByString:@"/"];// '/'分割日期字符串,得到一数组
    NSString *dateString1 = [dateFormatter stringFromDate:currentDate];//当前时间
    NSArray *arr1 = [dateString1 componentsSeparatedByString:@"/"];
    int hour = 24 + 24 + [arr1[3] intValue];
    NSMutableArray *time = [NSMutableArray arrayWithArray:arr];
    [time insertObject:@"3" atIndex:0];
    [time insertObject:[NSString stringWithFormat:@"%d",hour] atIndex:0];
    [time replaceObjectAtIndex:5 withObject:@"0"];
    [time replaceObjectAtIndex:6 withObject:@"0"];
    for (int i = 0; i<mp_pointNum; i++) {
        for (int j = (int)time.count; j>0; j--,len++) {
            
            unsigned char buf = BCDToHex([time[j-1] intValue]);
            unsigned char hh = [time[0] intValue];
            Buf[len] = buf;
            if (1 == j) {
                Buf[len] = hh;
            }
        }
    }
    Byte terminl[5];
    TerminalAddrToByte(m_Inaddr, terminl);
    len = TSRGW2015_ADDFrameStartEnd1(terminl, Buf, len);
    len = TSRAPP_ADDFrameStartEnd(OutBufData, len, 3, Usr_checkID);
    return len;

}

#pragma mark -- 获取表码分析
- (int)TSR376_Analysis_TableCodeInf:(unsigned char *)in_bufer bufer_len:(int)bufer_len iEnd:(int*)iEnd
{
    unsigned int i,nLen;
    int l;
    NSString * wy_addr,* wy_name;
    Byte frin,*pBuf;
    unsigned int pn[8],Fn[8],pnLen,FnLen,n;
        if (!TSR376_Checkout(in_bufer, bufer_len)) {
            return 1;
        }
    if (0x0D != in_bufer[12]) {
        return 6;
    }
    nLen = ((unsigned int)in_bufer[2]<<6)|(in_bufer[1]>>2);
    //判断附加域中是否带事件计数器
    if (in_bufer[6] & 0x20)
    {
        nLen -= 2;
    }
    
    //判断是否多帧
    frin = in_bufer[13];
    switch(frin&0x60)
    {
        case  0x00:
            //多帧,中间帧
            break;
        case	0x40:
            //多帧,第一帧
            *iEnd = 1;
            break;
        case	0x20:
            //多帧,结束帧
            break;
        case	0x60:
            //单帧
            *iEnd = 0;
            break;
        default:
            //错误帧
            return -3;
    }
    //判断是否有时间标签
    if(frin&0x80)
    {
        nLen -= 6;
    }
    pBuf = &in_bufer[14];
    
    //获取终端地址
    NSMutableString *strAddr;
    ByteToTerminalAddr(&in_bufer[7],&strAddr);
    i += 5;
    arr = [[NSMutableArray alloc]init];
    int ct = 1,pt = 1;
    for (i = 0; i<(nLen-8); )
    {
        l = i;
        //获取数据类型
        pnLen = GetPn(pBuf[i], pBuf[i+1], &pn[0]);//电表数量
        FnLen = GetFn(pBuf[i+2], pBuf[i+3], &Fn[0]);
        int num = pBuf[i+10];    //pbuf[10]这一位表示数据密度点数,多少个数据
        //pn fn四个字节
        i += 4;
        for (n = 0; n<pnLen; n++)
        {
            UInt64 mp_ID = 0;
            DeviceModel *de = [[DeviceModel alloc] init];//设备初始化
            de.dataArr = [[NSMutableArray alloc] init];
            //时间
            int mm,hour,day,MM,yy;
            NSString *mmS = [NSString stringWithFormat:@"%0x",pBuf[i]];
            NSString *hourS = [NSString stringWithFormat:@"%0x",pBuf[1+i]];
            NSString *dayS = [NSString stringWithFormat:@"%0x",pBuf[2+i]];
            NSString *MMS = [NSString stringWithFormat:@"%0x",pBuf[3+i]];
            NSString *YYS = [NSString stringWithFormat:@"%0x",pBuf[4+i]];
            mm = [mmS intValue];
            hour = [hourS intValue];
            day = [dayS intValue];
            MM = [MMS intValue];
            yy = [YYS intValue];

            HYSingleManager *manager = [HYSingleManager sharedManager];
            for (int a = 0; a<manager.archiveUser.child_obj.count; a++)
            {
                CCompanyModel *company = manager.archiveUser.child_obj[a];
                for (int b = 0; b<company.child_obj1.count; b++)
                {
                    CTerminalModel *terminal = company.child_obj1[b];
                    if ([terminal.term_ID isEqualToString:strAddr])
                    {
                        for (int c = 0; c<terminal.child_obj.count; c++)
                        {
                            CMPModel *mp = terminal.child_obj[c];
                           
                            if (mp.mp_point == pn[n])
                            {
                                mp_ID = mp.strID;
                                de.De_addr = [NSString stringWithFormat:@"%llu",mp.strID];
                                wy_addr = [NSString stringWithFormat:@"%llu",mp.strID];
                                wy_name = mp.name;
                                ct = mp.mp_CT;
                                pt = mp.mp_PT;
                            }
                        }
                     }
                }
            }
            i += 7;
            NSMutableArray *codeArr = [NSMutableArray array];
            
            for (int j = 0; j<num; j++)
            {
                Byte IDByte[5];
                //DataModel
                DataModel * data = [[DataModel alloc] init];
                data.D_id = [NSString stringWithFormat:@"%@",wy_addr];
                data.pt = [NSString stringWithFormat:@"%d",pt];
                data.ct = [NSString stringWithFormat:@"%d",ct];
                for (int k = 0; k<5; k++,i++)//i++
                {
                    IDByte[k] = pBuf[i];
                }
                NSMutableString *keyString = [NSMutableString string];
                [keyString appendFormat:@"%02x",IDByte[4]];
                [keyString appendFormat:@"%02x",IDByte[3]];
                [keyString appendFormat:@"%02x",IDByte[2]];
                [keyString appendFormat:@"%02x",IDByte[1]];
                [keyString appendFormat:@"%02x",IDByte[0]];
                
                NSMutableString *tableCode = [NSMutableString string];
                BOOL result = isPureInt(tableCode);
                if (result == YES)
                {
                    if (IDByte[0]>>7 == 0)
                    {
                        [tableCode appendFormat:@"%02x",IDByte[4]];
                    }else if (IDByte[0]>>7 == 1){
                        [tableCode appendFormat:@"-%02x",IDByte[4]&0xFF];
                    }
                    [tableCode appendFormat:@"%02x",IDByte[3]];
                    [tableCode appendFormat:@"%02x.",IDByte[2]];
                    [tableCode appendFormat:@"%02x",IDByte[1]];
                    [tableCode appendFormat:@"%02x",IDByte[0]];
                }else{
                    [tableCode appendFormat:@"%02x",IDByte[4]];
                    [tableCode appendFormat:@"%02x",IDByte[3]];
                    [tableCode appendFormat:@"%02x.",IDByte[2]];
                    [tableCode appendFormat:@"%02x",IDByte[1]];
                    [tableCode appendFormat:@"%02x",IDByte[0]];
                }
                [codeArr addObject:tableCode];
                int a = pBuf[9+l];
                switch (a) {
                    case 1:
                        data.data_density = [NSString stringWithFormat:@"%d",15];
                        break;
                    case 2:
                        data.data_density = [NSString stringWithFormat:@"%d",30];
                        break;
                    case 3:
                        data.data_density = [NSString stringWithFormat:@"%d",60];
                        break;
                     case 254:
                        
                    default:
                        break;
                }
                if (hour >= 24) {
                    day ++;
                    hour = 0;
                    if ((day )>[self getDayByMonthWith:yy month:MM]) {
                        MM ++;
                        day = 1;
                        if (MM > 12) {
                            yy ++;
                            MM = 1;
                        }
                    }
                }
#pragma mark --时间戳
                data.mm = [NSString stringWithFormat:@"%02d",mm];
                data.hour = [NSString stringWithFormat:@"%02d",hour];
                data.day = [NSString stringWithFormat:@"%02d",day];
                data.Month = [NSString stringWithFormat:@"%02d",MM];
                data.year = [NSString stringWithFormat:@"%02d",yy];
                hour++;
#pragma mark --data
                data.point = [NSString stringWithFormat:@"%02d",j];//点
                data.data = tableCode;
                data.name = wy_name;
                [de.dataArr  addObject:data];
                
            }
            [arr addObject:de];
//            HYSingleManager * manager1 = [HYSingleManager sharedManager];
            if (!manager.memory_Array) {
                manager.memory_Array = [[NSMutableArray alloc] init];
            }
            [manager.memory_Array addObject:de];
            [manager.tableCode_dict setObject:codeArr forKey:[NSString stringWithFormat:@"%llu",mp_ID]];
        }
        
    }

    return 0;
}



-(int)getDayByMonthWith:(int)yy month:(int)mm {
    if ((yy % 4 == 0) && (yy% 400 != 0)|(yy % 400 ==0 ))
    {
        return [self judgeMonthWithMonth:mm];
    }else{
        return [self judgeMonthWithMonth1:mm];
    }
    
    return 0;
}

-(int)judgeMonthWithMonth:(int)mm{
    switch (mm) {
        case 2:
            return 29;
            break;
        case 4:
            return 30;
            break;
        case 6:
            return 30;
            break;
        case 9:
            return 30;
            break;
        case 11:
            return 30;
            break;
        default:
            return 31;
            break;
    }
}

-(int)judgeMonthWithMonth1:(int)mm{
    switch (mm) {
        case 2:
            return 28;
            break;
        case 4:
            return 30;
            break;
        case 6:
            return 30;
            break;
        case 9:
            return 30;
            break;
        case 11:
            return 30;
            break;
        default:
            return 31;
            break;
    }
}

- (int)intervalSinceNow1: (NSString *) theDate {
    NSDateFormatter *date=[[NSDateFormatter alloc] init];
    [date setDateFormat:@"yyyy-MM-dd"];//设置时间格式//很重要
    NSDate *d=[date dateFromString:theDate];
    
    NSTimeInterval late=[d timeIntervalSince1970]*1;
    NSDate* dat = [NSDate dateWithTimeIntervalSinceNow:0];
    NSTimeInterval now=[dat timeIntervalSince1970]*1;
    NSString *timeString=@"";
    NSTimeInterval cha=now-late;
    if (cha/86400>1) {
        timeString = [NSString stringWithFormat:@"%f", cha/86400];
        timeString = [timeString substringToIndex:timeString.length-7];
        return [timeString intValue];
    }
    return -1;
}

#pragma mark --用量请求帧
- (int)TSR376_GetACK_TableCodeForHourInfFame:(NSString *)m_Inaddr mp_pointArr:(unsigned int *)mp_pointArr mp_pointNum:(int)mp_pointNum timeArr:(NSArray *)timeArr Usr_checkID:(UInt64)Usr_checkID OutBufData:(unsigned char *)OutBufData
{
    int len;
    unsigned int Fn = 97;
    Byte * Buf;
    Buf = &OutBufData[14];
    Buf[6] = 0x4B;   //Ctrl
    Buf[12] = 0x0D;  //APN
    Buf[13] = 0x70;  //SEQ
    len = 14;
    
    Setpn(&mp_pointArr[0],mp_pointNum, &Buf[len], &Buf[len+1]);
    len += 2;
    SetFn(&Fn, 1, &Buf[len], &Buf[len+1]);
    len += 2;
//    memcpy(<#void *#>, <#const void *#>, <#size_t#>)
    NSMutableArray *time = [NSMutableArray arrayWithArray:timeArr];
    [time replaceObjectAtIndex:4 withObject:@"0"];
    [time insertObject:@"3" atIndex:0];
    [time insertObject:@"1" atIndex:0];
    for (int j = 0; j<mp_pointNum; j++) {
        for (int k = (int)time.count; k>0; k--,len++) {
            unsigned char buf = BCDToHex([time[k-1] intValue]);
            Buf[len] = buf;
        }
    }
    Byte terminl[5];
    TerminalAddrToByte(m_Inaddr, terminl);
    len = TSRGW2015_ADDFrameStartEnd1(terminl, Buf, len);
    len = TSRAPP_ADDFrameStartEnd(OutBufData, len, 3, Usr_checkID);
    
    return len;
}

#pragma mark -- 用量分段数据
- (int)TSR376_Analysis_TableCodeForHourInfFame:(unsigned char *)in_bufer bufer_len:(int)bufer_len iEnd:(int*)iEnd
{
    unsigned int i,nLen;
    Byte frin,*pBuf;
    unsigned int pn[8],Fn[8],pnLen,FnLen,n;
    if (!TSR376_Checkout(in_bufer, bufer_len)) {
        return 1;
    }
    if (0x0D != in_bufer[12]) {
        return 6;
    }
    nLen = ((unsigned int)in_bufer[2]<<6)|(in_bufer[1]>>2);
    //判断附加域中是否带事件计数器
    if (in_bufer[6] & 0x20)
    {
        nLen -= 2;
    }
    
    //判断是否多帧
    frin = in_bufer[13];
    switch(frin&0x60)
    {
        case  0x00:
            //多帧,中间帧
            break;
        case	0x40:
            //多帧,第一帧
            *iEnd = 1;
            break;
        case	0x20:
            //多帧,结束帧
            break;
        case	0x60:
            //单帧
            *iEnd = 0;
            break;
        default:
            //错误帧
            return -3;
    }
    //判断是否有时间标签
    if(frin&0x80)
    {
        nLen -= 6;
    }
    pBuf = &in_bufer[14];
    
    //获取终端地址
    NSMutableString *strAddr;
    ByteToTerminalAddr(&in_bufer[7],&strAddr);
    i += 5;
    for (i = 0; i<(nLen-8); )
    {
        //获取数据类型
        pnLen = GetPn(pBuf[i], pBuf[i+1], &pn[0]);
        FnLen = GetFn(pBuf[i+2], pBuf[i+3], &Fn[0]);
        int num = pBuf[i+10];
        //pn fn四个字节
        i += 4;
        for (n = 0; n<pnLen; n++) {
            UInt64 mp_ID = 0;
            HYSingleManager *manager = [HYSingleManager sharedManager];
            for (int a = 0; a<manager.archiveUser.child_obj.count; a++) {
                CCompanyModel *company = manager.archiveUser.child_obj[a];
                for (int b = 0; b<company.child_obj1.count; b++) {
                    CTerminalModel *terminal = company.child_obj1[b];
                    if ([terminal.term_ID isEqualToString:strAddr]) {
                        for (int c = 0; c<terminal.child_obj.count; c++) {
                            CMPModel *mp = terminal.child_obj[c];
                            if (mp.mp_point == pn[n]) {
                                mp_ID = mp.strID;
                            }
                        }
                    }
                    
                }
            }
            NSMutableString *timeString = [NSMutableString string];
            [timeString appendFormat:@"%.2x",pBuf[i+4]];
            [timeString appendFormat:@"%.2x",pBuf[i+3]];
            [timeString appendFormat:@"%.2x",pBuf[i+2]];
            [timeString appendFormat:@"%.2x",pBuf[i+1]];
            //            NSString *year = [NSString stringWithFormat:@"%x",pBuf[i+4]];
            //            NSString *month = [NSString stringWithFormat:@"%x",pBuf[i+3]];
            //            NSString *day = [NSString stringWithFormat:@"%x",pBuf[i+2]];
            //            NSDate* dat = [NSDate dateWithTimeIntervalSinceNow:0];
            //            NSTimeInterval a=[dat timeIntervalSince1970];
            //            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            //            [formatter setDateFormat:@"YY/MM/dd"];
            //            NSDate *curDate = [formatter dateFromString:[NSString stringWithFormat:@"%d/%d/%d",[year intValue],[month intValue],[day intValue]]];
            //            NSTimeInterval dis = [curDate timeIntervalSince1970];
            //            int c = a - dis;
            //            int type = c/ONEDay;
            //            NSString *typeStr = [NSString stringWithFormat:@"%d",type];
            i += 7;
            NSMutableArray *codeArr = [NSMutableArray array];
            for (int j = 0; j<num; j++) {
                Byte IDByte[5];
                for (int k = 0; k<5; k++,i++) {
                    IDByte[k] = pBuf[i];
                }
                NSMutableString *keyString = [NSMutableString string];
                [keyString appendFormat:@"%02x",IDByte[4]];
                [keyString appendFormat:@"%02x",IDByte[3]];
                [keyString appendFormat:@"%02x",IDByte[2]];
                [keyString appendFormat:@"%02x",IDByte[1]];
                [keyString appendFormat:@"%02x",IDByte[0]];
                
                NSMutableString *tableCode = [NSMutableString string];
                BOOL result = isPureInt(tableCode);
                if (result == YES) {
                    if (IDByte[0]>>7 == 0) {
                        [tableCode appendFormat:@"%02x",IDByte[4]];
                    }else if (IDByte[0]>>7 == 1){
                        [tableCode appendFormat:@"-%02x",IDByte[4]&0xFF];
                    }
                    [tableCode appendFormat:@"%02x",IDByte[3]];
                    [tableCode appendFormat:@"%02x.",IDByte[2]];
                    [tableCode appendFormat:@"%02x",IDByte[1]];
                    [tableCode appendFormat:@"%02x",IDByte[0]];
                }else{
                    [tableCode appendFormat:@"%02x",IDByte[4]];
                    [tableCode appendFormat:@"%02x",IDByte[3]];
                    [tableCode appendFormat:@"%02x.",IDByte[2]];
                    [tableCode appendFormat:@"%02x",IDByte[1]];
                    [tableCode appendFormat:@"%02x",IDByte[0]];
                }
                [codeArr addObject:tableCode];
            }
            if (manager.usepower_dict[[NSString stringWithFormat:@"%llu",mp_ID] ] == nil) {
                NSMutableDictionary *dic = [NSMutableDictionary dictionary];
                [dic setObject:codeArr forKey:timeString];
                [manager.usepower_dict setObject:dic forKey:[NSString stringWithFormat:@"%llu",mp_ID]];
            }else{
                NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:manager.usepower_dict[[NSString stringWithFormat:@"%llu",mp_ID]]];
                [dict setObject:codeArr forKey:timeString];
                [manager.usepower_dict setObject:dict forKey:[NSString stringWithFormat:@"%llu",mp_ID]];
            }
            
        }
        
    }
    
    return 0;
    
}





#pragma mark -- 解析用量帧
- (int)TSR376_Analysis_TableCodeForHourInfFame:(unsigned char *)in_bufer bufer_len:(int)bufer_len iEnd:(int*)iEnd With:(NSString *)end
{
    unsigned int i,nLen;
    NSMutableArray * receiveDate = [[NSMutableArray alloc] init];;
    int l;
    NSString * wy_addr,* wy_name, * wy_ct, * wy_pt;
    Byte frin,*pBuf;
    unsigned int pn[8],Fn[8],pnLen,FnLen,n;
    if (!TSR376_Checkout(in_bufer, bufer_len)) {
        return 1;
    }
    if (0x0D != in_bufer[12]) {
        return 6;
    }
    nLen = ((unsigned int)in_bufer[2]<<6)|(in_bufer[1]>>2);
    //判断附加域中是否带事件计数器
    if (in_bufer[6] & 0x20)
    {
        nLen -= 2;
    }
    
    //判断是否多帧
    frin = in_bufer[13];
    switch(frin&0x60)
    {
        case  0x00:
            //多帧,中间帧
            break;
        case	0x40:
            //多帧,第一帧
            *iEnd = 1;
            break;
        case	0x20:
            //多帧,结束帧
            break;
        case	0x60:
            //单帧
            *iEnd = 0;
            break;
        default:
            //错误帧
            return -3;
    }
    //判断是否有时间标签
    if(frin&0x80)
    {
        nLen -= 6;
    }
    pBuf = &in_bufer[14];
    
    //获取终端地址
    NSMutableString *strAddr;
    NSMutableString *ack_strAddr;
    ByteToAckTerminalAddr(&in_bufer[7],&ack_strAddr);
    ByteToTerminalAddr(&in_bufer[7],&strAddr);
    i += 5;
    NSMutableArray * termianalArr = [[NSMutableArray alloc] init];
    for (i = 0; i<(nLen-8); )
    {
        l = i;
        NSString * isEmpty = [[NSString alloc] init];
        //获取数据类型
        pnLen = GetPn(pBuf[i], pBuf[i+1], &pn[0]);
        FnLen = GetFn(pBuf[i+2], pBuf[i+3], &Fn[0]);
        int num = pBuf[i+10];
        //pn fn四个字节
        i += 4;
        for (n = 0; n<pnLen; n++)
        {
            //时间
            int mm,hour,day,MM,yy;
            NSString *mmS = [NSString stringWithFormat:@"%0x",pBuf[i]];
            NSString *hourS = [NSString stringWithFormat:@"%0x",pBuf[1+i]];
            NSString *dayS = [NSString stringWithFormat:@"%0x",pBuf[2+i]];
            NSString *MMS = [NSString stringWithFormat:@"%0x",pBuf[3+i]];
            NSString *YYS = [NSString stringWithFormat:@"%0x",pBuf[4+i]];
            mm = [mmS intValue];
            hour = [hourS intValue];
            day = [dayS intValue];
            MM = [MMS intValue];
            yy = [YYS intValue];
            
            /*
                获取时间
                */
            
            UInt64 mp_ID = 0;
            HYSingleManager *manager = [HYSingleManager sharedManager];
            for (int a = 0; a<manager.archiveUser.child_obj.count; a++) {
                CCompanyModel *company = manager.archiveUser.child_obj[a];
                for (int b = 0; b<company.child_obj1.count; b++) {
                    CTerminalModel *terminal = company.child_obj1[b];
                    if ([terminal.term_ID isEqualToString:strAddr]) {
                        for (int c = 0; c<terminal.child_obj.count; c++) {
                            CMPModel *mp = terminal.child_obj[c];
                            if (mp.mp_point == pn[n]) {
                                mp_ID = mp.strID;
                                wy_name = mp.name;
                                wy_addr = [NSString stringWithFormat:@"%llu",mp.strID];
                                wy_ct = [NSString stringWithFormat:@"%d",mp.mp_CT];
                                wy_pt = [NSString stringWithFormat:@"%d",mp.mp_PT];
                            }
                        }
                    }
                    
                }
            }
            /////////////////////////////////////////
            NSMutableArray * da = [NSMutableArray new];
            NSData * archDa = [HY_NSusefDefaults objectForKey:@"usePowerData"];
            da = [NSKeyedUnarchiver unarchiveObjectWithData:archDa];
            DeviceModel *de = [[DeviceModel alloc] init];//设备初始化
            de.dataArr = [[NSMutableArray alloc] init];
            
            if (da.count > 0) {
                for (DeviceModel * devices in da)
                {
                    //设备序号是否相同
                    if ([devices.De_addr isEqualToString:wy_addr])
                    {
                        de = devices;
                    }
                }

            }
            /////////////////////////////////////////
            NSMutableString *timeString = [NSMutableString string];
            [timeString appendFormat:@"%.2x",pBuf[i+4]];
            [timeString appendFormat:@"%.2x",pBuf[i+3]];
            [timeString appendFormat:@"%.2x",pBuf[i+2]];
            [timeString appendFormat:@"%.2x",pBuf[i+1]];
            i += 7;
            NSMutableArray *codeArr = [NSMutableArray array];
            for (int j = 0; j<num; j++) {
                //数据模型
                DataModel * data = [[DataModel alloc] init];
                //数据模型
                Byte IDByte[5];
                for (int k = 0; k<5; k++,i++) {
                    IDByte[k] = pBuf[i];
                }
                NSMutableString *keyString = [NSMutableString string];
                [keyString appendFormat:@"%02x",IDByte[4]];
                [keyString appendFormat:@"%02x",IDByte[3]];
                [keyString appendFormat:@"%02x",IDByte[2]];
                [keyString appendFormat:@"%02x",IDByte[1]];
                [keyString appendFormat:@"%02x",IDByte[0]];
                
                NSMutableString *tableCode = [NSMutableString string];
                BOOL result = isPureInt(tableCode);
                if (result == YES) {
                    if (IDByte[0]>>7 == 0) {
                        [tableCode appendFormat:@"%02x",IDByte[4]];
                    }else if (IDByte[0]>>7 == 1){
                        [tableCode appendFormat:@"-%02x",IDByte[4]&0xFF];
                    }
                    [tableCode appendFormat:@"%02x",IDByte[3]];
                    [tableCode appendFormat:@"%02x",IDByte[2]];
                    [tableCode appendFormat:@"%02x",IDByte[1]];
                    [tableCode appendFormat:@"%02x",IDByte[0]];
                }else{
                    [tableCode appendFormat:@"%02x",IDByte[4]];
                    [tableCode appendFormat:@"%02x",IDByte[3]];
                    [tableCode appendFormat:@"%02x.",IDByte[2]];
                    [tableCode appendFormat:@"%02x",IDByte[1]];
                    [tableCode appendFormat:@"%02x",IDByte[0]];
                }
                
                [codeArr addObject:tableCode];
         
                //数据
                int a = pBuf[9+l];
                switch (a) {
                    case 1:
                        data.data_density = [NSString stringWithFormat:@"%d",15];
                        break;
                    case 2:
                        data.data_density = [NSString stringWithFormat:@"%d",30];
                        break;
                    case 3:
                        data.data_density = [NSString stringWithFormat:@"%d",60];
                        break;
                    case 254:
                        
                    default:
                        break;
                }

                if (hour >= 24) {
                    day ++;
                    hour = 0;
                    if ((day )>[self getDayByMonthWith:yy month:MM]) {
                        MM ++;
                        day = 1;
                        if (MM > 12) {
                            yy ++;
                            MM = 1;
                        }
                    }
                }
#pragma mark --时间戳
                data.mm = [NSString stringWithFormat:@"%02d",mm];
                data.hour = [NSString stringWithFormat:@"%02d",hour];
                data.day = [NSString stringWithFormat:@"%02d",day];
                data.Month = [NSString stringWithFormat:@"%02d",MM];
                data.year = [NSString stringWithFormat:@"%02d",yy];
#pragma mark --data
                data.point = [NSString stringWithFormat:@"%02d",j];//点
                data.data = tableCode;
                data.name = wy_name;
                data.ct  = wy_ct;
                data.pt = wy_pt;
                //接收到的时间
                receiveDate = @[data.year,data.Month,data.day,data.hour,data.mm];
                NSMutableArray * nexTtimeArr = [[NSMutableArray alloc] init];
                if ([self isPureInt:tableCode])
                {
                    //
                    //de设备数组
                    if (de.dataArr.count > 0)
                    {
                        BOOL flag = true;
                        for (DataModel * model in de.dataArr)
                        {
                            if (([model.mm isEqualToString:data.mm] && [model.day isEqualToString:data.day] && [model.Month isEqualToString:data.Month] && [model.data isEqualToString:data.data] &&[model.year isEqualToString:data.year] && [model.name isEqualToString:data.name] && [model.hour isEqualToString:data.hour]))
                            {
                                flag = false;
                                break;
                            }
                            
                        }
                        
                        if (flag == true)
                        {
                            [de.dataArr  addObject:data];
                        }
                    }else{
                        [de.dataArr addObject:data];
                    }
                    de.De_addr = wy_addr;
                    isEmpty = @"NO";
                }else{
                    
                    isEmpty = @"YES";
                    hour --;
                    if (hour < 0) {
                        day --;
                        hour = 23;
                        if (day < 1)  {
                            MM --;
                            day = [self getDayByMonthWith:[data.year intValue] month:([data.Month intValue] -1)];
                            if (MM < 1) {
                                yy --;
                                MM = 12;
                            }
                        }
                    }
#pragma mark --时间戳
                    data.mm = [NSString stringWithFormat:@"%02d",mm];
                    data.hour = [NSString stringWithFormat:@"%02d",hour];
                    data.day = [NSString stringWithFormat:@"%02d",day];
                    data.Month = [NSString stringWithFormat:@"%02d",MM];
                    data.year = [NSString stringWithFormat:@"%02d",yy];
                    data.ct  = wy_ct;
                    data.pt = wy_pt;
                    nexTtimeArr = @[data.year,data.Month,data.day,data.hour,data.mm];
                    //接受错误x信息=
                    [HY_NSusefDefaults setObject:@"End" forKey:@"End"];
                    //继续请求前一个时间点的数据
//                    self.sendUsePowerNextData(nexTtimeArr,pn[n],strAddr);
                    
                    
//                    将需要的请求信息存储
                    NSMutableArray * nextAllData = [[NSMutableArray alloc] init];
                    if ([HY_NSusefDefaults objectForKey:@"NextData"] != nil) {
                        NSArray * arr1  = [HY_NSusefDefaults objectForKey:@"NextData"];
                        nextAllData = [NSMutableArray arrayWithArray:arr1];
                    }
                    NSMutableDictionary * dic1 = [[NSMutableDictionary alloc] init];
                    
                    [dic1 setValue:nexTtimeArr forKey:@"Time"];
                    [dic1 setValue:[NSString stringWithFormat:@"%d",pn[n]] forKey:@"Pn"];
                    [dic1 setValue:strAddr forKey:@"Address"];
                    
                    NSMutableDictionary * dic2 = [[NSMutableDictionary alloc] init];
                    [dic2 setValue:receiveDate forKey:@"Time"];
                    [dic2 setValue:dic2 forKey:@"data"];
                    [dic2 setValue:[NSString stringWithFormat:@"%d",pn[n]] forKey:@"Pn"];
                    [dic2 setValue:strAddr forKey:@"Address"];
                    //获取本地时间
                    NSDate * currentDate = [NSDate dateWithTimeIntervalSinceNow:0];
                    NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
                    [formatter setDateFormat:@"HH"];
                    NSString * currentDataString = [formatter stringFromDate:currentDate];
                    if ([data.hour integerValue] == (24 - 5) || ([currentDataString integerValue] - [data.hour  integerValue]) == 5)
                    {
                        [nextAllData addObject:dic1];
                        [HY_NSusefDefaults setObject:nextAllData forKey:@"NextData"];
                        
                    }else{
                        //调用Block
                        unsigned int pnI = pn[n];
                        self.sendUsePowerNextData(nexTtimeArr,pnI,strAddr);
                    }
                }
            }
            
            
            if ([isEmpty isEqualToString:@"NO"]) {//有数据存储
                [termianalArr addObject:de];
            }
       }
    }
    /////////////////////////////////////////
    NSMutableArray * da1 = [[NSMutableArray alloc]init];
    NSData * dataDa1 = [HY_NSusefDefaults objectForKey:@"usePowerData"];
    da1 =[NSKeyedUnarchiver unarchiveObjectWithData:dataDa1];
    if (da1.count == 0) {
        da1 = [[NSMutableArray alloc]init];
    }
    //termianalArr存储获取的数据
    //da1 defaults中的数据
    for (DeviceModel * devices in termianalArr)
    {
        NSMutableArray * add = [[NSMutableArray alloc] init];
        for (DeviceModel * devices1 in da1)
        {
            //设备序号是否相同
            if ([devices.De_addr isEqualToString:devices1.De_addr])
            {
                devices1.dataArr = devices.dataArr; //更新数据
            }
                [add addObject:devices1.De_addr];

        }
        if (![add containsObject:devices.De_addr]) {
            //原油不存在，添加该设备到数组
            [da1 addObject:devices];
        }
        
        //还没存入数据
        if (da1.count == 0) {
            NSData * terData = [NSKeyedArchiver archivedDataWithRootObject:termianalArr];
            [HY_NSusefDefaults setObject:terData forKey:@"usePowerData"];
        }
    }
    NSData * archDa1 = [NSKeyedArchiver archivedDataWithRootObject:da1];
    [HY_NSusefDefaults setObject:archDa1 forKey:@"usePowerData"];
    
    /////////////////////////////////////////
    return 0;

}



#pragma mark -- 解析上一个点用量帧
- (int)TSR376_Analysis_TableCodeForHourInfNextFame:(unsigned char *)in_bufer bufer_len:(int)bufer_len iEnd:(int*)iEnd With:(NSString *)end
{
    unsigned int i,nLen;
    int l;
    NSString * wy_addr,* wy_name;
    Byte frin,*pBuf;
    unsigned int pn[8],Fn[8],pnLen,FnLen,n;
    if (!TSR376_Checkout(in_bufer, bufer_len)) {
        return 1;
    }
    if (0x0D != in_bufer[12]) {
        return 6;
    }
    nLen = ((unsigned int)in_bufer[2]<<6)|(in_bufer[1]>>2);
    //判断附加域中是否带事件计数器
    if (in_bufer[6] & 0x20)
    {
        nLen -= 2;
    }
    
    //判断是否多帧
    frin = in_bufer[13];
    switch(frin&0x60)
    {
        case  0x00:
            //多帧,中间帧
            break;
        case	0x40:
            //多帧,第一帧
            *iEnd = 1;
            break;
        case	0x20:
            //多帧,结束帧
            break;
        case	0x60:
            //单帧
            *iEnd = 0;
            break;
        default:
            //错误帧
            return -3;
    }
    //判断是否有时间标签
    if(frin&0x80)
    {
        nLen -= 6;
    }
    pBuf = &in_bufer[14];
    
    //获取终端地址
    NSMutableString *strAddr;
    NSMutableString *ack_strAddr;
    ByteToAckTerminalAddr(&in_bufer[7],&ack_strAddr);
    ByteToTerminalAddr(&in_bufer[7],&strAddr);
    i += 5;
    NSMutableArray * termianalArr = [[NSMutableArray alloc] init];
    for (i = 0; i<(nLen-8); )
    {
        l = i;
        NSString * isEmpty = [[NSString alloc] init];
        //获取数据类型
        pnLen = GetPn(pBuf[i], pBuf[i+1], &pn[0]);
        FnLen = GetFn(pBuf[i+2], pBuf[i+3], &Fn[0]);
        int num = pBuf[i+10];
        //pn fn四个字节
        i += 4;
        for (n = 0; n<pnLen; n++)
        {
            //时间
            int mm,hour,day,MM,yy;
            NSString *mmS = [NSString stringWithFormat:@"%0x",pBuf[i]];
            NSString *hourS = [NSString stringWithFormat:@"%0x",pBuf[1+i]];
            NSString *dayS = [NSString stringWithFormat:@"%0x",pBuf[2+i]];
            NSString *MMS = [NSString stringWithFormat:@"%0x",pBuf[3+i]];
            NSString *YYS = [NSString stringWithFormat:@"%0x",pBuf[4+i]];
            mm = [mmS intValue];
            hour = [hourS intValue];
            day = [dayS intValue];
            MM = [MMS intValue];
            yy = [YYS intValue];
            
            /*
             获取时间
             */
            
            UInt64 mp_ID = 0;
            HYSingleManager *manager = [HYSingleManager sharedManager];
            for (int a = 0; a<manager.archiveUser.child_obj.count; a++) {
                CCompanyModel *company = manager.archiveUser.child_obj[a];
                for (int b = 0; b<company.child_obj1.count; b++) {
                    CTerminalModel *terminal = company.child_obj1[b];
                    if ([terminal.term_ID isEqualToString:strAddr]) {
                        for (int c = 0; c<terminal.child_obj.count; c++) {
                            CMPModel *mp = terminal.child_obj[c];
                            if (mp.mp_point == pn[n]) {
                                mp_ID = mp.strID;
                                wy_name = mp.name;
                                wy_addr = [NSString stringWithFormat:@"%llu",mp.strID];
                            }
                        }
                    }
                    
                }
            }
            /////////////////////////////////////////
            NSMutableArray * da = [NSMutableArray new];
            NSData * archDa = [HY_NSusefDefaults objectForKey:@"usePowerData"];
            da = [NSKeyedUnarchiver unarchiveObjectWithData:archDa];
            DeviceModel *de = [[DeviceModel alloc] init];//设备初始化
            de.dataArr = [[NSMutableArray alloc] init];
            
            if (da.count > 0) {
                for (DeviceModel * devices in da)
                {
                    //设备序号是否相同
                    if ([devices.De_addr isEqualToString:wy_addr])
                    {
                        de = devices;
                    }
                }
                
            }
            /////////////////////////////////////////
            NSMutableString *timeString = [NSMutableString string];
            [timeString appendFormat:@"%.2x",pBuf[i+4]];
            [timeString appendFormat:@"%.2x",pBuf[i+3]];
            [timeString appendFormat:@"%.2x",pBuf[i+2]];
            [timeString appendFormat:@"%.2x",pBuf[i+1]];
            i += 7;
            NSMutableArray *codeArr = [NSMutableArray array];
            for (int j = 0; j<num; j++)
            {
                //数据模型
                DataModel * data = [[DataModel alloc] init];
                //数据模型
                Byte IDByte[5];
                for (int k = 0; k<5; k++,i++) {
                    IDByte[k] = pBuf[i];
                }
                NSMutableString *keyString = [NSMutableString string];
                [keyString appendFormat:@"%02x",IDByte[4]];
                [keyString appendFormat:@"%02x",IDByte[3]];
                [keyString appendFormat:@"%02x",IDByte[2]];
                [keyString appendFormat:@"%02x",IDByte[1]];
                [keyString appendFormat:@"%02x",IDByte[0]];
                
                NSMutableString *tableCode = [NSMutableString string];
                BOOL result = isPureInt(tableCode);
                if (result == YES) {
                    if (IDByte[0]>>7 == 0) {
                        [tableCode appendFormat:@"%02x",IDByte[4]];
                    }else if (IDByte[0]>>7 == 1){
                        [tableCode appendFormat:@"-%02x",IDByte[4]&0xFF];
                    }
                    [tableCode appendFormat:@"%02x",IDByte[3]];
                    [tableCode appendFormat:@"%02x",IDByte[2]];
                    [tableCode appendFormat:@"%02x",IDByte[1]];
                    [tableCode appendFormat:@"%02x",IDByte[0]];
                }else{
                    [tableCode appendFormat:@"%02x",IDByte[4]];
                    [tableCode appendFormat:@"%02x",IDByte[3]];
                    [tableCode appendFormat:@"%02x.",IDByte[2]];
                    [tableCode appendFormat:@"%02x",IDByte[1]];
                    [tableCode appendFormat:@"%02x",IDByte[0]];
                }
                [codeArr addObject:tableCode];
                //数据
                int a = pBuf[9+l];
                switch (a) {
                    case 1:
                        data.data_density = [NSString stringWithFormat:@"%d",15];
                        break;
                    case 2:
                        data.data_density = [NSString stringWithFormat:@"%d",30];
                        break;
                    case 3:
                        data.data_density = [NSString stringWithFormat:@"%d",60];
                        break;
                    case 254:
                        
                    default:
                        break;
                }
                
#pragma mark --时间戳
                data.mm = [NSString stringWithFormat:@"%02d",mm];
                data.hour = [NSString stringWithFormat:@"%02d",hour];
                data.day = [NSString stringWithFormat:@"%02d",day];
                data.Month = [NSString stringWithFormat:@"%02d",MM];
                data.year = [NSString stringWithFormat:@"%02d",yy];
#pragma mark --data
                data.point = [NSString stringWithFormat:@"%02d",j];//点
                data.data = tableCode;
                data.name = wy_name;
                    //
                    //de设备数组
                    if (de.dataArr.count > 0)
                    {
                        BOOL flag = true;
                        for (DataModel * model in de.dataArr)
                        {
                            if (([model.mm isEqualToString:data.mm] && [model.day isEqualToString:data.day] && [model.Month isEqualToString:data.Month] && [model.data isEqualToString:data.data] &&[model.year isEqualToString:data.year] && [model.name isEqualToString:data.name]))
                            {
//                                flag = false;
                                break;
                            }
                            
                        }
                        
                        if (flag == true)
                        {
                            [de.dataArr  addObject:data];
                        }
                    }else{
                        [de.dataArr addObject:data];
                    }
                    de.De_addr = wy_addr;
                //将设备存入数组
                [termianalArr addObject:de];
            }
        }
    }
    /////////////////////////////////////////
    NSMutableArray * da1 = [[NSMutableArray alloc]init];
    NSData * dataDa1 = [HY_NSusefDefaults objectForKey:@"usePowerData"];
    da1 =[NSKeyedUnarchiver unarchiveObjectWithData:dataDa1];
    if (da1.count == 0) {
        da1 = [[NSMutableArray alloc]init];
    }
    //termianalArr存储获取的数据
    //da1 defaults中的数据
    for (DeviceModel * devices in termianalArr)
    {
        NSMutableArray * add = [[NSMutableArray alloc] init];
        for (DeviceModel * devices1 in da1)
        {
            //设备序号是否相同
            if ([devices.De_addr isEqualToString:devices1.De_addr])
            {
                devices1.dataArr = devices.dataArr; //更新数据
            }
            [add addObject:devices1.De_addr];
            
        }
        if (![add containsObject:devices.De_addr]) {
            //原油不存在，添加该设备到数组
            [da1 addObject:devices];
        }
        
        //还没存入数据
        if (da1.count == 0) {
            NSData * terData = [NSKeyedArchiver archivedDataWithRootObject:termianalArr];
            [HY_NSusefDefaults setObject:terData forKey:@"usePowerData"];
        }
    }
    NSData * archDa1 = [NSKeyedArchiver archivedDataWithRootObject:da1];
    [HY_NSusefDefaults setObject:archDa1 forKey:@"usePowerData"];
    return 0;
}



//是否为纯数字
-(BOOL)isPureInt:(NSString *) string
{
    NSScanner * scanner = [NSScanner scannerWithString:string];
    float var;
    return [scanner scanFloat:&var]&&[scanner isAtEnd];
}

- (int)TSR376_GetACK_QueryInfFame:(NSString *)m_Inaddr mp_pointArr:(unsigned int *)mp_pointArr mp_pointNum:(int)mp_pointNum timeArr:(NSArray *)timeArr request_type:(int)request_type Usr_checkID:(UInt64)Usr_checkID OutBufData:(unsigned char *)OutBufData
{
    int len;
    Byte * Buf;
    Buf = &OutBufData[14];
    Buf[6] = 0x4B;   //Ctrl
    Buf[12] = 0x0D;  //APN
    Buf[13] = 0x70;  //SEQ
    len = 14;

    switch (request_type) {
        case 1:
        {//总功率
            unsigned int Fn1 = 81;
            unsigned int Fn2 = 85;
            unsigned int Fn3 = 249;
            Setpn(&mp_pointArr[0],mp_pointNum, &Buf[len], &Buf[len+1]);
            len += 2;
            SetFn(&Fn1, 1, &Buf[len], &Buf[len+1]);
            len += 2;
            for (int j = 0; j<mp_pointNum; j++) {
                for (int k = (int)timeArr.count; k>0; k--,len++) {
                    unsigned char buf = BCDToHex([timeArr[k-1] intValue]);
                    unsigned char hh = [timeArr[0] intValue];
                    Buf[len] = buf;
                    if (1 == k) {
                        Buf[len] = hh;
                    }
                }
            }
            Setpn(&mp_pointArr[0],mp_pointNum, &Buf[len], &Buf[len+1]);
            len += 2;
            SetFn(&Fn2, 1, &Buf[len], &Buf[len+1]);
            len += 2;
            for (int j = 0; j<mp_pointNum; j++) {
                for (int k = (int)timeArr.count; k>0; k--,len++) {
                    unsigned char buf = BCDToHex([timeArr[k-1] intValue]);
                    unsigned char hh = [timeArr[0] intValue];
                    Buf[len] = buf;
                    if (1 == k) {
                        Buf[len] = hh;
                    }
                }
            }
            Setpn(&mp_pointArr[0],mp_pointNum, &Buf[len], &Buf[len+1]);
            len += 2;
            SetFn(&Fn3, 1, &Buf[len], &Buf[len+1]);
            len += 2;
            for (int j = 0; j<mp_pointNum; j++) {
                for (int k = (int)timeArr.count; k>0; k--,len++) {
                    unsigned char buf = BCDToHex([timeArr[k-1] intValue]);
                    unsigned char hh = [timeArr[0] intValue];
                    Buf[len] = buf;
                    if (1 == k) {
                        Buf[len] = hh;
                    }
                }
            }
            break;
        }
        case 2:
        {//电压
            unsigned int Fn1 = 89;
            unsigned int Fn2 = 90;
            unsigned int Fn3 = 91;
            Setpn(&mp_pointArr[0], mp_pointNum, &Buf[len], &Buf[len+1]);
            len += 2;
            SetFn(&Fn1, 1, &Buf[len], &Buf[len+1]);
            len += 2;
            for (int j = 0; j<mp_pointNum; j++) {
                for (int k = (int)timeArr.count; k>0; k--,len++) {
                    unsigned char buf = BCDToHex([timeArr[k-1] intValue]);
                    unsigned char hh = [timeArr[0] intValue];
                    Buf[len] = buf;
                    if (1 == k) {
                        Buf[len] = hh;
                    }
                }
            }
            Setpn(&mp_pointArr[0], mp_pointNum, &Buf[len], &Buf[len+1]);
            len += 2;
            SetFn(&Fn2, 1, &Buf[len], &Buf[len+1]);
            len += 2;
            for (int j = 0; j<mp_pointNum; j++) {
                for (int k = (int)timeArr.count; k>0; k--,len++) {
                    unsigned char buf = BCDToHex([timeArr[k-1] intValue]);
                    unsigned char hh = [timeArr[0] intValue];
                    Buf[len] = buf;
                    if (1 == k) {
                        Buf[len] = hh;
                    }
                }
            }
            Setpn(&mp_pointArr[0], mp_pointNum, &Buf[len], &Buf[len+1]);
            len += 2;
            SetFn(&Fn3, 1, &Buf[len], &Buf[len+1]);
            len += 2;
            for (int j = 0; j<mp_pointNum; j++) {
                for (int k = (int)timeArr.count; k>0; k--,len++) {
                    unsigned char buf = BCDToHex([timeArr[k-1] intValue]);
                    unsigned char hh = [timeArr[0] intValue];
                    Buf[len] = buf;
                    if (1 == k) {
                        Buf[len] = hh;
                    }
                }
            }
            
            break;}
        case 3:
        {//电流
            unsigned int Fn1 = 92;
            unsigned int Fn2 = 93;
            unsigned int Fn3 = 94;
            Setpn(&mp_pointArr[0], mp_pointNum, &Buf[len], &Buf[len+1]);
            len += 2;
            SetFn(&Fn1, 1, &Buf[len], &Buf[len+1]);
            len += 2;
            for (int j = 0; j<mp_pointNum; j++) {
                for (int k = (int)timeArr.count; k>0; k--,len++) {
                    unsigned char buf = BCDToHex([timeArr[k-1] intValue]);
                    unsigned char hh = [timeArr[0] intValue];
                    Buf[len] = buf;
                    if (1 == k) {
                        Buf[len] = hh;
                    }
                }
            }
            Setpn(&mp_pointArr[0], mp_pointNum, &Buf[len], &Buf[len+1]);
            len += 2;
            SetFn(&Fn2, 1, &Buf[len], &Buf[len+1]);
            len += 2;
            for (int j = 0; j<mp_pointNum; j++) {
                for (int k = (int)timeArr.count; k>0; k--,len++) {
                    unsigned char buf = BCDToHex([timeArr[k-1] intValue]);
                    unsigned char hh = [timeArr[0] intValue];
                    Buf[len] = buf;
                    if (1 == k) {
                        Buf[len] = hh;
                    }
                }
            }
            Setpn(&mp_pointArr[0], mp_pointNum, &Buf[len], &Buf[len+1]);
            len += 2;
            SetFn(&Fn3, 1, &Buf[len], &Buf[len+1]);
            len += 2;
            for (int j = 0; j<mp_pointNum; j++) {
                for (int k = (int)timeArr.count; k>0; k--,len++) {
                    unsigned char buf = BCDToHex([timeArr[k-1] intValue]);
                    unsigned char hh = [timeArr[0] intValue];
                    Buf[len] = buf;
                    if (1 == k) {
                        Buf[len] = hh;
                    }
                }
            }
            break;}
        case 4:
        {//有功功率
            unsigned int Fn1 = 82;
            unsigned int Fn2 = 83;
            unsigned int Fn3 = 84;
            Setpn(&mp_pointArr[0], mp_pointNum, &Buf[len], &Buf[len+1]);
            len += 2;
            SetFn(&Fn1, 1, &Buf[len], &Buf[len+1]);
            len += 2;
            for (int j = 0; j<mp_pointNum; j++) {
                for (int k = (int)timeArr.count; k>0; k--,len++) {
                    unsigned char buf = BCDToHex([timeArr[k-1] intValue]);
                    unsigned char hh = [timeArr[0] intValue];
                    Buf[len] = buf;
                    if (1 == k) {
                        Buf[len] = hh;
                    }
                }
            }
            Setpn(&mp_pointArr[0], mp_pointNum, &Buf[len], &Buf[len+1]);
            len += 2;
            SetFn(&Fn2, 1, &Buf[len], &Buf[len+1]);
            len += 2;
            for (int j = 0; j<mp_pointNum; j++) {
                for (int k = (int)timeArr.count; k>0; k--,len++) {
                    unsigned char buf = BCDToHex([timeArr[k-1] intValue]);
                    unsigned char hh = [timeArr[0] intValue];
                    Buf[len] = buf;
                    if (1 == k) {
                        Buf[len] = hh;
                    }
                }
            }
            Setpn(&mp_pointArr[0], mp_pointNum, &Buf[len], &Buf[len+1]);
            len += 2;
            SetFn(&Fn3, 1, &Buf[len], &Buf[len+1]);
            len += 2;
            for (int j = 0; j<mp_pointNum; j++) {
                for (int k = (int)timeArr.count; k>0; k--,len++) {
                    unsigned char buf = BCDToHex([timeArr[k-1] intValue]);
                    unsigned char hh = [timeArr[0] intValue];
                    Buf[len] = buf;
                    if (1 == k) {
                        Buf[len] = hh;
                    }
                }
            }
            
            break;}
        case 5:
        {//无功功率
            unsigned int Fn1 = 86;
            unsigned int Fn2 = 87;
            unsigned int Fn3 = 88;
            Setpn(&mp_pointArr[0], mp_pointNum, &Buf[len], &Buf[len+1]);
            len += 2;
            SetFn(&Fn1, 1, &Buf[len], &Buf[len+1]);
            len += 2;
            for (int j = 0; j<mp_pointNum; j++) {
                for (int k = (int)timeArr.count; k>0; k--,len++) {
                    unsigned char buf = BCDToHex([timeArr[k-1] intValue]);
                    unsigned char hh = [timeArr[0] intValue];
                    Buf[len] = buf;
                    if (1 == k) {
                        Buf[len] = hh;
                    }
                }
            }
            Setpn(&mp_pointArr[0], mp_pointNum, &Buf[len], &Buf[len+1]);
            len += 2;
            SetFn(&Fn2, 1, &Buf[len], &Buf[len+1]);
            len += 2;
            for (int j = 0; j<mp_pointNum; j++) {
                for (int k = (int)timeArr.count; k>0; k--,len++) {
                    unsigned char buf = BCDToHex([timeArr[k-1] intValue]);
                    unsigned char hh = [timeArr[0] intValue];
                    Buf[len] = buf;
                    if (1 == k) {
                        Buf[len] = hh;
                    }
                }
            }
            Setpn(&mp_pointArr[0], mp_pointNum, &Buf[len], &Buf[len+1]);
            len += 2;
            SetFn(&Fn3, 1, &Buf[len], &Buf[len+1]);
            len += 2;
            for (int j = 0; j<mp_pointNum; j++) {
                for (int k = (int)timeArr.count; k>0; k--,len++) {
                    unsigned char buf = BCDToHex([timeArr[k-1] intValue]);
                    unsigned char hh = [timeArr[0] intValue];
                    Buf[len] = buf;
                    if (1 == k) {
                        Buf[len] = hh;
                    }
                }
            }
            break;}
        case 6:
        {//总功率因数
            unsigned int Fn1 = 105;
            Setpn(&mp_pointArr[0], mp_pointNum, &Buf[len], &Buf[len+1]);
            len += 2;
            SetFn(&Fn1, 1, &Buf[len], &Buf[len+1]);
            len += 2;
            for (int j = 0; j<mp_pointNum; j++) {
                for (int k = (int)timeArr.count; k>0; k--,len++) {
                    unsigned char buf = BCDToHex([timeArr[k-1] intValue]);
                    unsigned char hh = [timeArr[0] intValue];
                    Buf[len] = buf;
                    if (1 == k) {
                        Buf[len] = hh;
                    }
                }
            }
            
            break;
        }
        default:
            break;
    }
    Byte terminl[5];
    TerminalAddrToByte(m_Inaddr, terminl);
    len = TSRGW2015_ADDFrameStartEnd1(terminl, Buf, len);
    len = TSRAPP_ADDFrameStartEnd(OutBufData, len, 3, Usr_checkID);
    
    return len;
}


#pragma mark --状态模块帧的解析处理
- (int)TSR376_Analysis_QueryInfFame:(unsigned char *)in_bufer bufer_len:(int)bufer_len iEnd:(int*)iEnd
{
    unsigned int i,nLen;
    Byte frin,*pBuf;
    int new = 0;//是否的新创建的数据
    int new1 = 0;//存单利是否存在
    NSString * _wycName, * _wyc_adress;
    unsigned int pn[8],Fn[8],pnLen,FnLen,n,m;
    if (!TSR376_Checkout(in_bufer, bufer_len)) {
        return 1;
    }
    if (0x0D != in_bufer[12]) {
        return 6;
    }
    nLen = ((unsigned int)in_bufer[2]<<6)|(in_bufer[1]>>2);
    //判断附加域中是否带事件计数器
    if (in_bufer[6] & 0x20)
    {
        nLen -= 2;
    }
    
    //判断是否多帧
    frin = in_bufer[13];
    switch(frin&0x60)
    {
        case  0x00:
            //多帧,中间帧
            break;
        case	0x40:
            //多帧,第一帧
            *iEnd = 1;
            break;
        case	0x20:
            //多帧,结束帧
            break;
        case	0x60:
            //单帧
            *iEnd = 0;
            break;
        default:
            //错误帧
            return -3;
    }
    //判断是否有时间标签
    if(frin&0x80)
    {
        nLen -= 6;
    }
    pBuf = &in_bufer[14];
    
    //获取终端地址
    NSMutableString *strAddr;
    ByteToTerminalAddr(&in_bufer[7],&strAddr);
    i += 5;
    HYSingleManager *manager = [HYSingleManager sharedManager];
    for (i = 0; i<(nLen-8); )
    {
        //获取数据类型
        pnLen = GetPn(pBuf[i], pBuf[i+1], &pn[0]);
        FnLen = GetFn(pBuf[i+2], pBuf[i+3], &Fn[0]);
        int num = pBuf[i+10];
        //pn fn四个字节
        i += 4;
        int  ct = 0, pt = 0;
        NSMutableArray * memory_Array = manager.memory_Array;
        if (memory_Array.count == 0) {
            new1 = 1;
            memory_Array = [[NSMutableArray alloc] init];
            manager.memory_Array = [[NSMutableArray alloc] init];
        }
        DeviceModel * deModel = [[DeviceModel alloc] init];
        deModel.dataArr  = [[NSMutableArray alloc] init];;
        new = 1;//1表示新创建的数据
        new1 = 1;
        int new2 = 1;
        for (m = 0; m<FnLen; m++) {
            switch (Fn[m]) {
                case 81:
                {//总有功功率
                    for (n = 0; n<pnLen; n++) {
                        UInt64 mp_ID = 0;
                        for (int a = 0; a<manager.archiveUser.child_obj.count; a++) {
                            CCompanyModel *company = manager.archiveUser.child_obj[a];
                            for (int b = 0; b<company.child_obj1.count; b++) {
                                CTerminalModel *terminal = company.child_obj1[b];
                                if ([terminal.term_ID isEqualToString:strAddr]) {
                                    for (int c = 0; c<terminal.child_obj.count; c++) {
                                        CMPModel *mp = terminal.child_obj[c];
                                        if (mp.mp_point == pn[n]) {
                                            mp_ID = mp.strID;
                                            _wycName = mp.name;
                                            ct = mp.mp_CT;
                                            pt = mp.mp_PT;
                                            _wyc_adress = [NSString stringWithFormat:@"%llu",mp_ID];
                                            if (memory_Array.count > 0) {
                                                for (DeviceModel * deM in memory_Array) {
                                                    if ([deM.De_addr isEqualToString:[NSString stringWithFormat:@"%llu",mp_ID]] ) {
                                                        //设备ID相同，取出设备
                                                        deModel = deM;
                                                        new1 = 0;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                
                            }
                        }
                        NSString *year = [NSString stringWithFormat:@"%x",pBuf[i+4]];
                        NSString *month = [NSString stringWithFormat:@"%x",pBuf[i+3]];
                        NSString *day = [NSString stringWithFormat:@"%x",pBuf[i+2]];
                        NSDate* dat = [NSDate dateWithTimeIntervalSinceNow:0];
                        NSTimeInterval a=[dat timeIntervalSince1970];
                        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                        [formatter setDateFormat:@"YY/MM/dd"];
                        NSDate *curDate = [formatter dateFromString:[NSString stringWithFormat:@"%d/%d/%d",[year intValue],[month intValue],[day intValue]]];
                        NSTimeInterval dis = [curDate timeIntervalSince1970];
                        int c = a - dis;
                        int type = c/ONEDay;
                        NSString *typeStr = [NSString stringWithFormat:@"%d",type];
                        i += 7;
                        NSMutableArray *codeArr = [NSMutableArray array];
                        for (int j = 0; j<num; j++) {
                            new = 1;
                            Byte IDByte[3];
                            for (int k = 0; k<3; k++,i++) {
                                IDByte[k] = pBuf[i];
                            }
                            NSMutableString *keyString = [NSMutableString string];
                            [keyString appendFormat:@"%02x",IDByte[2]];
                            [keyString appendFormat:@"%02x",IDByte[1]];
                            [keyString appendFormat:@"%02x",IDByte[0]];
                            
                            NSMutableString *tableCode = [NSMutableString string];
                            BOOL result = isPureInt(keyString);
                            if (result == YES) {
                                if ((IDByte[2] & 0x80) == 0) {
                                    [tableCode appendFormat:@"%02x.",IDByte[2]];
                                }else if ((IDByte[2] & 0x80) == 0x80){
                                    IDByte[2] &= 0x7F;
                                    [tableCode appendFormat:@"-%02x.",IDByte[2]];
                                }
                                [tableCode appendFormat:@"%02x",IDByte[1]];
                                [tableCode appendFormat:@"%02x",IDByte[0]];
                            }else{
                                [tableCode appendFormat:@"%02x.",IDByte[2]];
                                [tableCode appendFormat:@"%02x",IDByte[1]];
                                [tableCode appendFormat:@"%02x",IDByte[0]];
                            }
                            [codeArr addObject:tableCode];
                            
                            DataModel * data = [[DataModel alloc] init];
                            DateModel * date = [[DateModel alloc]init];
                            date.data = [[NSMutableArray alloc] init];
                            for (DateModel * date1 in deModel.dataArr) {
                                if ([date1.day intValue] == [day intValue]) {
                                    //找到该Day数据
                                    date = date1;
                                    new2 = 0;
                                    if ((date1.data.count ) > j) {
                                        new = 0;//0表示Data已存在
                                        data.total_actPower = tableCode;
                                        data.point = [NSString stringWithFormat:@"%d",j];
                                        data.name = _wycName;
                                        data.Month = month;
                                        data.year = year;
                                        data.day = day;
                                        data.hour = @"00";
                                        data.ct = [NSString stringWithFormat:@"%d",ct];
                                        data.pt = [NSString stringWithFormat:@"%d",pt];
                                        NSString * tString =  [HY_NSusefDefaults objectForKey:@"TIME"];
                                        int t = (dis - [tString intValue])/(15 * 60);
                                        data.my_id = [NSString stringWithFormat:@"%d",t +j];
                                        date1.data[j] = data;
                                        DataModel * newData = date1.data[j];
                                        newData.total_actPower = tableCode;
                                        
                                    }else if ((date1.data.count ) <= j){
                                        data.total_actPower = tableCode;
                                        data.point = [NSString stringWithFormat:@"%d",j];
                                        data.name = _wycName;
                                        data.Month = month;
                                        data.year = year;
                                        data.day = day;
                                        data.hour = @"00";
                                        data.ct = [NSString stringWithFormat:@"%d",ct];
                                        data.pt = [NSString stringWithFormat:@"%d",pt];
                                        NSString * tString =  [HY_NSusefDefaults objectForKey:@"TIME"];
                                        int t = (dis - [tString intValue])/(15 * 60);
                                        data.my_id = [NSString stringWithFormat:@"%d",t +j];
                                        date1.day = day;
                                        [date1.data addObject:data];
                                    }
                                }

                            }
                            if (new2 == 1) {//new
                                data.total_actPower = tableCode;
                                data.point = [NSString stringWithFormat:@"%d",j];
                                data.name = _wycName;
                                data.Month = month;
                                data.year = year;
                                data.day = day;
                                data.hour = @"00";
                                data.ct = [NSString stringWithFormat:@"%d",ct];
                                data.pt = [NSString stringWithFormat:@"%d",pt];
                                NSString * tString =  [HY_NSusefDefaults objectForKey:@"TIME"];
                                int t = (dis - [tString intValue])/(15 * 60);
                                data.my_id = [NSString stringWithFormat:@"%d",t +j];
                                date.day = day;
                                [date.data addObject:data];
                                [deModel.dataArr addObject:date];
                            }
                        }
                        //存储
                        deModel.De_addr = [NSString stringWithFormat:@"%llu",mp_ID];
                        deModel.pointNum = [NSString stringWithFormat:@"%d",num + [deModel.pointNum intValue]];
                        //将设备存入单利
                        if (new1 == 1) {//新创建
                            [manager.memory_Array addObject:deModel];
                        }else if (new1 == 0){//已存在
                            for (int i = 0;i<manager.memory_Array.count; i++ ) {
                                DeviceModel * data1 = manager.memory_Array[i];
                                if ([data1.De_addr isEqualToString: _wyc_adress]) {
                                    //找到该设备更新数据
                                    data1 = deModel;
                                }
                            }
                        }
                    }
                    break;
                }
                case 85:
                {//总无功功率
                    for (n = 0; n<pnLen; n++) {
                        UInt64 mp_ID = 0;
                        HYSingleManager *manager = [HYSingleManager sharedManager];
                        for (int a = 0; a<manager.archiveUser.child_obj.count; a++) {
                            CCompanyModel *company = manager.archiveUser.child_obj[a];
                            for (int b = 0; b<company.child_obj1.count; b++) {
                                CTerminalModel *terminal = company.child_obj1[b];
                                if ([terminal.term_ID isEqualToString:strAddr]) {
                                    for (int c = 0; c<terminal.child_obj.count; c++) {
                                        CMPModel *mp = terminal.child_obj[c];
                                        if (mp.mp_point == pn[n]) {
                                            mp_ID = mp.strID;
                                            _wycName = mp.name;
                                            ct = mp.mp_CT;
                                            pt = mp.mp_PT;
                                            _wyc_adress = [NSString stringWithFormat:@"%llu",mp_ID];
                                            if (memory_Array.count > 0) {
                                                for (DeviceModel * deM in memory_Array) {
                                                    if ([deM.De_addr isEqualToString:[NSString stringWithFormat:@"%llu",mp_ID]]) {
                                                        //设备ID相同，取出设备
                                                        deModel = deM;
                                                        new1 = 0;
                                                    }
                                                }
                                            }

                                        }
                                    }
                                }
                                
                            }
                        }
                        NSString *year = [NSString stringWithFormat:@"%x",pBuf[i+4]];
                        NSString *month = [NSString stringWithFormat:@"%x",pBuf[i+3]];
                        NSString *day = [NSString stringWithFormat:@"%x",pBuf[i+2]];
                        NSDate* dat = [NSDate dateWithTimeIntervalSinceNow:0];
                        NSTimeInterval a=[dat timeIntervalSince1970];
                        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                        [formatter setDateFormat:@"YY/MM/dd"];
                        NSDate *curDate = [formatter dateFromString:[NSString stringWithFormat:@"%d/%d/%d",[year intValue],[month intValue],[day intValue]]];
                        NSTimeInterval dis = [curDate timeIntervalSince1970];
                        int c = a - dis;
                        int type = c/ONEDay;
                        NSString *typeStr = [NSString stringWithFormat:@"%d",type];
                        i += 7;
                        NSMutableArray *codeArr = [NSMutableArray array];
                        for (int j = 0; j<num; j++) {
                            new = 1;
                            Byte IDByte[3];
                            for (int k = 0; k<3; k++,i++) {
                                IDByte[k] = pBuf[i];
                            }
                            NSMutableString *keyString = [NSMutableString string];
                            [keyString appendFormat:@"%02x",IDByte[2]];
                            [keyString appendFormat:@"%02x",IDByte[1]];
                            [keyString appendFormat:@"%02x",IDByte[0]];
                            
                            NSMutableString *tableCode = [NSMutableString string];
                            BOOL result = isPureInt(keyString);
                            if (result == YES) {
                                if ((IDByte[2] & 0x80) == 0) {
                                    [tableCode appendFormat:@"%02x.",IDByte[2]];
                                }else if ((IDByte[2] & 0x80) == 0x80){
                                    IDByte[2] &= 0x7F;
                                    [tableCode appendFormat:@"-%02x.",IDByte[2]];
                                }
                                [tableCode appendFormat:@"%02x",IDByte[1]];
                                [tableCode appendFormat:@"%02x",IDByte[0]];
                            }else{
                                [tableCode appendFormat:@"%02x.",IDByte[2]];
                                [tableCode appendFormat:@"%02x",IDByte[1]];
                                [tableCode appendFormat:@"%02x",IDByte[0]];
                            }
                            [codeArr addObject:tableCode];
                            DataModel * data = [[DataModel alloc] init];
                            DateModel * date = [[DateModel alloc]init];
                            date.data = [[NSMutableArray alloc] init];
                            for (DateModel * date1 in deModel.dataArr) {
                                if ([date1.day intValue] == [day intValue]) {
                                    //找到该Day数据
                                    date = date1;
                                    new2 = 0;
                                    if ((date1.data.count) > j) {
                                        new = 0;//0表示Data已存在
                                        data.total_reactPower = tableCode;
                                        data.point = [NSString stringWithFormat:@"%d",j];
                                        data.name = _wycName;
                                        data.Month = month;
                                        data.year = year;
                                        data.day = day;
                                        data.hour = @"00";
                                        data.ct = [NSString stringWithFormat:@"%d",ct];
                                        data.pt = [NSString stringWithFormat:@"%d",pt];
                                        NSString * tString =  [HY_NSusefDefaults objectForKey:@"TIME"];
                                        int t = (dis - [tString intValue])/(15 * 60);
                                        data.my_id = [NSString stringWithFormat:@"%d",t +j];
                                        DataModel * newData = date1.data[j];
                                        newData.total_reactPower = tableCode;
                                        
                                    }else if ((date1.data.count ) <= j){
                                        data.total_reactPower = tableCode;
                                        data.point = [NSString stringWithFormat:@"%d",j];
                                        data.name = _wycName;
                                        data.Month = month;
                                        data.year = year;
                                        data.day = day;
                                        data.hour = @"00";
                                        data.ct = [NSString stringWithFormat:@"%d",ct];
                                        data.pt = [NSString stringWithFormat:@"%d",pt];
                                        NSString * tString =  [HY_NSusefDefaults objectForKey:@"TIME"];
                                        int t = (dis - [tString intValue])/(15 * 60);
                                        data.my_id = [NSString stringWithFormat:@"%d",t +j];
                                        date1.day = day;
                                        [date1.data addObject:data];
                                    }
                                }
                                
                            }
                            if (new2 == 1) {//new
                                data.total_reactPower = tableCode;
                                data.point = [NSString stringWithFormat:@"%d",j];
                                data.name = _wycName;
                                data.Month = month;
                                data.year = year;
                                data.day = day;
                                data.hour = @"00";
                                data.ct = [NSString stringWithFormat:@"%d",ct];
                                data.pt = [NSString stringWithFormat:@"%d",pt];
                                NSString * tString =  [HY_NSusefDefaults objectForKey:@"TIME"];
                                int t = (dis - [tString intValue])/(15 * 60);
                                data.my_id = [NSString stringWithFormat:@"%d",t +j];
                                date.day = day;
                                [date.data addObject:data];
                                [deModel.dataArr addObject:date];
                            }

                        }
                        
                        //存储
                        deModel.De_addr = [NSString stringWithFormat:@"%llu",mp_ID];
                        deModel.pointNum = [NSString stringWithFormat:@"%d",num + [deModel.pointNum intValue]];
                        //将设备存入单利
                        //将设备存入单利
                        if (new1 == 1) {//新创建
                            [manager.memory_Array addObject:deModel];
                        }else if (new1 == 0){//已存在
                            for (int i = 0;i<manager.memory_Array.count; i++ ) {
                                DeviceModel * data1 = manager.memory_Array[i];
                                if ([data1.De_addr isEqualToString: _wyc_adress]) {
                                    //找到该设备更新数据
                                    data1 = deModel;
                                }
                            }
                            
                        }
                    }

                    break;
                }
                case 249:
                {//总视在功率
                    for (n = 0; n<pnLen; n++) {
                        UInt64 mp_ID = 0;
                        HYSingleManager *manager = [HYSingleManager sharedManager];
                        for (int a = 0; a<manager.archiveUser.child_obj.count; a++) {
                            CCompanyModel *company = manager.archiveUser.child_obj[a];
                            for (int b = 0; b<company.child_obj1.count; b++) {
                                CTerminalModel *terminal = company.child_obj1[b];
                                if ([terminal.term_ID isEqualToString:strAddr]) {
                                    for (int c = 0; c<terminal.child_obj.count; c++) {
                                        CMPModel *mp = terminal.child_obj[c];
                                        if (mp.mp_point == pn[n]) {
                                            mp_ID = mp.strID;
                                            _wycName = mp.name;
                                            ct = mp.mp_CT;
                                            pt = mp.mp_PT;
                                            _wyc_adress = [NSString stringWithFormat:@"%llu",mp_ID];
                                            if (memory_Array.count > 0) {
                                                for (DeviceModel * deM in memory_Array) {
                                                    if ([deM.De_addr isEqualToString:[NSString stringWithFormat:@"%llu",mp_ID]]) {
                                                        //设备ID相同，取出设备
                                                        deModel = deM;
                                                        new1 = 0;
                                                    }
                                                }
                                            }

                                        }
                                    }
                                }
                                
                            }
                        }
                        NSString *year = [NSString stringWithFormat:@"%x",pBuf[i+4]];
                        NSString *month = [NSString stringWithFormat:@"%x",pBuf[i+3]];
                        NSString *day = [NSString stringWithFormat:@"%x",pBuf[i+2]];
                        NSDate* dat = [NSDate dateWithTimeIntervalSinceNow:0];
                        NSTimeInterval a=[dat timeIntervalSince1970];
                        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                        [formatter setDateFormat:@"YY/MM/dd"];
                        NSDate *curDate = [formatter dateFromString:[NSString stringWithFormat:@"%d/%d/%d",[year intValue],[month intValue],[day intValue]]];
                        NSTimeInterval dis = [curDate timeIntervalSince1970];
                        int c = a - dis;
                        int type = c/ONEDay;
                        NSString *typeStr = [NSString stringWithFormat:@"%d",type];
                        i += 7;
                        NSMutableArray *codeArr = [NSMutableArray array];
                        for (int j = 0; j<num; j++) {
                            new = 1;
                            Byte IDByte[3];
                            for (int k = 0; k<3; k++,i++) {
                                IDByte[k] = pBuf[i];
                            }
                            NSMutableString *keyString = [NSMutableString string];
                            [keyString appendFormat:@"%02x",IDByte[2]];
                            [keyString appendFormat:@"%02x",IDByte[1]];
                            [keyString appendFormat:@"%02x",IDByte[0]];
                            
                            NSMutableString *tableCode = [NSMutableString string];
                            BOOL result = isPureInt(keyString);
                            if (result == YES) {
                                if ((IDByte[2] & 0x80) == 0) {
                                    [tableCode appendFormat:@"%02x.",IDByte[2]];
                                }else if ((IDByte[2] & 0x80) == 0x80){
                                    IDByte[2] &= 0x7F;
                                    [tableCode appendFormat:@"-%02x.",IDByte[2]];
                                }
                                [tableCode appendFormat:@"%02x",IDByte[1]];
                                [tableCode appendFormat:@"%02x",IDByte[0]];
                            }else{
                                [tableCode appendFormat:@"%02x.",IDByte[2]];
                                [tableCode appendFormat:@"%02x",IDByte[1]];
                                [tableCode appendFormat:@"%02x",IDByte[0]];
                            }
                            [codeArr addObject:tableCode];
                            DataModel * data = [[DataModel alloc] init];
                            DateModel * date = [[DateModel alloc]init];
                            date.data = [[NSMutableArray alloc] init];
                            for (DateModel * date1 in deModel.dataArr) {
                                if ([date1.day intValue] == [day intValue]) {
                                    //找到该Day数据
                                    date = date1;
                                    new2 = 0;
                                    if ((date1.data.count ) > j) {
                                        new = 0;//0表示Data已存在
                                        data.total_apparentPower = tableCode;
                                        data.point = [NSString stringWithFormat:@"%d",j];
                                        data.name = _wycName;
                                        data.Month = month;
                                        data.year = year;
                                        data.day = day;
                                        data.hour = @"00";
                                        data.ct = [NSString stringWithFormat:@"%d",ct];
                                        data.pt = [NSString stringWithFormat:@"%d",pt];
                                        NSString * tString =  [HY_NSusefDefaults objectForKey:@"TIME"];
                                        int t = (dis - [tString intValue])/(15 * 60);
                                        data.my_id = [NSString stringWithFormat:@"%d",t +j];
                                        DataModel * newData = date1.data[j];
                                        newData.total_apparentPower = tableCode;
                                        
                                    }else if ((date1.data.count ) <= j){
                                        data.total_apparentPower = tableCode;
                                        data.point = [NSString stringWithFormat:@"%d",j];
                                        data.name = _wycName;
                                        data.Month = month;
                                        data.year = year;
                                        data.day = day;
                                        data.hour = @"00";
                                        data.ct = [NSString stringWithFormat:@"%d",ct];
                                        data.pt = [NSString stringWithFormat:@"%d",pt];
                                        NSString * tString =  [HY_NSusefDefaults objectForKey:@"TIME"];
                                        int t = (dis - [tString intValue])/(15 * 60);
                                        data.my_id = [NSString stringWithFormat:@"%d",t +j];
                                        date1.day = day;
                                        [date1.data addObject:data];
                                    }
                                }
                                
                            }
                            if (new2 == 1) {//new
                                data.total_apparentPower = tableCode;
                                data.point = [NSString stringWithFormat:@"%d",j];
                                data.name = _wycName;
                                data.Month = month;
                                data.year = year;
                                data.day = day;
                                data.hour = @"00";
                                data.ct = [NSString stringWithFormat:@"%d",ct];
                                data.pt = [NSString stringWithFormat:@"%d",pt];
                                NSString * tString =  [HY_NSusefDefaults objectForKey:@"TIME"];
                                int t = (dis - [tString intValue])/(15 * 60);
                                data.my_id = [NSString stringWithFormat:@"%d",t +j];
                                date.day = day;
                                [date.data addObject:data];
                                [deModel.dataArr addObject:date];
                            }
                        }
                        //存储
                        deModel.De_addr = [NSString stringWithFormat:@"%llu",mp_ID];
                        deModel.pointNum = [NSString stringWithFormat:@"%d",num + [deModel.pointNum intValue]];
                        //将设备存入单利
                        if (new1 == 1) {//新创建
                            [manager.memory_Array addObject:deModel];
                        }else if (new1 == 0){//已存在
                            for (int i = 0;i<manager.memory_Array.count; i++ ) {
                                DeviceModel * data1 = manager.memory_Array[i];
                                if ([data1.De_addr isEqualToString: _wyc_adress]) {
                                    //找到该设备更新数据
                                    data1 = deModel;
                                }
                            }
                            
                        }

                        if (manager.total_apparentPower_dict[[NSString stringWithFormat:@"%llu",mp_ID] ] == nil) {
                            NSMutableDictionary *dic = [NSMutableDictionary dictionary];
                            [dic setObject:codeArr forKey:typeStr];
                            [manager.total_apparentPower_dict setObject:dic forKey:[NSString stringWithFormat:@"%llu",mp_ID]];
                        }else{
                            NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:manager.total_apparentPower_dict[[NSString stringWithFormat:@"%llu",mp_ID]]];
                            [dict setObject:codeArr forKey:typeStr];
                            [manager.total_apparentPower_dict setObject:dict forKey:[NSString stringWithFormat:@"%llu",mp_ID]];
                        }
                    }

                    break;
                }
                case 89:
                {//A相电压
                    for (n = 0; n<pnLen; n++) {
                        UInt64 mp_ID = 0;
                        HYSingleManager *manager = [HYSingleManager sharedManager];
                        for (int a = 0; a<manager.archiveUser.child_obj.count; a++) {
                            CCompanyModel *company = manager.archiveUser.child_obj[a];
                            for (int b = 0; b<company.child_obj1.count; b++) {
                                CTerminalModel *terminal = company.child_obj1[b];
                                if ([terminal.term_ID isEqualToString:strAddr]) {
                                    for (int c = 0; c<terminal.child_obj.count; c++) {
                                        CMPModel *mp = terminal.child_obj[c];
                                        if (mp.mp_point == pn[n]) {
                                            mp_ID = mp.strID;
                                            _wycName = mp.name;
                                            ct = mp.mp_CT;
                                            pt = mp.mp_PT;
                                            _wyc_adress = [NSString stringWithFormat:@"%llu",mp_ID];
                                            if (memory_Array.count > 0) {
                                                for (DeviceModel * deM in memory_Array) {
                                                    if ([deM.De_addr isEqualToString:[NSString stringWithFormat:@"%llu",mp_ID]] ) {
                                                        //设备ID相同，取出设备
                                                        deModel = deM;
                                                        new1 = 0;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                
                            }
                        }
                        NSString *year = [NSString stringWithFormat:@"%x",pBuf[i+4]];
                        NSString *month = [NSString stringWithFormat:@"%x",pBuf[i+3]];
                        NSString *day = [NSString stringWithFormat:@"%x",pBuf[i+2]];
                        NSDate* dat = [NSDate dateWithTimeIntervalSinceNow:0];
                        NSTimeInterval a=[dat timeIntervalSince1970];
                        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                        [formatter setDateFormat:@"YY/MM/dd"];
                        NSDate *curDate = [formatter dateFromString:[NSString stringWithFormat:@"%d/%d/%d",[year intValue],[month intValue],[day intValue]]];
                        NSTimeInterval dis = [curDate timeIntervalSince1970];
                        int c = a - dis;
                        int type = c/ONEDay;
                        NSString *typeStr = [NSString stringWithFormat:@"%d",type];
                        i += 7;
                        NSMutableArray *codeArr = [NSMutableArray array];
                        for (int j = 0; j<num; j++) {
                            Byte IDByte[2];
                            for (int k = 0; k<2; k++,i++) {
                                IDByte[k] = pBuf[i];
                            }
                            NSMutableString *keyString = [NSMutableString string];
                            [keyString appendFormat:@"%02x",IDByte[1]];
                            [keyString appendFormat:@"%02x",IDByte[0]];
                            
                            NSMutableString *tableCode = [NSMutableString string];
                            BOOL result = isPureInt(keyString);
                            if (result == YES) {
                                if ((IDByte[1] & 0x80) == 0) {
                                    [tableCode appendFormat:@"%02x",IDByte[1]];
                                }else if ((IDByte[1] & 0x80) == 0x80){
                                    IDByte[1] &= 0x7F;
                                    [tableCode appendFormat:@"-%02x",IDByte[1]];
                                }
                                [tableCode appendFormat:@"%02x",IDByte[0]];
                            }else{
                                [tableCode appendFormat:@"%02x",IDByte[1]];
                                [tableCode appendFormat:@"%02x",IDByte[0]];
                            }
                            NSRange range = {3,0};
                            NSString *aac = [tableCode stringByReplacingCharactersInRange:range withString:@"."];
                            [codeArr addObject:aac];
                            
                            DataModel * data = [[DataModel alloc] init];
                            DateModel * date = [[DateModel alloc]init];
                            date.data = [[NSMutableArray alloc] init];
                            for (DateModel * date1 in deModel.dataArr) {
                                if ([date1.day intValue] == [day intValue]) {
                                    //找到该Day数据
                                    date = date1;
                                    new2 = 0;
                                    if ((date1.data.count ) > j) {
                                        new = 0;//0表示Data已存在
                                        data.voltageA = aac;
                                        data.point = [NSString stringWithFormat:@"%d",j];
                                        data.name = _wycName;
                                        data.Month = month;
                                        data.year = year;
                                        data.day = day;
                                        data.hour = @"00";
                                        data.ct = [NSString stringWithFormat:@"%d",ct];
                                        data.pt = [NSString stringWithFormat:@"%d",pt];
                                        NSString * tString =  [HY_NSusefDefaults objectForKey:@"TIME"];
                                        int t = (dis - [tString intValue])/(15 * 60);
                                        data.my_id = [NSString stringWithFormat:@"%d",t +j];
                                        DataModel * newData = date1.data[j];
                                        newData.voltageA = tableCode;
                                        
                                    }else if ((date1.data.count ) <= j){
                                        data.voltageA = aac;
                                        data.point = [NSString stringWithFormat:@"%d",j];
                                        data.name = _wycName;
                                        data.Month = month;
                                        data.year = year;
                                        data.day = day;
                                        data.hour = @"00";
                                        data.ct = [NSString stringWithFormat:@"%d",ct];
                                        data.pt = [NSString stringWithFormat:@"%d",pt];
                                        NSString * tString =  [HY_NSusefDefaults objectForKey:@"TIME"];
                                        int t = (dis - [tString intValue])/(15 * 60);
                                        data.my_id = [NSString stringWithFormat:@"%d",t +j];
                                        date1.day = day;
                                        [date1.data addObject:data];
                                    }
                                }
                                
                            }
                            if (new2 == 1) {//new
                                data.voltageA = aac;
                                data.point = [NSString stringWithFormat:@"%d",j];
                                data.name = _wycName;
                                data.Month = month;
                                data.year = year;
                                data.day = day;
                                data.hour = @"00";
                                data.ct = [NSString stringWithFormat:@"%d",ct];
                                data.pt = [NSString stringWithFormat:@"%d",pt];
                                NSString * tString =  [HY_NSusefDefaults objectForKey:@"TIME"];
                                int t = (dis - [tString intValue])/(15 * 60);
                                data.my_id = [NSString stringWithFormat:@"%d",t +j];
                                date.day = day;
                                [date.data addObject:data];
                                [deModel.dataArr addObject:date];
                            }
                        }
                        
                        //存储
                        deModel.De_addr = [NSString stringWithFormat:@"%llu",mp_ID];
                        deModel.pointNum = [NSString stringWithFormat:@"%d",num + [deModel.pointNum intValue]];
                        //将设备存入单利
                        if (new1 == 1) {//新创建
                            [manager.memory_Array addObject:deModel];
                        }else if (new == 0){//已存在
                            for (int i = 0;i<manager.memory_Array.count; i++ ) {
                                DeviceModel * data1 = manager.memory_Array[i];
                                if ([data1.De_addr isEqualToString: _wyc_adress]) {
                                    //找到该设备更新数据
                                    data1 = deModel;
                                }
                            }
                            
                        }
/////////////////////////////////
                    }
                    break;
                }
                case 90:
                {//B相电压
                    for (n = 0; n<pnLen; n++) {
                        UInt64 mp_ID = 0;
                        HYSingleManager *manager = [HYSingleManager sharedManager];
                        for (int a = 0; a<manager.archiveUser.child_obj.count; a++) {
                            CCompanyModel *company = manager.archiveUser.child_obj[a];
                            for (int b = 0; b<company.child_obj1.count; b++) {
                                CTerminalModel *terminal = company.child_obj1[b];
                                if ([terminal.term_ID isEqualToString:strAddr]) {
                                    for (int c = 0; c<terminal.child_obj.count; c++) {
                                        CMPModel *mp = terminal.child_obj[c];
                                        if (mp.mp_point == pn[n]) {
                                            mp_ID = mp.strID;
                                            _wycName = mp.name;
                                            ct = mp.mp_CT;
                                            pt = mp.mp_PT;
                                            _wyc_adress = [NSString stringWithFormat:@"%llu",mp_ID];
                                            if (memory_Array.count > 0) {
                                                for (DeviceModel * deM in memory_Array) {
                                                    if ([deM.De_addr isEqualToString:[NSString stringWithFormat:@"%llu",mp_ID]] ) {
                                                        //设备ID相同，取出设备
                                                        deModel = deM;
                                                        new1 = 0;
                                                    }
                                                }
                                            }

                                        }
                                    }
                                }
                                
                            }
                        }
                        NSString *year = [NSString stringWithFormat:@"%x",pBuf[i+4]];
                        NSString *month = [NSString stringWithFormat:@"%x",pBuf[i+3]];
                        NSString *day = [NSString stringWithFormat:@"%x",pBuf[i+2]];
                        NSDate* dat = [NSDate dateWithTimeIntervalSinceNow:0];
                        NSTimeInterval a=[dat timeIntervalSince1970];
                        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                        [formatter setDateFormat:@"YY/MM/dd"];
                        NSDate *curDate = [formatter dateFromString:[NSString stringWithFormat:@"%d/%d/%d",[year intValue],[month intValue],[day intValue]]];
                        NSTimeInterval dis = [curDate timeIntervalSince1970];
                        int c = a - dis;
                        int type = c/ONEDay;
                        NSString *typeStr = [NSString stringWithFormat:@"%d",type];
                        i += 7;
                        NSMutableArray *codeArr = [NSMutableArray array];
                        for (int j = 0; j<num; j++) {
                            Byte IDByte[2];
                            for (int k = 0; k<2; k++,i++) {
                                IDByte[k] = pBuf[i];
                            }
                            NSMutableString *keyString = [NSMutableString string];
                            [keyString appendFormat:@"%02x",IDByte[1]];
                            [keyString appendFormat:@"%02x",IDByte[0]];
                            
                            NSMutableString *tableCode = [NSMutableString string];
                            BOOL result = isPureInt(keyString);
                            if (result == YES) {
                                if ((IDByte[1] & 0x80) == 0) {
                                    [tableCode appendFormat:@"%02x",IDByte[1]];
                                }else if ((IDByte[1] & 0x80) == 0x80){
                                    IDByte[1] &= 0x7F;
                                    [tableCode appendFormat:@"-%02x",IDByte[1]];
                                }
                                [tableCode appendFormat:@"%02x",IDByte[0]];
                            }else{
                                [tableCode appendFormat:@"%02x",IDByte[1]];
                                [tableCode appendFormat:@"%02x",IDByte[0]];
                            }
                            NSRange range = {3,0};
                            NSString *aac = [tableCode stringByReplacingCharactersInRange:range withString:@"."];
                            [codeArr addObject:aac];
                            
                            DataModel * data = [[DataModel alloc] init];
                            DateModel * date = [[DateModel alloc]init];
                            date.data = [[NSMutableArray alloc] init];
                            for (DateModel * date1 in deModel.dataArr) {
                                if ([date1.day intValue] == [day intValue]) {
                                    //找到该Day数据
                                    date = date1;
                                    new2 = 0;
                                    if ((date1.data.count ) > j) {
                                        new = 0;//0表示Data已存在
                                        data.voltageB = aac;
                                        data.point = [NSString stringWithFormat:@"%d",j];
                                        data.name = _wycName;
                                        data.Month = month;
                                        data.year = year;
                                        data.day = day;
                                        data.hour = @"00";
                                        data.ct = [NSString stringWithFormat:@"%d",ct];
                                        data.pt = [NSString stringWithFormat:@"%d",pt];
                                        NSString * tString =  [HY_NSusefDefaults objectForKey:@"TIME"];
                                        int t = (dis - [tString intValue])/(15 * 60);
                                        data.my_id = [NSString stringWithFormat:@"%d",t +j];
                                        DataModel * newData = date1.data[j];
                                        newData.voltageB = aac;
                                        
                                    }else if ((date1.data.count ) <= j){
                                        data.voltageB = aac;
                                        data.point = [NSString stringWithFormat:@"%d",j];
                                        data.name = _wycName;
                                        data.Month = month;
                                        data.year = year;
                                        data.day = day;
                                        data.hour = @"00";
                                        data.ct = [NSString stringWithFormat:@"%d",ct];
                                        data.pt = [NSString stringWithFormat:@"%d",pt];
                                        NSString * tString =  [HY_NSusefDefaults objectForKey:@"TIME"];
                                        int t = (dis - [tString intValue])/(15 * 60);
                                        data.my_id = [NSString stringWithFormat:@"%d",t +j];
                                        date1.day = day;
                                        [date1.data addObject:data];
                                    }
                                }
                                
                            }
                            if (new2 == 1) {//new
                                data.voltageB = aac;
                                data.point = [NSString stringWithFormat:@"%d",j];
                                data.name = _wycName;
                                data.Month = month;
                                data.year = year;
                                data.day = day;
                                data.hour = @"00";
                                data.ct = [NSString stringWithFormat:@"%d",ct];
                                data.pt = [NSString stringWithFormat:@"%d",pt];
                                NSString * tString =  [HY_NSusefDefaults objectForKey:@"TIME"];
                                int t = (dis - [tString intValue])/(15 * 60);
                                data.my_id = [NSString stringWithFormat:@"%d",t +j];
                                date.day = day;
                                [date.data addObject:data];
                                [deModel.dataArr addObject:date];
                            }

                        }
                        //存储
                        deModel.De_addr = [NSString stringWithFormat:@"%llu",mp_ID];
                        deModel.pointNum = [NSString stringWithFormat:@"%d",num + [deModel.pointNum intValue]];
                        //将设备存入单利
                        if (new1 == 1) {//新创建
                            [manager.memory_Array addObject:deModel];
                        }else if (new == 0){//已存在
                            for (int i = 0;i<manager.memory_Array.count; i++ ) {
                                DeviceModel * data1 = manager.memory_Array[i];
                                if ([data1.De_addr isEqualToString: _wyc_adress]) {
                                    //找到该设备更新数据
                                    data1 = deModel;
                                }
                            }
                            
                        }
                    }
                    break;
                }
                case 91:
                {//C相电压
                    for (n = 0; n<pnLen; n++) {
                        UInt64 mp_ID = 0;
                        HYSingleManager *manager = [HYSingleManager sharedManager];
                        for (int a = 0; a<manager.archiveUser.child_obj.count; a++) {
                            CCompanyModel *company = manager.archiveUser.child_obj[a];
                            for (int b = 0; b<company.child_obj1.count; b++) {
                                CTerminalModel *terminal = company.child_obj1[b];
                                if ([terminal.term_ID isEqualToString:strAddr]) {
                                    for (int c = 0; c<terminal.child_obj.count; c++) {
                                        CMPModel *mp = terminal.child_obj[c];
                                        if (mp.mp_point == pn[n]) {
                                            mp_ID = mp.strID;
                                            _wycName = mp.name;
                                            ct = mp.mp_CT;
                                            pt = mp.mp_PT;
                                            _wyc_adress = [NSString stringWithFormat:@"%llu",mp_ID];
                                            if (memory_Array.count > 0) {
                                                for (DeviceModel * deM in memory_Array) {
                                                    if ([deM.De_addr isEqualToString:[NSString stringWithFormat:@"%llu",mp_ID]] ) {
                                                        //设备ID相同，取出设备
                                                        deModel = deM;
                                                        new1 = 0;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                
                            }
                        }
                        NSString *year = [NSString stringWithFormat:@"%x",pBuf[i+4]];
                        NSString *month = [NSString stringWithFormat:@"%x",pBuf[i+3]];
                        NSString *day = [NSString stringWithFormat:@"%x",pBuf[i+2]];
                        NSDate* dat = [NSDate dateWithTimeIntervalSinceNow:0];
                        NSTimeInterval a=[dat timeIntervalSince1970];
                        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                        [formatter setDateFormat:@"YY/MM/dd"];
                        NSDate *curDate = [formatter dateFromString:[NSString stringWithFormat:@"%d/%d/%d",[year intValue],[month intValue],[day intValue]]];
                        NSTimeInterval dis = [curDate timeIntervalSince1970];
                        int c = a - dis;
                        int type = c/ONEDay;
                        NSString *typeStr = [NSString stringWithFormat:@"%d",type];
                        i += 7;
                        NSMutableArray *codeArr = [NSMutableArray array];
                        for (int j = 0; j<num; j++) {
                            Byte IDByte[2];
                            for (int k = 0; k<2; k++,i++) {
                                IDByte[k] = pBuf[i];
                            }
                            NSMutableString *keyString = [NSMutableString string];
                            [keyString appendFormat:@"%02x",IDByte[1]];
                            [keyString appendFormat:@"%02x",IDByte[0]];
                            
                            NSMutableString *tableCode = [NSMutableString string];
                            BOOL result = isPureInt(keyString);
                            if (result == YES) {
                                if ((IDByte[1] & 0x80) == 0) {
                                    [tableCode appendFormat:@"%02x",IDByte[1]];
                                }else if ((IDByte[1] & 0x80) == 0x80){
                                    IDByte[1] &= 0x7F;
                                    [tableCode appendFormat:@"-%02x",IDByte[1]];
                                }
                                [tableCode appendFormat:@"%02x",IDByte[0]];
                            }else{
                                [tableCode appendFormat:@"%02x",IDByte[1]];
                                [tableCode appendFormat:@"%02x",IDByte[0]];
                            }
                            NSRange range = {3,0};
                            NSString *aac = [tableCode stringByReplacingCharactersInRange:range withString:@"."];
                            [codeArr addObject:aac];
                            
                            DataModel * data = [[DataModel alloc] init];
                            DateModel * date = [[DateModel alloc]init];
                            date.data = [[NSMutableArray alloc] init];
                            for (DateModel * date1 in deModel.dataArr) {
                                if ([date1.day intValue] == [day intValue]) {
                                    //找到该Day数据
                                    date = date1;
                                    new2 = 0;
                                    if ((date1.data.count ) > j) {
                                        new = 0;//0表示Data已存在
                                        data.voltageC = aac;
                                        data.point = [NSString stringWithFormat:@"%d",j];
                                        data.name = _wycName;
                                        data.Month = month;
                                        data.year = year;
                                        data.day = day;
                                        data.hour = @"00";
                                        data.ct = [NSString stringWithFormat:@"%d",ct];
                                        data.pt = [NSString stringWithFormat:@"%d",pt];
                                        NSString * tString =  [HY_NSusefDefaults objectForKey:@"TIME"];
                                        int t = (dis - [tString intValue])/(15 * 60);
                                        data.my_id = [NSString stringWithFormat:@"%d",t +j];
                                        DataModel * newData = date1.data[j];
                                        newData.voltageC = aac;
                                        
                                    }else if ((date1.data.count ) <= j){
                                        data.voltageC = aac;
                                        data.point = [NSString stringWithFormat:@"%d",j];
                                        data.name = _wycName;
                                        data.Month = month;
                                        data.year = year;
                                        data.day = day;
                                        data.hour = @"00";
                                        data.ct = [NSString stringWithFormat:@"%d",ct];
                                        data.pt = [NSString stringWithFormat:@"%d",pt];
                                        NSString * tString =  [HY_NSusefDefaults objectForKey:@"TIME"];
                                        int t = (dis - [tString intValue])/(15 * 60);
                                        data.my_id = [NSString stringWithFormat:@"%d",t +j];
                                        date1.day = day;
                                        [date1.data addObject:data];
                                    }
                                }
                                
                            }
                            if (new2 == 1) {//new
                                data.voltageC = aac;
                                data.point = [NSString stringWithFormat:@"%d",j];
                                data.name = _wycName;
                                data.Month = month;
                                data.year = year;
                                data.day = day;
                                data.hour = @"00";
                                data.ct = [NSString stringWithFormat:@"%d",ct];
                                data.pt = [NSString stringWithFormat:@"%d",pt];
                                NSString * tString =  [HY_NSusefDefaults objectForKey:@"TIME"];
                                int t = (dis - [tString intValue])/(15 * 60);
                                data.my_id = [NSString stringWithFormat:@"%d",t +j];
                                date.day = day;
                                [date.data addObject:data];
                                [deModel.dataArr addObject:date];
                            }
                        }
                        //存储
                        deModel.De_addr = [NSString stringWithFormat:@"%llu",mp_ID];
                        deModel.pointNum = [NSString stringWithFormat:@"%d",num + [deModel.pointNum intValue]];
                        //将设备存入单利
                        if (new1 == 1) {//新创建
                            [manager.memory_Array addObject:deModel];
                        }else if (new == 0){//已存在
                            for (int i = 0;i<manager.memory_Array.count; i++ ) {
                                DeviceModel * data1 = manager.memory_Array[i];
                                if ([data1.De_addr isEqualToString: _wyc_adress]) {
                                    //找到该设备更新数据
                                    data1 = deModel;
                                }
                            }
                            
                        }
/////////////////////
                    }
                    break;
                }
                case 92:
                {//A相电流
                    for (n = 0; n<pnLen; n++) {
                        UInt64 mp_ID = 0;
                        HYSingleManager *manager = [HYSingleManager sharedManager];
                        for (int a = 0; a<manager.archiveUser.child_obj.count; a++) {
                            CCompanyModel *company = manager.archiveUser.child_obj[a];
                            for (int b = 0; b<company.child_obj1.count; b++) {
                                CTerminalModel *terminal = company.child_obj1[b];
                                if ([terminal.term_ID isEqualToString:strAddr]) {
                                    for (int c = 0; c<terminal.child_obj.count; c++) {
                                        CMPModel *mp = terminal.child_obj[c];
                                        if (mp.mp_point == pn[n]) {
                                            mp_ID = mp.strID;
                                            _wycName = mp.name;
                                            ct = mp.mp_CT;
                                            pt = mp.mp_PT;
                                            _wyc_adress = [NSString stringWithFormat:@"%llu",mp_ID];
                                            if (memory_Array.count > 0) {
                                                for (DeviceModel * deM in memory_Array) {
                                                    if ([deM.De_addr isEqualToString:[NSString stringWithFormat:@"%llu",mp_ID]] ) {
                                                        //设备ID相同，取出设备
                                                        deModel = deM;
                                                        new1 = 0;
                                                    }
                                                }
                                            }

                                        }
                                    }
                                }
                                
                            }
                        }
                        NSString *year = [NSString stringWithFormat:@"%x",pBuf[i+4]];
                        NSString *month = [NSString stringWithFormat:@"%x",pBuf[i+3]];
                        NSString *day = [NSString stringWithFormat:@"%x",pBuf[i+2]];
                        NSDate* dat = [NSDate dateWithTimeIntervalSinceNow:0];
                        NSTimeInterval a=[dat timeIntervalSince1970];
                        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                        [formatter setDateFormat:@"YY/MM/dd"];
                        NSDate *curDate = [formatter dateFromString:[NSString stringWithFormat:@"%d/%d/%d",[year intValue],[month intValue],[day intValue]]];
                        NSTimeInterval dis = [curDate timeIntervalSince1970];
                        int c = a - dis;
                        int type = c/ONEDay;
                        NSString *typeStr = [NSString stringWithFormat:@"%d",type];
                        i += 7;
                        NSMutableArray *codeArr = [NSMutableArray array];
                        for (int j = 0; j<num; j++) {
                            Byte IDByte[3];
                            for (int k = 0; k<3; k++,i++) {
                                IDByte[k] = pBuf[i];
                            }
                            NSMutableString *keyString = [NSMutableString string];
                            [keyString appendFormat:@"%02x",IDByte[2]];
                            [keyString appendFormat:@"%02x",IDByte[1]];
                            [keyString appendFormat:@"%02x",IDByte[0]];
                            
                            NSMutableString *tableCode = [NSMutableString string];
                            BOOL result = isPureInt(keyString);
                            if (result == YES) {
                                if ((IDByte[2] & 0x80) == 0) {
                                    [tableCode appendFormat:@"%02x",IDByte[2]];
                                }else if ((IDByte[2] & 0x80) == 0x80){
                                    IDByte[2] &= 0x7F;
                                    [tableCode appendFormat:@"-%02x",IDByte[2]];
                                }
                                [tableCode appendFormat:@"%02x",IDByte[1]];
                                [tableCode appendFormat:@"%02x",IDByte[0]];
                            }else{
                                [tableCode appendFormat:@"%02x",IDByte[2]];
                                [tableCode appendFormat:@"%02x",IDByte[1]];
                                [tableCode appendFormat:@"%02x",IDByte[0]];
                            }
                            NSRange range = {3,0};
                            NSString *aac = [tableCode stringByReplacingCharactersInRange:range withString:@"."];
                            [codeArr addObject:aac];
                            DataModel * data = [[DataModel alloc] init];
                            DateModel * date = [[DateModel alloc]init];
                            date.data = [[NSMutableArray alloc] init];
                            for (DateModel * date1 in deModel.dataArr) {
                                if ([date1.day intValue] == [day intValue]) {
                                    //找到该Day数据
                                    date = date1;
                                    new2 = 0;
                                    if ((date1.data.count ) > j) {
                                        new = 0;//0表示Data已存在
                                        data.electricA = aac;
                                        data.point = [NSString stringWithFormat:@"%d",j];
                                        data.name = _wycName;
                                        data.Month = month;
                                        data.year = year;
                                        data.day = day;
                                        data.hour = @"00";
                                        data.ct = [NSString stringWithFormat:@"%d",ct];
                                        data.pt = [NSString stringWithFormat:@"%d",pt];
                                        NSString * tString =  [HY_NSusefDefaults objectForKey:@"TIME"];
                                        int t = (dis - [tString intValue])/(15 * 60);
                                        data.my_id = [NSString stringWithFormat:@"%d",t +j];
                                        DataModel * newData = date1.data[j];
                                        newData.electricA = aac;
                                        
                                    }else if ((date1.data.count ) <= j){
                                        data.electricA = aac;
                                        data.point = [NSString stringWithFormat:@"%d",j];
                                        data.name = _wycName;
                                        data.Month = month;
                                        data.year = year;
                                        data.day = day;
                                        data.hour = @"00";
                                        data.ct = [NSString stringWithFormat:@"%d",ct];
                                        data.pt = [NSString stringWithFormat:@"%d",pt];
                                        NSString * tString =  [HY_NSusefDefaults objectForKey:@"TIME"];
                                        int t = (dis - [tString intValue])/(15 * 60);
                                        data.my_id = [NSString stringWithFormat:@"%d",t +j];
                                        date1.day = day;
                                        [date1.data addObject:data];
                                    }
                                }
                                
                            }
                            if (new2 == 1) {//new
                                data.electricA = aac;
                                data.point = [NSString stringWithFormat:@"%d",j];
                                data.name = _wycName;
                                data.Month = month;
                                data.year = year;
                                data.day = day;
                                data.hour = @"00";
                                data.ct = [NSString stringWithFormat:@"%d",ct];
                                data.pt = [NSString stringWithFormat:@"%d",pt];
                                NSString * tString =  [HY_NSusefDefaults objectForKey:@"TIME"];
                                int t = (dis - [tString intValue])/(15 * 60);
                                data.my_id = [NSString stringWithFormat:@"%d",t +j];
                                date.day = day;
                                [date.data addObject:data];
                                [deModel.dataArr addObject:date];
                            }
                        }
                        //存储
                        deModel.De_addr = [NSString stringWithFormat:@"%llu",mp_ID];
                        deModel.pointNum = [NSString stringWithFormat:@"%d",num + [deModel.pointNum intValue]];
                        //将设备存入单利
                        if (new1 == 1) {//新创建
                            [manager.memory_Array addObject:deModel];
                        }else if (new == 0){//已存在
                            for (int i = 0;i<manager.memory_Array.count; i++ ) {
                                DeviceModel * data1 = manager.memory_Array[i];
                                if ([data1.De_addr isEqualToString: _wyc_adress]) {
                                    //找到该设备更新数据
                                    data1 = deModel;
                                }
                            }
                            
                        }
////////////////////
                        if (manager.electricA_dict[[NSString stringWithFormat:@"%llu",mp_ID] ] == nil) {
                            NSMutableDictionary *dic = [NSMutableDictionary dictionary];
                            [dic setObject:codeArr forKey:typeStr];
                            [manager.electricA_dict setObject:dic forKey:[NSString stringWithFormat:@"%llu",mp_ID]];
                        }else{
                            NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:manager.electricA_dict[[NSString stringWithFormat:@"%llu",mp_ID]]];
                            [dict setObject:codeArr forKey:typeStr];
                            [manager.electricA_dict setObject:dict forKey:[NSString stringWithFormat:@"%llu",mp_ID]];
                        }
                    }

                    break;
                }
                case 93:
                {//B相电流
                    for (n = 0; n<pnLen; n++) {
                        UInt64 mp_ID = 0;
                        HYSingleManager *manager = [HYSingleManager sharedManager];
                        for (int a = 0; a<manager.archiveUser.child_obj.count; a++) {
                            CCompanyModel *company = manager.archiveUser.child_obj[a];
                            for (int b = 0; b<company.child_obj1.count; b++) {
                                CTerminalModel *terminal = company.child_obj1[b];
                                if ([terminal.term_ID isEqualToString:strAddr]) {
                                    for (int c = 0; c<terminal.child_obj.count; c++) {
                                        CMPModel *mp = terminal.child_obj[c];
                                        if (mp.mp_point == pn[n]) {
                                            mp_ID = mp.strID;
                                            _wycName = mp.name;
                                            ct = mp.mp_CT;
                                            pt = mp.mp_PT;
                                            _wyc_adress = [NSString stringWithFormat:@"%llu",mp_ID];
                                            if (memory_Array.count > 0) {
                                                for (DeviceModel * deM in memory_Array) {
                                                    if ([deM.De_addr isEqualToString:[NSString stringWithFormat:@"%llu",mp_ID]] ) {
                                                        //设备ID相同，取出设备
                                                        deModel = deM;
                                                        new1 = 0;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                
                            }
                        }
                        NSString *year = [NSString stringWithFormat:@"%x",pBuf[i+4]];
                        NSString *month = [NSString stringWithFormat:@"%x",pBuf[i+3]];
                        NSString *day = [NSString stringWithFormat:@"%x",pBuf[i+2]];
                        NSDate* dat = [NSDate dateWithTimeIntervalSinceNow:0];
                        NSTimeInterval a=[dat timeIntervalSince1970];
                        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                        [formatter setDateFormat:@"YY/MM/dd"];
                        NSDate *curDate = [formatter dateFromString:[NSString stringWithFormat:@"%d/%d/%d",[year intValue],[month intValue],[day intValue]]];
                        NSTimeInterval dis = [curDate timeIntervalSince1970];
                        int c = a - dis;
                        int type = c/ONEDay;
                        NSString *typeStr = [NSString stringWithFormat:@"%d",type];
                        i += 7;
                        NSMutableArray *codeArr = [NSMutableArray array];
                        for (int j = 0; j<num; j++) {
                            Byte IDByte[3];
                            for (int k = 0; k<3; k++,i++) {
                                IDByte[k] = pBuf[i];
                            }
                            NSMutableString *keyString = [NSMutableString string];
                            [keyString appendFormat:@"%02x",IDByte[2]];
                            [keyString appendFormat:@"%02x",IDByte[1]];
                            [keyString appendFormat:@"%02x",IDByte[0]];
                            
                            NSMutableString *tableCode = [NSMutableString string];
                            BOOL result = isPureInt(keyString);
                            if (result == YES) {
                                if ((IDByte[2] & 0x80) == 0) {
                                    [tableCode appendFormat:@"%02x",IDByte[2]];
                                }else if ((IDByte[2] & 0x80) == 0x80){
                                    IDByte[2] &= 0x7F;
                                    [tableCode appendFormat:@"-%02x",IDByte[2]];
                                }
                                [tableCode appendFormat:@"%02x",IDByte[1]];
                                [tableCode appendFormat:@"%02x",IDByte[0]];
                            }else{
                                [tableCode appendFormat:@"%02x",IDByte[2]];
                                [tableCode appendFormat:@"%02x",IDByte[1]];
                                [tableCode appendFormat:@"%02x",IDByte[0]];
                            }
                            NSRange range = {3,0};
                            NSString *aac = [tableCode stringByReplacingCharactersInRange:range withString:@"."];
                            [codeArr addObject:aac];
                            DataModel * data = [[DataModel alloc] init];
                            DateModel * date = [[DateModel alloc]init];
                            date.data = [[NSMutableArray alloc] init];
                            for (DateModel * date1 in deModel.dataArr) {
                                if ([date1.day intValue] == [day intValue]) {
                                    //找到该Day数据
                                    date = date1;
                                    new2 = 0;
                                    if ((date1.data.count ) > j) {
                                        new = 0;//0表示Data已存在
                                        data.electricB = aac;
                                        data.point = [NSString stringWithFormat:@"%d",j];
                                        data.name = _wycName;
                                        data.Month = month;
                                        data.year = year;
                                        data.day = day;
                                        data.hour = @"00";
                                        data.ct = [NSString stringWithFormat:@"%d",ct];
                                        data.pt = [NSString stringWithFormat:@"%d",pt];
                                        NSString * tString =  [HY_NSusefDefaults objectForKey:@"TIME"];
                                        int t = (dis - [tString intValue])/(15 * 60);
                                        data.my_id = [NSString stringWithFormat:@"%d",t +j];
                                        DataModel * newData = date1.data[j];
                                        newData.electricB = aac;
                                        
                                    }else if ((date1.data.count ) <= j){
                                        data.electricB = aac;
                                        data.point = [NSString stringWithFormat:@"%d",j];
                                        data.name = _wycName;
                                        data.Month = month;
                                        data.year = year;
                                        data.day = day;
                                        data.hour = @"00";
                                        data.ct = [NSString stringWithFormat:@"%d",ct];
                                        data.pt = [NSString stringWithFormat:@"%d",pt];
                                        NSString * tString =  [HY_NSusefDefaults objectForKey:@"TIME"];
                                        int t = (dis - [tString intValue])/(15 * 60);
                                        data.my_id = [NSString stringWithFormat:@"%d",t +j];
                                        date1.day = day;
                                        [date1.data addObject:data];
                                    }
                                }
                                
                            }
                            if (new2 == 1) {//new
                                data.electricB = aac;
                                data.point = [NSString stringWithFormat:@"%d",j];
                                data.name = _wycName;
                                data.Month = month;
                                data.year = year;
                                data.day = day;
                                data.hour = @"00";
                                data.ct = [NSString stringWithFormat:@"%d",ct];
                                data.pt = [NSString stringWithFormat:@"%d",pt];
                                NSString * tString =  [HY_NSusefDefaults objectForKey:@"TIME"];
                                int t = (dis - [tString intValue])/(15 * 60);
                                data.my_id = [NSString stringWithFormat:@"%d",t +j];
                                date.day = day;
                                [date.data addObject:data];
                                [deModel.dataArr addObject:date];
                            }
                        }
                        //存储
                        deModel.De_addr = [NSString stringWithFormat:@"%llu",mp_ID];
                        deModel.pointNum = [NSString stringWithFormat:@"%d",num + [deModel.pointNum intValue]];
                        //将设备存入单利
                        if (new1 == 1) {//新创建
                            [manager.memory_Array addObject:deModel];
                        }else if (new == 0){//已存在
                            for (int i = 0;i<manager.memory_Array.count; i++ ) {
                                DeviceModel * data1 = manager.memory_Array[i];
                                if ([data1.De_addr isEqualToString: _wyc_adress]) {
                                    //找到该设备更新数据
                                    data1 = deModel;
                                }
                            }
                            
                        }
////////////////
                        if (manager.electricB_dict[[NSString stringWithFormat:@"%llu",mp_ID] ] == nil) {
                            NSMutableDictionary *dic = [NSMutableDictionary dictionary];
                            [dic setObject:codeArr forKey:typeStr];
                            [manager.electricB_dict setObject:dic forKey:[NSString stringWithFormat:@"%llu",mp_ID]];
                        }else{
                            NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:manager.electricB_dict[[NSString stringWithFormat:@"%llu",mp_ID]]];
                            [dict setObject:codeArr forKey:typeStr];
                            [manager.electricB_dict setObject:dict forKey:[NSString stringWithFormat:@"%llu",mp_ID]];
                        }
                    }
                    break;
                }
                case 94:
                {//C相电流
                    for (n = 0; n<pnLen; n++) {
                        UInt64 mp_ID = 0;
                        HYSingleManager *manager = [HYSingleManager sharedManager];
                        for (int a = 0; a<manager.archiveUser.child_obj.count; a++) {
                            CCompanyModel *company = manager.archiveUser.child_obj[a];
                            for (int b = 0; b<company.child_obj1.count; b++) {
                                CTerminalModel *terminal = company.child_obj1[b];
                                if ([terminal.term_ID isEqualToString:strAddr]) {
                                    for (int c = 0; c<terminal.child_obj.count; c++) {
                                        CMPModel *mp = terminal.child_obj[c];
                                        if (mp.mp_point == pn[n]) {
                                            mp_ID = mp.strID;
                                            _wycName = mp.name;
                                            ct = mp.mp_CT;
                                            pt = mp.mp_PT;
                                            _wyc_adress = [NSString stringWithFormat:@"%llu",mp_ID];
                                            if (memory_Array.count > 0) {
                                                for (DeviceModel * deM in memory_Array) {
                                                    if ([deM.De_addr isEqualToString:[NSString stringWithFormat:@"%llu",mp_ID]] ) {
                                                        //设备ID相同，取出设备
                                                        deModel = deM;
                                                        new1 = 0;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                
                            }
                        }
                        NSString *year = [NSString stringWithFormat:@"%x",pBuf[i+4]];
                        NSString *month = [NSString stringWithFormat:@"%x",pBuf[i+3]];
                        NSString *day = [NSString stringWithFormat:@"%x",pBuf[i+2]];
                        NSDate* dat = [NSDate dateWithTimeIntervalSinceNow:0];
                        NSTimeInterval a=[dat timeIntervalSince1970];
                        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                        [formatter setDateFormat:@"YY/MM/dd"];
                        NSDate *curDate = [formatter dateFromString:[NSString stringWithFormat:@"%d/%d/%d",[year intValue],[month intValue],[day intValue]]];
                        NSTimeInterval dis = [curDate timeIntervalSince1970];
                        int c = a - dis;
                        int type = c/ONEDay;
                        NSString *typeStr = [NSString stringWithFormat:@"%d",type];
                        i += 7;
                        NSMutableArray *codeArr = [NSMutableArray array];
                        for (int j = 0; j<num; j++) {
                            Byte IDByte[3];
                            for (int k = 0; k<3; k++,i++) {
                                IDByte[k] = pBuf[i];
                            }
                            NSMutableString *keyString = [NSMutableString string];
                            [keyString appendFormat:@"%02x",IDByte[2]];
                            [keyString appendFormat:@"%02x",IDByte[1]];
                            [keyString appendFormat:@"%02x",IDByte[0]];
                            
                            NSMutableString *tableCode = [NSMutableString string];
                            BOOL result = isPureInt(keyString);
                            if (result == YES) {
                                if ((IDByte[2] & 0x80) == 0) {
                                    [tableCode appendFormat:@"%02x",IDByte[2]];
                                }else if ((IDByte[2] & 0x80) == 0x80){
                                    IDByte[2] &= 0x7F;
                                    [tableCode appendFormat:@"-%02x",IDByte[2]];
                                }
                                [tableCode appendFormat:@"%02x",IDByte[1]];
                                [tableCode appendFormat:@"%02x",IDByte[0]];
                            }else{
                                [tableCode appendFormat:@"%02x",IDByte[2]];
                                [tableCode appendFormat:@"%02x",IDByte[1]];
                                [tableCode appendFormat:@"%02x",IDByte[0]];
                            }
                            NSRange range = {3,0};
                            NSString *aac = [tableCode stringByReplacingCharactersInRange:range withString:@"."];
                            [codeArr addObject:aac];
                            DataModel * data = [[DataModel alloc] init];
                            DateModel * date = [[DateModel alloc]init];
                            date.data = [[NSMutableArray alloc] init];
                            for (DateModel * date1 in deModel.dataArr) {
                                if ([date1.day intValue] == [day intValue]) {
                                    //找到该Day数据
                                    date = date1;
                                    new2 = 0;
                                    if ((date1.data.count ) > j) {
                                        new = 0;//0表示Data已存在
                                        data.electricC = aac;
                                        data.point = [NSString stringWithFormat:@"%d",j];
                                        data.name = _wycName;
                                        data.Month = month;
                                        data.year = year;
                                        data.day = day;
                                        data.hour = @"00";
                                        data.ct = [NSString stringWithFormat:@"%d",ct];
                                        data.pt = [NSString stringWithFormat:@"%d",pt];
                                        NSString * tString =  [HY_NSusefDefaults objectForKey:@"TIME"];
                                        int t = (dis - [tString intValue])/(15 * 60);
                                        data.my_id = [NSString stringWithFormat:@"%d",t +j];
                                        DataModel * newData = date1.data[j];
                                        newData.electricC = aac;
                                        
                                    }else if ((date1.data.count ) <= j){
                                        data.electricC = aac;
                                        data.point = [NSString stringWithFormat:@"%d",j];
                                        data.name = _wycName;
                                        data.Month = month;
                                        data.year = year;
                                        data.day = day;
                                        data.hour = @"00";
                                        data.ct = [NSString stringWithFormat:@"%d",ct];
                                        data.pt = [NSString stringWithFormat:@"%d",pt];
                                        NSString * tString =  [HY_NSusefDefaults objectForKey:@"TIME"];
                                        int t = (dis - [tString intValue])/(15 * 60);
                                        data.my_id = [NSString stringWithFormat:@"%d",t +j];
                                        date1.day = day;
                                        [date1.data addObject:data];
                                    }
                                }
                                
                            }
                            if (new2 == 1) {//new
                                data.electricC = aac;
                                data.point = [NSString stringWithFormat:@"%d",j];
                                data.name = _wycName;
                                data.Month = month;
                                data.year = year;
                                data.day = day;
                                data.hour = @"00";
                                data.ct = [NSString stringWithFormat:@"%d",ct];
                                data.pt = [NSString stringWithFormat:@"%d",pt];
                                NSString * tString =  [HY_NSusefDefaults objectForKey:@"TIME"];
                                int t = (dis - [tString intValue])/(15 * 60);
                                data.my_id = [NSString stringWithFormat:@"%d",t +j];
                                date.day = day;
                                [date.data addObject:data];
                                [deModel.dataArr addObject:date];
                            }
                        }
                        //存储
                        deModel.De_addr = [NSString stringWithFormat:@"%llu",mp_ID];
                        deModel.pointNum = [NSString stringWithFormat:@"%d",num + [deModel.pointNum intValue]];
                        //将设备存入单利
                        if (new1 == 1) {//新创建
                            [manager.memory_Array addObject:deModel];
                        }else if (new == 0){//已存在
                            for (int i = 0;i<manager.memory_Array.count; i++ ) {
                                DeviceModel * data1 = manager.memory_Array[i];
                                if ([data1.De_addr isEqualToString: _wyc_adress]) {
                                    //找到该设备更新数据
                                    data1 = deModel;
                                }
                            }
                            
                        }

                        if (manager.electricC_dict[[NSString stringWithFormat:@"%llu",mp_ID] ] == nil) {
                            NSMutableDictionary *dic = [NSMutableDictionary dictionary];
                            [dic setObject:codeArr forKey:typeStr];
                            [manager.electricC_dict setObject:dic forKey:[NSString stringWithFormat:@"%llu",mp_ID]];
                        }else{
                            NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:manager.electricC_dict[[NSString stringWithFormat:@"%llu",mp_ID]]];
                            [dict setObject:codeArr forKey:typeStr];
                            [manager.electricC_dict setObject:dict forKey:[NSString stringWithFormat:@"%llu",mp_ID]];
                        }
                    }
                    break;
                }
                case 82:
                {//A相有功功率
                    for (n = 0; n<pnLen; n++) {
                        UInt64 mp_ID = 0;
                        HYSingleManager *manager = [HYSingleManager sharedManager];
                        for (int a = 0; a<manager.archiveUser.child_obj.count; a++) {
                            CCompanyModel *company = manager.archiveUser.child_obj[a];
                            for (int b = 0; b<company.child_obj1.count; b++) {
                                CTerminalModel *terminal = company.child_obj1[b];
                                if ([terminal.term_ID isEqualToString:strAddr]) {
                                    for (int c = 0; c<terminal.child_obj.count; c++) {
                                        CMPModel *mp = terminal.child_obj[c];
                                        if (mp.mp_point == pn[n]) {
                                            mp_ID = mp.strID;
                                            _wycName = mp.name;
                                            ct = mp.mp_CT;
                                            pt = mp.mp_PT;
                                            _wyc_adress = [NSString stringWithFormat:@"%llu",mp_ID];
                                            if (memory_Array.count > 0) {
                                                for (DeviceModel * deM in memory_Array) {
                                                    if ([deM.De_addr isEqualToString:[NSString stringWithFormat:@"%llu",mp_ID]] ) {
                                                        //设备ID相同，取出设备
                                                        deModel = deM;
                                                        new1 = 0;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                
                            }
                        }
                        NSString *year = [NSString stringWithFormat:@"%x",pBuf[i+4]];
                        NSString *month = [NSString stringWithFormat:@"%x",pBuf[i+3]];
                        NSString *day = [NSString stringWithFormat:@"%x",pBuf[i+2]];
                        NSDate* dat = [NSDate dateWithTimeIntervalSinceNow:0];
                        NSTimeInterval a=[dat timeIntervalSince1970];
                        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                        [formatter setDateFormat:@"YY/MM/dd"];
                        NSDate *curDate = [formatter dateFromString:[NSString stringWithFormat:@"%d/%d/%d",[year intValue],[month intValue],[day intValue]]];
                        NSTimeInterval dis = [curDate timeIntervalSince1970];
                        int c = a - dis;
                        int type = c/ONEDay;
                        NSString *typeStr = [NSString stringWithFormat:@"%d",type];
                        i += 7;
                        NSMutableArray *codeArr = [NSMutableArray array];
                        for (int j = 0; j<num; j++) {
                            Byte IDByte[3];
                            for (int k = 0; k<3; k++,i++) {
                                IDByte[k] = pBuf[i];
                            }
                            NSMutableString *keyString = [NSMutableString string];
                            [keyString appendFormat:@"%02x",IDByte[2]];
                            [keyString appendFormat:@"%02x",IDByte[1]];
                            [keyString appendFormat:@"%02x",IDByte[0]];
                            
                            NSMutableString *tableCode = [NSMutableString string];
                            BOOL result = isPureInt(keyString);
                            if (result == YES) {
                                if ((IDByte[2] & 0x80) == 0) {
                                    [tableCode appendFormat:@"%02x.",IDByte[2]];
                                }else if ((IDByte[2] & 0x80) == 0x80){
                                    IDByte[2] &= 0x7F;
                                    [tableCode appendFormat:@"-%02x.",IDByte[2]];
                                }
                                [tableCode appendFormat:@"%02x",IDByte[1]];
                                [tableCode appendFormat:@"%02x",IDByte[0]];
                            }else{
                                [tableCode appendFormat:@"%02x.",IDByte[2]];
                                [tableCode appendFormat:@"%02x",IDByte[1]];
                                [tableCode appendFormat:@"%02x",IDByte[0]];
                            }
                            [codeArr addObject:tableCode];
                            DataModel * data = [[DataModel alloc] init];
                            DateModel * date = [[DateModel alloc]init];
                            date.data = [[NSMutableArray alloc] init];
                            for (DateModel * date1 in deModel.dataArr) {
                                if ([date1.day intValue] == [day intValue]) {
                                    //找到该Day数据
                                    date = date1;
                                    new2 = 0;
                                    if ((date1.data.count ) > j) {
                                        new = 0;//0表示Data已存在
                                        data.activeA = tableCode;
                                        data.point = [NSString stringWithFormat:@"%d",j];
                                        data.name = _wycName;
                                        data.Month = month;
                                        data.year = year;
                                        data.day = day;
                                        data.hour = @"00";
                                        data.ct = [NSString stringWithFormat:@"%d",ct];
                                        data.pt = [NSString stringWithFormat:@"%d",pt];
                                        NSString * tString =  [HY_NSusefDefaults objectForKey:@"TIME"];
                                        int t = (dis - [tString intValue])/(15 * 60);
                                        data.my_id = [NSString stringWithFormat:@"%d",t +j];
                                        DataModel * newData = date1.data[j];
                                        newData.activeA = tableCode;
                                    }else if ((date1.data.count ) <= j){
                                        data.activeA = tableCode;
                                        data.point = [NSString stringWithFormat:@"%d",j];
                                        data.name = _wycName;
                                        data.Month = month;
                                        data.year = year;
                                        data.day = day;
                                        data.hour = @"00";
                                        data.ct = [NSString stringWithFormat:@"%d",ct];
                                        data.pt = [NSString stringWithFormat:@"%d",pt];
                                        NSString * tString =  [HY_NSusefDefaults objectForKey:@"TIME"];
                                        int t = (dis - [tString intValue])/(15 * 60);
                                        data.my_id = [NSString stringWithFormat:@"%d",t +j];
                                        date1.day = day;
                                        [date1.data addObject:data];
                                    }
                                }
                                
                            }
                            if (new2 == 1) {//new
                                data.activeA = tableCode;
                                data.point = [NSString stringWithFormat:@"%d",j];
                                data.name = _wycName;
                                data.Month = month;
                                data.year = year;
                                data.day = day;
                                data.hour = @"00";
                                data.ct = [NSString stringWithFormat:@"%d",ct];
                                data.pt = [NSString stringWithFormat:@"%d",pt];
                                NSString * tString =  [HY_NSusefDefaults objectForKey:@"TIME"];
                                int t = (dis - [tString intValue])/(15 * 60);
                                data.my_id = [NSString stringWithFormat:@"%d",t +j];
                                date.day = day;
                                [date.data addObject:data];
                                [deModel.dataArr addObject:date];
                            }

                        }
                        //存储
                        deModel.De_addr = [NSString stringWithFormat:@"%llu",mp_ID];
                        deModel.pointNum = [NSString stringWithFormat:@"%d",num + [deModel.pointNum intValue]];
                        //将设备存入单利
                        if (new1 == 1) {//新创建
                            [manager.memory_Array addObject:deModel];
                        }else if (new == 0){//已存在
                            for (int i = 0;i<manager.memory_Array.count; i++ ) {
                                DeviceModel * data1 = manager.memory_Array[i];
                                if ([data1.De_addr isEqualToString: _wyc_adress]) {
                                    //找到该设备更新数据
                                    data1 = deModel;
                                }
                            }
                            
                        }
/////////////
                      }
                    break;
                }
                case 83:
                {//B相有功功率
                    for (n = 0; n<pnLen; n++) {
                        UInt64 mp_ID = 0;
                        HYSingleManager *manager = [HYSingleManager sharedManager];
                        for (int a = 0; a<manager.archiveUser.child_obj.count; a++) {
                            CCompanyModel *company = manager.archiveUser.child_obj[a];
                            for (int b = 0; b<company.child_obj1.count; b++) {
                                CTerminalModel *terminal = company.child_obj1[b];
                                if ([terminal.term_ID isEqualToString:strAddr]) {
                                    for (int c = 0; c<terminal.child_obj.count; c++) {
                                        CMPModel *mp = terminal.child_obj[c];
                                        if (mp.mp_point == pn[n]) {
                                            mp_ID = mp.strID;
                                            _wycName = mp.name;
                                            ct = mp.mp_CT;
                                            pt = mp.mp_PT;
                                            _wyc_adress = [NSString stringWithFormat:@"%llu",mp_ID];
                                            if (memory_Array.count > 0) {
                                                for (DeviceModel * deM in memory_Array) {
                                                    if ([deM.De_addr isEqualToString:[NSString stringWithFormat:@"%llu",mp_ID]] ) {
                                                        //设备ID相同，取出设备
                                                        deModel = deM;
                                                        new1 = 0;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                
                            }
                        }
                        NSString *year = [NSString stringWithFormat:@"%x",pBuf[i+4]];
                        NSString *month = [NSString stringWithFormat:@"%x",pBuf[i+3]];
                        NSString *day = [NSString stringWithFormat:@"%x",pBuf[i+2]];
                        NSDate* dat = [NSDate dateWithTimeIntervalSinceNow:0];
                        NSTimeInterval a=[dat timeIntervalSince1970];
                        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                        [formatter setDateFormat:@"YY/MM/dd"];
                        NSDate *curDate = [formatter dateFromString:[NSString stringWithFormat:@"%d/%d/%d",[year intValue],[month intValue],[day intValue]]];
                        NSTimeInterval dis = [curDate timeIntervalSince1970];
                        int c = a - dis;
                        int type = c/ONEDay;
                        NSString *typeStr = [NSString stringWithFormat:@"%d",type];
                        i += 7;
                        NSMutableArray *codeArr = [NSMutableArray array];
                        for (int j = 0; j<num; j++) {
                            Byte IDByte[3];
                            for (int k = 0; k<3; k++,i++) {
                                IDByte[k] = pBuf[i];
                            }
                            NSMutableString *keyString = [NSMutableString string];
                            [keyString appendFormat:@"%02x",IDByte[2]];
                            [keyString appendFormat:@"%02x",IDByte[1]];
                            [keyString appendFormat:@"%02x",IDByte[0]];
                            
                            NSMutableString *tableCode = [NSMutableString string];
                            BOOL result = isPureInt(keyString);
                            if (result == YES) {
                                if ((IDByte[2] & 0x80) == 0) {
                                    [tableCode appendFormat:@"%02x.",IDByte[2]];
                                }else if ((IDByte[2] & 0x80) == 0x80){
                                    IDByte[2] &= 0x7F;
                                    [tableCode appendFormat:@"-%02x.",IDByte[2]];
                                }
                                [tableCode appendFormat:@"%02x",IDByte[1]];
                                [tableCode appendFormat:@"%02x",IDByte[0]];
                            }else{
                                [tableCode appendFormat:@"%02x.",IDByte[2]];
                                [tableCode appendFormat:@"%02x",IDByte[1]];
                                [tableCode appendFormat:@"%02x",IDByte[0]];
                            }
                            [codeArr addObject:tableCode];
                            DataModel * data = [[DataModel alloc] init];
                            DateModel * date = [[DateModel alloc]init];
                            date.data = [[NSMutableArray alloc] init];
                            for (DateModel * date1 in deModel.dataArr) {
                                if ([date1.day intValue] == [day intValue]) {
                                    //找到该Day数据
                                    date = date1;
                                    new2 = 0;
                                    if ((date1.data.count ) > j) {
                                        new = 0;//0表示Data已存在
                                        data.activeB = tableCode;
                                        data.point = [NSString stringWithFormat:@"%d",j];
                                        data.name = _wycName;
                                        data.Month = month;
                                        data.year = year;
                                        data.day = day;
                                        data.hour = @"00";
                                        data.ct = [NSString stringWithFormat:@"%d",ct];
                                        data.pt = [NSString stringWithFormat:@"%d",pt];
                                        NSString * tString =  [HY_NSusefDefaults objectForKey:@"TIME"];
                                        int t = (dis - [tString intValue])/(15 * 60);
                                        data.my_id = [NSString stringWithFormat:@"%d",t +j];
                                        DataModel * newData = date1.data[j];
                                        newData.activeB = tableCode;
                                        
                                    }else if ((date1.data.count ) <= j){
                                        data.activeB = tableCode;
                                        data.point = [NSString stringWithFormat:@"%d",j];
                                        data.name = _wycName;
                                        data.Month = month;
                                        data.year = year;
                                        data.day = day;
                                        data.hour = @"00";
                                        data.ct = [NSString stringWithFormat:@"%d",ct];
                                        data.pt = [NSString stringWithFormat:@"%d",pt];
                                        NSString * tString =  [HY_NSusefDefaults objectForKey:@"TIME"];
                                        int t = (dis - [tString intValue])/(15 * 60);
                                        data.my_id = [NSString stringWithFormat:@"%d",t +j];
                                        date1.day = day;
                                        [date1.data addObject:data];
                                    }
                                }
                                
                            }
                            if (new2 == 1) {//new
                                data.activeB = tableCode;
                                data.point = [NSString stringWithFormat:@"%d",j];
                                data.name = _wycName;
                                data.Month = month;
                                data.year = year;
                                data.day = day;
                                data.hour = @"00";
                                data.ct = [NSString stringWithFormat:@"%d",ct];
                                data.pt = [NSString stringWithFormat:@"%d",pt];
                                NSString * tString =  [HY_NSusefDefaults objectForKey:@"TIME"];
                                int t = (dis - [tString intValue])/(15 * 60);
                                data.my_id = [NSString stringWithFormat:@"%d",t +j];
                                date.day = day;
                                [date.data addObject:data];
                                [deModel.dataArr addObject:date];
                            }
                        }
                        //存储
                        deModel.De_addr = [NSString stringWithFormat:@"%llu",mp_ID];
                        deModel.pointNum = [NSString stringWithFormat:@"%d",num + [deModel.pointNum intValue]];
                        //将设备存入单利
                        if (new1 == 1) {//新创建
                            [manager.memory_Array addObject:deModel];
                        }else if (new == 0){//已存在
                            for (int i = 0;i<manager.memory_Array.count; i++ ) {
                                DeviceModel * data1 = manager.memory_Array[i];
                                if ([data1.De_addr isEqualToString: _wyc_adress]) {
                                    //找到该设备更新数据
                                    data1 = deModel;
                                }
                            }
                        }

                    }

                    break;
                }
                case 84:
                {//C相有功功率
                    for (n = 0; n<pnLen; n++) {
                        UInt64 mp_ID = 0;
                        HYSingleManager *manager = [HYSingleManager sharedManager];
                        for (int a = 0; a<manager.archiveUser.child_obj.count; a++) {
                            CCompanyModel *company = manager.archiveUser.child_obj[a];
                            for (int b = 0; b<company.child_obj1.count; b++) {
                                CTerminalModel *terminal = company.child_obj1[b];
                                if ([terminal.term_ID isEqualToString:strAddr]) {
                                    for (int c = 0; c<terminal.child_obj.count; c++) {
                                        CMPModel *mp = terminal.child_obj[c];
                                        if (mp.mp_point == pn[n]) {
                                            mp_ID = mp.strID;
                                            _wycName = mp.name;
                                            ct = mp.mp_CT;
                                            pt = mp.mp_PT;
                                            _wyc_adress = [NSString stringWithFormat:@"%llu",mp_ID];
                                            if (memory_Array.count > 0) {
                                                for (DeviceModel * deM in memory_Array) {
                                                    if ([deM.De_addr isEqualToString:[NSString stringWithFormat:@"%llu",mp_ID]]) {
                                                        //设备ID相同，取出设备
                                                        deModel = deM;
                                                        new1 = 0;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                
                            }
                        }
                        NSString *year = [NSString stringWithFormat:@"%x",pBuf[i+4]];
                        NSString *month = [NSString stringWithFormat:@"%x",pBuf[i+3]];
                        NSString *day = [NSString stringWithFormat:@"%x",pBuf[i+2]];
                        NSDate* dat = [NSDate dateWithTimeIntervalSinceNow:0];
                        NSTimeInterval a=[dat timeIntervalSince1970];
                        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                        [formatter setDateFormat:@"YY/MM/dd"];
                        NSDate *curDate = [formatter dateFromString:[NSString stringWithFormat:@"%d/%d/%d",[year intValue],[month intValue],[day intValue]]];
                        NSTimeInterval dis = [curDate timeIntervalSince1970];
                        int c = a - dis;
                        int type = c/ONEDay;
                        NSString *typeStr = [NSString stringWithFormat:@"%d",type];
                        i += 7;
                        NSMutableArray *codeArr = [NSMutableArray array];
                        for (int j = 0; j<num; j++) {
                            Byte IDByte[3];
                            for (int k = 0; k<3; k++,i++) {
                                IDByte[k] = pBuf[i];
                            }
                            NSMutableString *keyString = [NSMutableString string];
                            [keyString appendFormat:@"%02x",IDByte[2]];
                            [keyString appendFormat:@"%02x",IDByte[1]];
                            [keyString appendFormat:@"%02x",IDByte[0]];
                            
                            NSMutableString *tableCode = [NSMutableString string];
                            BOOL result = isPureInt(keyString);
                            if (result == YES) {
                                if ((IDByte[2] & 0x80) == 0) {
                                    [tableCode appendFormat:@"%02x.",IDByte[2]];
                                }else if ((IDByte[2] & 0x80) == 0x80){
                                    IDByte[2] &= 0x7F;
                                    [tableCode appendFormat:@"-%02x.",IDByte[2]];
                                }
                                [tableCode appendFormat:@"%02x",IDByte[1]];
                                [tableCode appendFormat:@"%02x",IDByte[0]];
                            }else{
                                [tableCode appendFormat:@"%02x.",IDByte[2]];
                                [tableCode appendFormat:@"%02x",IDByte[1]];
                                [tableCode appendFormat:@"%02x",IDByte[0]];
                            }
                            [codeArr addObject:tableCode];
                            DataModel * data = [[DataModel alloc] init];
                            DateModel * date = [[DateModel alloc]init];
                            date.data = [[NSMutableArray alloc] init];
                            for (DateModel * date1 in deModel.dataArr) {
                                if ([date1.day intValue] == [day intValue]) {
                                    //找到该Day数据
                                    date = date1;
                                    new2 = 0;
                                    if ((date1.data.count ) > j) {
                                        new = 0;//0表示Data已存在
                                        data.activeC = tableCode;
                                        data.point = [NSString stringWithFormat:@"%d",j];
                                        data.name = _wycName;
                                        data.Month = month;
                                        data.year = year;
                                        data.day = day;
                                        data.hour = @"00";
                                        data.ct = [NSString stringWithFormat:@"%d",ct];
                                        data.pt = [NSString stringWithFormat:@"%d",pt];
                                        NSString * tString =  [HY_NSusefDefaults objectForKey:@"TIME"];
                                        int t = (dis - [tString intValue])/(15 * 60);
                                        data.my_id = [NSString stringWithFormat:@"%d",t +j];
                                        DataModel * newData = date1.data[j];
                                        newData.activeC = tableCode;
                                        
                                    }else if ((date1.data.count ) <= j){
                                        data.activeC = tableCode;
                                        data.point = [NSString stringWithFormat:@"%d",j];
                                        data.name = _wycName;
                                        data.Month = month;
                                        data.year = year;
                                        data.day = day;
                                        data.hour = @"00";
                                        data.ct = [NSString stringWithFormat:@"%d",ct];
                                        data.pt = [NSString stringWithFormat:@"%d",pt];
                                        NSString * tString =  [HY_NSusefDefaults objectForKey:@"TIME"];
                                        int t = (dis - [tString intValue])/(15 * 60);
                                        data.my_id = [NSString stringWithFormat:@"%d",t +j];
                                        date1.day = day;
                                        [date1.data addObject:data];
                                    }
                                }
                                
                            }
                            if (new2 == 1) {//new
                                data.activeC = tableCode;
                                data.point = [NSString stringWithFormat:@"%d",j];
                                data.name = _wycName;
                                data.Month = month;
                                data.year = year;
                                data.day = day;
                                data.hour = @"00";
                                data.ct = [NSString stringWithFormat:@"%d",ct];
                                data.pt = [NSString stringWithFormat:@"%d",pt];
                                NSString * tString =  [HY_NSusefDefaults objectForKey:@"TIME"];
                                int t = (dis - [tString intValue])/(15 * 60);
                                data.my_id = [NSString stringWithFormat:@"%d",t +j];
                                date.day = day;
                                [date.data addObject:data];
                                [deModel.dataArr addObject:date];
                            }
                        }
                        if (manager.activeC_dict[[NSString stringWithFormat:@"%llu",mp_ID] ] == nil) {
                            NSMutableDictionary *dic = [NSMutableDictionary dictionary];
                            [dic setObject:codeArr forKey:typeStr];
                            [manager.activeC_dict setObject:dic forKey:[NSString stringWithFormat:@"%llu",mp_ID]];
                        }else{
                            NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:manager.activeC_dict[[NSString stringWithFormat:@"%llu",mp_ID]]];
                            [dict setObject:codeArr forKey:typeStr];
                            [manager.activeC_dict setObject:dict forKey:[NSString stringWithFormat:@"%llu",mp_ID]];
                        }
                    }

                    break;
                }case 86:
                {//A相无功功率
                    for (n = 0; n<pnLen; n++) {
                        UInt64 mp_ID = 0;
                        HYSingleManager *manager = [HYSingleManager sharedManager];
                        for (int a = 0; a<manager.archiveUser.child_obj.count; a++) {
                            CCompanyModel *company = manager.archiveUser.child_obj[a];
                            for (int b = 0; b<company.child_obj1.count; b++) {
                                CTerminalModel *terminal = company.child_obj1[b];
                                if ([terminal.term_ID isEqualToString:strAddr]) {
                                    for (int c = 0; c<terminal.child_obj.count; c++) {
                                        CMPModel *mp = terminal.child_obj[c];
                                        if (mp.mp_point == pn[n]) {
                                            mp_ID = mp.strID;
                                            _wycName = mp.name;
                                            ct = mp.mp_CT;
                                            pt = mp.mp_PT;
                                            _wyc_adress = [NSString stringWithFormat:@"%llu",mp_ID];
                                            if (memory_Array.count > 0) {
                                                for (DeviceModel * deM in memory_Array) {
                                                    if ([deM.De_addr isEqualToString:[NSString stringWithFormat:@"%llu",mp_ID]]) {
                                                        //设备ID相同，取出设备
                                                        deModel = deM;
                                                        new1 = 0;
                                                    }
                                                }
                                            }
                                            _wycName = mp.name;
                                            ct = mp.mp_CT;
                                            pt = mp.mp_PT;
                                            _wyc_adress = [NSString stringWithFormat:@"%llu",mp_ID];
                                            if (memory_Array.count > 0) {
                                                for (DeviceModel * deM in memory_Array) {
                                                    if ([deM.De_addr isEqualToString:[NSString stringWithFormat:@"%llu",mp_ID]]) {
                                                        //设备ID相同，取出设备
                                                        deModel = deM;
                                                        new1 = 0;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                
                            }
                        }
                        NSString *year = [NSString stringWithFormat:@"%x",pBuf[i+4]];
                        NSString *month = [NSString stringWithFormat:@"%x",pBuf[i+3]];
                        NSString *day = [NSString stringWithFormat:@"%x",pBuf[i+2]];
                        NSDate* dat = [NSDate dateWithTimeIntervalSinceNow:0];
                        NSTimeInterval a=[dat timeIntervalSince1970];
                        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                        [formatter setDateFormat:@"YY/MM/dd"];
                        NSDate *curDate = [formatter dateFromString:[NSString stringWithFormat:@"%d/%d/%d",[year intValue],[month intValue],[day intValue]]];
                        NSTimeInterval dis = [curDate timeIntervalSince1970];
                        int c = a - dis;
                        int type = c/ONEDay;
                        NSString *typeStr = [NSString stringWithFormat:@"%d",type];
                        i += 7;
                        NSMutableArray *codeArr = [NSMutableArray array];
                        for (int j = 0; j<num; j++) {
                            Byte IDByte[3];
                            for (int k = 0; k<3; k++,i++) {
                                IDByte[k] = pBuf[i];
                            }
                            NSMutableString *keyString = [NSMutableString string];
                            [keyString appendFormat:@"%02x",IDByte[2]];
                            [keyString appendFormat:@"%02x",IDByte[1]];
                            [keyString appendFormat:@"%02x",IDByte[0]];
                            
                            NSMutableString *tableCode = [NSMutableString string];
                            BOOL result = isPureInt(keyString);
                            if (result == YES) {
                                if ((IDByte[2] & 0x80) == 0) {
                                    [tableCode appendFormat:@"%02x.",IDByte[2]];
                                }else if ((IDByte[2] & 0x80) == 0x80){
                                    IDByte[2] &= 0x7F;
                                    [tableCode appendFormat:@"-%02x.",IDByte[2]];
                                }
                                [tableCode appendFormat:@"%02x",IDByte[1]];
                                [tableCode appendFormat:@"%02x",IDByte[0]];
                            }else{
                                [tableCode appendFormat:@"%02x.",IDByte[2]];
                                [tableCode appendFormat:@"%02x",IDByte[1]];
                                [tableCode appendFormat:@"%02x",IDByte[0]];
                            }
                            [codeArr addObject:tableCode];
                            DataModel * data = [[DataModel alloc] init];
                            DateModel * date = [[DateModel alloc]init];
                            date.data = [[NSMutableArray alloc] init];
                            for (DateModel * date1 in deModel.dataArr) {
                                if ([date1.day intValue] == [day intValue]) {
                                    //找到该Day数据
                                    date = date1;
                                    new2 = 0;
                                    if ((date1.data.count ) > j) {
                                        new = 0;//0表示Data已存在
                                        data.reactiveA = tableCode;
                                        data.point = [NSString stringWithFormat:@"%d",j];
                                        data.name = _wycName;
                                        data.Month = month;
                                        data.year = year;
                                        data.day = day;
                                        data.hour = @"00";
                                        data.ct = [NSString stringWithFormat:@"%d",ct];
                                        data.pt = [NSString stringWithFormat:@"%d",pt];
                                        NSString * tString =  [HY_NSusefDefaults objectForKey:@"TIME"];
                                        int t = (dis - [tString intValue])/(15 * 60);
                                        data.my_id = [NSString stringWithFormat:@"%d",t +j];
                                        DataModel * newData = date1.data[j];
                                        newData.reactiveA = tableCode;
                                        
                                    }else if ((date1.data.count ) <= j){
                                        data.reactiveA = tableCode;
                                        data.point = [NSString stringWithFormat:@"%d",j];
                                        data.name = _wycName;
                                        data.Month = month;
                                        data.year = year;
                                        data.day = day;
                                        data.hour = @"00";
                                        data.ct = [NSString stringWithFormat:@"%d",ct];
                                        data.pt = [NSString stringWithFormat:@"%d",pt];
                                        NSString * tString =  [HY_NSusefDefaults objectForKey:@"TIME"];
                                        int t = (dis - [tString intValue])/(15 * 60);
                                        data.my_id = [NSString stringWithFormat:@"%d",t +j];
                                        date1.day = day;
                                        [date1.data addObject:data];
                                    }
                                }
                                
                            }
                            if (new2 == 1) {//new
                                data.reactiveA = tableCode;
                                data.point = [NSString stringWithFormat:@"%d",j];
                                data.name = _wycName;
                                data.Month = month;
                                data.year = year;
                                data.day = day;
                                data.hour = @"00";
                                data.ct = [NSString stringWithFormat:@"%d",ct];
                                data.pt = [NSString stringWithFormat:@"%d",pt];
                                NSString * tString =  [HY_NSusefDefaults objectForKey:@"TIME"];
                                int t = (dis - [tString intValue])/(15 * 60);
                                data.my_id = [NSString stringWithFormat:@"%d",t +j];
                                date.day = day;
                                [date.data addObject:data];
                                [deModel.dataArr addObject:date];
                            }
                        }
                        //存储
                        deModel.De_addr = [NSString stringWithFormat:@"%llu",mp_ID];
                        deModel.pointNum = [NSString stringWithFormat:@"%d",num + [deModel.pointNum intValue]];
                        //将设备存入单利
                        //将设备存入单利
                        if (new1 == 1) {//新创建
                            [manager.memory_Array addObject:deModel];
                        }else if (new == 0){//已存在
                            for (int i = 0;i<manager.memory_Array.count; i++ ) {
                                DeviceModel * data1 = manager.memory_Array[i];
                                if ([data1.De_addr isEqualToString: _wyc_adress]) {
                                    //找到该设备更新数据
                                    data1 = deModel;
                                }
                            }
                            
                        }
                        

                    }

                    break;
                }
                case 87:
                {//B相无功功率
                    for (n = 0; n<pnLen; n++) {
                        UInt64 mp_ID = 0;
                        HYSingleManager *manager = [HYSingleManager sharedManager];
                        for (int a = 0; a<manager.archiveUser.child_obj.count; a++) {
                            CCompanyModel *company = manager.archiveUser.child_obj[a];
                            for (int b = 0; b<company.child_obj1.count; b++) {
                                CTerminalModel *terminal = company.child_obj1[b];
                                if ([terminal.term_ID isEqualToString:strAddr]) {
                                    for (int c = 0; c<terminal.child_obj.count; c++) {
                                        CMPModel *mp = terminal.child_obj[c];
                                        if (mp.mp_point == pn[n]) {
                                            mp_ID = mp.strID;
                                            _wycName = mp.name;
                                            ct = mp.mp_CT;
                                            pt = mp.mp_PT;
                                            _wyc_adress = [NSString stringWithFormat:@"%llu",mp_ID];
                                            if (memory_Array.count > 0) {
                                                for (DeviceModel * deM in memory_Array) {
                                                    if ([deM.De_addr isEqualToString:[NSString stringWithFormat:@"%llu",mp_ID]]) {
                                                        //设备ID相同，取出设备
                                                        deModel = deM;
                                                        new1 = 0;
                                                    }
                                                }
                                            }
                                            _wycName = mp.name;
                                            ct = mp.mp_CT;
                                            pt = mp.mp_PT;
                                            _wyc_adress = [NSString stringWithFormat:@"%llu",mp_ID];
                                            if (memory_Array.count > 0) {
                                                for (DeviceModel * deM in memory_Array) {
                                                    if ([deM.De_addr isEqualToString:[NSString stringWithFormat:@"%llu",mp_ID]]) {
                                                        //设备ID相同，取出设备
                                                        deModel = deM;
                                                        new1 = 0;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                
                            }
                        }
                        NSString *year = [NSString stringWithFormat:@"%x",pBuf[i+4]];
                        NSString *month = [NSString stringWithFormat:@"%x",pBuf[i+3]];
                        NSString *day = [NSString stringWithFormat:@"%x",pBuf[i+2]];
                        NSDate* dat = [NSDate dateWithTimeIntervalSinceNow:0];
                        NSTimeInterval a=[dat timeIntervalSince1970];
                        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                        [formatter setDateFormat:@"YY/MM/dd"];
                        NSDate *curDate = [formatter dateFromString:[NSString stringWithFormat:@"%d/%d/%d",[year intValue],[month intValue],[day intValue]]];
                        NSTimeInterval dis = [curDate timeIntervalSince1970];
                        int c = a - dis;
                        int type = c/ONEDay;
                        NSString *typeStr = [NSString stringWithFormat:@"%d",type];
                        i += 7;
                        NSMutableArray *codeArr = [NSMutableArray array];
                        for (int j = 0; j<num; j++) {
                            Byte IDByte[3];
                            for (int k = 0; k<3; k++,i++) {
                                IDByte[k] = pBuf[i];
                            }
                            NSMutableString *keyString = [NSMutableString string];
                            [keyString appendFormat:@"%02x",IDByte[2]];
                            [keyString appendFormat:@"%02x",IDByte[1]];
                            [keyString appendFormat:@"%02x",IDByte[0]];
                            
                            NSMutableString *tableCode = [NSMutableString string];
                            BOOL result = isPureInt(keyString);
                            if (result == YES) {
                                if ((IDByte[2] & 0x80) == 0) {
                                    [tableCode appendFormat:@"%02x.",IDByte[2]];
                                }else if ((IDByte[2] & 0x80) == 0x80){
                                    IDByte[2] &= 0x7F;
                                    [tableCode appendFormat:@"-%02x.",IDByte[2]];
                                }
                                [tableCode appendFormat:@"%02x",IDByte[1]];
                                [tableCode appendFormat:@"%02x",IDByte[0]];
                            }else{
                                [tableCode appendFormat:@"%02x.",IDByte[2]];
                                [tableCode appendFormat:@"%02x",IDByte[1]];
                                [tableCode appendFormat:@"%02x",IDByte[0]];
                            }
                            [codeArr addObject:tableCode];
                            DataModel * data = [[DataModel alloc] init];
                            DateModel * date = [[DateModel alloc]init];
                            date.data = [[NSMutableArray alloc] init];
                            for (DateModel * date1 in deModel.dataArr) {
                                if ([date1.day intValue] == [day intValue]) {
                                    //找到该Day数据
                                    date = date1;
                                    new2 = 0;
                                    if ((date1.data.count ) > j) {
                                        new = 0;//0表示Data已存在
                                        data.reactiveB = tableCode;
                                        data.point = [NSString stringWithFormat:@"%d",j];
                                        data.name = _wycName;
                                        data.Month = month;
                                        data.year = year;
                                        data.day = day;
                                        data.hour = @"00";
                                        data.ct = [NSString stringWithFormat:@"%d",ct];
                                        data.pt = [NSString stringWithFormat:@"%d",pt];
                                        NSString * tString =  [HY_NSusefDefaults objectForKey:@"TIME"];
                                        int t = (dis - [tString intValue])/(15 * 60);
                                        data.my_id = [NSString stringWithFormat:@"%d",t +j];
                                        DataModel * newData = date1.data[j];
                                        newData.reactiveB = tableCode;
                                        
                                    }else if ((date1.data.count ) <= j){
                                        data.reactiveB = tableCode;
                                        data.point = [NSString stringWithFormat:@"%d",j];
                                        data.name = _wycName;
                                        data.Month = month;
                                        data.year = year;
                                        data.day = day;
                                        data.hour = @"00";
                                        data.ct = [NSString stringWithFormat:@"%d",ct];
                                        data.pt = [NSString stringWithFormat:@"%d",pt];
                                        NSString * tString =  [HY_NSusefDefaults objectForKey:@"TIME"];
                                        int t = (dis - [tString intValue])/(15 * 60);
                                        data.my_id = [NSString stringWithFormat:@"%d",t +j];
                                        date1.day = day;
                                        [date1.data addObject:data];
                                    }
                                }
                                
                            }
                            if (new2 == 1) {//new
                                data.reactiveB = tableCode;
                                data.point = [NSString stringWithFormat:@"%d",j];
                                data.name = _wycName;
                                data.Month = month;
                                data.year = year;
                                data.day = day;
                                data.hour = @"00";
                                data.ct = [NSString stringWithFormat:@"%d",ct];
                                data.pt = [NSString stringWithFormat:@"%d",pt];
                                NSString * tString =  [HY_NSusefDefaults objectForKey:@"TIME"];
                                int t = (dis - [tString intValue])/(15 * 60);
                                data.my_id = [NSString stringWithFormat:@"%d",t +j];
                                date.day = day;
                                [date.data addObject:data];
                                [deModel.dataArr addObject:date];
                            }

                        }
                    }
                    break;
                }
                case 88:
                {//C相无功功率
                    for (n = 0; n<pnLen; n++) {
                        UInt64 mp_ID = 0;
                        HYSingleManager *manager = [HYSingleManager sharedManager];
                        for (int a = 0; a<manager.archiveUser.child_obj.count; a++) {
                            CCompanyModel *company = manager.archiveUser.child_obj[a];
                            for (int b = 0; b<company.child_obj1.count; b++) {
                                CTerminalModel *terminal = company.child_obj1[b];
                                if ([terminal.term_ID isEqualToString:strAddr]) {
                                    for (int c = 0; c<terminal.child_obj.count; c++) {
                                        CMPModel *mp = terminal.child_obj[c];
                                        if (mp.mp_point == pn[n]) {
                                            mp_ID = mp.strID;
                                            _wycName = mp.name;
                                            ct = mp.mp_CT;
                                            pt = mp.mp_PT;
                                            _wyc_adress = [NSString stringWithFormat:@"%llu",mp_ID];
                                            if (memory_Array.count > 0) {
                                                for (DeviceModel * deM in memory_Array) {
                                                    if ([deM.De_addr isEqualToString:[NSString stringWithFormat:@"%llu",mp_ID]]) {
                                                        //设备ID相同，取出设备
                                                        deModel = deM;
                                                        new1 = 0;
                                                    }
                                                }
                                            }
                                            _wycName = mp.name;
                                            ct = mp.mp_CT;
                                            pt = mp.mp_PT;
                                            _wyc_adress = [NSString stringWithFormat:@"%llu",mp_ID];
                                            if (memory_Array.count > 0) {
                                                for (DeviceModel * deM in memory_Array) {
                                                    if ([deM.De_addr isEqualToString:[NSString stringWithFormat:@"%llu",mp_ID]]) {
                                                        //设备ID相同，取出设备
                                                        deModel = deM;
                                                        new1 = 0;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                
                            }
                        }
                        NSString *year = [NSString stringWithFormat:@"%x",pBuf[i+4]];
                        NSString *month = [NSString stringWithFormat:@"%x",pBuf[i+3]];
                        NSString *day = [NSString stringWithFormat:@"%x",pBuf[i+2]];
                        NSDate* dat = [NSDate dateWithTimeIntervalSinceNow:0];
                        NSTimeInterval a=[dat timeIntervalSince1970];
                        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                        [formatter setDateFormat:@"YY/MM/dd"];
                        NSDate *curDate = [formatter dateFromString:[NSString stringWithFormat:@"%d/%d/%d",[year intValue],[month intValue],[day intValue]]];
                        NSTimeInterval dis = [curDate timeIntervalSince1970];
                        int c = a - dis;
                        int type = c/ONEDay;
                        NSString *typeStr = [NSString stringWithFormat:@"%d",type];
                        i += 7;
                        NSMutableArray *codeArr = [NSMutableArray array];
                        for (int j = 0; j<num; j++) {
                            Byte IDByte[3];
                            for (int k = 0; k<3; k++,i++) {
                                IDByte[k] = pBuf[i];
                            }
                            NSMutableString *keyString = [NSMutableString string];
                            [keyString appendFormat:@"%02x",IDByte[2]];
                            [keyString appendFormat:@"%02x",IDByte[1]];
                            [keyString appendFormat:@"%02x",IDByte[0]];
                            
                            NSMutableString *tableCode = [NSMutableString string];
                            BOOL result = isPureInt(keyString);
                            if (result == YES) {
                                if ((IDByte[2] & 0x80) == 0) {
                                    [tableCode appendFormat:@"%02x.",IDByte[2]];
                                }else if ((IDByte[2] & 0x80) == 0x80){
                                    IDByte[2] &= 0x7F;
                                    [tableCode appendFormat:@"-%02x.",IDByte[2]];
                                }
                                [tableCode appendFormat:@"%02x",IDByte[1]];
                                [tableCode appendFormat:@"%02x",IDByte[0]];
                            }else{
                                [tableCode appendFormat:@"%02x.",IDByte[2]];
                                [tableCode appendFormat:@"%02x",IDByte[1]];
                                [tableCode appendFormat:@"%02x",IDByte[0]];
                            }
                            [codeArr addObject:tableCode];
                            DataModel * data = [[DataModel alloc] init];
                            DateModel * date = [[DateModel alloc]init];
                            date.data = [[NSMutableArray alloc] init];
                            for (DateModel * date1 in deModel.dataArr) {
                                if ([date1.day intValue] == [day intValue]) {
                                    //找到该Day数据
                                    date = date1;
                                    new2 = 0;
                                    if ((date1.data.count ) > j) {
                                        new = 0;//0表示Data已存在
                                        data.reactiveC = tableCode;
                                        data.point = [NSString stringWithFormat:@"%d",j];
                                        data.name = _wycName;
                                        data.Month = month;
                                        data.year = year;
                                        data.day = day;
                                        data.hour = @"00";
                                        data.ct = [NSString stringWithFormat:@"%d",ct];
                                        data.pt = [NSString stringWithFormat:@"%d",pt];
                                        NSString * tString =  [HY_NSusefDefaults objectForKey:@"TIME"];
                                        int t = (dis - [tString intValue])/(15 * 60);
                                        data.my_id = [NSString stringWithFormat:@"%d",t +j];
                                        DataModel * newData = date1.data[j];
                                        newData.reactiveC = tableCode;
                                        
                                    }else if ((date1.data.count ) <= j){
                                        data.reactiveC = tableCode;
                                        data.point = [NSString stringWithFormat:@"%d",j];
                                        data.name = _wycName;
                                        data.Month = month;
                                        data.year = year;
                                        data.day = day;
                                        data.hour = @"00";
                                        data.ct = [NSString stringWithFormat:@"%d",ct];
                                        data.pt = [NSString stringWithFormat:@"%d",pt];
                                        NSString * tString =  [HY_NSusefDefaults objectForKey:@"TIME"];
                                        int t = (dis - [tString intValue])/(15 * 60);
                                        data.my_id = [NSString stringWithFormat:@"%d",t +j];
                                        date1.day = day;
                                        [date1.data addObject:data];
                                    }
                                }
                                
                            }
                            if (new2 == 1) {//new
                                data.reactiveC = tableCode;
                                data.point = [NSString stringWithFormat:@"%d",j];
                                data.name = _wycName;
                                data.Month = month;
                                data.year = year;
                                data.day = day;
                                data.hour = @"00";
                                data.ct = [NSString stringWithFormat:@"%d",ct];
                                data.pt = [NSString stringWithFormat:@"%d",pt];
                                NSString * tString =  [HY_NSusefDefaults objectForKey:@"TIME"];
                                int t = (dis - [tString intValue])/(15 * 60);
                                data.my_id = [NSString stringWithFormat:@"%d",t +j];
                                date.day = day;
                                [date.data addObject:data];
                                [deModel.dataArr addObject:date];
                            }

                        }
                    }

                    break;
                }
                case 105:
                {//总功率因数
                    for (n = 0; n<pnLen; n++) {
                        UInt64 mp_ID = 0;
                        HYSingleManager *manager = [HYSingleManager sharedManager];
                        for (int a = 0; a<manager.archiveUser.child_obj.count; a++) {
                            CCompanyModel *company = manager.archiveUser.child_obj[a];
                            for (int b = 0; b<company.child_obj1.count; b++) {
                                CTerminalModel *terminal = company.child_obj1[b];
                                if ([terminal.term_ID isEqualToString:strAddr]) {
                                    for (int c = 0; c<terminal.child_obj.count; c++) {
                                        CMPModel *mp = terminal.child_obj[c];
                                        if (mp.mp_point == pn[n]) {
                                            mp_ID = mp.strID;
                                            _wycName = mp.name;
                                            ct = mp.mp_CT;
                                            pt = mp.mp_PT;
                                            _wyc_adress = [NSString stringWithFormat:@"%llu",mp_ID];
                                            if (memory_Array.count > 0) {
                                                for (DeviceModel * deM in memory_Array) {
                                                    if ([deM.De_addr isEqualToString:[NSString stringWithFormat:@"%llu",mp_ID]]) {
                                                        //设备ID相同，取出设备
                                                        deModel = deM;
                                                        new1 = 0;
                                                    }
                                                }
                                            }
                                            _wycName = mp.name;
                                            ct = mp.mp_CT;
                                            pt = mp.mp_PT;
                                            _wyc_adress = [NSString stringWithFormat:@"%llu",mp_ID];
                                            if (memory_Array.count > 0) {
                                                for (DeviceModel * deM in memory_Array) {
                                                    if ([deM.De_addr isEqualToString:[NSString stringWithFormat:@"%llu",mp_ID]]) {
                                                        //设备ID相同，取出设备
                                                        deModel = deM;
                                                        new1 = 0;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                
                            }
                        }
                        NSString *year = [NSString stringWithFormat:@"%x",pBuf[i+4]];
                        NSString *month = [NSString stringWithFormat:@"%x",pBuf[i+3]];
                        NSString *day = [NSString stringWithFormat:@"%x",pBuf[i+2]];
                        NSDate* dat = [NSDate dateWithTimeIntervalSinceNow:0];
                        NSTimeInterval a=[dat timeIntervalSince1970];
                        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                        [formatter setDateFormat:@"YY/MM/dd"];
                        NSDate *curDate = [formatter dateFromString:[NSString stringWithFormat:@"%d/%d/%d",[year intValue],[month intValue],[day intValue]]];
                        NSTimeInterval dis = [curDate timeIntervalSince1970];
                        int c = a - dis;
                        int type = c/ONEDay;
                        NSString *typeStr = [NSString stringWithFormat:@"%d",type];
                        i += 7;
                        NSMutableArray *codeArr = [NSMutableArray array];
                        for (int j = 0; j<num; j++) {
                            Byte IDByte[2];
                            for (int k = 0; k<2; k++,i++) {
                                IDByte[k] = pBuf[i];
                            }
                            NSMutableString *keyString = [NSMutableString string];
                            [keyString appendFormat:@"%02x",IDByte[1]];
                            [keyString appendFormat:@"%02x",IDByte[0]];
                            
                            NSMutableString *tableCode = [NSMutableString string];
                            BOOL result = isPureInt(keyString);
                            if (result == YES) {
                                if ((IDByte[1] & 0x80) == 0) {
                                    [tableCode appendFormat:@"%02x",IDByte[1]];
                                }else if ((IDByte[1] & 0x80) == 0x80){
                                    IDByte[1] &= 0x7F;
                                    [tableCode appendFormat:@"-%02x",IDByte[1]];
                                }
                                [tableCode appendFormat:@"%02x",IDByte[0]];
                            }else{
                                [tableCode appendFormat:@"%02x",IDByte[1]];
                                [tableCode appendFormat:@"%02x",IDByte[0]];
                            }
                            NSRange range = {1,0};
                            NSString *aac = [tableCode stringByReplacingCharactersInRange:range withString:@"."];
                            [codeArr addObject:aac];
                            
                            DataModel * data = [[DataModel alloc] init];
                            DateModel * date = [[DateModel alloc]init];
                            date.data = [[NSMutableArray alloc] init];
                            for (DateModel * date1 in deModel.dataArr) {
                                if ([date1.day intValue] == [day intValue]) {
                                    //找到该Day数据
                                    date = date1;
                                    new2 = 0;
                                    if ((date1.data.count ) > j) {
                                        new = 0;//0表示Data已存在
                                        data.powerFactor = aac;
                                        data.point = [NSString stringWithFormat:@"%d",j];
                                        data.name = _wycName;
                                        data.Month = month;
                                        data.year = year;
                                        data.day = day;
                                        data.hour = @"00";
                                        data.ct = [NSString stringWithFormat:@"%d",ct];
                                        data.pt = [NSString stringWithFormat:@"%d",pt];
                                        NSString * tString =  [HY_NSusefDefaults objectForKey:@"TIME"];
                                        int t = (dis - [tString intValue])/(15 * 60);
                                        data.my_id = [NSString stringWithFormat:@"%d",t +j];
                                        DataModel * newData = date1.data[j];
                                        newData.powerFactor = aac;
                                        
                                    }else if ((date1.data.count ) <= j){
                                        data.powerFactor = aac;
                                        data.point = [NSString stringWithFormat:@"%d",j];
                                        data.name = _wycName;
                                        data.Month = month;
                                        data.year = year;
                                        data.day = day;
                                        data.hour = @"00";
                                        data.ct = [NSString stringWithFormat:@"%d",ct];
                                        data.pt = [NSString stringWithFormat:@"%d",pt];
                                        NSString * tString =  [HY_NSusefDefaults objectForKey:@"TIME"];
                                        int t = (dis - [tString intValue])/(15 * 60);
                                        data.my_id = [NSString stringWithFormat:@"%d",t +j];
                                        date1.day = day;
                                        [date1.data addObject:data];
                                    }
                                }
                                
                            }
                            if (new2 == 1) {//new
                                data.powerFactor = aac;
                                data.point = [NSString stringWithFormat:@"%d",j];
                                data.name = _wycName;
                                data.Month = month;
                                data.year = year;
                                data.day = day;
                                data.hour = @"00";
                                data.ct = [NSString stringWithFormat:@"%d",ct];
                                data.pt = [NSString stringWithFormat:@"%d",pt];
                                NSString * tString =  [HY_NSusefDefaults objectForKey:@"TIME"];
                                int t = (dis - [tString intValue])/(15 * 60);
                                data.my_id = [NSString stringWithFormat:@"%d",t +j];
                                date.day = day;
                                [date.data addObject:data];
                                [deModel.dataArr addObject:date];
                            }

                        }
                        //存储
                        deModel.De_addr = [NSString stringWithFormat:@"%llu",mp_ID];
                        deModel.pointNum = [NSString stringWithFormat:@"%d",num + [deModel.pointNum intValue]];
                        //将设备存入单利
                        if (new1 == 1) {//新创建
                            [manager.memory_Array addObject:deModel];
                        }else if (new == 0){//已存在
                            for (int i = 0;i<manager.memory_Array.count; i++ ) {
                                DeviceModel * data1 = manager.memory_Array[i];
                                if ([data1.De_addr isEqualToString: _wyc_adress]) {
                                    //找到该设备更新数据
                                    data1 = deModel;
                                }
                            }
                            
                        }

                        if (manager.powerFactor_dict[[NSString stringWithFormat:@"%llu",mp_ID] ] == nil) {
                            NSMutableDictionary *dic = [NSMutableDictionary dictionary];
                            [dic setObject:codeArr forKey:typeStr];
                            [manager.powerFactor_dict setObject:dic forKey:[NSString stringWithFormat:@"%llu",mp_ID]];
                        }else{
                            NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:manager.powerFactor_dict[[NSString stringWithFormat:@"%llu",mp_ID]]];
                            [dict setObject:codeArr forKey:typeStr];
                            [manager.powerFactor_dict setObject:dict forKey:[NSString stringWithFormat:@"%llu",mp_ID]];
                        }
                    }
                    
                    break;
                }
                default:
                    break;
            }
        }
    }
    return 0;
}

#pragma mark ==jjj
- (NSData *)combinRemoteControlFrame:(NSString *)terminalAddress :(NSString *)mpAddress :(int)type :(UInt64)Usr_checkID
{
    Byte OutBufData[1024];
    unsigned int nLen,L,i;
    unsigned char cs;
    unsigned char P[3]={0};//密码
    unsigned char C[4]={0};//操作者代码
    for (int i = 0; i < 3; ++i)
    {
        P[i] = 0x00;
    }
    for (int i = 0; i < 4; ++i)
    {
        C[i] = 0x00;
    }
    nLen = 38;
    for (i = 0; i<4; i++) {
        OutBufData[nLen++] = 0xFE;
    }
    OutBufData[nLen++] = 0x68;
    NSData *mpAddData = [self stringToByte:mpAddress];
    Byte *bytes = (Byte *)[mpAddData bytes];
    Byte mp_addr[6];
    for (int j = 0; j<6; j++) {
        mp_addr[j] = bytes[j];
    }
    for (i = 0; i<6; i++) {
        //电表地址
        OutBufData[nLen++] = mp_addr[i];
    }
    OutBufData[nLen++] = 0x68;
    OutBufData[nLen++] = 0x1C;
    OutBufData[nLen++] = 0x10;
    OutBufData[nLen++] = 0x02+0x33;
    for(i=0;i<3;i++)
    {
        OutBufData[nLen++] = 0x33;
    }
    for(i=0;i<4;i++)
    {
        OutBufData[nLen++] = 0x33;
    }
    switch(type)
    {
        case 0:{OutBufData[nLen++] = 0x1A+0x33;break;}
        case 1:{OutBufData[nLen++] = 0x1C+0x33;break;}
        case 2:{OutBufData[nLen++] = 0x2A+0x33;break;}
        case 3:{OutBufData[nLen++] = 0x2B+0x33;break;}
        case 4:{OutBufData[nLen++] = 0x3A+0x33;break;}
        case 5:{OutBufData[nLen++] = 0x3B+0x33;break;}
        default:  return 0;
    }
    OutBufData[nLen++] = 0x33;
    
    unsigned char  nYear=0,nMonth=0,nDay=0, nHour=0, nMinute=0,nSecond=0;
    int a;
    
    NSTimeInterval time = [[NSDate date] timeIntervalSince1970];
    long long int date = (long long int)time + 600;
    //把秒数转化成yyyy-MM-dd hh:mm:ss格式
    NSDate *dd = [NSDate dateWithTimeIntervalSince1970:date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"YY/MM/dd/HH/mm/ss"];
    NSString *dateString = [dateFormatter stringFromDate:dd];
    NSArray *arr = [dateString componentsSeparatedByString:@"/"];// '/'分割日期字符串,得到一数组
    a = [arr[5] intValue];
    nSecond = (a/10)<<4;
    nSecond += a %10;//秒
    
    a = [arr[4] intValue];
    nMinute = (a/10)<<4;
    nMinute += a %10;//分
    
    a = [arr[3] intValue];
    nHour = (a/10)<<4;
    nHour += a %10;//时
    
    a = [arr[2] intValue];
    nDay = (a/10)<<4;
    nDay += a %10;//日
    
    a = [arr[1] intValue];
    nMonth = (a/10)<<4;
    nMonth += a %10;//月
    
    a = [arr[0] intValue];
    nYear = ((a%100)/10)<<4;
    nYear += a %10;//年
    
    OutBufData[nLen++] = nSecond+0x33;
    OutBufData[nLen++] = nMinute+0x33;
    OutBufData[nLen++] = nHour+0x33;
    OutBufData[nLen++] = nDay+0x33;
    OutBufData[nLen++] = nMonth+0x33;
    OutBufData[nLen++] = nYear+0x33;
    cs = 0;
    for(i=42;i<nLen;i++)
    {
        cs += OutBufData[i];
    }
    OutBufData[nLen++] = cs;
    OutBufData[nLen++] = 0x16;
    OutBufData[nLen++] = 0;//帧计数器
    a = ([arr[5]intValue]/10)<<4;
    a += [arr[5]intValue]%10;
    OutBufData[nLen++] = a;//秒
    a = ([arr[4]intValue]/10)<<4;
    a += [arr[4]intValue]%10;
    OutBufData[nLen++]=a;//分
    a = ([arr[3]intValue]/10)<<4;
    a += [arr[3]intValue]%10;
    OutBufData[nLen++]=a;//时
    a = ([arr[2]intValue]/10)<<4;
    a += [arr[2]intValue]%10;
    OutBufData[nLen++]=a;//日
    OutBufData[nLen++]=60;//允许发送延时2min
    int M = 14;
    OutBufData[M++] =0x68;
    OutBufData[M++] =((nLen-6-14)<<2)|0x02;
    OutBufData[M++] =(nLen-6-14)>>6;
    OutBufData[M++] =((nLen-6-14)<<2)|0x02;
    OutBufData[M++] =(nLen-6-14)>>6;
    OutBufData[M++] =0x68;
    OutBufData[M++] =0x4B;    //Ctrl
    
    Byte terminl[5];
    TerminalAddrToByte(terminalAddress, terminl);
    
    OutBufData[M++] =terminl[0];
    OutBufData[M++] =terminl[1];
    OutBufData[M++] =terminl[2];
    OutBufData[M++] =terminl[3];
    OutBufData[M++]=0x02;
    OutBufData[M++]=0x10;    //APN
    OutBufData[M++]=0xE0;    //SEQ
    L=28;
    OutBufData[L++]=0;
    OutBufData[L++]=0;
    OutBufData[L++]=1;
    OutBufData[L++]=0;
    OutBufData[L++]=1;//通信端口号
    OutBufData[L++]=0x6B;//2400的波特率。8位数，偶校验。
    OutBufData[L++]=0x84;//透明转发等待超时时间4S
    OutBufData[L++]=0x02;//等待字节超时时间2S
    OutBufData[L++]=nLen-24-6;
    OutBufData[L++]=(nLen-24-6)>>8;
    OutBufData[0] = 0xAA;
    OutBufData[1] = (Byte)(64&0x000000FF);
    OutBufData[2] = (Byte)(64&0x0000FF00);;
    OutBufData[3] = 0x04;
//    NSData *sureIDData = [[NSUserDefaults standardUserDefaults]objectForKey:@"sureID"];
    Byte out_data[8];
    UINT64ToBYTE(Usr_checkID, out_data);
//    Byte *sureIDByte = (Byte *)[sureIDData bytes];
    for (int i = 0,j = 4; i<8; i++,j++) {
        OutBufData[j] = out_data[i];
    }
    
    //公司规约CS
    unsigned char cs1 = 0;
    for (int i = 0; i<8; i++) {
        cs1 = cs1 + out_data[i];
    }
    cs1 = cs1 + OutBufData[1] + OutBufData[2] + 0x04;
    OutBufData[12] = (Byte)(cs1&0x000000FF);
    OutBufData[13] = 0xAA;
    cs = 0;
    for(i=0;i<(nLen-6-14);i++)
    {
        cs = cs + OutBufData[6+14+i];
    }
    OutBufData[nLen++]=cs;
    OutBufData[nLen++]=0x16;
    OutBufData[nLen++]=0x16;
    NSData *sendData = [NSData dataWithBytes:OutBufData length:nLen];
    
    return sendData;
}

/*
 入参：pHostBuf 收到的电表远程控制返回数据帧
 返回：0错误帧
 1确认帧
 2异常返回帧
 */
- (unsigned int)GW09_AnalysisTripControl:(unsigned char*)pHostBuf :(unsigned int)nLen
{
    unsigned int i,len;
    unsigned char cs;
    unsigned char *cMeterBuf;
    if(![self GW09_Checkout:pHostBuf :nLen])
    {
        return 0;
    }
    //AfxMessageBox(_T("GW09_Checkout Right"));
    if(pHostBuf[12] != 0x10)
    {
        return 0;
    }
    len = (pHostBuf[20]<<8)|pHostBuf[19];
    cMeterBuf=&pHostBuf[21];
    
    //AfxMessageBox(_T("0"));
    if(len<8) return 0;
    
    //0  1  2  3  4  5  6  7   8   9  10 11 12
    //68 a0 a1 a2 a3 a4 a5 68 ctrl len da cs 16
    for(i=0;i<(len-7);i++)
    {
        cMeterBuf=&pHostBuf[21+i];
        if((cMeterBuf[0]==0x68)&&(cMeterBuf[7]==0x68))
        {
            len = cMeterBuf[9]+12;
            if(cMeterBuf[len-1]==0x16) //check
            {
                cs = 0;
                for(i=0;i<(len-2);i++)
                {
                    cs += cMeterBuf[i];
                }
                if(cs==cMeterBuf[len-2])
                {
                    //正确的数据帧
                    if(cMeterBuf[8] == 0x9c)
                    {
                        return 1;
                    }
                    else if(cMeterBuf[8] == 0xdc)
                    {
                        return 2;
                    }
                    else{
                        //	AfxMessageBox(_T("1"));
                        return 0;
                    }
                }
                else
                {
                    // AfxMessageBox(_T("2"));
                    return 0;
                }
            }
            else
            {
                //	AfxMessageBox(_T("3"));
                return 0;
            }
        }
    }
    //AfxMessageBox(_T("4"));
    return 0;
}

//装换ip
-(NSString *)convertHostToAddress:(NSString *)host {
    
    NSError *err = nil;
    
    NSMutableArray *addresses = [GCDAsyncSocket lookupHost:host port:0 error:&err];
    
    //    NSLog(@"address%@",addresses);
    
    NSData *address4 = nil;
    NSData *address6 = nil;
    
    for (NSData *address in addresses)
    {
        if (!address4 && [GCDAsyncSocket isIPv4Address:address])
        {
            address4 = address;
        }
        else if (!address6 && [GCDAsyncSocket isIPv6Address:address])
        {
            address6 = address;
        }
    }
    
    NSString *ip;
    
    if (address6) {
        //        NSLog(@"ipv6%@",[GCDAsyncSocket hostFromAddress:address6]);
        ip = [GCDAsyncSocket hostFromAddress:address6];
    }else {
        //        NSLog(@"ipv4%@",[GCDAsyncSocket hostFromAddress:address4]);
        ip = [GCDAsyncSocket hostFromAddress:address4];
    }
    
    return ip;
    
}


#pragma mark --状态帧解析

@end
