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
    
    [self formatAttendanceDaceWith:attendanceArr];
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
        
        if (person.name == nil || person.name.length == 0) {
            NSLog(@"err");
        } else {
            [attendanceArr addObject:person];
        }
        
    }
    
    return attendanceArr;
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
            
            NSLog(@"%@",arriveTimeResults);
        }
    }
}

- (BOOL)writeToCSVFile:(NSArray *)arr
{
    NSString *path = @"/Users/wangzz/Desktop/000.csv";
    NSMutableData *data = [NSMutableData data];
    for (FGPerson *person in arr) {
        NSString *string = [NSString stringWithFormat:@"%@\t%@\t%@\t%@\n",person.ID,person.employeeID,person.name,person.arriveTime];
//        NSLog(@"%@",string);
        [data appendData:[string dataUsingEncoding:NSUTF16StringEncoding]];
    }
    
    return [data writeToFile:path atomically:YES];
}




@end
