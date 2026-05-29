import Combine
import Foundation

enum WakeSessionMode: String, Codable, CaseIterable, Identifiable, Sendable {
    case fajr
    case suhoor

    var id: String { rawValue }

    var confirmationTitle: String {
        switch self {
        case .fajr:
            return "Fajr"
        case .suhoor:
            return "Suhoor"
        }
    }
}

enum WakeSessionStatus: String, Codable, CaseIterable, Identifiable, Sendable {
    case scheduled
    case activeWindowOpen
    case primaryAlarmFired
    case unconfirmed
    case wakeChecksPending
    case confirmedAwake
    case expiredUnconfirmed
    case cancelledForMorning
    case quietMorning

    var id: String { rawValue }

    var isTerminal: Bool {
        switch self {
        case .confirmedAwake, .expiredUnconfirmed, .cancelledForMorning, .quietMorning:
            return true
        case .scheduled, .activeWindowOpen, .primaryAlarmFired, .unconfirmed, .wakeChecksPending:
            return false
        }
    }

    var isConfirmedAwake: Bool {
        self == .confirmedAwake
    }
}

struct WakeSessionDraft: Equatable, Sendable {
    let wakeSessionID: String
    let dateKey: String
    let morningDate: Date
    let mode: WakeSessionMode
    let finalThirdStart: Date?
    let fajrBegins: Date
    let fajrEnds: Date?
    let plannedWakeTime: Date
    let primaryAlarmID: String?
    let primaryScheduledEventID: String?
    let wakeCheckIDs: [String]
    let wakeCheckScheduledEventIDs: [String]
    var isTest: Bool = false
    var scenarioID: String? = nil
}

struct WakeSession: Codable, Equatable, Identifiable, Sendable {
    let wakeSessionID: String
    let dateKey: String
    let morningDate: Date
    var mode: WakeSessionMode
    var confirmedWakeMode: WakeSessionMode?
    var finalThirdStart: Date?
    var fajrBegins: Date
    var fajrEnds: Date?
    var plannedWakeTime: Date
    var primaryAlarmID: String?
    var primaryScheduledEventID: String?
    var wakeCheckIDs: [String]
    var wakeCheckScheduledEventIDs: [String]
    var status: WakeSessionStatus
    var confirmedAt: Date?
    var acknowledgementSource: WakeAcknowledgementSource?
    var expiredAt: Date?
    var cancelledAt: Date?
    var quietReason: String?
    var firedScheduledEventIDs: [String]
    var stoppedScheduledEventIDs: [String]
    var operationalLogIDs: [UUID]
    var createdAt: Date
    var updatedAt: Date
    var isTest: Bool
    var scenarioID: String?

    var id: String { wakeSessionID }

    var isQuiet: Bool {
        status == .quietMorning
    }

    var isConfirmedAwake: Bool {
        status.isConfirmedAwake
    }

    init(draft: WakeSessionDraft, now: Date) {
        self.wakeSessionID = draft.wakeSessionID
        self.dateKey = draft.dateKey
        self.morningDate = draft.morningDate
        self.mode = draft.mode
        self.confirmedWakeMode = nil
        self.finalThirdStart = draft.finalThirdStart
        self.fajrBegins = draft.fajrBegins
        self.fajrEnds = draft.fajrEnds
        self.plannedWakeTime = draft.plannedWakeTime
        self.primaryAlarmID = draft.primaryAlarmID
        self.primaryScheduledEventID = draft.primaryScheduledEventID
        self.wakeCheckIDs = draft.wakeCheckIDs
        self.wakeCheckScheduledEventIDs = draft.wakeCheckScheduledEventIDs
        self.status = .scheduled
        self.confirmedAt = nil
        self.acknowledgementSource = nil
        self.expiredAt = nil
        self.cancelledAt = nil
        self.quietReason = nil
        self.firedScheduledEventIDs = []
        self.stoppedScheduledEventIDs = []
        self.operationalLogIDs = []
        self.createdAt = now
        self.updatedAt = now
        self.isTest = draft.isTest
        self.scenarioID = draft.scenarioID
    }

    mutating func apply(draft: WakeSessionDraft, now: Date) {
        mode = draft.mode
        finalThirdStart = draft.finalThirdStart
        fajrBegins = draft.fajrBegins
        fajrEnds = draft.fajrEnds
        plannedWakeTime = draft.plannedWakeTime
        primaryAlarmID = draft.primaryAlarmID
        primaryScheduledEventID = draft.primaryScheduledEventID
        wakeCheckIDs = draft.wakeCheckIDs
        wakeCheckScheduledEventIDs = draft.wakeCheckScheduledEventIDs
        isTest = draft.isTest
        scenarioID = draft.scenarioID
        if !status.isTerminal {
            status = .scheduled
        } else if status == .quietMorning {
            status = .scheduled
            cancelledAt = nil
            quietReason = nil
        }
        updatedAt = now
    }

