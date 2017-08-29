//
//  ViewController.swift
//  client_bootpay_swift
//
//  Created by YoonTaesup on 2017. 8. 11..
//  Copyright © 2017년 bootpay.co.kr. All rights reserved.
//

import UIKit
import WebKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let btn = UIButton(type: .roundedRect)
        btn.frame = CGRect(x: 0, y:0, width: self.view.frame.width, height: self.view.frame.height)
        btn.setTitle("Request", for: .normal)
        btn.addTarget(self, action: #selector(btnClick), for: .touchUpInside)
        self.view.addSubview(btn)
    }
    
    func btnClick() {
        let item = BootpayItem().params {
            $0.item_name = "B사 마스카라"
            $0.qty = 1
            $0.unique = "123"
            $0.price = 1000
        }
        
        let customParams: [String: String] = [
            "callbackParam1": "value12",
            "callbackParam2": "value34",
            "callbackParam3": "value56",
            "callbackParam4": "value78",
        ]
        do {
            try SwiftyBootpay.sharedInstance.params {
                    $0.price = 1000
                    $0.application_id = "593f8febe13f332431a8ddae"
                    $0.name = "블링블링 마스카라"
                    $0.order_id = "1234"
                    $0.params = customParams
                    $0.method = "card"
                    $0.scheme = "customscheme"
                    $0.pg = "kcp"
                }.addItem(item: item).request(self)
        } catch let error {
            NSLog(error.localizedDescription)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension ViewController: BootpayRequestProtocol {
    func onError(data: [String: String]) {
        SwiftyBootpay.sharedInstance.dismiss()
    }
    
    func onConfirm(data: [String: String]) {
        let iWantPay = true
        if iWantPay == true {
            SwiftyBootpay.sharedInstance.transactionConfirm(data: data)
        } else {
            SwiftyBootpay.sharedInstance.dismiss()
        }
    }
    
    func onCancel(data: [String: String]) {
        SwiftyBootpay.sharedInstance.dismiss()
    }
    
    func onDone(data: [String: String]) {
        SwiftyBootpay.sharedInstance.dismiss()
    }
}
