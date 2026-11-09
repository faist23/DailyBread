//
//  LiturgicalRank.swift
//  DailyBread
//
//  Created for DailyBread.
//  Copyright © 2026 DailyBread. All rights reserved.
//

import Foundation

/// Represents the hierarchy of liturgical days according to the Universal Norms for the Liturgical Year
/// and the General Roman Calendar (UNLY §59, Table of Liturgical Days).
///
/// In the Catholic liturgy, when multiple celebrations fall on the same day, the precedence table
/// determines which celebration is observed and whether the displaced celebration is transferred,
/// commemorated, or omitted.
///
/// **Precedence Rule:** Lower numerical rawValue represents higher liturgical precedence:
/// `triduum (1)` has the highest precedence; `weekday (12)` has the lowest precedence.
public enum LiturgicalRank: Int, CaseIterable, Identifiable, Hashable, Codable, Sendable, Comparable {
    /// Rank 1: The Paschal Triduum of the Passion and Resurrection of the Lord
    /// (Holy Thursday Mass of the Lord's Supper, Good Friday, Holy Saturday, Easter Sunday).
    case triduum = 1

    /// Rank 2: Primary Solemnities and Days of the First Rank:
    /// - The Nativity of the Lord (Christmas), Epiphany, Ascension, Pentecost
    /// - Sundays of Advent, Lent, and Easter
    /// - Ash Wednesday
    /// - Weekdays of Holy Week from Monday to Thursday inclusive
    /// - Days within the Octave of Easter
    case primarySolemnity = 2

    /// Rank 3: General Solemnities inscribed in the General Roman Calendar:
    /// - Mary, Mother of God (Jan 1)
    /// - Saint Joseph (Mar 19)
    /// - The Annunciation (Mar 25)
    /// - The Nativity of Saint John the Baptist (Jun 24)
    /// - Saints Peter and Paul (Jun 29)
    /// - The Assumption of Mary (Aug 15)
    /// - All Saints (Nov 1)
    /// - The Immaculate Conception (Dec 8)
    /// - The Most Holy Trinity
    /// - The Most Holy Body and Blood of Christ (Corpus Christi)
    /// - The Most Sacred Heart of Jesus
    /// - Our Lord Jesus Christ, King of the Universe
    /// - All Souls' Day (Nov 2, commemorated with rank of solemnity)
    case generalSolemnity = 3

    /// Rank 4: Proper Solemnities:
    /// - Principal Patron of the nation, state, diocese, or city
    /// - The Solemnity of the dedication and the anniversary of the dedication of one's own church
    /// - The Solemnity of the titular saint of one's own church
    /// - The Solemnity of the founder or principal patron of an order or congregation
    case properSolemnity = 4

    /// Rank 5: Feasts of the Lord in the General Roman Calendar:
    /// - The Holy Family
    /// - The Baptism of the Lord
    /// - The Presentation of the Lord (Feb 2)
    /// - The Transfiguration of the Lord (Aug 6)
    /// - The Exaltation of the Holy Cross (Sep 14)
    /// - The Dedication of the Lateran Basilica (Nov 9)
    case feastOfLord = 5

    /// Rank 6: Sundays of the Christmas Season and Sundays in Ordinary Time.
    case sundayChristmasOrdinary = 6

    /// Rank 7: Feasts of the Blessed Virgin Mary and of Saints in the General Roman Calendar
    /// (e.g. Apostles, Evangelists, Visitation, Nativity of Mary).
    case feastGeneral = 7

    /// Rank 8: Proper Feasts:
    /// - Principal patron of the diocese
    /// - Anniversary of the dedication of the cathedral church
    /// - Principal patron of a region or province
    /// - Titular feast of a parish or religious house
    case properFeast = 8

    /// Rank 9: Privileged Weekdays:
    /// - Weekdays of Advent from December 17 to December 24 inclusive
    /// - Days within the Octave of Christmas (Dec 26 to Dec 31)
    /// - Weekdays of Lent (from the Thursday after Ash Wednesday through Wednesday of Holy Week)
    case privilegedWeekday = 9

