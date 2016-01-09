//
//  TrainDatas.swift
//  SNCF_API
//
//  Created by Jean-Louis Danielo on 07/01/2016.
//  Copyright © 2016 Jean-Louis Danielo. All rights reserved.
//




import UIKit

//        <train>
//            <date mode="R">06/01/2016 13:56</date>
//            <num>EPAU39</num>
//            <miss>EPAU</miss>
//            <term>87001479</term>
//        </train>

/// Indicate the state of the train
enum TrainState {
    case RETARD;
    case SUPPRIME;
    case ONTIME;
}

enum ScheduleType {
    case REALTIME;
    case THEORICAL;
}

struct GlobalConstants {
    static let TRAVELTIME:Double = -600; // 10 minutes
    /// Return the current date with seconds set to zero
    static func getNeutralNow() -> NSDate {
        // 2014-02-20 11:36:20 +0000
        let flags: NSCalendarUnit = [NSCalendarUnit.Year, NSCalendarUnit.Month, NSCalendarUnit.Day, NSCalendarUnit.Hour, NSCalendarUnit.Minute]
        let currentCalendar: NSCalendar = NSCalendar.currentCalendar()
        let calendar: NSCalendar = NSCalendar(calendarIdentifier: currentCalendar.calendarIdentifier)!
        calendar.timeZone = NSTimeZone(forSecondsFromGMT: 0)
        let components: NSDateComponents = calendar.components(flags, fromDate: NSDate())
        
        return calendar.dateFromComponents(components)!
    }
}



class TrainDatas: NSObject {
    var date:NSString = "";
    var numero:NSString = "";
    var codeMission:NSString = "";
    var terminus:NSString = "";
    
    var scheduleType:ScheduleType = .REALTIME;
    var state:TrainState = .ONTIME;
    
    // http://mikebuss.com/2014/06/22/lazy-initialization-swift/
    lazy var scheduleWithMarch:NSDate = {
         [unowned self] in
        
        return self.getTrainDate().dateByAddingTimeInterval(GlobalConstants.TRAVELTIME);
    }();
    

    private var dateFormat:NSDateFormatter = NSDateFormatter.init();
    
    override init() {
        dateFormat.dateFormat = "dd/MM/yyyy HH:mm";
        dateFormat.timeZone = NSTimeZone.systemTimeZone();
        
        super.init();
    }
    
    func getTrainDate() -> NSDate {
        return self.dateFormat.dateFromString(self.date as String)!;
    }
    
    func getRemainingTime() -> Double {
        let now = NSDate.init();
        
        let distanceBetweenDates:NSTimeInterval = self.getTrainDate().timeIntervalSinceDate(now);

        return distanceBetweenDates/60; //3600 for hours
    }
    
    /// Returns the litteral schedule time for the train
    func getLitteralSchedule() -> String {
        let dateFormatter: NSDateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "HH'h'mm";
        dateFormatter.timeZone = NSTimeZone.systemTimeZone();

        
        let schedule = dateFormatter.stringFromDate(self.getTrainDate());
        
        return schedule;
    }
    
}
