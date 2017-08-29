//
//  SwiftyBootpay.swift
//  client_bootpay_swift
//
//  Created by YoonTaesup on 2017. 8. 11..
//  Copyright © 2017년 bootpay.co.kr. All rights reserved.
//

import UIKit
import WebKit

extension String: LocalizedError {
    public var errorDescription: String? { return self }
}

extension URL {
    public var queryItems: [String: String] {
        var params = [String: String]()
        return URLComponents(url: self, resolvingAgainstBaseURL: false)?
            .queryItems?
            .reduce([:], { (_, item) -> [String: String] in
                params[item.name] = item.value
                return params
            }) ?? [:]
    }
}

public protocol Params {}

//// from - devxoul's then (https://github.com/devxoul/Then)
extension Params where Self: AnyObject {
    public func params(_ block: (Self) -> Void) -> Self {
        block(self)
        return self
    }
}

class BootpayItem: Params {
    var item_name = ""
    var qty: Int = 0
    var unique = ""
    var price = Double(0)
    
    func toString() -> String {
        if item_name.isEmpty { return "" }
        if qty == 0 { return "" }
        if unique.isEmpty { return "" }
        if price == Double(0) { return "" }
        
        return [
            "{",
            "item_name: '\(item_name)',",
            "qty: '\(qty)',",
            "unique: '\(unique)',",
            "price: '\(Int(price))'",
            "}"
            ].reduce("", +)
    }
}

class SwiftyBootpay {
    public static let sharedInstance = SwiftyBootpay()
    
    var price = Double(0)
    var application_id = ""
    var name = ""
    var pg = ""
    var items = [BootpayItem]()
    var method = ""
    var params: [String: String] = [:]
    var order_id = ""
    var scheme = ""
    var isPaying = false
    
    internal var wv: BootpayWebView!
}


extension SwiftyBootpay: Params {
    func addItem(item: BootpayItem) -> SwiftyBootpay {
        self.items.append(item)
        return self
    }
    
    func setItems(items: [BootpayItem]) -> SwiftyBootpay {
        self.items = items
        return self
    }
    
    func request(_ sendable: BootpayRequestProtocol?) throws {
        do { try validCheck()} catch let error { throw error.localizedDescription }
        addBootpayView(sendable)
        let script = generateScript()
        NSLog(script)
        wv.bootpayRequest(script)
    }
    
    func callback(url: URL) {
        if let host = url.host {
            if host == "error" { wv.sendable?.onError(data: url.queryItems) }
            else if host == "confirm" { wv.sendable?.onConfirm(data: url.queryItems) }
            else if host == "cancel" { wv.sendable?.onCancel(data: url.queryItems) }
            else if host == "done" { wv.sendable?.onDone(data: url.queryItems) }
        }
    }
    
    func transactionConfirm(data: [String: String]) {
        wv.doJavascript("this.transactionConfirm(JSON.parse(\(dicToJsonString(data))));")
    }
    
    func dismiss() {
        clear()
        
        wv.removeFromSuperview()
        wv = nil
        self.isPaying = false
    }
    
    func isPayingNow() -> Bool {
        return self.isPaying
    }
}


extension SwiftyBootpay {
    fileprivate func dicToJsonString(_ data: [String: String]) -> String {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: data, options: [])
            let jsonStr = String(data: jsonData, encoding: .utf8)
            if let jsonStr = jsonStr {
                return jsonStr
            }
            return ""
        } catch {
            print(error.localizedDescription)
            return ""
        }
    }
    
    fileprivate func addBootpayView(_ sendable: BootpayRequestProtocol?) {
        let window = UIApplication.shared.keyWindow!
        self.isPaying = true
        if wv == nil { wv = BootpayWebView() }
        wv.frame = CGRect(x: window.frame.origin.x, y: window.frame.origin.y, width: window.frame.width, height: window.frame.height)
        wv.sendable = sendable
        window.addSubview(wv);
    }
    
    fileprivate func validCheck() throws {
        if scheme.isEmpty { throw "App shceme is not configured." }
        if price <= 0 { throw "Price is not configured." }
        if application_id.isEmpty { throw "Application id is not configured." }
        if pg.isEmpty { throw "PG is not configured." }
        if order_id.isEmpty { throw "order_id is not configured." }
        
        if !self.scheme.contains("://") {
            self.scheme = "\(self.scheme)://"
        }
    }
    
    fileprivate func generateItems() -> String {
        if self.items.count == 0 { return "" }
        return self.items.map { $0.toString() }.reduce(",", +)
    }
    
    fileprivate func generateScript() -> String {
        return ["BootPay.request({",
                "price: '\(price)',",
                "application_id: '\(application_id)',",
                "name: '\(name)',",
                "pg:'\(pg)',",
                "item: [\(generateItems())],",
                "method: '\(method)',",
                "params: JSON.parse(\(dicToJsonString(params))),",
                "order_id: '\(order_id)'",
                "}).error(function (data) {",
                "document.location = '\(scheme)error?$.param(JSON.stringify(data));'",
                "}).confirm(function (data) {",
                "document.location = '\(scheme)confirm?$.param(JSON.stringify(data));'",
                "}).cancel(function (data) {",
                "document.location = '\(scheme)cancel?$.param(JSON.stringify(data));'",
                "}).done(function (data) {",
                "document.location = '\(scheme)done?$.param(JSON.stringify(data));'",
                "});"
                ].reduce("", +)
    }
    
    fileprivate func clear() {
        if self.items.count > 0 { self.items.removeAll() }
        
        self.price = Double(0)
        self.application_id = ""
        self.name = ""
        self.pg = ""
        self.items = [BootpayItem]()
        self.method = ""
        self.order_id = ""
        self.scheme = ""
    }
} 