    private enum CodingKeys: String, CodingKey {
        case wakeSessionID
        case dateKey
        case morningDate
        case mode
        case confirmedWakeMode
        case finalThirdStart
        case fajrBegins
        case fajrEnds
        case plannedWakeTime
        case primaryAlarmID
        case primaryScheduledEventID
        case wakeCheckIDs
        case wakeCheckScheduledEventIDs
        case status
        case confirmedAt
        case acknowledgementSource
        case expiredAt
        case cancelledAt
        case quietReason
        case firedScheduledEventIDs
        case stoppedScheduledEventIDs
        case operationalLogIDs
        case createdAt
        case updatedAt
        case isTest
        case scenarioID
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        wakeSessionID = try container.decode(String.self, forKey: .wakeSessionID)
        dateKey = try container.decode(String.self, forKey: .dateKey)
        morningDate = try container.decode(Date.self, forKey: .morningDate)
        mode = try container.decode(WakeSessionMode.self, forKey: .mode)
        confirmedWakeMode = try container.decodeIfPresent(WakeSessionMode.self, forKey: .confirmedWakeMode)
        finalThirdStart = try container.decodeIfPresent(Date.self, forKey: .finalThirdStart)
        fajrBegins = try container.decode(Date.self, forKey: .fajrBegins)
        fajrEnds = try container.decodeIfPresent(Date.self, forKey: .fajrEnds)
        plannedWakeTime = try container.decode(Date.self, forKey: .plannedWakeTime)
        primaryAlarmID = try container.decodeIfPresent(String.self, forKey: .primaryAlarmID)
        primaryScheduledEventID = try container.decodeIfPresent(String.self, forKey: .primaryScheduledEventID)
        wakeCheckIDs = try container.decode([String].self, forKey: .wakeCheckIDs)
        wakeCheckScheduledEventIDs = try container.decode([String].self, forKey: .wakeCheckScheduledEventIDs)
        status = try container.decode(WakeSessionStatus.self, forKey: .status)
        confirmedAt = try container.decodeIfPresent(Date.self, forKey: .confirmedAt)
        acknowledgementSource = try container.decodeIfPresent(WakeAcknowledgementSource.self, forKey: .acknowledgementSource)
        expiredAt = try container.decodeIfPresent(Date.self, forKey: .expiredAt)
        cancelledAt = try container.decodeIfPresent(Date.self, forKey: .cancelledAt)
        quietReason = try container.decodeIfPresent(String.self, forKey: .quietReason)
        firedScheduledEventIDs = try container.decodeIfPresent([String].self, forKey: .firedScheduledEventIDs) ?? []
        stoppedScheduledEventIDs = try container.decodeIfPresent([String].self, forKey: .stoppedScheduledEventIDs) ?? []
        operationalLogIDs = try container.decodeIfPresent([UUID].self, forKey: .operationalLogIDs) ?? []
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        isTest = try container.decodeIfPresent(Bool.self, forKey: .isTest) ?? false
        scenarioID = try container.decodeIfPresent(String.self, forKey: .scenarioID)
    }
}

enum MorningLogRecordType: String, Codable, CaseIterable, Identifiable, Sendable {
    case wakeSessionCreated
    case primaryAlarmScheduled
    case wakeCheckScheduled
    case primaryAlarmFired
    case wakeCheckFired
    case alarmStopped
    case confirmedAwakeForFajr
    case confirmedAwakeForSuhoor
    case fajrPrayerConfirmed
    case fastingIntentConfirmed
    case wakeChecksCancelled
    case wakeSessionExpiredUnconfirmed
    case quietMorning

    var id: String { rawValue }
}

