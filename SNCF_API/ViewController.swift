//
//  ViewController.swift
//  SNCF_API
//
//  Created by Jean-Louis Danielo on 07/01/2016.
//  Copyright © 2016 Jean-Louis Danielo. All rights reserved.
//




import UIKit
import Alamofire


class ViewController: UIViewController {
    var trainsTimesheets:Array = [TrainDatas]();
    var element:NSString = "";
    var trainDate:String = "";
    var trainCodeMission:String = "";
    var trainNumero:String = "";
    var trainTerminus = "";
    
    var trainState:TrainState = TrainState.ONTIME;
    var trainScheduleType:ScheduleType = ScheduleType.REALTIME;
    
    // Count the number of iterations in the train
    var scheduleCount:Int = 0;

    @IBOutlet weak var fetchDatas: UIButton!
    @IBOutlet weak var trainScheduleTimeLabel: UILabel!
    @IBOutlet weak var trainTerminusLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        fetchServerDatas()
    }
    
    func fetchServerDatas () {
        // Paris Saint-Lazare : 87384008
        // Clichy Lavallois : 87381129
        
        Alamofire.request(.GET, "http://api.transilien.com/gare/87381129/depart/87384008")
            .authenticate(user: Login.username, password: Login.password)
            .response { (request, response, data, error) in
                let parser = NSXMLParser(data: data!);
                parser.delegate = self;
                parser.parse();
        }
    }
    
    @IBAction func checkIfTrainArrived(sender: UIButton?) {
        fetchDatas.enabled = false;
        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(10 * Double(NSEC_PER_SEC)))
        dispatch_after(delayTime, dispatch_get_main_queue()) {
            self.fetchDatas.enabled = true;
            
            print(UIApplication.sharedApplication().scheduledLocalNotifications);
        }
