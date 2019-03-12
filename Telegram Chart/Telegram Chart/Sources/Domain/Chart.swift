//
// Created by Vadim on 2019-03-10.
// Copyright (c) 2019 Vadim Belotitskiy. All rights reserved.
//

import UIKit

public class Chart {

    public let plots: [Plot]
    public let timestamps: [Int64]

    public init(timestamps: [Int64], plots: [Plot]) {
        self.timestamps = timestamps
        self.plots = plots
    }

    public class Plot {
        public let identifier: String
        public let name: String
        public let color: UIColor
        public let values: [Int64]

        public init(identifier: String,
                         name: String,
                         color: UIColor,
                         values: [Int64]) {
            
            self.identifier = identifier
            self.name = name
            self.color = color
            self.values = values
        }
    }
}