struct MorningLogRecord: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    let dateKey: String
    let wakeSessionID: String?
    let type: MorningLogRecordType
    let timestamp: Date
    let scheduledEventID: String?
    let metadata: [String: String]
    let isTest: Bool
    let scenarioID: String?

    init(
        id: UUID = UUID(),
        dateKey: String,
        wakeSessionID: String?,
        type: MorningLogRecordType,
        timestamp: Date,
        scheduledEventID: String? = nil,
        metadata: [String: String] = [:],
        isTest: Bool = false,
        scenarioID: String? = nil
    ) {
        self.id = id
        self.dateKey = dateKey
        self.wakeSessionID = wakeSessionID
        self.type = type
        self.timestamp = timestamp
        self.scheduledEventID = scheduledEventID
        self.metadata = metadata
        self.isTest = isTest
        self.scenarioID = scenarioID
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case dateKey
        case wakeSessionID
        case type
        case timestamp
        case scheduledEventID
        case metadata
        case isTest
        case scenarioID
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        dateKey = try container.decode(String.self, forKey: .dateKey)
        wakeSessionID = try container.decodeIfPresent(String.self, forKey: .wakeSessionID)
        type = try container.decode(MorningLogRecordType.self, forKey: .type)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        scheduledEventID = try container.decodeIfPresent(String.self, forKey: .scheduledEventID)
        metadata = try container.decodeIfPresent([String: String].self, forKey: .metadata) ?? [:]
        isTest = try container.decodeIfPresent(Bool.self, forKey: .isTest) ?? false
        scenarioID = try container.decodeIfPresent(String.self, forKey: .scenarioID)
    }
}

enum MorningWakeOutcome: String, Codable, CaseIterable, Identifiable, Sendable {
    case unconfirmed
    case confirmedAwakeForFajr
    case confirmedAwakeForSuhoor
    case expiredUnconfirmed
    case quietMorning

    var id: String { rawValue }
}

enum FajrPrayerOutcome: String, Codable, CaseIterable, Identifiable, Sendable {
    case unconfirmed
    case fajrPrayerConfirmed

    var id: String { rawValue }
}

enum FastingIntentOutcome: String, Codable, CaseIterable, Identifiable, Sendable {
    case unconfirmed
    case fastingIntentConfirmed

    var id: String { rawValue }
}

enum FastCompletionOutcome: String, Codable, CaseIterable, Identifiable, Sendable {
    case unconfirmed
    case fastCompletionConfirmed

    var id: String { rawValue }
}

struct MorningLogEntry: Codable, Equatable, Sendable {
    let dateKey: String
    var suhoorWakeOutcome: MorningWakeOutcome
    var fajrWakeOutcome: MorningWakeOutcome
    var fajrPrayerOutcome: FajrPrayerOutcome
    var fastingIntentOutcome: FastingIntentOutcome
    var fastingDayPlanned: Bool
    var fastCompletionOutcome: FastCompletionOutcome
    var quietMorning: Bool
    var records: [MorningLogRecord]
    var updatedAt: Date
    var isTest: Bool
    var scenarioID: String?

    init(dateKey: String, updatedAt: Date, isTest: Bool = false, scenarioID: String? = nil) {
        self.dateKey = dateKey
        self.suhoorWakeOutcome = .unconfirmed
        self.fajrWakeOutcome = .unconfirmed
        self.fajrPrayerOutcome = .unconfirmed
        self.fastingIntentOutcome = .unconfirmed
        self.fastingDayPlanned = false
        self.fastCompletionOutcome = .unconfirmed
        self.quietMorning = false
        self.records = []
        self.updatedAt = updatedAt
        self.isTest = isTest
        self.scenarioID = scenarioID
    }

    var hasFajrPrayerConfirmed: Bool {
        fajrPrayerOutcome == .fajrPrayerConfirmed
    }

    private enum CodingKeys: String, CodingKey {
        case dateKey
        case suhoorWakeOutcome
        case fajrWakeOutcome
        case fajrPrayerOutcome
        case fastingIntentOutcome
        case fastingDayPlanned
        case fastCompletionOutcome
        case quietMorning
        case records
        case updatedAt
        case isTest
        case scenarioID
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        dateKey = try container.decode(String.self, forKey: .dateKey)
        suhoorWakeOutcome = try container.decodeIfPresent(MorningWakeOutcome.self, forKey: .suhoorWakeOutcome) ?? .unconfirmed
        fajrWakeOutcome = try container.decodeIfPresent(MorningWakeOutcome.self, forKey: .fajrWakeOutcome) ?? .unconfirmed
        fajrPrayerOutcome = try container.decodeIfPresent(FajrPrayerOutcome.self, forKey: .fajrPrayerOutcome) ?? .unconfirmed
        fastingIntentOutcome = try container.decodeIfPresent(FastingIntentOutcome.self, forKey: .fastingIntentOutcome) ?? .unconfirmed
        fastingDayPlanned = try container.decodeIfPresent(Bool.self, forKey: .fastingDayPlanned) ?? false
        fastCompletionOutcome = try container.decodeIfPresent(FastCompletionOutcome.self, forKey: .fastCompletionOutcome) ?? .unconfirmed
        quietMorning = try container.decodeIfPresent(Bool.self, forKey: .quietMorning) ?? false
        records = try container.decodeIfPresent([MorningLogRecord].self, forKey: .records) ?? []
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        isTest = try container.decodeIfPresent(Bool.self, forKey: .isTest) ?? records.contains { $0.isTest }
        scenarioID = try container.decodeIfPresent(String.self, forKey: .scenarioID) ?? records.first(where: { $0.scenarioID != nil })?.scenarioID
    }
}