    /// Rank 10: Obligatory Memorials in the General Roman Calendar
    /// (e.g. St. Elizabeth Ann Seton, St. Francis of Assisi, St. Patrick).
    case obligatoryMemorial = 10

    /// Rank 11: Optional Memorials in the General Roman Calendar and diocesan proper calendars.
    case optionalMemorial = 11

    /// Rank 12: Weekdays:
    /// - Weekdays of Advent from Monday after the First Sunday of Advent through December 16
    /// - Weekdays of Christmas Time from January 2 through the Saturday after Epiphany
    /// - Weekdays of Easter Time from Monday after the Octave of Easter through Saturday before Pentecost
    /// - Weekdays in Ordinary Time
    case weekday = 12

    // MARK: - Identifiable

    public var id: Int {
        rawValue
    }

    // MARK: - Comparable

    /// Evaluates whether `lhs` has higher precedence (numerically lower rank) than `rhs`.
    ///
    /// For example: `.triduum < .primarySolemnity` evaluates to `true`, because Rank 1 precedes Rank 2.
    public static func < (lhs: LiturgicalRank, rhs: LiturgicalRank) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    /// Explicit helper indicating whether this rank takes precedence over another rank.
    ///
    /// - Parameter other: The rank to compare against.
    /// - Returns: `true` if `self` has strictly higher liturgical precedence (lower numerical rank).
    public func takesPrecedence(over other: LiturgicalRank) -> Bool {
        self.rawValue < other.rawValue
    }

    // MARK: - Display Properties

    /// The canonical category name of this rank.
    public var displayName: String {
        switch self {
        case .triduum:
            return "Paschal Triduum"
        case .primarySolemnity:
            return "Primary Solemnity"
        case .generalSolemnity:
            return "Solemnity"
        case .properSolemnity:
            return "Proper Solemnity"
        case .feastOfLord:
            return "Feast of the Lord"
        case .sundayChristmasOrdinary:
            return "Sunday"
        case .feastGeneral:
            return "Feast"
        case .properFeast:
            return "Proper Feast"
        case .privilegedWeekday:
            return "Privileged Weekday"
        case .obligatoryMemorial:
            return "Obligatory Memorial"
        case .optionalMemorial:
            return "Optional Memorial"
        case .weekday:
            return "Weekday"
        }
    }

    /// Whether this rank corresponds to a Solemnity (Ranks 1–4).
    public var isSolemnity: Bool {
        rawValue <= 4
    }

    /// Whether this rank corresponds to a Feast (Ranks 5, 7, 8).
    public var isFeast: Bool {
        self == .feastOfLord || self == .feastGeneral || self == .properFeast
    }

    /// Whether this rank corresponds to a Memorial (Ranks 10, 11).
    public var isMemorial: Bool {
        self == .obligatoryMemorial || self == .optionalMemorial
    }

    /// Whether the Gloria in Excelsis is recited at Mass on this day.
    public var isGloriaPrescribed: Bool {
        switch self {
        case .triduum:
            // Sung on Holy Thursday and at Easter Vigil; omitted on Good Friday and Holy Saturday
            return true
        case .primarySolemnity, .generalSolemnity, .properSolemnity, .feastOfLord, .feastGeneral, .properFeast:
            return true
        case .sundayChristmasOrdinary:
            // Sundays in Christmas and Ordinary Time recite the Gloria; Sundays in Advent and Lent omit it
            return true
        case .privilegedWeekday, .obligatoryMemorial, .optionalMemorial, .weekday:
            return false
        }
    }

    /// Whether the Creed (Credo) is recited at Mass on this day (Sundays and Solemnities).
    public var isCreedPrescribed: Bool {
        isSolemnity || self == .sundayChristmasOrdinary
    }

    // MARK: - Compatibility Aliases

    /// Solemnity alias matching generalSolemnity.
    public static let solemnity: LiturgicalRank = .generalSolemnity

    /// Commemoration alias matching optionalMemorial.
    public static let commemoration: LiturgicalRank = .optionalMemorial

    /// Feast alias matching feastGeneral.
    public static let feast: LiturgicalRank = .feastGeneral

    /// Memorial alias matching obligatoryMemorial.
    public static let memorial: LiturgicalRank = .obligatoryMemorial
}
