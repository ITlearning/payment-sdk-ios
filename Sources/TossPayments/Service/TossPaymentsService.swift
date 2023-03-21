//
//  File.swift
//  
//
//  Created by 김진규 on 2022/09/27.
//

#if canImport(UIKit)
import UIKit
import WebKit

protocol PaymentServiceProtocol: WKNavigationDelegate {
    var htmlString: String { get }
    var baseURL: URL { get }
    var failURLHandler: ((URL) -> Void)? { get set }
    var successBrandPayURLHandler: ((URL) -> Void)? { get set }
    var successPaymentURLHandler: ((URL) -> Void)? { get set }
}

class TossPaymentsService: NSObject, PaymentServiceProtocol {
    private let clientKey: String
    private let paymentMethod: PaymentMethod
    private let paymentInfo: PaymentInfo
    let baseURL: URL = URL(string: "https://tosspayments.com")!
    init(
        clientKey: String,
        paymentMethod: PaymentMethod,
        paymentInfo: PaymentInfo
    ) {
        self.clientKey = clientKey
        self.paymentMethod = paymentMethod
        self.paymentInfo = paymentInfo
    }
    
    var failURLHandler: ((URL) -> Void)?
    var successBrandPayURLHandler: ((URL) -> Void)?
    var successPaymentURLHandler: ((URL) -> Void)?
    
    // 한번만 요청할 Javascript 요청 여부
    private var didEvaluateRequestPaymentJavascript: Bool = false
}

extension TossPaymentsService {
    var htmlString: String {
        """
        <!DOCTYPE html>
        <html lang="ko">

        <head>
            <meta charset="UTF-8">
            <meta http-equiv="X-UA-Compatible" content="IE=edge">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <script src="https://js.tosspayments.com/v1"></script>
        </head>

        <body>
        </body>

        </html>
        """
    }
    
    var requestPaymentJavascript: String {
        let javascriptString = """
        var tossPayments = TossPayments('\(clientKey)');
        tossPayments.requestPayment('\(paymentMethod.rawValue)', \(paymentInfo.requestJSONString ?? ""));
        """
        return javascriptString
    }
    
    private func evaluateRequestPaymentJavascript(with webView: WKWebView) {
        if didEvaluateRequestPaymentJavascript { return }
        DispatchQueue.main.async {
            webView.evaluateJavaScript(self.requestPaymentJavascript)
            self.didEvaluateRequestPaymentJavascript = true
        }
    }
}

extension TossPaymentsService: WKNavigationDelegate {
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        //  FailURL 혹은 SuccessURL 처리
        if handleResult(with: navigationAction) {
            decisionHandler(.cancel)
            return
        }
        
        // https 이외의 action 처리
        if handleActionExceptHTTP(with: navigationAction) {
            decisionHandler(.cancel)
            return
        }
        
        decisionHandler(.allow)
    }
    
    func webView(
        _ webView: WKWebView,
        didFinish navigation: WKNavigation!
    ) {
        if webView.url?.absoluteString == "https://tosspayments.com/" {
            self.evaluateRequestPaymentJavascript(with: webView)
        }
    }
}

extension TossPaymentsService {
    
    private func handleResult(with navigationAction: WKNavigationAction) -> Bool {
        guard let url = navigationAction.request.url else { return false }
        let urlString = url.absoluteString
        
        if urlString.hasPrefix(WebConstants.failURL) {
            failURLHandler?(url)
            return true
        } else if urlString.hasPrefix(WebConstants.successPaymentURL) {
            successPaymentURLHandler?(url)
            return true
        } else if urlString.hasPrefix(WebConstants.successBrandPayURL) {
            successBrandPayURLHandler?(url)
            return true
        }
        
        return false
    }
    
    private func handleActionExceptHTTP(with navigationAction: WKNavigationAction) -> Bool {
        guard let url = navigationAction.request.url else { return false }
        guard !(url.scheme?.hasPrefix("http") ?? false) else { return false }
        guard url.scheme != "about" else { return false }
        UIApplication.shared.open(url)
        return true
    }
}

#endif