@MainActor
final class WakeSessionStore: ObservableObject {
    @Published private(set) var sessionsByID: [String: WakeSession]
    @Published private(set) var morningLogsByDateKey: [String: MorningLogEntry]
    @Published private(set) var currentRevision: Int

    private let defaults: UserDefaults
    private let storageKey = "Subh.WakeSessionsAndMorningLogs"
    private let revisionKey = "Subh.WakeSessionsAndMorningLogsRevision"
    private let persistence = DebouncedPersistenceController(
        label: "com.suhoor.app.wake-session-store",
        delay: 0.2
    )

    init(defaults: UserDefaults = .standard, loadPersistedData: Bool = true) {
        self.defaults = defaults
        guard loadPersistedData else {
            self.sessionsByID = [:]
            self.morningLogsByDateKey = [:]
            self.currentRevision = 0
            return
        }

        if let data = defaults.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode(Payload.self, from: data) {
            self.sessionsByID = decoded.sessionsByID
            self.morningLogsByDateKey = decoded.morningLogsByDateKey
        } else {
            self.sessionsByID = [:]
            self.morningLogsByDateKey = [:]
        }
        self.currentRevision = defaults.integer(forKey: revisionKey)
    }

    func session(for dateKey: String) -> WakeSession? {
        sessionsByID[Self.sessionID(for: dateKey)]
    }

    func session(id: String) -> WakeSession? {
        sessionsByID[id]
    }

    func morningLog(for dateKey: String) -> MorningLogEntry? {
        morningLogsByDateKey[dateKey]
    }

    @discardableResult
    func upsertScheduledSession(from draft: WakeSessionDraft, now: Date = Date()) -> WakeSession {
        let existing = sessionsByID[draft.wakeSessionID]
        let isNew = existing == nil
        var session = existing ?? WakeSession(draft: draft, now: now)
        session.apply(draft: draft, now: now)

        var logIDs = session.operationalLogIDs
        if isNew {
            let record = appendRecord(
                dateKey: draft.dateKey,
                wakeSessionID: draft.wakeSessionID,
                type: .wakeSessionCreated,
                timestamp: now,
                isTest: draft.isTest,
                scenarioID: draft.scenarioID
            )
            logIDs.append(record.id)
        }
        if let primaryID = draft.primaryScheduledEventID,
           existing?.primaryScheduledEventID != primaryID {
            let record = appendRecord(
                dateKey: draft.dateKey,
                wakeSessionID: draft.wakeSessionID,
                type: .primaryAlarmScheduled,
                timestamp: now,
                scheduledEventID: primaryID,
                isTest: draft.isTest,
                scenarioID: draft.scenarioID
            )
            logIDs.append(record.id)
        }

        let existingWakeChecks = Set(existing?.wakeCheckScheduledEventIDs ?? [])
        for wakeCheckID in draft.wakeCheckScheduledEventIDs where !existingWakeChecks.contains(wakeCheckID) {
            let record = appendRecord(
                dateKey: draft.dateKey,
                wakeSessionID: draft.wakeSessionID,
                type: .wakeCheckScheduled,
                timestamp: now,
                scheduledEventID: wakeCheckID,
                isTest: draft.isTest,
                scenarioID: draft.scenarioID
            )
            logIDs.append(record.id)
        }
        session.operationalLogIDs = uniqueLogIDs(logIDs)
        updateSession(session)
        return session
    }

    @discardableResult
    func recordPrimaryAlarmFired(
        wakeSessionID: String,
        scheduledEventID: String?,
        now: Date = Date()
    ) -> WakeSession? {
        guard var session = sessionsByID[wakeSessionID] else { return nil }
        guard !session.status.isTerminal else { return session }
        session.status = .primaryAlarmFired
        if let scheduledEventID {
            appendUnique(&session.firedScheduledEventIDs, value: scheduledEventID)
        }
        let record = appendRecord(
            dateKey: session.dateKey,
            wakeSessionID: wakeSessionID,
            type: .primaryAlarmFired,
            timestamp: now,
            scheduledEventID: scheduledEventID,
            isTest: session.isTest,
            scenarioID: session.scenarioID
        )
        appendUnique(&session.operationalLogIDs, value: record.id)
        session.updatedAt = now
        updateSession(session)
        return session
    }

