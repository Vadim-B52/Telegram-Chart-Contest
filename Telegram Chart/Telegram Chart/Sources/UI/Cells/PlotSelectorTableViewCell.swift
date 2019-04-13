//
// Created by Vadim on 2019-04-13.
// Copyright (c) 2019 Vadim Belotitskiy. All rights reserved.
//

import UIKit

public protocol PlotSelectorTableViewCellColorSource: AnyObject {
    func backgroundColor(cell: PlotSelectorTableViewCell) -> UIColor
}

public protocol PlotSelectorTableViewCellDelegate: AnyObject {
    func plotSelectorTableViewCell(_ cell: UITableViewCell, didChangeState: ChartState)
}

public class PlotSelectorTableViewCell: UITableViewCell {

    private let layout = CloudFlowLayout()
    private let collectionView: UICollectionView
    private lazy var sizingView: PlotView = PlotView()
    private let plotCellId = "plotCellId"

    public weak var delegate: PlotSelectorTableViewCellDelegate?

    private var heightConstraint: NSLayoutConstraint!
    public var data: (chart: Chart, state: ChartState)? {
        didSet {
            collectionView.reloadData()
            setNeedsUpdateConstraints()
        }
    }
    public weak var colorSource: PlotSelectorTableViewCellColorSource? {
        didSet {
            reloadColors()
        }
    }

    private var chart: Chart! {
        return data?.chart
    }

    private var state: ChartState! {
        return data?.state
    }

    public override init(style: CellStyle, reuseIdentifier: String?) {
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(PlotCollectionViewCell.self, forCellWithReuseIdentifier: plotCellId)
        collectionView.contentInset = UIEdgeInsets(top: 10, left: 15, bottom: 10, right: 15)
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(collectionView)
        NSLayoutConstraint.activate(LayoutConstraints.constraints(view: collectionView, pinnedToView: contentView))

        heightConstraint = NSLayoutConstraint(
                item: collectionView, attribute: .height,
                relatedBy: .equal,
                toItem: nil, attribute: .notAnAttribute,
                multiplier: 1, constant: 40)
        heightConstraint.isActive = true
    }

//    public override func updateConstraints() {
//        heightConstraint.constant = collectionView.contentSize.height
//        super.updateConstraints()
//    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func reloadColors() {
        collectionView.reloadData()
        let color = colorSource?.backgroundColor(cell: self)
        collectionView.backgroundColor = color
        backgroundColor = color
    }
}

extension PlotSelectorTableViewCell: UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data?.chart.plots.count ?? 0
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: plotCellId, for: indexPath) as! PlotCollectionViewCell
        let plot = chart.plots[indexPath.row]
        cell.longPressAction = { [unowned self] sender in
            self.handleLongPress(sender: sender)
        }
        configure(
                view: cell.plotView,
                plot: plot,
                checked: state.enabledPlotId.contains(plot.identifier),
                backgroundColor: colorSource?.backgroundColor(cell: self))
        return cell
    }
}

extension PlotSelectorTableViewCell: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let newState = state.byTurningPlot(identifier: chart.plots[indexPath.row].identifier)
        data = (chart, newState)
        delegate?.plotSelectorTableViewCell(self, didChangeState: newState)
        collectionView.reloadData()
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let chart = data!.chart
        let state = data!.state
        let plot = chart.plots[indexPath.row]
        configure(
                view: sizingView,
                plot: plot,
                checked: state.enabledPlotId.contains(plot.identifier),
                backgroundColor: colorSource?.backgroundColor(cell: self))
        return sizingView.sizeThatFits(.zero)
    }
}

extension PlotSelectorTableViewCell {

    fileprivate func handleLongPress(sender: PlotCollectionViewCell) {
        guard let indexPath = collectionView.indexPath(for: sender) else {
            return
        }
        let newState = state.bySingleEnabling(identifier: chart.plots[indexPath.row].identifier)
        data = (chart, newState)
        delegate?.plotSelectorTableViewCell(self, didChangeState: newState)
        collectionView.reloadData()
    }

