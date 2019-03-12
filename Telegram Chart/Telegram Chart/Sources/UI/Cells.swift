//
//  Cells.swift
//  Telegram Chart
//
//  Created by Vadim on 11/03/2019.
//  Copyright © 2019 Vadim Belotitskiy. All rights reserved.
//

import UIKit

public class ChartTableViewCell: UITableViewCell {
    
}

public class NightModeTableViewCell: UITableViewCell {
    public private(set) lazy var button: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(button)
        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            button.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            button.topAnchor.constraint(equalTo: contentView.topAnchor),
            button.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
        return button
    }()
}

public class ChartSectionHeaderView: UIView {

    public private(set) lazy var label: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 15),
            label.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -15),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
        ])
        return label
    }()

    public var separatorColor: UIColor? {
        didSet {
            setNeedsDisplay()
        }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        contentMode = .redraw
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func draw(_ rect: CGRect) {
        super.draw(rect)

        let thinLine = 1 / UIScreen.main.scale
        separatorColor?.setFill()
        let (slice, _) = bounds.divided(atDistance: thinLine, from: .maxYEdge)
        let ctx = UIGraphicsGetCurrentContext()
        ctx?.fill(slice)
    }
}
