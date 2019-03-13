//
//  ViewController.swift
//  Telegram Chart
//
//  Created by Vadim on 10/03/2019.
//  Copyright © 2019 Vadim Belotitskiy. All rights reserved.
//

import UIKit

// TODO: separarators
// TODO: taps
// TODO: skin
class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    
    private let model = ChartListScreen()
    private let skin: Skin = DaySkin()
    private let chartCellReuseId = "chartCell"
    private let plotCellReuseId = "plotCell"
    private let nightModeCellId = "nightModeCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(ChartTableViewCell.self, forCellReuseIdentifier: chartCellReuseId)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: plotCellReuseId)
        tableView.register(NightModeTableViewCell.self, forCellReuseIdentifier: nightModeCellId)

        tableView.tableFooterView = UIView()
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 36, right: 0)
        tableView.backgroundColor = skin.sectionHeaderColor
        tableView.separatorColor = skin.separatorColor
        
        updateSkin()
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return model.charts.count + 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == model.charts.count {
            return 1
        }
        return model.charts[section].plots.count + 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == model.charts.count {
            return 44
        }
        if indexPath.row == 0 {
            return UIScreen.main.bounds.size.height / 2
        }
        return 44
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == model.charts.count {
            let cell: NightModeTableViewCell = tableView.dequeueReusableCell(withIdentifier: nightModeCellId) as! NightModeTableViewCell

            cell.separatorInset = UIEdgeInsets.zero
            cell.selectionStyle = .none
            let title = model.isNightModeEnabled ?
                NSLocalizedString("Switch to Day Mode", comment: "") :
                NSLocalizedString("Switch To Night Mode", comment: "")
            cell.button.setTitle(title, for: .normal)
            cell.button.addTarget(self, action: #selector(handleNightModeButtonTap), for: .touchUpInside)
            return cell
        }
        let (chart, state) = model.dataAt(indexPath.section)
        if indexPath.row == 0 {
            let cell: ChartTableViewCell = tableView.dequeueReusableCell(withIdentifier: chartCellReuseId) as! ChartTableViewCell
            cell.selectionStyle = .none
            cell.separatorInset = UIEdgeInsets(top: 0, left: 9999, bottom: 0, right: -9999)
            cell.chartView.backgroundColor = UIColor.green.withAlphaComponent(0.1)
            cell.miniChartView.backgroundColor = UIColor.blue.withAlphaComponent(0.1)

            // TODO: reorganize
            cell.miniChartView.chart = DrawingChart(timestamps: chart.timestamps, timeRange: chart.timeRange, plots: chart.plots)

            return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: plotCellReuseId)!
        let plotIdx = indexPath.row - 1
        let plot = chart.plots[plotIdx]
        cell.textLabel?.text = plot.name
        cell.imageView?.image = UIImage.plotIndicatorWithColor(plot.color)
        cell.accessoryType = state.enabledPlotId.contains(plot.identifier) ? .checkmark : .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // TOOD: implement
        tableView.deselectRow(at: indexPath, animated: false)
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = ChartSectionHeaderView()
        header.backgroundColor = skin.sectionHeaderColor
        header.separatorColor = skin.separatorColor
        if section == model.charts.count {
            header.label.text = nil
        } else {
            // TODO: header
            header.label.text = "Section \(section)"
        }
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == model.charts.count {
            return 36
        }
        return 54
    }

    @objc
    private func handleNightModeButtonTap() {
        model.switchMode()
        updateSkin()
    }
    
    private func updateSkin() {
        // TODO: implement
        tableView.reloadData()
    }
}

