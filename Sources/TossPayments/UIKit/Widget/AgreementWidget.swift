//
//  AgreementWidget.swift
//  
//
//  Created by 김진규 on 2023/05/09.
//

import Foundation
import WebKit

public final class AgreementWidget: WKWebView, CanUpdateHeight, WKUIDelegate {
    public weak var agreementUIDelegate: TossPaymentsAgreementUIDelegate?
    
    public var updatedHeight: CGFloat = 92 {
        didSet {
            guard oldValue != updatedHeight else { return }
            agreementUIDelegate?.didUpdateHeight(self, height: updatedHeight)
            invalidateIntrinsicContentSize()
        }
    }
    
    init() {
        super.init(frame: .zero, configuration: WKWebViewConfiguration())
        uiDelegate = self
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    public override var intrinsicContentSize: CGSize {
        var size = UIScreen.main.bounds.size
        size.height = self.updatedHeight
        return size
    }
    
}
