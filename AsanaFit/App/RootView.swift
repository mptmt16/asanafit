import SwiftUI

enum AppTab: Hashable {
    case today, practice, analyze, progress, you
}

struct RootView: View {
    @AppStorage(SettingsKey.hasOnboarded) private var hasOnboarded = false
    @State private var tab: AppTab = .today
    @State private var showingPaywall = false

    var body: some View {
        TabView(selection: $tab) {
            TodayView(selectedTab: $tab)
                .tabItem { Label("Today", systemImage: "sun.max") }
                .tag(AppTab.today)
            PracticeView()
                .tabItem { Label("Practice", systemImage: "figure.yoga") }
                .tag(AppTab.practice)
            AnalyzeView()
                .tabItem { Label("Analyse", systemImage: "figure.stand.line.dotted.figure.stand") }
                .tag(AppTab.analyze)
            TrendsView()
                .tabItem { Label("Progress", systemImage: "chart.line.uptrend.xyaxis") }
                .tag(AppTab.progress)
            ProfileView()
                .tabItem { Label("You", systemImage: "person") }
                .tag(AppTab.you)
        }
        .fullScreenCover(isPresented: Binding(get: { !hasOnboarded }, set: { hasOnboarded = !$0 })) {
            OnboardingView { hasOnboarded = true }
        }
        .sheet(isPresented: $showingPaywall) { PaywallView() }
        .task {
            // Development switch, for looking at the first-run paywall without reinstalling.
            guard DevFlags.showPaywallOnLaunch, hasOnboarded, !SubscriptionStore.shared.isPro else { return }
            showingPaywall = true
        }
    }
}
