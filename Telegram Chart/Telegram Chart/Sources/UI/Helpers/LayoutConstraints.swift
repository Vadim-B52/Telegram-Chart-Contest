//
// Created by Vadim on 2019-04-13.
// Copyright (c) 2019 Vadim Belotitskiy. All rights reserved.
//

import UIKit

class LayoutConstraints {

    static func constraints(view view1: UIView, pinnedToView view2: UIView) -> [NSLayoutConstraint] {
        return [
            NSLayoutConstraint(
                    item: view1, attribute: .top,
                    relatedBy: .equal,
                    toItem: view2, attribute: .top,
                    multiplier: 1, constant: 0),
            NSLayoutConstraint(
                    item: view1, attribute: .leading,
                    relatedBy: .equal,
                    toItem: view2, attribute: .leading,
                    multiplier: 1, constant: 0),
            NSLayoutConstraint(
                    item: view1, attribute: .bottom,
                    relatedBy: .equal,
                    toItem: view2, attribute: .bottom,
                    multiplier: 1, constant: 0),
            NSLayoutConstraint(
                    item: view1, attribute: .trailing,
                    relatedBy: .equal,
                    toItem: view2, attribute: .trailing,
                    multiplier: 1, constant: 0),
        ]
    }

}
