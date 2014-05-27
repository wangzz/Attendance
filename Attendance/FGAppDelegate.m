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
    
    [self formatAttendanceStatus:attendanceArr];
    
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
    NSString *path = @"/Users/wangzz/Desktop/detail.txt";
    NSString *result = @"/Users/wangzz/Desktop/detail_result.csv";
    NSError *err = nil;
    NSMutableData *attendanceData = [NSMutableData dataWithContentsOfFile:path options:NSDataReadingMappedIfSafe error:&err];
    if (err) {
        NSLog(@"read file err:%@",err);
    }
    
    NSArray *nameResults = [arr valueForKeyPath:@"@distinctUnionOfObjects.name"];
    for (NSString *name in nameResults) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name == %@",name];
        NSArray *personArr = [arr filteredArrayUsingPredicate: predicate];
        NSString *personRowString = [self rowStringWithPersonName:name personArr:personArr];
        [attendanceData appendData:[personRowString dataUsingEncoding:NSUTF16StringEncoding]];
    }

    return [attendanceData writeToFile:result atomically:YES];
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

- (NSString *)rowStringWithPerson:(FGPerson *)person
{
    NSMutableString *rowString = nil;
    for (NSInteger row = 1; row <= 2; row++) {
        if (row == 1) {
            [rowString appendString:person.name];
        } else if (row == 2) {
            [rowString appendString:@"\t"];
        }
        
        for (NSInteger column = 1; column <= 31; column++) {
            
            NSArray *dateArr = [person.date componentsSeparatedByString:@"-"];
            if (dateArr.count != 3) {
                continue;
            }
            
            if (column == [[dateArr objectAtIndex:2] integerValue]) {
                if (row == 1) {
                    [rowString appendString:person.timeArray.firstObject];
                } else if (row == 2) {
                    if (person.timeArray.count > 1) {
                        [rowString appendString:person.timeArray.lastObject];
                    } else {
                        [rowString appendString:@"\t"];
                    }
                }
            } else {
                [rowString appendString:@"\t"];
            }
        }
        [rowString appendString:@"\n"];
    }
    
    return rowString;
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
