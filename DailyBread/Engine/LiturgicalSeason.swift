//
//  LiturgicalSeason.swift
//  DailyBread
//
//  Created for DailyBread.
//  Copyright © 2026 DailyBread. All rights reserved.
//

import Foundation

/// Represents the major seasons of the Catholic liturgical year according to the Roman Rite.
///
/// The liturgical year unfolds the whole mystery of Christ, from the Incarnation and Nativity
/// through the Ascension, Pentecost, and the expectant hope for the Lord's return in glory.
public enum LiturgicalSeason: String, CaseIterable, Identifiable, Hashable, Codable, Sendable {
    /// The season of preparation for both the Nativity of Christ and His Second Coming.
    /// Runs from the First Sunday of Advent through the afternoon of Christmas Eve (December 24).
    case advent

    /// The season celebrating the Incarnation and Nativity of the Lord.
    /// Runs from the Vigil of Christmas (December 24 evening) through the Feast of the Baptism of the Lord.
    case christmas

    /// The season celebrating the mystery of Christ in its fullness rather than one specific aspect.
    /// Divided into two periods: between Christmas and Lent, and between Pentecost and Advent.
    case ordinaryTime

    /// The forty-day penitential season of prayer, fasting, and almsgiving in preparation for Easter.
    /// Runs from Ash Wednesday until the Mass of the Lord's Supper on Holy Thursday.
    case lent

    /// The summit of the liturgical year: Holy Thursday evening, Good Friday, Holy Saturday, and Easter Sunday.
    case paschalTriduum

    /// The joyful fifty-day celebration of the Resurrection of Jesus Christ.
    /// Runs from Easter Sunday through Pentecost Sunday.
    case easter

    // MARK: - Identifiable

    public var id: String {
        rawValue
    }

    // MARK: - Display Names

    /// The English display name for the liturgical season.
    public var displayName: String {
        switch self {
        case .advent:
            return "Advent"
        case .christmas:
            return "Christmas"
        case .ordinaryTime:
            return "Ordinary Time"
        case .lent:
            return "Lent"
        case .paschalTriduum:
            return "Paschal Triduum"
        case .easter:
            return "Easter"
        }
    }

    /// The traditional Latin name for the liturgical season.
    public var latinName: String {
        switch self {
        case .advent:
            return "Tempus Adventus"
        case .christmas:
            return "Tempus Nativitatis"
        case .ordinaryTime:
            return "Tempus per Annum"
        case .lent:
            return "Tempus Quadragesimae"
        case .paschalTriduum:
            return "Triduum Paschale"
        case .easter:
            return "Tempus Paschale"
        }
    }

    /// A theological and devotional description of the season.
    public var seasonDescription: String {
        switch self {
        case .advent:
            return "A period of devout and joyful expectation for the coming of Christ at Christmas and His return at the end of time."
        case .christmas:
            return "The joyful celebration of the Incarnation of the Word made flesh dwelling among us."
        case .ordinaryTime:
            return "The ordered journey of Christian discipleship, contemplating the teachings and miracles of Jesus."
        case .lent:
            return "A sacred 40-day retreat of prayer, fasting, and repentance leading to renewal of baptismal promises at Easter."
        case .paschalTriduum:
            return "The holy three days commemorating the Paschal mystery: Christ's Last Supper, Passion, Death, and Resurrection."
        case .easter:
            return "Fifty days of exultant celebration of Christ's victory over sin and death, culminating at Pentecost."
        }
    }

    /// The default liturgical color associated with this season.
    public var defaultColor: LiturgicalColor {
        switch self {
        case .advent:
            return .violet
        case .christmas:
            return .white
        case .ordinaryTime:
            return .green
        case .lent:
            return .violet
        case .paschalTriduum:
            return .red
        case .easter:
            return .white
        }
    }
}
