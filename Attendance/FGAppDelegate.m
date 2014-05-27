//
//  FGAppDelegate.m
//  Attendance
//
//  Created by wangzz on 14-5-22.
//  Copyright (c) 2014年 FOOGRY. All rights reserved.
//

#import "FGAppDelegate.h"
#import "FGPerson.h"

//导出的文件路径
#define EXPORT_PATH     @"/Users/wangzz/Desktop/detail_result.csv"

@interface FGAppDelegate ()
{
    IBOutlet NSTextView *_textView;
    
    NSURL *_originFileUrl;
    NSURL *_exportFileUrl;
}

- (IBAction)onSelectDateFileButtonAction:(id)sender;
- (IBAction)onSelectModuleFileButtonAction:(id)sender;
- (IBAction)onCreateDataButtonAction:(id)sender;

@end

@implementation FGAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
}

#pragma mark - Button Action
- (IBAction)onSelectDateFileButtonAction:(id)sender
{
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setPrompt: @"Select"];
    [panel beginSheetModalForWindow:_window completionHandler:^(NSInteger result)
    {
        if (result == NSFileHandlingPanelOKButton) {
            _originFileUrl = [panel URL];
            
            NSString *selectFile = [NSString stringWithFormat:@"已选择数据文件：%@",[_originFileUrl absoluteString]];
            [_textView insertText:[self timestampStringWithString:selectFile]];
        } else if (result == NSFileHandlingPanelCancelButton) {
            [_textView insertText:[self timestampStringWithString:@"数据文件选择已取消"]];
        }
    }];
}

- (IBAction)onSelectModuleFileButtonAction:(id)sender
{
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setPrompt: @"Select"];
    [panel beginSheetModalForWindow:_window completionHandler:^(NSInteger result)
     {
         if (result == NSFileHandlingPanelOKButton) {
             _exportFileUrl = [panel URL];
             
             NSString *selectFile = [NSString stringWithFormat:@"已选择模板文件：%@",[_exportFileUrl absoluteString]];
             [_textView insertText:[self timestampStringWithString:selectFile]];
         } else if (result == NSFileHandlingPanelCancelButton) {
             [_textView insertText:[self timestampStringWithString:@"模板文件选择已取消"]];
         }
     }];
}

- (IBAction)onCreateDataButtonAction:(id)sender
{
    if (_originFileUrl == nil) {
        [_textView insertText:[self timestampStringWithString:@"请先选择数据文件！"]];
        return;
    }
    
    if (_exportFileUrl == nil) {
        [_textView insertText:[self timestampStringWithString:@"请先选择模板文件！"]];
        return;
    }
    
    NSArray  *attendanceArr = [self readFile];
    if (attendanceArr.count == 0) {
        return;
    } else {
        [_textView insertText:[self timestampStringWithString:@"数据文件读取成功！"]];
    }
    
    [self formatAttendanceStatus:attendanceArr];
    
    BOOL result = NO;
    result = [self writeToCSVFile:attendanceArr];
    if (!result) {
        NSLog(@"write to file error.");
        [_textView insertText:[self timestampStringWithString:@"生成表格数据失败！"]];
    } else {
        [_textView insertText:[self timestampStringWithString:@"生成表格数据成功！"]];
        [_textView insertText:[self timestampStringWithString:[NSString stringWithFormat:@"表格数据文件路径：%@",EXPORT_PATH]]];
    }
}

- (NSString *)timestampStringWithString:(NSString *)string
{
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *dateString = [NSString stringWithFormat:@"%@    %@\n",[format stringFromDate:[NSDate date]],string];
    
    return dateString;
}

