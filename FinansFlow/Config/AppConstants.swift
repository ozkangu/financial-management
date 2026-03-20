import Foundation

enum AppConstants {
    static let defaultCurrency = "TRY"
    static let appName = "FinansFlow"
    static let pageSize = 20

    enum CurrencyOptions {
        static let all = ["TRY", "USD", "EUR", "GBP"]
    }

    enum DateFormats {
        static let display: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.locale = Locale.current
            return formatter
        }()

        static let monthYear: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            formatter.locale = Locale.current
            return formatter
        }()
    }
}
