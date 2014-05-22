//
//  FGAppDelegate.m
//  Attendance
//
//  Created by wangzz on 14-5-22.
//  Copyright (c) 2014年 FOOGRY. All rights reserved.
//

#import "FGAppDelegate.h"
#import "FGPerson.h"


@implementation FGAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
}

- (IBAction)onLoadDataButtonAction:(id)sender
{
    NSArray  *attendanceArr = [self readFile];
    
    BOOL result = NO;
    result = [self writeToCSVFile:attendanceArr];
    if (!result) {
        NSLog(@"write to file error.");
    }
}

- (NSArray *)readFile
{
    NSString *path = @"/Users/wangzz/Desktop/502.txt";
    NSError *err = nil;
    NSString *contents = [[NSString alloc] initWithContentsOfFile:path
                                                         encoding:NSUTF16StringEncoding
                                                            error:&err];
    NSArray *contentsArray = [contents componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    
    NSMutableArray  *attendanceArr = [NSMutableArray array];
    
    for (NSInteger idx = 0; idx < contentsArray.count; idx++) {
        NSString* currentContent = [contentsArray objectAtIndex:idx];
        
        NSArray *currentContentArr = [currentContent componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
        if (currentContentArr.count < 5) {
            continue;
        }
        
        FGPerson *person = [[FGPerson alloc] init];
        
        person.ID = [currentContentArr objectAtIndex:0];
        
        person.employeeID = [currentContentArr objectAtIndex:1];
        
        person.name = [currentContentArr objectAtIndex:2];
        
        person.date = [currentContentArr objectAtIndex:3];
        
        person.arriveTime = [currentContentArr objectAtIndex:4];
        
        [attendanceArr addObject:person];
    }
    
    return attendanceArr;
}

- (BOOL)writeToCSVFile:(NSArray *)arr
{
    NSString *path = @"/Users/wangzz/Desktop/000.csv";
    NSMutableData *data = [NSMutableData data];
    for (FGPerson *person in arr) {
        NSString *string = [NSString stringWithFormat:@"%@\t%@\t%@\t%@\n",person.ID,person.employeeID,person.name,person.arriveTime];
        NSLog(@"%@",string);
        [data appendData:[string dataUsingEncoding:NSUTF16StringEncoding]];
    }
    
    return [data writeToFile:path atomically:YES];
}

/*
 
 转义字符               意义                    ASCII码值（十进制）
 \a         响铃(BEL)                             007
 \b         退格(BS) ，将当前位置移到前一列           008
 \f         换页(FF)，将当前位置移到下页开头          012
 \n         换行(LF) ，将当前位置移到下一行开头       010
 \r         回车(CR) ，将当前位置移到本行开头         013
 \t         水平制表(HT) （跳到下一个TAB位置）        009
 \v         垂直制表(VT)	011
 \\         代表一个反斜线字符''\'                   092
 
 \'         代表一个单引号（撇号）字符                039
 \"         代表一个双引号字符                       034
 \0         空字符(NULL)                           000
 \ddd       1到3位八进制数所代表的任意字符            三位八进制
 \xhh       1到2位十六进制所代表的任意字符            二位十六进制

 
 */



@end
