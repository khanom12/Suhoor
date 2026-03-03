import SwiftUI

struct TodayFastCheckInCard: View {
    @EnvironmentObject private var scheduleManager: ScheduleManager
    @EnvironmentObject private var fastLogStore: FastLogStore

    @State private var showingHistory = false

    var body: some View {
        let timeZone = TimeZone.current
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let now = Date()
        let todayStart = calendar.startOfDay(for: now)
        let dateKey = DateHelpers.dayIdentifier(for: todayStart, timeZone: timeZone)

        let status = fastLogStore.status(for: dateKey)
        let intent = resolvedIntentSnapshot(for: dateKey) ?? .empty

        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Fast Check-in")
                            .font(.headline.weight(.semibold))
                        Text(GregorianDateFormatter.shared.headerString(for: todayStart))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    NavigationLink {
                        FastHistoryView()
                    } label: {
                        Text("History")
                            .font(.footnote.weight(.semibold))
                    }
                    .tint(DawnColor.accent)
                }

                intentSummary(intent)

                Divider()

                statusRow(status: status, dateKey: dateKey, intent: intent)
            }
        }
    }

    @ViewBuilder
    private func intentSummary(_ snapshot: FastIntentSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                let style = snapshot.primaryIntent.style
                if let systemImage = style.systemImage {
                    Image(systemName: systemImage)
                        .foregroundStyle(style.color)
                }
                Text(style.title)
                    .font(.subheadline.weight(.semibold))
            }

            if snapshot.secondaryTags.isEmpty == false {
                FlexibleTagRow(tags: snapshot.secondaryTags.sorted(by: { $0.title < $1.title }).map(\.title))
            } else {
                Text("No secondary tags.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func statusRow(status: FastLogStatus, dateKey: String, intent: FastIntentSnapshot) -> some View {
        switch status {
        case .unknown:
            HStack(spacing: 12) {
                Button {
                    fastLogStore.setStatus(.completed, for: dateKey, intentSnapshot: intent)
                } label: {
                    Label("Completed", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)

                Button {
                    fastLogStore.setStatus(.missed, for: dateKey, intentSnapshot: intent)
                } label: {
                    Label("Missed", systemImage: "xmark.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }

        case .completed, .missed:
            HStack {
                Label(status.title, systemImage: status == .completed ? "checkmark.seal.fill" : "xmark.seal.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(status == .completed ? .green : .red)

                Spacer()

                Menu("Edit") {
                    Button("Mark Completed") {
                        fastLogStore.setStatus(.completed, for: dateKey, intentSnapshot: intent)
                    }
                    Button("Mark Missed") {
                        fastLogStore.setStatus(.missed, for: dateKey, intentSnapshot: intent)
                    }
                    Button("Clear Log") {
                        fastLogStore.setStatus(.unknown, for: dateKey)
                    }
                }
                .font(.footnote.weight(.semibold))
            }
        }
    }

    private func resolvedIntentSnapshot(for dateKey: String) -> FastIntentSnapshot? {
        let day = scheduleManager.activeWindowSnapshot.byDateKey[dateKey]
        guard let day else { return nil }
        return FastIntentSnapshot(
            primaryIntent: day.tagResult.computedPrimaryIntent,
            secondaryTags: day.tagResult.computedSecondaryTags
        )
    }
}

private struct FlexibleTagRow: View {
    let tags: [String]

    var body: some View {
        // Simple wrap: keep MVP small; improve later if needed.
        VStack(alignment: .leading, spacing: 6) {
            ForEach(chunked(tags, chunkSize: 3), id: \.self) { chunk in
                HStack(spacing: 8) {
                    ForEach(chunk, id: \.self) { tag in
                        RuleBadgeView(text: tag)
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }

    private func chunked(_ input: [String], chunkSize: Int) -> [[String]] {
        guard chunkSize > 0 else { return [input] }
        var result: [[String]] = []
        var current: [String] = []
        for item in input {
            current.append(item)
            if current.count >= chunkSize {
                result.append(current)
                current = []
            }
        }
        if !current.isEmpty {
            result.append(current)
        }
        return result
    }
}

