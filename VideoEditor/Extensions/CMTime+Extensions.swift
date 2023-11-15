//
//  CMTime+Extensions.swift
//  VideoEditor
//
//  Created by Mohtasim Abrar Samin on 15/11/23.
//

import CoreMedia

extension CMTime {
    var displayString: String {
        let offset = TimeInterval(seconds)
        let numberOfNanosecondsFloat = (offset - TimeInterval(Int(offset))) * 100.0
        let nanoseconds = Int(numberOfNanosecondsFloat)
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .dropAll
        formatter.allowedUnits = [.minute, .second]
        return String(format: "%@.%02d", formatter.string(from: offset) ?? "00:00", nanoseconds)
    }
}
