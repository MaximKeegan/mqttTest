//
//  ViewController.swift
//  mqttTest
//
//  Created by Maksim Kigan on 08/01/17.
//  Copyright © 2017 Maxim Keegan. All rights reserved.
//

import UIKit
import CocoaMQTT
import Keys

class ViewController: UIViewController, CocoaMQTTDelegate {
    @IBOutlet var temp1Label: UILabel!
    @IBOutlet var temp2Label: UILabel!
    @IBOutlet var temp3Label: UILabel!
    @IBOutlet var setpointSlider: UISlider!
    @IBOutlet var heaterEnabledSwitch: UISwitch!
    @IBOutlet var connectLabel: UILabel!
    var mqtt:CocoaMQTT?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        let keys = MqttTestKeys.init()
        
        let clientID = "CocoaMQTT-" + String(ProcessInfo().processIdentifier)
        mqtt = CocoaMQTT(clientID: clientID, host: keys.mqttHost, port: 8883)
        mqtt!.username = keys.mqttUser
        mqtt!.password = keys.mqttPassword
        mqtt!.willMessage = CocoaMQTTWill(topic: "/will", message: "dieout")
        mqtt!.keepAlive = 60
        mqtt!.delegate = self
        mqtt!.enableSSL = true
        mqtt!.connect()
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.connect), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.disconnect), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
    }

    func connect () {
        mqtt!.connect()
        print("connecting")
        self.connectLabel.text = "connecting..."
        
    }
    
    func disconnect () {
        mqtt!.disconnect()
    }
    
    
    func subscribeToChannel() {
        
        mqtt!.subscribe("/heater/1/temperature/internal", qos: CocoaMQTTQOS.qos1)
        mqtt!.subscribe("/heater/1/temperature/external", qos: CocoaMQTTQOS.qos1)
        mqtt!.subscribe("/heater/1/temperature/floor", qos: CocoaMQTTQOS.qos1)
        mqtt!.subscribe("/heater/1/relay/1/status", qos: CocoaMQTTQOS.qos1)
        mqtt!.subscribe("/heater/1/relay/2/status", qos: CocoaMQTTQOS.qos1)
        mqtt!.subscribe("/heater/1/relay/3/status", qos: CocoaMQTTQOS.qos1)
        mqtt!.subscribe("/heater/1/setpoint/status", qos: CocoaMQTTQOS.qos1)
        mqtt!.subscribe("/heater/1/rules/status", qos: CocoaMQTTQOS.qos1)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func switchValueChangedAction(_ sender: UISwitch) {
        let channel = "/heater/1/relay/3"
        let message = (sender.isOn ? "1" : "0")
        self.mqtt!.publish(channel, withString: message, qos: CocoaMQTTQOS.qos0, retained: true, dup: true)
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
            self.mqtt!.publish(channel, withString: message!, qos: CocoaMQTTQOS.qos1, retained: true, dup: true)
        } catch {
            print(error.localizedDescription)
        }
    }

    func sendSliderValue() {
        let channel = "/heater/1/setpoint"
        let message = "\(setpointSlider.value)"
        self.mqtt!.publish(channel, withString: message, qos: CocoaMQTTQOS.qos1, retained: true, dup: true)

    }
    
    // MARK: - MQTTSession delegate
    
    func mqtt(_ mqtt: CocoaMQTT, didConnect host: String, port: Int) {
        print("did connect", host, port)
    }
    func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
        self.connectLabel.text = "connected"
        print("didConnectAck: \(ack)，rawValue: \(ack.rawValue)")
        
        if ack == .accept {
            subscribeToChannel()
        }

        
    }
    func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {
    }
    func mqtt(_ mqtt: CocoaMQTT, didPublishAck id: UInt16) {
    }
    func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16 ) {
        print("message", message.topic, message.string as Any)
        switch message.topic {
        case "/heater/1/temperature/internal":
            temp1Label.text = message.string
            break
        case "/heater/1/temperature/external":
            temp2Label.text = message.string
            break
        case "/heater/1/temperature/floor":
            temp3Label.text = message.string
            break
        case "/heater/1/relay/3/status":
            heaterEnabledSwitch.setOn((message.string == "1" ? true : false) , animated: true)
            break
            
        case "/heater/1/setpoint/status":
            setpointSlider.value = Float(message.string!)!
            break
        default: break
            
        }

    }
    func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopic topic: String) {
    }
    func mqtt(_ mqtt: CocoaMQTT, didUnsubscribeTopic topic: String) {
    }
    func mqttDidPing(_ mqtt: CocoaMQTT) {
    }
    func mqttDidReceivePong(_ mqtt: CocoaMQTT) {
    }
    func mqttDidDisconnect(_ mqtt: CocoaMQTT, withError err: Error?) {
        print("did disconnect", err?.localizedDescription)
        self.connectLabel.text = "disconnected"
    }
    
}

