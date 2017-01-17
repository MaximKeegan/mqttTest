//
//  ViewController.swift
//  mqttTest
//
//  Created by Maksim Kigan on 08/01/17.
//  Copyright © 2017 Maxim Keegan. All rights reserved.
//

import UIKit
import CocoaMQTT

class ViewController: UIViewController {
    @IBOutlet var temp1Label: UILabel!
    @IBOutlet var temp2Label: UILabel!
    @IBOutlet var temp3Label: UILabel!
    @IBOutlet var setpointSlider: UISlider!
    @IBOutlet var heaterEnabledSwitch: UISwitch!
    @IBOutlet var connectLabel: UILabel!
    
//    var appState : UIApplicationState

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

    }

    func subscribeToChannel() {

        MQTTClient.shared.mqtt?.subscribe("/heater/1/temperature/internal", qos: CocoaMQTTQOS.qos1)
        MQTTClient.shared.mqtt?.subscribe("/heater/1/temperature/external", qos: CocoaMQTTQOS.qos1)
        MQTTClient.shared.mqtt?.subscribe("/heater/1/temperature/floor", qos: CocoaMQTTQOS.qos1)
        MQTTClient.shared.mqtt?.subscribe("/heater/1/relay/success", qos: CocoaMQTTQOS.qos1)
        MQTTClient.shared.mqtt?.subscribe("/heater/1/setpoint/success", qos: CocoaMQTTQOS.qos1)
        MQTTClient.shared.mqtt?.subscribe("/heater/1/rules/success", qos: CocoaMQTTQOS.qos1)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func switchValueChangedAction(_ sender: UISwitch) {
        let channel = "/heater/1/relay"
        let message = (sender.isOn ? "1" : "0")
        MQTTClient.shared.mqtt?.publish(channel, withString: message, qos: CocoaMQTTQOS.qos0, retained: true, dup: true)
    }

    @IBAction func sliderValueChangedAction(_ sender: UISlider) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(ViewController.sendSliderValue), object: nil)
        self.perform(#selector(ViewController.sendSliderValue), with: nil, afterDelay: 0.2)
    }
    
    @IBAction func commitRulesAction(_ sender: UIButton) {
        let channel = "/heater/1/rules"
//        var rules = [String : AnyObject]()
//        rules["1"] = [["00:00-06:00": 25],["06:00-23:00": 5], ["23:00-24:00": 25]] as AnyObject?
//        rules["2"] = [["00:00-06:00": 25],["06:00-23:00": 5], ["23:00-24:00": 25]] as AnyObject?
//        rules["3"] = [["00:00-06:00": 25],["06:00-23:00": 5], ["23:00-24:00": 25]] as AnyObject?
//        rules["4"] = [["00:00-06:00": 25],["06:00-23:00": 5], ["23:00-24:00": 25]] as AnyObject?
//        rules["5"] = [["00:00-06:00": 25],["06:00-23:00": 5], ["23:00-24:00": 25]] as AnyObject?
//        rules["6"] = [["00:00-24:00": 25]] as AnyObject?
//        rules["7"] = [["00:00-24:00": 25]] as AnyObject?
        var rules = [String : AnyObject]()
        rules["1"] = [["00:00-06:00": 25],["06:00-23:00": 5], ["23:00-24:00": 25]] as AnyObject?
        
        do {
            let data = try JSONSerialization.data(withJSONObject: rules)
            let message = String(bytes: data, encoding: String.Encoding.utf8)
            MQTTClient.shared.mqtt?.publish(channel, withString: message!, qos: CocoaMQTTQOS.qos1, retained: true, dup: true)
        } catch {
            print(error.localizedDescription)
        }
    }

    func sendSliderValue() {
        let channel = "/heater/1/setpoint"
        let message = "\(setpointSlider.value)"
        MQTTClient.shared.mqtt?.publish(channel, withString: message, qos: CocoaMQTTQOS.qos1, retained: true, dup: true)

    }
}

