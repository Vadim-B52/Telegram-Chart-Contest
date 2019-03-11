//
//  ChartListScreen.swift
//  Telegram Chart
//
//  Created by Vadim on 11/03/2019.
//  Copyright © 2019 Vadim Belotitskiy. All rights reserved.
//

import Foundation

public class ChartListScreen {
    
    private let charts: [Chart]
    private let errorText: String?
    
    public private(set) var isNightModeEnabled = false

    public init() {
        let client = ChartClient()
        let charts: [Chart]
        let errorText: String?
        do {
            charts = try client.loadChartData()
            errorText = nil
        } catch {
            charts = []
            errorText = NSLocalizedString("Something went wrong", comment: "")
        }
        self.charts = charts
        self.errorText = errorText
    }
    
    public func switchMode() {
        isNightModeEnabled = !isNightModeEnabled
    }
    
}
