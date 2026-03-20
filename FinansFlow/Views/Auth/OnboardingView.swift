import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var currentPage = 0

    private let pages: [(icon: String, title: LocalizedStringKey, description: LocalizedStringKey)] = [
        ("chart.bar.fill", "Gelir & Gider Takibi", "Tüm gelir ve giderlerini kategori bazlı takip et, aylık nakit akışını kontrol altında tut."),
        ("chart.pie.fill", "Yatırım Portföyü", "Hisse, fon, kripto ve diğer yatırımlarını tek yerden yönet, kar/zarar durumunu izle."),
        ("banknote.fill", "Net Varlık", "Varlıkların ve borçlarını gör, toplam net varlığını zaman içinde takip et."),
        ("person.2.fill", "Ortak Kullanım", "Eşin veya ailenle ortak workspace oluştur, birlikte finansal durumunuzu yönetin.")
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    VStack(spacing: 24) {
                        Spacer()
                        Image(systemName: pages[index].icon)
                            .font(.system(size: 80))
                            .foregroundStyle(Color.accentColor)
                        Text(pages[index].title)
                            .font(.title.bold())
                        Text(pages[index].description)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        Spacer()
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            Button {
                if currentPage < pages.count - 1 {
                    withAnimation { currentPage += 1 }
                } else {
                    hasSeenOnboarding = true
                }
            } label: {
                Group {
                    if currentPage < pages.count - 1 {
                        Text("Devam")
                    } else {
                        Text("Başla")
                    }
                }
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 24)
            .padding(.bottom, 16)

            if currentPage < pages.count - 1 {
                Button("Atla") {
                    hasSeenOnboarding = true
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.bottom, 16)
            }
        }
    }
}

#Preview {
    OnboardingView()
}
