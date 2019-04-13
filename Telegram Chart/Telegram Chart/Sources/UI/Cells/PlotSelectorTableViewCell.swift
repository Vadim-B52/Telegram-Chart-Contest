//
// Created by Vadim on 2019-04-13.
// Copyright (c) 2019 Vadim Belotitskiy. All rights reserved.
//

import UIKit

public protocol PlotSelectorViewColorSource: AnyObject {
    func backgroundColor(view: PlotSelectorView) -> UIColor
}

public protocol PlotSelectorViewDelegate: AnyObject {
    func plotSelectorView(_ view: PlotSelectorView, didChangeEnabledPlotIds: Set<Chart.Plot.Identifier>)
}

public class PlotSelectorTableViewCell: UITableViewCell {
    public private(set) lazy var view: PlotSelectorView = {
        let view = PlotSelectorView()
        view.owningCell = self
        view.frame = contentView.bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        contentView.addSubview(view)
        return view
    }()
}

public class PlotSelectorView: UIView {
    private let layout = CloudFlowLayout()
    private let collectionView: UICollectionView
    private lazy var sizingView: PlotView = PlotView()
    private let plotCellId = "plotCellId"

    public fileprivate(set) unowned var owningCell: UITableViewCell?
    public weak var delegate: PlotSelectorViewDelegate?

    public var data: (chart: Chart, enabledPlotIds: Set<Chart.Plot.Identifier>)? {
        didSet {
            collectionView.reloadData()
        }
    }
    public weak var colorSource: PlotSelectorViewColorSource? {
        didSet {
            reloadColors()
        }
    }

    private var chart: Chart! {
        return data?.chart
    }

    private var enabledPlotIds: Set<Chart.Plot.Identifier>! {
        return data?.enabledPlotIds
    }

    public override var intrinsicContentSize: CGSize {
        collectionView.layoutIfNeeded()
        var sz = collectionView.contentSize
        sz.height += 20
        return sz
    }

    public override init(frame: CGRect) {
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(frame: frame)
        collectionView.bounces = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(PlotCollectionViewCell.self, forCellWithReuseIdentifier: plotCellId)
        collectionView.contentInset = UIEdgeInsets(top: 10, left: 15, bottom: 10, right: 15)
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(collectionView)
        NSLayoutConstraint.activate(LayoutConstraints.constraints(view: collectionView, pinnedToView: self))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func reloadColors() {
        collectionView.reloadData()
        let color = colorSource?.backgroundColor(view: self)
        collectionView.backgroundColor = color
        backgroundColor = color
    }
}

extension PlotSelectorView: UICollectionViewDataSource {
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
                checked: enabledPlotIds.contains(plot.identifier),
                backgroundColor: colorSource?.backgroundColor(view: self))
        return cell
    }
}

extension PlotSelectorView: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let identifier = chart.plots[indexPath.row].identifier
        let newIds: Set<Chart.Plot.Identifier>
        if enabledPlotIds.contains(identifier) {
            newIds = enabledPlotIds.subtracting([identifier])
        } else {
            newIds = enabledPlotIds.union([identifier])
        }
        data = (chart, newIds)
        delegate?.plotSelectorView(self, didChangeEnabledPlotIds: newIds)
        collectionView.reloadData()
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let chart = data!.chart
        let state = data!.enabledPlotIds
        let plot = chart.plots[indexPath.row]
        configure(
                view: sizingView,
                plot: plot,
                checked: state.contains(plot.identifier),
                backgroundColor: colorSource?.backgroundColor(view: self))
        return sizingView.sizeThatFits(.zero)
    }
}

extension PlotSelectorView {

    fileprivate func handleLongPress(sender: PlotCollectionViewCell) {
        guard let indexPath = collectionView.indexPath(for: sender) else {
            return
        }
        let newState: Set<Chart.Plot.Identifier> = [chart.plots[indexPath.row].identifier]
        data = (chart, newState)
        delegate?.plotSelectorView(self, didChangeEnabledPlotIds: newState)
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
        var newAttributes = NSArray(array: attributes, copyItems: true) as! [UICollectionViewLayoutAttributes]
        for i in 1..<newAttributes.count {
            let prev = newAttributes[i - 1]
            let curr = newAttributes[i]
            guard prev.frame.minY < curr.frame.midY,
                  curr.frame.midY < prev.frame.maxY,
                  prev.indexPath.row + 1 == curr.indexPath.row else {

                continue
            }
            var frame = curr.frame
            frame.origin.x = prev.frame.maxX + minimumInteritemSpacing
            curr.frame = frame
        }
        return newAttributes
    }
}
