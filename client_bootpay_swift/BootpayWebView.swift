//
//  BootpayWebview.swift
//  client_bootpay_swift
//
//  Created by YoonTaesup on 2017. 8. 11..
//  Copyright © 2017년 bootpay.co.kr. All rights reserved.
//

import UIKit
import WebKit

protocol BootpayRequestProtocol {
    func onError(data: [String: String])
    func onConfirm(data: [String: String])
    func onCancel(data: [String: String])
    func onDone(data: [String: String])
}

class BootpayWebView: UIView {
    var wv: WKWebView!
    
    final let BASE_URL = "https://app.bootpay.co.kr"
    final let cdnArray = [
        "https://code.jquery.com/jquery-1.12.4.min.js",
        "https://d-cdn.bootpay.co.kr/bootpay-1.0.0.min.js"
    ]
    var importedJS = false
    let bridgeName = "Bootpay_iOS"
    var sendable: BootpayRequestProtocol?
    var bootpayScript = ""
    
    func bootpayRequest(_ script: String) {
        
        let configuration = WKWebViewConfiguration()
        configuration.userContentController.add(self, name: bridgeName)
        wv = WKWebView(frame: self.bounds, configuration: configuration)
        wv.navigationDelegate = self
        self.addSubview(wv)
        
        self.bootpayScript = script
        self.importedJS = false
        self.loadUrl(BASE_URL)
    }
}

extension BootpayWebView {
    internal func importJS() {
        for cdn in cdnArray {
            importScript(cdn: cdn)
        }
        loadBootapyRequest()
    }
    
    internal func doJavascript(_ script: String) {
        wv.evaluateJavaScript(script, completionHandler: nil)
    }
    
    internal func importScript(cdn: String) {
        doJavascript("var jq = document.createElement('script');jq.src = '\(cdn)';document.getElementsByTagName('head')[0].appendChild(jq);");
    }
    
    internal func loadUrl(_ urlString: String) {
        let url = URL(string: urlString)
        if let url = url {
            let request = URLRequest(url: url)
            wv.load(request)
        }
    }
    
    internal func loadBootapyRequest() { 
        doJavascript(self.bootpayScript)
    }
}

extension BootpayWebView: WKNavigationDelegate, WKScriptMessageHandler  {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if importedJS == false {
            importedJS = true
            importJS()
        }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url {
            
            if url.absoluteString.contains("https://dev-app.bootpay.co.kr/start/") {
                if #available(iOS 10, *) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                } else {
                    UIApplication.shared.openURL(url)
                }
                
                decisionHandler(.cancel)
            }
        }
        decisionHandler(.allow)
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {

    }
}
