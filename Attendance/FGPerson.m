//
//  FGPerson.m
//  Attendance
//
//  Created by wangzz on 14-5-22.
//  Copyright (c) 2014年 FOOGRY. All rights reserved.
//

#import "FGPerson.h"

@implementation FGPerson

- (NSString *)description
{
    NSString *des = [NSString stringWithFormat:@"ID:%@   employeeID:%@   name:%@   date:%@   timeArray:%@   arriveTime:%@   leaveTime:%@   status:%ld",_ID,_employeeID,_name,_date,_timeArray,_arriveTime,_leaveTime,_status];
    
    return des;
}

@end
