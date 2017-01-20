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
    @IBOutlet var setpointLabel: UILabel!
    @IBOutlet var heaterEnabledSwitch: UISwitch!
    @IBOutlet var connectLabel: UILabel!
    
    @IBOutlet var heater1statusView: UIView!
    @IBOutlet var heater2statusView: UIView!
//    var appState : UIApplicationState

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        MQTTClient.shared.setConnectionStatusBlock { (status) in
            switch status {
            case .connected:
                self.connectLabel.text = "connected"
                break
            case .connecting:
                self.connectLabel.text = "connecting..."
                break
                
            case .disconnected:
                self.connectLabel.text = "disconnected"
                break
                
            case .initial:
                self.connectLabel.text = "initial..."
                break
                
            }
        }
        
        
        MQTTClient.shared.setMessageReceivedBlock { (device, topic, message) in
            switch topic {
            case "/heater/1/temperature/internal":
                self.temp1Label.text = message as? String
                break
            case "/heater/1/temperature/external":
                self.temp2Label.text = message as? String
                break
            case "/heater/1/temperature/floor":
                self.temp3Label.text = message as? String
                break
            case "/heater/1/relay/1/status":
                self.heater1statusView.backgroundColor = (message as? String == "1" ? UIColor.red : UIColor.gray)
                break
            case "/heater/1/relay/2/status":
                self.heater2statusView.backgroundColor = (message as? String == "1" ? UIColor.red : UIColor.gray)
                break
            case "/heater/1/relay/3/status":
                self.heaterEnabledSwitch.setOn((message as? String == "1" ? true : false) , animated: true)
                break
    
            case "/heater/1/setpoint/status":
                self.setpointSlider.value = Float(message as! String)!
                self.setpointLabel.textColor = UIColor.green
                self.setpointLabel.text = message as! String
                break
            default: break
                
            }

            
            
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func switchValueChangedAction(_ sender: UISwitch) {
        let channel = "/heater/1/relay/3"
        let message = (sender.isOn ? "1" : "0")
        MQTTClient.shared.mqtt?.publish(channel, withString: message, qos: CocoaMQTTQOS.qos0, retained: true, dup: true)
    }

    @IBAction func sliderValueChangedAction(_ sender: UISlider) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(ViewController.sendSliderValue), object: nil)
        self.perform(#selector(ViewController.sendSliderValue), with: nil, afterDelay: 0.5)
        self.setpointLabel.text = "\(setpointSlider.value)"
        self.setpointLabel.textColor = UIColor.black
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
        self.setpointLabel.textColor = UIColor.yellow
        
    }
}

