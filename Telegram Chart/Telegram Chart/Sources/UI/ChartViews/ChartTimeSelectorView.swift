//
// Created by Vadim on 2019-03-16.
// Copyright (c) 2019 Vadim Belotitskiy. All rights reserved.
//

import UIKit

public class ChartTimeSelectorView: UIView {

    private let scrollView = UIScrollView()
    private let longPress = UILongPressGestureRecognizer()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        scrollView.frame = bounds
        scrollView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        addSubview(scrollView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
