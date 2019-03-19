//
//  ViewController.swift
//  Telegram Chart
//
//  Created by Vadim on 10/03/2019.
//  Copyright © 2019 Vadim Belotitskiy. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    
    private let model = ChartListScreen()
    private let chartCellReuseId = "chartCell"
    private let plotCellReuseId = "plotCell"
    private let nightModeCellId = "nightModeCell"
    private var skin: Skin = DaySkin()

    private lazy var screenMaxEdge = max(UIScreen.main.bounds.size.height, UIScreen.main.bounds.size.width)
    private lazy var chartCellHeight = UIScreen.main.bounds.size.height / 2
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = NSLocalizedString("Statistics", comment: "")
        tableView.register(ChartTableViewCell.self, forCellReuseIdentifier: chartCellReuseId)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: plotCellReuseId)
        tableView.register(NightModeTableViewCell.self, forCellReuseIdentifier: nightModeCellId)
        updateSkin()
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return model.charts.count + 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isChartSection(section) {
            return model.charts[section].plots.count + 1
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if isChartRowAt(indexPath) {
            return chartCellHeight
        }
        return 44
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if isSwitchSkinRowAt(indexPath) {
            return switchSkinCell(tableView: tableView)
        }
        if isChartRowAt(indexPath) {
            return chartCellAt(indexPath, tableView: tableView)
        }
        return plotCellAt(indexPath, tableView: tableView)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        guard isChartSection(indexPath.section) else {
            model.switchMode()
            updateSkin()
            return
        }
        guard isPlotRowAt(indexPath) else {
            return
        }
        let plotIdx = indexPath.row - 1
        guard model.canChangeVisibilityForChartAt(indexPath.section, plotIndex: plotIdx) else {
            UIAlertView(title: "Cannot change", message: "Enable other plot before", delegate: nil, cancelButtonTitle: "Ok").show()
            return
        }
        model.changeVisibilityForChartAt(indexPath.section, plotIndex: plotIdx)
        let chartIndexPath = IndexPath(row: 0, section: indexPath.section)
        if let chartCell = tableView.cellForRow(at: chartIndexPath) as? ChartTableViewCell {
            let (chart, state) = model.dataAt(plotIdx)
            let plotId = chart.plots[plotIdx].identifier
            if state.enabledPlotId.contains(plotId) {
                chartCell.showPlot(plotId: plotId)
            } else {
                chartCell.hidePlot(plotId: plotId)
            }
        }
        if let plotCell = tableView.cellForRow(at: indexPath) {
            configure(plotCell: plotCell, atIndexPath: indexPath)
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
        cell.miniChartTimeSelectorViewColorSource = self
        cell.chartViewColorSource = self
        let (chart, state) = model.dataAt(indexPath.section)
        cell.display(chart: chart, state: state)
        return cell
    }

    private func plotCellAt(_ indexPath: IndexPath, tableView: UITableView) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: plotCellReuseId)!
        cell.textLabel?.textColor = skin.mainTextColor
        cell.imageView?.clipsToBounds = true
        cell.imageView?.backgroundColor = skin.cellBackgroundColor
        cell.imageView?.layer.cornerRadius = 2
        cell.backgroundColor = skin.cellBackgroundColor
        cell.backgroundView?.backgroundColor = skin.cellBackgroundColor
        cell.selectedBackgroundView? = UIView()
        cell.selectedBackgroundView?.backgroundColor = skin.rowSelectionColor
        configure(plotCell: cell, atIndexPath: indexPath)
        return cell
    }

    private func configure(plotCell cell: UITableViewCell, atIndexPath indexPath: IndexPath) {
        let (chart, state) = model.dataAt(indexPath.section)
        let plotIdx = indexPath.row - 1
        let plot = chart.plots[plotIdx]
        cell.textLabel?.text = plot.name
        cell.imageView?.image = UIImage.plotIndicatorWithColor(plot.color)
        cell.accessoryType = state.enabledPlotId.contains(plot.identifier) ? .checkmark : .none
    }
}

extension ViewController: MiniChartTimeSelectorViewColorSource {
    func chevronColor(miniChartTimeSelectorView view: MiniChartTimeSelectorView) -> UIColor {
        return skin.timeSelectorChevronColor
    }

    func dimmingColor(miniChartTimeSelectorView view: MiniChartTimeSelectorView) -> UIColor {
        return skin.timeSelectorDimmingColor
    }

    func controlColor(miniChartTimeSelectorView view: MiniChartTimeSelectorView) -> UIColor {
        return skin.timeSelectorControlColor
    }
}

extension ViewController: ChartViewColorSource {
    public func valueAxisColor(chartView: ChartView) -> UIColor {
        return skin.valueAxisColor
    }

    public func zeroValueAxisColor(chartView: ChartView) -> UIColor {
        return skin.zeroValueAxisColor
    }

    public func chartAxisLabelColor(chartView: ChartView) -> UIColor {
        return skin.chartAxisLabelColor
    }

    public func popupBackgroundColor(chartView: ChartView) -> UIColor {
        return skin.popupBackgroundColor
    }

    public func popupLabelColor(chartView: ChartView) -> UIColor {
        return skin.popupLabelColor
    }
}

extension ViewController: ChartTableViewCellDelegate {
    func chartTableViewCell(_ cell: ChartTableViewCell, didChangeSelectedTimeRange timeRange: TimeRange) {
        guard let indexPath = tableView.indexPath(for: cell) else {
            return
        }
        model.updateSelectedTimeRange(timeRange, at: indexPath.row)
    }
}
