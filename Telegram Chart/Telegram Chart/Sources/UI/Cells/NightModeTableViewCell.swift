//
// Created by Vadim on 2019-03-19.
// Copyright (c) 2019 Vadim Belotitskiy. All rights reserved.
//

import UIKit

public class NightModeTableViewCell: UITableViewCell {
    public private(set) lazy var button: UIButton = {
        let button = UIButton(type: .system)
        contentView.addSubview(button)
        button.frame = contentView.bounds
        button.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return button
    }()
}
