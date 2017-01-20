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

typealias ConnectionStatusBlock = (CocoaMQTTConnState) -> Void
typealias MessageReceivedBlock = (_ device:String, _ topic:String, _ message:Any) -> Void

class MQTTClient: NSObject, CocoaMQTTDelegate {
    static let shared = MQTTClient()
    public var mqtt:CocoaMQTT?
    
    private var connectionStatusBlock:ConnectionStatusBlock?
    func setConnectionStatusBlock(callback: ConnectionStatusBlock? = nil ) {
        connectionStatusBlock = callback
    }
    
    private var messageReceivedBlock:MessageReceivedBlock?
    func setMessageReceivedBlock(callback: MessageReceivedBlock? = nil) {
        messageReceivedBlock = callback
    }
    
    
    private override init() {
        super.init()
        let keys = MqttTestKeys.init()
        
        let clientID = "CocoaMQTT-" + String(ProcessInfo().processIdentifier)
        mqtt = CocoaMQTT(clientID: clientID, host: keys.mqttHost, port: 8883)
        mqtt!.username = keys.mqttUser
        mqtt!.password = keys.mqttPassword
//        mqtt!.willMessage = CocoaMQTTWill(topic: "/will", message: "dieout")
        mqtt!.keepAlive = 60
        mqtt!.delegate = self
        mqtt!.enableSSL = true
        
        NotificationCenter.default.addObserver(self, selector: #selector(connect), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(disconnect), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)

    }
    
    func connect () {
        mqtt!.connect()
//        print("connecting")
        if (connectionStatusBlock != nil) {
            connectionStatusBlock!( CocoaMQTTConnState.connecting )
        }
    }
    
    func disconnect () {
        mqtt!.disconnect()
    }
    
    // MARK: - MQTTSession delegate
    
    func mqtt(_ mqtt: CocoaMQTT, didConnect host: String, port: Int) {
        print("did connect", host, port)
        self.subscribeToChannel()
    }
    func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
        if (connectionStatusBlock != nil) {
            connectionStatusBlock!(CocoaMQTTConnState.connected)
        }
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
        
        if (messageReceivedBlock != nil) {
            self.messageReceivedBlock?("device", message.topic as String, message.string as Any)
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
//        print("did disconnect", err?.localizedDescription)
        
        if (connectionStatusBlock != nil) {
            connectionStatusBlock!(CocoaMQTTConnState.disconnected)
        }
        
        if (UIApplication.shared.applicationState == .active && mqtt.connState == .disconnected && err != nil) {
            self.perform(#selector(self.connect), with: nil, afterDelay: 3.0)
        }
        
    }

    func subscribeToChannel() {
        
        mqtt?.subscribe("/heater/1/temperature/internal", qos: CocoaMQTTQOS.qos1)
        mqtt?.subscribe("/heater/1/temperature/external", qos: CocoaMQTTQOS.qos1)
        mqtt?.subscribe("/heater/1/temperature/floor", qos: CocoaMQTTQOS.qos1)
        mqtt?.subscribe("/heater/1/relay/3/status", qos: CocoaMQTTQOS.qos1)
        mqtt?.subscribe("/heater/1/setpoint/status", qos: CocoaMQTTQOS.qos1)
        mqtt?.subscribe("/heater/1/rules/status", qos: CocoaMQTTQOS.qos1)
    }
    

}
