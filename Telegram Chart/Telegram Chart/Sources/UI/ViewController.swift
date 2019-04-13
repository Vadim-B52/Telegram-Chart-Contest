//
//  ViewController.swift
//  Telegram Chart
//
//  Created by Vadim on 10/03/2019.
//  Copyright © 2019 Vadim Belotitskiy. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet
    private weak var tableView: UITableView!
    private lazy var sizingPlotSelector: PlotSelectorView = PlotSelectorView()
    
    private let model = ChartListScreen()
    private let chartCellReuseId = "chartCell"
    private let plotSelectorCellReuseId = "plotSelectorCellReuseId"
    private let nightModeCellId = "nightModeCell"
    private var skin: Skin = DaySkin()

    private lazy var screenMaxEdge = max(UIScreen.main.bounds.size.height, UIScreen.main.bounds.width)
    private lazy var chartCellHeight = UIScreen.main.bounds.size.height / 2

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = NSLocalizedString("Statistics", comment: "")
        tableView.register(ChartTableViewCell.self, forCellReuseIdentifier: chartCellReuseId)
        tableView.register(PlotSelectorTableViewCell.self, forCellReuseIdentifier: plotSelectorCellReuseId)
        tableView.register(NightModeTableViewCell.self, forCellReuseIdentifier: nightModeCellId)
        updateSkin()
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return model.charts.count + 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isChartSection(section) {
            let chart = model.charts[section]
            return chart.plots.count > 1 ? 2 : 1
        }
        return 1
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if isChartRowAt(indexPath) {
            return chartCellHeight
        }
        if isSwitchSkinRowAt(indexPath) {
            return 44
        }
        sizingPlotSelector.bounds = tableView.bounds
        sizingPlotSelector.layoutIfNeeded()
        configure(plotSelector: sizingPlotSelector, atIndexPath: indexPath)
        return sizingPlotSelector.intrinsicContentSize.height
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if isChartRowAt(indexPath) {
            return chartCellHeight
        }
        if isSwitchSkinRowAt(indexPath) {
            return 44
        }
        return 60
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if isSwitchSkinRowAt(indexPath) {
            return switchSkinCell(tableView: tableView)
        }
        if isChartRowAt(indexPath) {
            return chartCellAt(indexPath, tableView: tableView)
        }
        return plotSelectorCellAt(indexPath, tableView: tableView)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        let section: Int = indexPath.section
        guard isChartSection(section) else {
            model.switchMode()
            updateSkin()
            return
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if isChartSection(section) {
            let format = NSLocalizedString("Chart #%@", comment: "")
            return String(format: format, arguments: ["\(section)"])
        }
        return nil
    }

    @objc
    private func handleNightModeButtonTap() {
        model.switchMode()
        updateSkin()
    }
    
    private func updateSkin() {
        let isNight = model.isNightModeEnabled
        skin = isNight ? NightSkin() : DaySkin()
        let navigationBar = navigationController?.navigationBar
        navigationBar?.isTranslucent = false
        navigationBar?.barStyle = skin.barStyle
        navigationBar?.barTintColor = skin.navigationBarColor
        navigationBar?.setBackgroundImage(UIImage.navigationBarImage(skin.navigationBarColor), for: .default)
        tableView.backgroundColor = skin.sectionHeaderColor
        tableView.separatorColor = skin.separatorColor
        tableView.reloadData()
    }
}

fileprivate extension ViewController {
    func isChartSection(_ section: Int) -> Bool {
        return section < model.charts.count
    }
    
    func isChartRowAt(_ indexPath: IndexPath) -> Bool {
        return isChartSection(indexPath.section) && indexPath.row == 0
    }

    func isPlotRowAt(_ indexPath: IndexPath) -> Bool {
        return isChartSection(indexPath.section) && indexPath.row > 0
    }
    
    func isSwitchSkinRowAt(_ indexPath: IndexPath) -> Bool {
        return !isChartSection(indexPath.section)   
    }
}