    @discardableResult
    func recordWakeCheckFired(
        wakeSessionID: String,
        scheduledEventID: String?,
        now: Date = Date()
    ) -> WakeSession? {
        guard var session = sessionsByID[wakeSessionID] else { return nil }
        guard !session.status.isTerminal else { return session }
        session.status = .wakeChecksPending
        if let scheduledEventID {
            appendUnique(&session.firedScheduledEventIDs, value: scheduledEventID)
        }
        let record = appendRecord(
            dateKey: session.dateKey,
            wakeSessionID: wakeSessionID,
            type: .wakeCheckFired,
            timestamp: now,
            scheduledEventID: scheduledEventID,
            isTest: session.isTest,
            scenarioID: session.scenarioID
        )
        appendUnique(&session.operationalLogIDs, value: record.id)
        session.updatedAt = now
        updateSession(session)
        return session
    }

    @discardableResult
    func recordAlarmStopped(
        wakeSessionID: String,
        scheduledEventID: String?,
        now: Date = Date()
    ) -> WakeSession? {
        guard var session = sessionsByID[wakeSessionID] else { return nil }
        if let scheduledEventID {
            appendUnique(&session.stoppedScheduledEventIDs, value: scheduledEventID)
        }
        if !session.status.isTerminal {
            session.status = .confirmedAwake
            session.confirmedWakeMode = session.mode
            session.confirmedAt = now
            session.acknowledgementSource = .systemAlarmDismiss
            updateMorningLog(dateKey: session.dateKey, now: now) { log in
                switch session.mode {
                case .fajr:
                    log.fajrWakeOutcome = .confirmedAwakeForFajr
                case .suhoor:
                    log.suhoorWakeOutcome = .confirmedAwakeForSuhoor
                }
            }
        }
        let record = appendRecord(
            dateKey: session.dateKey,
            wakeSessionID: wakeSessionID,
            type: .alarmStopped,
            timestamp: now,
            scheduledEventID: scheduledEventID,
            isTest: session.isTest,
            scenarioID: session.scenarioID
        )
        appendUnique(&session.operationalLogIDs, value: record.id)
        session.updatedAt = now
        updateSession(session)
        return session
    }

    @discardableResult
    func confirmAwake(
        wakeSessionID: String,
        mode: WakeSessionMode,
        cancelledScheduledEventIDs: [String],
        source: WakeAcknowledgementSource = .inAppButton,
        now: Date = Date()
    ) -> WakeSession? {
        guard var session = sessionsByID[wakeSessionID] else { return nil }
        session.status = .confirmedAwake
        session.confirmedWakeMode = mode
        session.confirmedAt = now
        session.acknowledgementSource = source
        session.cancelledAt = nil
        session.quietReason = nil

        let confirmationType: MorningLogRecordType
        switch mode {
        case .fajr:
            confirmationType = .confirmedAwakeForFajr
            updateMorningLog(dateKey: session.dateKey, now: now) { log in
                log.fajrWakeOutcome = .confirmedAwakeForFajr
            }
        case .suhoor:
            confirmationType = .confirmedAwakeForSuhoor
            updateMorningLog(dateKey: session.dateKey, now: now) { log in
                log.suhoorWakeOutcome = .confirmedAwakeForSuhoor
            }
        }

        let confirmationRecord = appendRecord(
            dateKey: session.dateKey,
            wakeSessionID: wakeSessionID,
            type: confirmationType,
            timestamp: now,
            isTest: session.isTest,
            scenarioID: session.scenarioID
        )
        appendUnique(&session.operationalLogIDs, value: confirmationRecord.id)

        if !cancelledScheduledEventIDs.isEmpty {
            let cancelRecord = appendRecord(
                dateKey: session.dateKey,
                wakeSessionID: wakeSessionID,
                type: .wakeChecksCancelled,
                timestamp: now,
                metadata: ["eventIDs": cancelledScheduledEventIDs.joined(separator: ",")],
                isTest: session.isTest,
                scenarioID: session.scenarioID
            )
            appendUnique(&session.operationalLogIDs, value: cancelRecord.id)
        }
        session.updatedAt = now
        updateSession(session)
        return session
    }

    @discardableResult
    func confirmFastingIntent(
        dateKey: String,
        wakeSessionID: String?,
        now: Date = Date()
    ) -> MorningLogEntry {
        updateMorningLog(dateKey: dateKey, now: now) { log in
            log.fastingIntentOutcome = .fastingIntentConfirmed
            log.fastingDayPlanned = true
        }
        let record = appendRecord(
            dateKey: dateKey,
            wakeSessionID: wakeSessionID,
            type: .fastingIntentConfirmed,
            timestamp: now,
            isTest: wakeSessionID.flatMap { sessionsByID[$0]?.isTest } ?? false,
            scenarioID: wakeSessionID.flatMap { sessionsByID[$0]?.scenarioID }
        )
        if let wakeSessionID, var session = sessionsByID[wakeSessionID] {
            appendUnique(&session.operationalLogIDs, value: record.id)
            session.updatedAt = now
            updateSession(session)
        }
        return morningLogsByDateKey[dateKey] ?? MorningLogEntry(dateKey: dateKey, updatedAt: now)
    }

