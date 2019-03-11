//
// Created by Vadim on 2019-03-10.
// Copyright (c) 2019 Vadim Belotitskiy. All rights reserved.
//

import UIKit

public class Chart {

    public let plots: [Plot]

    public init(plots: [Plot]) {
        self.plots = plots
    }

    public class Plot {
        public let name: String
        public let color: UIColor
        public let timestamps: [Int64]
        public let values: [Int64]

        fileprivate init(name: String, color: UIColor, timestamps: [Int64], values: [Int64]) {
            self.name = name
            self.color = color
            self.timestamps = timestamps
            self.values = values
        }
    }
    
    public class LinePlot: Plot {
        public override init(name: String, color: UIColor, timestamps: [Int64], values: [Int64]) {
            super.init(name: name, color: color, timestamps: timestamps, values: values)
        }
    }
}