fileprivate extension ViewController {

    func switchSkinCell(tableView: UITableView) -> NightModeTableViewCell {
        let cell: NightModeTableViewCell = tableView.dequeueReusableCell(withIdentifier: nightModeCellId) as! NightModeTableViewCell
        cell.separatorInset = UIEdgeInsets.zero
        cell.selectionStyle = .none
        let title = model.isNightModeEnabled ?
                NSLocalizedString("Switch to Day Mode", comment: "") :
                NSLocalizedString("Switch To Night Mode", comment: "")

        cell.button.setTitle(title, for: .normal)
        cell.button.addTarget(self, action: #selector(handleNightModeButtonTap), for: .touchUpInside)
        cell.backgroundColor = skin.cellBackgroundColor
        cell.backgroundView?.backgroundColor = skin.cellBackgroundColor
        return cell
    }

    private func chartCellAt(_ indexPath: IndexPath, tableView: UITableView) -> ChartTableViewCell {
        let cell: ChartTableViewCell = tableView.dequeueReusableCell(withIdentifier: chartCellReuseId) as! ChartTableViewCell
        cell.selectionStyle = .none
        cell.separatorInset = UIEdgeInsets(top: 0, left: screenMaxEdge, bottom: 0, right: -screenMaxEdge)
        cell.backgroundColor = skin.cellBackgroundColor
        cell.backgroundView?.backgroundColor = skin.cellBackgroundColor
        cell.delegate = self
        cell.timeSelectorViewColorSource = self
        cell.chartViewColorSource = self
        cell.colorSource = self
        let (chart, state) = model.dataAt(indexPath.section)
        cell.display(chart: chart, state: state, animated: false)
        return cell
    }

    private func plotSelectorCellAt(_ indexPath: IndexPath, tableView: UITableView) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: plotSelectorCellReuseId) as! PlotSelectorTableViewCell
        cell.selectionStyle = .none
        cell.view.colorSource = self
        cell.view.delegate = self
        configure(plotSelector: cell.view, atIndexPath: indexPath)
        return cell
    }

    private func configure(plotSelector view: PlotSelectorView, atIndexPath indexPath: IndexPath) {
        view.data = model.dataAt(indexPath.section)
    }
}

extension ViewController: MiniChartTimeSelectorViewColorSource {
    func chevronColor(miniChartTimeSelectorView view: TimeFrameSelectorView) -> UIColor {
        return skin.timeSelectorChevronColor
    }

    func dimmingColor(miniChartTimeSelectorView view: TimeFrameSelectorView) -> UIColor {
        return skin.timeSelectorDimmingColor
    }

    func controlColor(miniChartTimeSelectorView view: TimeFrameSelectorView) -> UIColor {
        return skin.timeSelectorControlColor
    }
}

extension ViewController: ChartViewColorSource {
    public func valueAxisColor(chartView: CompoundChartView) -> UIColor {
        return skin.valueAxisColor
    }

    public func zeroValueAxisColor(chartView: CompoundChartView) -> UIColor {
        return skin.zeroValueAxisColor
    }

    public func chartAxisLabelColor(chartView: CompoundChartView) -> UIColor {
        return skin.chartAxisLabelColor
    }

    public func popupBackgroundColor(chartView: CompoundChartView) -> UIColor {
        return skin.popupBackgroundColor
    }

    public func popupLabelColor(chartView: CompoundChartView) -> UIColor {
        return skin.popupLabelColor
    }

    public func backgroundColor(chartView: CompoundChartView) -> UIColor {
        return skin.cellBackgroundColor
    }
}

extension ViewController: ChartTableViewCellDelegate {
    func chartTableViewCell(_ cell: ChartTableViewCell, didChangeSelectedTimeRange timeRange: TimeRange) {
        guard let indexPath = tableView.indexPath(for: cell) else {
            return
        }
        model.updateSelectedTimeRange(timeRange, at: indexPath.section)
    }
}

extension ViewController: PlotSelectorViewColorSource {
    func backgroundColor(view: PlotSelectorView) -> UIColor {
        return skin.cellBackgroundColor
    }
}

extension ViewController: PlotSelectorViewDelegate {
    public func plotSelectorView(_ view: PlotSelectorView, didChangeState state: ChartState) {
        guard let cell = view.owningCell,
              let chartIdx = tableView.indexPath(for: cell)?.section else {
            return
        }
        model.updateState(state, at: chartIdx)
        let chartIndexPath = IndexPath(row: 0, section: chartIdx)
        if let chartCell = tableView.cellForRow(at: chartIndexPath) as? ChartTableViewCell {
            let (chart, state) = model.dataAt(chartIdx)
            chartCell.display(chart: chart, state: state, animated: true)
        }
    }
}

extension ViewController: ChartTableViewColorSource {
    public func errorTextColor(chartTableViewCell cell: ChartTableViewCell) -> UIColor {
        return skin.mainTextColor
    }

    public func errorBackgroundColor(chartTableViewCell cell: ChartTableViewCell) -> UIColor {
        return skin.cellBackgroundColor
    }
}