//        trainScheduleTimeLabel.performSelector(Selector("setEnabled:"), withObject: Bool(true), afterDelay: 10.0);
//        NSTimer.scheduledTimerWithTimeInterval(1.0, target: fetchDatas, selector: Selector("setEnabled:"), userInfo: nil, repeats: false)
        
        // Contains the next eleligible train after trainsTimesheetsTransformed[0];
        var nextEligibleTrain:TrainDatas = TrainDatas();
        var getNextEligibleTrain = false;
        
        let trainsTimesheetsTransformed = trainsTimesheets.flatMap{ $0 }.filter {
            (trainDatas: TrainDatas) -> Bool in
            
            // If the trainDatas' scheduleWithMarch is earlier than now (it means we don't have enough time to reach the station)
            // OR the trainDatas' scheduleWithMarch is greater than 180
            // OR the train has state "SUPPRIME"
            if trainDatas.scheduleWithMarch.earlierDate(GlobalConstants.getNeutralNow()) == trainDatas.scheduleWithMarch ||
                trainDatas.scheduleWithMarch.timeIntervalSinceDate(NSDate()) > 180 ||
                trainDatas.state == .SUPPRIME
            {
                // If the train is not SUPPRIME
                // AND there is not datas for getNextEligibleTrain (aka. the first train eligible after the good train)
                // AND the train is after now
                if trainDatas.state != .SUPPRIME &&
                    !getNextEligibleTrain &&
                    trainDatas.scheduleWithMarch.laterDate(GlobalConstants.getNeutralNow()) == trainDatas.scheduleWithMarch
                {
                    getNextEligibleTrain = true
                    nextEligibleTrain = trainDatas;
                }
                
                return false;
            }
            
            return true;
        }
        
        // There is no datas exploitable (every datas stored in trainsTimesheets are earlier than now)
        if trainsTimesheets.last?.scheduleWithMarch.earlierDate(GlobalConstants.getNeutralNow()) == trainsTimesheets.last?.scheduleWithMarch {
            let alertController = UIAlertController.init(title: "Oups !", message: "Tous les trains sont passés", preferredStyle: UIAlertControllerStyle.ActionSheet);
            self.presentViewController(alertController, animated: true) {};
            
            let cancelAction = UIAlertAction(title: "Rechercher", style: .Cancel) { (action) in
                self.fetchServerDatas()
            }
            alertController.addAction(cancelAction);
            
            return;
        }
        
        
        
        if let firstTrain = trainsTimesheetsTransformed.first where firstTrain.state != .SUPPRIME {
            if firstTrain.state == .ONTIME {
                self.view.backgroundColor = UIColor.init(red: (60/255), green: (118/255), blue: (61/255), alpha: 1.0);
            } else if firstTrain.state == .RETARD {
                self.view.backgroundColor = UIColor.init(red: (252/255), green: (248/255), blue: (227/255), alpha: 1.0);
            }
            trainScheduleTimeLabel.text = "Heure de passage : \(firstTrain.getLitteralSchedule())";
            print("firstTrain", firstTrain.getTrainDate());
        } else {
            trainScheduleTimeLabel.text = "Pas de train pour le moment";
            self.view.backgroundColor = UIColor.init(red: (235/255), green: (204/255), blue: (209/255), alpha: 1.0);
            print("not reachable", trainsTimesheetsTransformed.first?.getTrainDate(), trainsTimesheets.first?.getTrainDate());
//            print(trainsTimesheets.map{ $0.scheduleWithMarch })
            // create a corresponding local notification
            let notification = UILocalNotification()
            notification.alertBody = "Un train arrivera (presque) en même temps que toi si tu pars maintenant \(NSDate())"
            notification.alertAction = "open" // text that is displayed after "slide to..." on the lock screen - defaults to "slide to view"
            notification.fireDate = nextEligibleTrain.scheduleWithMarch; // trainsTimesheets.first?.getTrainDate()// todo item due date (when notification will be fired)
            notification.soundName = UILocalNotificationDefaultSoundName // play default sound
            notification.category = "TODO_CATEGORY"
            UIApplication.sharedApplication().scheduleLocalNotification(notification)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension ViewController:NSXMLParserDelegate {
    func parserDidEndDocument(parser: NSXMLParser) {
        checkIfTrainArrived(nil);
        fetchDatas.enabled = true;
    }
    
    func parser(parser: NSXMLParser,
                didStartElement elementName: String,
                namespaceURI: String?,
                qualifiedName qName: String?,
                attributes attributeDict: [String : String]) {
        
//        Data example
//        <train>
//            <date mode="R">06/01/2016 13:56</date>
//            <num>EPAU39</num>
//            <miss>EPAU</miss>
//            <term>87001479</term>
//        </train>
                    
        element = elementName

        if (element as NSString).isEqualToString("date"){
            if attributeDict["mode"] == "R" {
                trainScheduleType = ScheduleType.REALTIME;
            } else {
                trainScheduleType = ScheduleType.THEORICAL;
            }
        }
    }
    
    func parser(parser: NSXMLParser, foundCharacters string: String) {
        if (string == "\n") {
            return;
        }
        
        if (element as NSString).isEqualToString("date") {
            trainDate = string;
        } else if (element as NSString).isEqualToString("num") {
            trainNumero = string;
        } else if (element as NSString).isEqualToString("miss") {
            trainCodeMission = string;
        } else if (element as NSString).isEqualToString("term") {
            trainTerminus = string;
        } else if (element as NSString).isEqualToString("etat") {
            if (element as NSString) == "Retardé" {
                trainState = .RETARD;
            } else if (element as NSString)  == "Supprimé" {
                trainState = .SUPPRIME;
            }
        }
    }
    
    func parser(parser: NSXMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?) {
           
            if (elementName as NSString).isEqualToString("train")
            {
                let trainTimesheet:TrainDatas = TrainDatas();
                trainTimesheet.date = trainDate;
                trainTimesheet.codeMission = trainCodeMission;
                trainTimesheet.terminus = trainTerminus;
                trainTimesheet.numero = trainNumero;
                trainTimesheet.state = trainState;
                trainTimesheet.scheduleType = trainScheduleType;

                trainsTimesheets.append(trainTimesheet);
            }
    }
}