    @discardableResult
    func confirmFajrPrayer(
        dateKey: String,
        wakeSessionID: String?,
        now: Date = Date()
    ) -> MorningLogEntry {
        updateMorningLog(dateKey: dateKey, now: now) { log in
            log.fajrPrayerOutcome = .fajrPrayerConfirmed
        }
        let record = appendRecord(
            dateKey: dateKey,
            wakeSessionID: wakeSessionID,
            type: .fajrPrayerConfirmed,
            timestamp: now,
            isTest: wakeSessionID.flatMap { sessionsByID[$0]?.isTest } ?? false,
            scenarioID: wakeSessionID.flatMap { sessionsByID[$0]?.scenarioID }
        )
        if let wakeSessionID, var session = sessionsByID[wakeSessionID] {
            appendUnique(&session.operationalLogIDs, value: record.id)
            session.updatedAt = now
            updateSession(session)
        }
        return morningLogsByDateKey[dateKey] ?? MorningLogEntry(dateKey: dateKey, updatedAt: now)
    }

    @discardableResult
    func markQuietMorning(
        wakeSessionID: String,
        reason: String?,
        cancelledScheduledEventIDs: [String],
        now: Date = Date()
    ) -> WakeSession? {
        guard var session = sessionsByID[wakeSessionID] else { return nil }
        session.status = .quietMorning
        session.cancelledAt = now
        session.quietReason = reason
        updateMorningLog(dateKey: session.dateKey, now: now) { log in
            log.quietMorning = true
            log.fajrWakeOutcome = log.fajrWakeOutcome == .unconfirmed ? .quietMorning : log.fajrWakeOutcome
            log.suhoorWakeOutcome = log.suhoorWakeOutcome == .unconfirmed ? .quietMorning : log.suhoorWakeOutcome
        }
        let quietRecord = appendRecord(
            dateKey: session.dateKey,
            wakeSessionID: wakeSessionID,
            type: .quietMorning,
            timestamp: now,
            metadata: reason.map { ["reason": $0] } ?? [:],
            isTest: session.isTest,
            scenarioID: session.scenarioID
        )
        appendUnique(&session.operationalLogIDs, value: quietRecord.id)

        if !cancelledScheduledEventIDs.isEmpty {
            let cancelRecord = appendRecord(
                dateKey: session.dateKey,
                wakeSessionID: wakeSessionID,
                type: .wakeChecksCancelled,
                timestamp: now,
                metadata: ["eventIDs": cancelledScheduledEventIDs.joined(separator: ",")],
                isTest: session.isTest,
                scenarioID: session.scenarioID
            )
            appendUnique(&session.operationalLogIDs, value: cancelRecord.id)
        }
        session.updatedAt = now
        updateSession(session)
        return session
    }

    @discardableResult
    func markExpiredUnconfirmed(
        wakeSessionID: String,
        now: Date = Date()
    ) -> WakeSession? {
        guard var session = sessionsByID[wakeSessionID] else { return nil }
        guard !session.status.isTerminal else { return session }
        session.status = .expiredUnconfirmed
        session.expiredAt = now
        updateMorningLog(dateKey: session.dateKey, now: now) { log in
            switch session.mode {
            case .fajr:
                log.fajrWakeOutcome = .expiredUnconfirmed
            case .suhoor:
                log.suhoorWakeOutcome = .expiredUnconfirmed
            }
        }
        let record = appendRecord(
            dateKey: session.dateKey,
            wakeSessionID: wakeSessionID,
            type: .wakeSessionExpiredUnconfirmed,
            timestamp: now,
            isTest: session.isTest,
            scenarioID: session.scenarioID
        )
        appendUnique(&session.operationalLogIDs, value: record.id)
        session.updatedAt = now
        updateSession(session)
        return session
    }

    func reset() {
        persistence.cancelPending()
        sessionsByID = [:]
        morningLogsByDateKey = [:]
        currentRevision = 0
        defaults.removeObject(forKey: storageKey)
        defaults.removeObject(forKey: revisionKey)
    }

    func clearTestWakeSessions() {
        let original = sessionsByID
        sessionsByID = sessionsByID.filter { !$0.value.isTest }
        guard sessionsByID != original else { return }
        bumpRevision()
    }

