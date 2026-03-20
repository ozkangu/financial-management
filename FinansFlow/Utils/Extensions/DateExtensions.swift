import Foundation

extension Date {
    var startOfMonth: Date {
        Calendar.current.dateInterval(of: .month, for: self)?.start ?? self
    }

    var endOfMonth: Date {
        guard let interval = Calendar.current.dateInterval(of: .month, for: self) else { return self }
        return interval.end.addingTimeInterval(-1)
    }

    func monthsAgo(_ months: Int) -> Date {
        Calendar.current.date(byAdding: .month, value: -months, to: self) ?? self
    }

    var displayString: String {
        AppConstants.DateFormats.display.string(from: self)
    }

    var monthYearString: String {
        AppConstants.DateFormats.monthYear.string(from: self)
    }
}