- (NSArray *)readFile
{
    NSError *err = nil;
    NSString *contents = [[NSString alloc] initWithContentsOfURL:_originFileUrl
                                              encoding:NSUTF16StringEncoding
                                                 error:&err];
    if (err) {
        [_textView insertText:[self timestampStringWithString:err.description]];
        return nil;
    }
    
    NSArray *contentsArray = [contents componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    
    NSMutableArray  *attendanceArr = [NSMutableArray array];
    
    for (NSInteger idx = 0; idx < contentsArray.count; idx++) {
        NSString* currentContent = [contentsArray objectAtIndex:idx];
        
        NSArray *currentContentArr = [currentContent componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
        if (currentContentArr.count < 5) {
            continue;
        }
    
        NSString *name = [currentContentArr objectAtIndex:2];   //姓名
        NSString *date = [currentContentArr objectAtIndex:3];   //日期
        NSString *time = [currentContentArr objectAtIndex:4];   //打卡时间
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name == %@ and date == %@",name,date];
        NSArray *personArr = [attendanceArr filteredArrayUsingPredicate: predicate];
        if (personArr && personArr.count == 1) {
            FGPerson *person = [personArr objectAtIndex:0];
            NSMutableArray *timeArr = (NSMutableArray *)person.timeArray;
            [timeArr addObject:time];
        } else {
            FGPerson *person = [[FGPerson alloc] init];
            person.ID = [currentContentArr objectAtIndex:0];
            person.employeeID = [currentContentArr objectAtIndex:1];
            person.name = name;
            person.date = date;
            person.timeArray = [NSMutableArray arrayWithObject:time];
            
            if (person.name == nil || person.name.length == 0) {
//                NSLog(@"err");
            } else {
                [attendanceArr addObject:person];
            }
        }
    }
    
    return attendanceArr;
}

- (void)formatAttendanceStatus:(NSArray *)arr
{
    for (id object in arr) {
        if (object == nil || ![object isKindOfClass:[FGPerson class]]) {
            continue;
        }
        
        FGPerson *person = (FGPerson *)object;
        NSString *firstTime = person.timeArray.firstObject;
        NSString *lastTime = person.timeArray.lastObject;
        
        NSString *normalComeTimeString = @"9:00";   //正常上班时间
        NSString *normalLeveTimeString = @"18:30";  //正常下班时间
        NSString *seperateTimeString = @"5:00";     //5点之前的打卡时间算成前一天打卡记录，之后的算成当天打卡记录
        NSString *overTimeString = @"21:00";        //21点之后的有餐补
        
        //早上打卡时间在5点-9点，晚上打卡时间在18：30到21点的属于正常考勤
        if ([self comparisonString1:firstTime string2:seperateTimeString] == NSOrderedDescending &&
            [self comparisonString1:firstTime string2:normalComeTimeString] == NSOrderedAscending &&
            [self comparisonString1:lastTime string2:normalLeveTimeString] == NSOrderedDescending &&
            [self comparisonString1:lastTime string2:overTimeString] == NSOrderedAscending) {
            person.status = FGAttendanceStatusNormal;
            
            person.arriveTime = firstTime;
            person.leaveTime = lastTime;
            
        } else {
            person.status = FGAttendanceStatusUnknow;
        }
    }
}

- (NSComparisonResult)comparisonTimeString1:(NSString *)timeString1 timeString2:(NSString *)timeString2
{
    NSArray *timeArr1 = [timeString1 componentsSeparatedByString:@":"];
    NSArray *timeArr2 = [timeString2 componentsSeparatedByString:@":"];
    
    if (timeArr1.count != 2 || timeArr2.count != 2) {
        return NSNotFound;
    }
    
    NSComparisonResult result = [timeArr1.firstObject compare:timeArr2.firstObject];
    if (result != NSOrderedSame) {
        return result;
    } else {
        return [timeArr1.lastObject compare:timeArr2.lastObject];
    }
}

- (BOOL)writeToCSVFile:(NSArray *)arr
{
    NSError *err = nil;
    NSMutableData *attendanceData = [NSMutableData dataWithContentsOfURL:_exportFileUrl options:NSDataReadingMappedIfSafe error:&err];
    if (err) {
        NSLog(@"read file err:%@",err);
        [_textView insertText:[self timestampStringWithString:@"模板文件读取失败！"]];
        [_textView insertText:[self timestampStringWithString:err.description]];
        return NO;
    } else {
        [_textView insertText:[self timestampStringWithString:@"模板文件读取成功！"]];
    }
    
    NSArray *nameResults = [arr valueForKeyPath:@"@distinctUnionOfObjects.name"];
    for (NSString *name in nameResults) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name == %@",name];
        NSArray *personArr = [arr filteredArrayUsingPredicate: predicate];
        NSString *personRowString = [self rowStringWithPersonName:name personArr:personArr];
        [attendanceData appendData:[personRowString dataUsingEncoding:NSUTF16StringEncoding]];
    }

    return [attendanceData writeToFile:EXPORT_PATH atomically:YES];
}

- (NSString *)rowStringWithPersonName:(NSString *)personName personArr:(NSArray *)personArr
{
    NSMutableString *arriveString = [NSMutableString stringWithFormat:@"%@\t",personName];
    NSMutableString *leveString = [NSMutableString stringWithString:@"\t"];
    for (int column = 1; column <= 31; column++) {
        NSString *dateString = [NSString stringWithFormat:@"2014-5-%d",column];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"date == %@",dateString];
        NSArray *datePersonArr = [personArr filteredArrayUsingPredicate:predicate];
        if (datePersonArr.count == 0) {
            [arriveString appendString:@"\t"];
            [leveString appendString:@"\t"];
            continue;
        }
        
        if (datePersonArr.count != 1) {
            continue;
        }
        
        FGPerson *person = datePersonArr.firstObject;
        [arriveString appendFormat:@"%@\t",person.timeArray.firstObject];
        
        if (person.timeArray.count > 1) {
            [leveString appendFormat:@"%@\t",person.timeArray.lastObject];
        } else {
            [leveString appendString:@"\t"];
        }
    }
    
    [arriveString appendFormat:@"\n%@\n",leveString];
    
    return arriveString;
}