    func clearTestMorningLogs() {
        let original = morningLogsByDateKey
        morningLogsByDateKey = morningLogsByDateKey.filter { !$0.value.isTest }
        guard morningLogsByDateKey != original else { return }
        bumpRevision()
    }

    func clearAllTestRecords() {
        let originalSessions = sessionsByID
        let originalLogs = morningLogsByDateKey
        sessionsByID = sessionsByID.filter { !$0.value.isTest }
        morningLogsByDateKey = morningLogsByDateKey.filter { !$0.value.isTest }
        guard sessionsByID != originalSessions || morningLogsByDateKey != originalLogs else { return }
        bumpRevision()
    }

#if DEBUG
    func flushPersistenceForTesting() {
        persistence.flush()
    }
#endif

    static func sessionID(for dateKey: String) -> String {
        "\(dateKey).wake-session"
    }

    private func updateSession(_ session: WakeSession) {
        guard sessionsByID[session.wakeSessionID] != session else { return }
        sessionsByID[session.wakeSessionID] = session
        bumpRevision()
    }

    @discardableResult
    private func appendRecord(
        dateKey: String,
        wakeSessionID: String?,
        type: MorningLogRecordType,
        timestamp: Date,
        scheduledEventID: String? = nil,
        metadata: [String: String] = [:],
        isTest: Bool = false,
        scenarioID: String? = nil
    ) -> MorningLogRecord {
        let record = MorningLogRecord(
            dateKey: dateKey,
            wakeSessionID: wakeSessionID,
            type: type,
            timestamp: timestamp,
            scheduledEventID: scheduledEventID,
            metadata: metadata,
            isTest: isTest,
            scenarioID: scenarioID
        )
        updateMorningLog(dateKey: dateKey, now: timestamp) { log in
            log.isTest = log.isTest || isTest
            log.scenarioID = log.scenarioID ?? scenarioID
            log.records.append(record)
        }
        return record
    }

    private func updateMorningLog(
        dateKey: String,
        now: Date,
        mutate: (inout MorningLogEntry) -> Void
    ) {
        var log = morningLogsByDateKey[dateKey] ?? MorningLogEntry(dateKey: dateKey, updatedAt: now)
        let existing = log
        mutate(&log)
        log.updatedAt = now
        guard existing != log else { return }
        morningLogsByDateKey[dateKey] = log
        bumpRevision()
    }

    private func bumpRevision() {
        currentRevision += 1
        persist()
    }

    private func persist() {
        let payload = Payload(
            sessionsByID: sessionsByID,
            morningLogsByDateKey: morningLogsByDateKey
        )
        let revision = currentRevision
        persistence.schedule { [defaults, storageKey, revisionKey] in
            guard let data = try? JSONEncoder().encode(payload) else { return }
            defaults.set(data, forKey: storageKey)
            defaults.set(revision, forKey: revisionKey)
        }
    }

    private func uniqueLogIDs(_ values: [UUID]) -> [UUID] {
        var seen = Set<UUID>()
        return values.filter { seen.insert($0).inserted }
    }

    private func appendUnique<T: Hashable>(_ values: inout [T], value: T) {
        if !values.contains(value) {
            values.append(value)
        }
    }

    private struct Payload: Codable {
        let sessionsByID: [String: WakeSession]
        let morningLogsByDateKey: [String: MorningLogEntry]
    }
}

enum WakeSessionPlanner {
    struct WakeCheckConfiguration: Equatable, Sendable {
        let intervalMinutes: Int
        let maximumCount: Int
        let cutoffBufferMinutes: Int

        static let production = WakeCheckConfiguration(
            intervalMinutes: 5,
            maximumCount: 5,
            cutoffBufferMinutes: 5
        )

        static let compressedTest = WakeCheckConfiguration(
            intervalMinutes: 1,
            maximumCount: 3,
            cutoffBufferMinutes: 1
        )
    }

    static let wakeCheckIntervalMinutes = WakeCheckConfiguration.production.intervalMinutes
    static let maximumWakeCheckCount = WakeCheckConfiguration.production.maximumCount

    static func wakeSessionID(for dateKey: String) -> String {
        WakeSessionStore.sessionID(for: dateKey)
    }

    static func wakeCheckEventID(dateKey: String, index: Int) -> String {
        "\(dateKey).wakeCheck.\(index)"
    }

