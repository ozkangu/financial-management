import Foundation
import SwiftData

enum CategorySeeder {
    static func seedIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<Category>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        guard count == 0 else { return }

        let categories: [(String, CategoryType, String, String, [(String, String, String)])] = [
            ("Maaş", .income, "#2ECC71", "banknote.fill", []),
            ("Serbest Gelir", .income, "#27AE60", "briefcase.fill", []),
            ("Yatırım Geliri", .income, "#1ABC9C", "chart.line.uptrend.xyaxis", []),
            ("Diğer Gelir", .income, "#3498DB", "ellipsis.circle.fill", []),
            ("Market", .expense, "#FF6B6B", "cart.fill", []),
            ("Ulaşım", .expense, "#4ECDC4", "bus.fill", [
                ("Yakıt", "#95E1D3", "fuelpump.fill"),
                ("Toplu Taşıma", "#A8D8EA", "tram.fill")
            ]),
            ("Faturalar", .expense, "#FFD93D", "bolt.fill", [
                ("Elektrik", "#FFDAC1", "bolt.fill"),
                ("Su", "#A8D8EA", "drop.fill"),
                ("İnternet", "#C3AED6", "wifi"),
                ("Doğalgaz", "#FF8C94", "flame.fill")
            ]),
            ("Kira", .expense, "#957DAD", "house.fill", []),
            ("Sağlık", .expense, "#FF8C94", "heart.fill", []),
            ("Eğitim", .expense, "#A8D8EA", "book.fill", []),
            ("Eğlence", .expense, "#C3AED6", "gamecontroller.fill", []),
            ("Giyim", .expense, "#FFB6B9", "tshirt.fill", []),
            ("Yemek", .expense, "#E67E22", "fork.knife", []),
            ("Diğer Gider", .expense, "#7F8C8D", "ellipsis.circle.fill", [])
        ]

        for (name, type, color, icon, subs) in categories {
            let parent = Category(name: name, type: type, color: color, icon: icon, isDefault: true)
            context.insert(parent)

            for (subName, subColor, subIcon) in subs {
                let sub = Category(name: subName, type: type, parent: parent, color: subColor, icon: subIcon, isDefault: true)
                context.insert(sub)
            }
        }

        try? context.save()
    }
}
