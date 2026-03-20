import Foundation

extension Double {
    func formatted(as currency: String = AppConstants.defaultCurrency) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "tr_TR")

        switch currency {
        case "USD":
            formatter.currencyCode = "USD"
            formatter.locale = Locale(identifier: "en_US")
        case "EUR":
            formatter.currencyCode = "EUR"
            formatter.locale = Locale(identifier: "de_DE")
        case "GBP":
            formatter.currencyCode = "GBP"
            formatter.locale = Locale(identifier: "en_GB")
        default:
            formatter.currencyCode = "TRY"
        }

        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }

    var percentFormatted: String {
        String(format: "%+.1f%%", self)
    }
}