- (BOOL)writeToCSVFile2:(NSArray *)arr
{
    NSString *normalPath = @"/Users/wangzz/Desktop/normal.csv";
    NSString *unNormalPath = @"/Users/wangzz/Desktop/normal_un.csv";
    NSMutableData *normalData = [NSMutableData data];
    NSMutableData *unNormalData = [NSMutableData data];
    
    //初始化题头
    [normalData appendData:[@"登记号码\t工号\t姓名\t出勤日期\t签到时间\t签退时间\n" dataUsingEncoding:NSUTF16StringEncoding]];
    
    for (FGPerson *person in arr) {
        NSString *string = [NSString stringWithFormat:@"%@\t%@\t%@\t%@\t%@\t%@\n",person.ID,person.employeeID,person.name,person.date,person.arriveTime,person.leaveTime];
        if (person.status == FGAttendanceStatusNormal) {
            [normalData appendData:[string dataUsingEncoding:NSUTF16StringEncoding]];
        } else {
            [unNormalData appendData:[string dataUsingEncoding:NSUTF16StringEncoding]];
        }
    }
    
    [normalData writeToFile:normalPath atomically:YES];
    return [unNormalData writeToFile:unNormalPath atomically:YES];
}

- (NSComparisonResult)comparisonString1:(NSString *)string1 string2:(NSString *)string2
{
    if ([string1 integerValue] > [string2 integerValue]) {
        return NSOrderedDescending;
    } else if ([string1 integerValue] < [string2 integerValue]) {
        return NSOrderedAscending;
    } else {
        return NSOrderedSame;
    }
}

- (void)formatAttendanceDaceWith:(NSArray *)arr
{
    //获取全部姓名数组
    NSArray *nameResults = [arr valueForKeyPath:@"@distinctUnionOfObjects.name"];
    for (NSString *name in nameResults) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name == %@",name];
        NSArray *personArr = [arr filteredArrayUsingPredicate: predicate];
        NSArray *dateResults = [personArr valueForKeyPath:@"@distinctUnionOfObjects.date"];
        
        for (NSString *date in dateResults) {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"date == %@",date];
            NSArray *arriveTimeResults = [personArr filteredArrayUsingPredicate: predicate];
            
            NSArray *timeResults = [arriveTimeResults valueForKeyPath:@"@distinctUnionOfObjects.arriveTime"];
            NSArray *sortTimeArray = [timeResults sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2)
            {
                
                NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                [formatter setDateFormat:@"YYYY-m-d h:mm"];
                NSDate *date1 = [formatter dateFromString:[NSString stringWithFormat:@"%@ %@",date,obj1]];
                NSDate *date2 = [formatter dateFromString:[NSString stringWithFormat:@"%@ %@",date,obj2]];
                
                NSComparisonResult result = [date1 isEqualToDate:date2];
                
                return result == NSOrderedDescending; // 升序
            }];
            
            NSLog(@"%@",sortTimeArray);
        }
    }
}



@end
