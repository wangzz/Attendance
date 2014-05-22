//
//  FGPerson.h
//  Attendance
//
//  Created by wangzz on 14-5-22.
//  Copyright (c) 2014年 FOOGRY. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef NS_ENUM(NSInteger, FGAttendanceStatus)
{
    FGAttendanceStatusUnknow,                       //未知考勤状态
    FGAttendanceStatusBeLate,                       //迟到
    FGAttendanceStatusLeaveEarly,                   //早退
    FGAttendanceStatusBeLateAndLeaveEarly,          //迟到而且早退
    FGAttendanceStatusNormal,                       //正常考勤
};


@interface FGPerson : NSObject

@property (nonatomic, copy) NSString                *ID;                //签到号码

@property (nonatomic, copy) NSString                *employeeID;        //员工编号

@property (nonatomic, copy) NSString                *name;              //姓名

@property (nonatomic, copy) NSString                *date;              //签到日期

@property (nonatomic, copy) NSString                *arriveTime;        //签到时间

@property (nonatomic, copy) NSString                *leaveTime;         //签退时间

@property (nonatomic, assign) FGAttendanceStatus    status;             //考勤状态

@end
