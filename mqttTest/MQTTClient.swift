//
//  MQTTClient.swift
//  mqttTest
//
//  Created by Maxim Keegan on 17/01/2017.
//  Copyright © 2017 Maxim Keegan. All rights reserved.
//

import UIKit
import CocoaMQTT
import Keys


class MQTTClient: NSObject, CocoaMQTTDelegate {
    static let shared = MQTTClient()
    public var mqtt:CocoaMQTT?
    
    private override init() {
        let keys = MqttTestKeys.init()
        
        let clientID = "CocoaMQTT-" + String(ProcessInfo().processIdentifier)
        mqtt = CocoaMQTT(clientID: clientID, host: keys.mqttHost, port: 8883)
        mqtt!.username = keys.mqttUser
        mqtt!.password = keys.mqttPassword
        mqtt!.willMessage = CocoaMQTTWill(topic: "/will", message: "dieout")
        mqtt!.keepAlive = 60
        mqtt!.delegate = self
        mqtt!.enableSSL = true
        
        NotificationCenter.default.addObserver(self, selector: #selector(connect), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(disconnect), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)

    }
    
    func connect () {
        mqtt!.connect()
//        print("connecting")
//        self.connectLabel.text = "connecting..."
    }
    
    func disconnect () {
        mqtt!.disconnect()
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
        case "/heater/1/relay/success":
            heaterEnabledSwitch.setOn((message.string == "1" ? true : false) , animated: true)
            break
            
        case "/heater/1/setpoint/success":
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
        
        if (UIApplication.shared.applicationState == .active && mqtt.connState == .disconnected && err != nil) {
            self.perform(#selector(ViewController.connect), with: nil, afterDelay: 3.0)
        }
        
    }



}