    static func wakeCheckEvents(
        dateKey: String,
        wakeSessionID: String,
        mode: WakeSessionMode,
        primaryWakeTime: Date,
        prayerWindow: DailyPrayerWindow,
        soundRole: MorningSoundRole?,
        now: Date = .distantPast,
        configuration: WakeCheckConfiguration = .production
    ) -> [ScheduledEvent] {
        guard let cutoff = wakeCheckCutoff(
            mode: mode,
            prayerWindow: prayerWindow,
            cutoffBufferMinutes: configuration.cutoffBufferMinutes
        ) else {
            return []
        }

        return (1...configuration.maximumCount).compactMap { index in
            let wakeCheckTime = primaryWakeTime.addingTimeInterval(
                TimeInterval(index * configuration.intervalMinutes * 60)
            )
            guard wakeCheckTime <= cutoff, wakeCheckTime > now else {
                return nil
            }
            return ScheduledEvent(
                id: wakeCheckEventID(dateKey: dateKey, index: index),
                type: .wakeFollowUp,
                dateKey: dateKey,
                fireDate: wakeCheckTime,
                relativeTo: .wakeAlarm(offsetMinutes: index * configuration.intervalMinutes),
                isUserVisible: true,
                affectsCompletion: false,
                deliveryKinds: [.wake],
                soundRole: soundRole,
                wakeSessionID: wakeSessionID,
                wakeSessionRole: .wakeCheck
            )
        }
    }

    static func wakeSessionDraft(for day: ActiveAlarmDay) -> WakeSessionDraft? {
        guard !day.effectiveConfig.skipDay else { return nil }
        guard day.effectiveConfig.dateAlarmOverride != .quiet else { return nil }
        guard let primary = primaryWakeEvent(for: day) else { return nil }
        let wakeChecks = wakeCheckEvents(for: day)
        let mode = wakeSessionMode(for: day)
        let prayerWindow = day.decisionLog.prayerWindow
        return WakeSessionDraft(
            wakeSessionID: primary.wakeSessionID ?? wakeSessionID(for: day.dateKey),
            dateKey: day.dateKey,
            morningDate: day.date,
            mode: mode,
            finalThirdStart: EarlyWorshipBoundaryResolver.finalThirdStart(
                targetFajrStart: prayerWindow.fajrStart,
                maghrib: prayerWindow.maghrib,
                timeZone: .current
            ),
            fajrBegins: prayerWindow.fajrStart,
            fajrEnds: prayerWindow.fajrEnd,
            plannedWakeTime: primary.fireDate,
            primaryAlarmID: SchedulingIdentifiers.identifier(for: primary, deliveryKind: .wake),
            primaryScheduledEventID: primary.id,
            wakeCheckIDs: wakeChecks.map { SchedulingIdentifiers.identifier(for: $0, deliveryKind: .wake) },
            wakeCheckScheduledEventIDs: wakeChecks.map(\.id)
        )
    }

    static func primaryWakeEvent(for day: ActiveAlarmDay) -> ScheduledEvent? {
        day.scheduledEvents.first { $0.wakeSessionRole == .primaryWake }
            ?? day.scheduledEvents.first { $0.type == .wakeAlarm }
    }

    static func wakeCheckEvents(for day: ActiveAlarmDay) -> [ScheduledEvent] {
        day.scheduledEvents.filter { $0.wakeSessionRole == .wakeCheck }
    }

    static func cancellableWakeSessionEvents(
        for day: ActiveAlarmDay,
        wakeSessionID: String?,
        now: Date = Date()
    ) -> [ScheduledEvent] {
        day.scheduledEvents.filter { event in
            guard event.fireDate > now else { return false }
            guard event.deliveryKinds.contains(.wake) else { return false }
            if let wakeSessionID, event.wakeSessionID != wakeSessionID {
                return false
            }
            return event.wakeSessionRole == .primaryWake || event.wakeSessionRole == .wakeCheck
        }
    }

    static func wakeSessionMode(for day: ActiveAlarmDay) -> WakeSessionMode {
        if WakeStateSelectionResolver.selectedMode(for: day) == .suhoor {
            return .suhoor
        }
        if day.decisionLog.plannedWakeState == .preFajr || day.decisionLog.resolvedWakeState == .preFajr {
            return .suhoor
        }
        return .fajr
    }

    static func wakeCheckCutoff(
        mode: WakeSessionMode,
        prayerWindow: DailyPrayerWindow,
        cutoffBufferMinutes: Int = WakeCheckConfiguration.production.cutoffBufferMinutes
    ) -> Date? {
        switch mode {
        case .suhoor:
            return prayerWindow.fajrStart.addingTimeInterval(-TimeInterval(cutoffBufferMinutes * 60))
        case .fajr:
            return prayerWindow.fajrEnd?.addingTimeInterval(-TimeInterval(cutoffBufferMinutes * 60))
        }
    }
}
