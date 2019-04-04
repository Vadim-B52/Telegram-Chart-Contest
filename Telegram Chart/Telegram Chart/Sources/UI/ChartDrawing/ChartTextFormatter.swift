//
// Created by Vadim on 2019-03-23.
// Copyright (c) 2019 Vadim Belotitskiy. All rights reserved.
//

import UIKit

public final class ChartTextFormatter {

    public static let shared = ChartTextFormatter()
    public let sizingString = "MMM\u{00a0}dd"

    private let valueFont = Fonts.current.semibold11()
    private let dateFont = Fonts.current.semibold11()
    private let yearFont = Fonts.current.regular11()

    private init() {
    }

    private lazy var popupFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter
    }()

    private lazy var axisFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM\u{00a0}dd"
        return formatter
    }()

    func axisDateText(timestamp: Int64) -> String {
        let date = Date(timeIntervalSince1970: Double(timestamp) / 1000.0)
        let str = axisFormatter.string(from: date)
        return str
    }

    func popupDateText(timestamp: Int64) -> NSAttributedString {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp / 1000))
        let style = paragraphStyle(alignment: .left)
        let str = NSMutableAttributedString()

        str.append(NSAttributedString(
                string: axisDateText(timestamp: timestamp),
                attributes: [
                    NSAttributedString.Key.font: dateFont,
                    NSAttributedString.Key.paragraphStyle: style,
                ]))

        str.append(NSAttributedString(string: "\n"))

        str.append(NSAttributedString(
                string:  popupFormatter.string(from: date),
                attributes: [
                    NSAttributedString.Key.font: yearFont,
                    NSAttributedString.Key.paragraphStyle: style,
                ]))

        return str
    }

    func popupValueText(index idx: Int, plots: [Chart.Plot]) -> NSAttributedString {
        let str = NSMutableAttributedString()
        for plot in plots {
            let attrs = [
                NSAttributedString.Key.foregroundColor: plot.color,
                NSAttributedString.Key.font: valueFont,
            ]
            let value = NSAttributedString(string: "\(plot.values[idx])\n", attributes: attrs)
            str.append(value)
        }
        let fullRange = NSRange(location: 0, length: str.length)
        let style = paragraphStyle(alignment: .right)
        str.addAttribute(NSAttributedString.Key.paragraphStyle, value: style, range: fullRange)
        str.replaceCharacters(in: NSRange(location: str.length - 1, length: 1), with: "")
        return str
    }

    private func paragraphStyle(alignment: NSTextAlignment) -> NSMutableParagraphStyle {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = 2
        paragraph.alignment = alignment
        return paragraph
    }
}
