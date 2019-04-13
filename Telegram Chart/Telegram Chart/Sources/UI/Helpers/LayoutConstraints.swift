//
// Created by Vadim on 2019-04-13.
// Copyright (c) 2019 Vadim Belotitskiy. All rights reserved.
//

import UIKit

class LayoutConstraints {

    static func constraints(view view1: UIView, pinnedToView view2: UIView) -> [NSLayoutConstraint] {
        return [
            NSLayoutConstraint(
                    item: view1, attribute: .centerX,
                    relatedBy: .equal,
                    toItem: view2, attribute: .centerX,
                    multiplier: 1, constant: 0),
            NSLayoutConstraint(
                    item: view1, attribute: .centerY,
                    relatedBy: .equal,
                    toItem: view2, attribute: .centerY,
                    multiplier: 1, constant: 0),
            NSLayoutConstraint(
                    item: view1, attribute: .height,
                    relatedBy: .equal,
                    toItem: view2, attribute: .height,
                    multiplier: 1, constant: 0),
            NSLayoutConstraint(
                    item: view1, attribute: .width,
                    relatedBy: .equal,
                    toItem: view2, attribute: .width,
                    multiplier: 1, constant: 0),
        ]
    }

}