    fileprivate func configure(view: PlotView, plot: Chart.Plot, checked: Bool, backgroundColor: UIColor?) {
        view.layer.cornerRadius = 6
        view.layer.borderWidth = 1
        view.layer.borderColor = plot.color.cgColor
        view.setText(plot.name, isChecked: checked)
        if checked {
            view.setTextColor(backgroundColor)
            view.backgroundColor = plot.color
        } else {
            view.setTextColor(plot.color)
            view.backgroundColor = backgroundColor
        }
    }

    class PlotCollectionViewCell: UICollectionViewCell {

        let plotView = PlotView()
        var longPressAction: ((PlotCollectionViewCell) -> Void)?

        override init(frame: CGRect) {
            super.init(frame: frame)
            plotView.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(plotView)
            NSLayoutConstraint.activate(LayoutConstraints.constraints(view: plotView, pinnedToView: contentView))

            let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(sender:)))
            plotView.addGestureRecognizer(longPress)
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override var isHighlighted: Bool {
            get {
                return super.isHighlighted
            }
            set {
                super.isHighlighted = newValue
                plotView.alpha = isHighlighted ? 0.5 : 1
            }
        }

        @objc
        private func handleLongPress(sender: UIGestureRecognizer) {
            if sender.state == .began {
                longPressAction?(self)
            }
        }
    }

    class PlotView: UIView {
        private let gap1 = UIView()
        private let gap2 = UIView()
        private let checkmark = UILabel()
        private let label = UILabel()

        override init(frame: CGRect) {
            super.init(frame: frame)
            let views = [
                "gap1": gap1,
                "gap2": gap2,
                "checkmark": checkmark,
                "label": label,
            ]
            views.values.forEach { v in
                v.translatesAutoresizingMaskIntoConstraints = false
                addSubview(v)
            }
            NSLayoutConstraint.activate(NSLayoutConstraint.constraints(
                    withVisualFormat: "H:|[gap1][checkmark][label][gap2(==gap1)]|",
                    metrics: nil,
                    views: views))
            NSLayoutConstraint.activate(
                    views.values.flatMap { (v: UIView) -> [NSLayoutConstraint] in
                        return [
                            NSLayoutConstraint(
                                    item: v, attribute: .centerY,
                                    relatedBy: .equal,
                                    toItem: v.superview, attribute: .centerY,
                                    multiplier: 1, constant: 0),
                            NSLayoutConstraint(
                                    item: v, attribute: .height,
                                    relatedBy: .equal,
                                    toItem: v.superview, attribute: .height,
                                    multiplier: 1, constant: 0),
                        ]
                    }
            )

            checkmark.font = Fonts.current.bold13()
            label.font = Fonts.current.regular12()
            label.textAlignment = .center
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func sizeThatFits(_ size: CGSize) -> CGSize {
            var sz = label.sizeThatFits(size)
            sz.height = 30
            sz.width += 40
            return sz
        }

        func setTextColor(_ color: UIColor?) {
            checkmark.textColor = color
            label.textColor = color
        }

        func setText(_ text: String?, isChecked: Bool) {
            label.text = text
            checkmark.text = isChecked ? "\u{2713} " : nil
        }
    }
}

class CloudFlowLayout: UICollectionViewFlowLayout {
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let attributes = super.layoutAttributesForElements(in: rect) else {
            return nil
        }
        guard attributes.count > 1 else {
            return attributes
        }
        for i in 1..<attributes.count {
            let prev = attributes[i - 1]
            let curr = attributes[i]
            guard prev.frame.minY < curr.frame.midY,
                  curr.frame.midY < prev.frame.maxY,
                  prev.indexPath.row + 1 == curr.indexPath.row else {

                continue
            }
            var frame = curr.frame
            frame.origin.x = prev.frame.maxX + minimumInteritemSpacing
            curr.frame = frame
        }
        return attributes
    }
}
