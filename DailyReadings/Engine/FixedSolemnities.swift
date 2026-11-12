//
//  FixedSolemnities.swift
//  DailyReadings
//
//  Created for DailyReadings.
//  Copyright © 2026 DailyReadings. All rights reserved.
//

import Foundation

/// Represents a liturgical celebration on a fixed calendar date (month and day).
public struct FixedCelebration: Sendable, Hashable, Identifiable {
    public var id: String {
        String(format: "%02d-%02d-%@", month, day, title)
    }

    /// Calendar month (1–12).
    public let month: Int

    /// Calendar day of the month (1–31).
    public let day: Int

    /// The liturgical title of the celebration.
    public let title: String

    /// The liturgical rank according to the precedence table.
    public let rank: LiturgicalRank

    /// The liturgical vestment color.
    public let color: LiturgicalColor

    /// Whether this celebration is a solemnity (Rank 1–4).
    public let isSolemnity: Bool

    /// Whether this solemnity is a Holy Day of Obligation in the United States.
    public let isHolyDayOfObligationInUS: Bool

    /// Whether this celebration belongs specifically to the Proper Calendar for the Dioceses of the United States.
    public let isUSProper: Bool

    /// Optional devotional common description (e.g. "Common of Apostles", "Common of Martyrs").
    public let common: String?

    public init(
        month: Int,
        day: Int,
        title: String,
        rank: LiturgicalRank,
        color: LiturgicalColor,
        isSolemnity: Bool = false,
        isHolyDayOfObligationInUS: Bool = false,
        isUSProper: Bool = false,
        common: String? = nil
    ) {
        self.month = month
        self.day = day
        self.title = title
        self.rank = rank
        self.color = color
        self.isSolemnity = isSolemnity
        self.isHolyDayOfObligationInUS = isHolyDayOfObligationInUS
        self.isUSProper = isUSProper
        self.common = common
    }
}

/// Represents a solemnity transferred to another date due to collision with a higher-ranking liturgical day.
public struct TransferredCelebration: Sendable, Hashable {
    /// The fixed celebration that is being transferred.
    public let celebration: FixedCelebration

    /// The original canonical date (month and day).
    public let originalMonth: Int
    public let originalDay: Int

    /// The actual target date for this year.
    public let targetDate: Date

    /// Canonical reason for the transfer (e.g. "Transferred from March 25 due to Holy Week and Easter Octave").
    public let transferReason: String

    public init(
        celebration: FixedCelebration,
        originalMonth: Int,
        originalDay: Int,
        targetDate: Date,
        transferReason: String
    ) {
        self.celebration = celebration
        self.originalMonth = originalMonth
        self.originalDay = originalDay
        self.targetDate = targetDate
        self.transferReason = transferReason
    }
}

/// Defines all fixed-date solemnities, feasts, and memorials of the General Roman Calendar
/// and the Proper Calendar for the Dioceses of the United States, along with the canonical
/// collision and transfer rules established by the Universal Norms for the Liturgical Year.
public struct FixedSolemnities: Sendable {

    // MARK: - The Ten Fixed-Date Solemnities

    /// 1. Solemnity of Mary, The Holy Mother of God (January 1) - Octave Day of the Nativity
    public static let maryMotherOfGod = FixedCelebration(
        month: 1, day: 1,
        title: "Solemnity of Mary, The Holy Mother of God",
        rank: .generalSolemnity,
        color: .white,
        isSolemnity: true,
        isHolyDayOfObligationInUS: true
    )

    /// 2. Epiphany of the Lord (January 6)
    /// In the Universal Calendar, January 6; in the United States, assigned to the Sunday between January 2 and 8.
    public static let epiphanyUniversal = FixedCelebration(
        month: 1, day: 6,
        title: "The Epiphany of the Lord",
        rank: .primarySolemnity,
        color: .white,
        isSolemnity: true,
        isHolyDayOfObligationInUS: true
    )

    /// 3. Solemnity of Saint Joseph, Spouse of the Blessed Virgin Mary (March 19)
    public static let saintJoseph = FixedCelebration(
        month: 3, day: 19,
        title: "Solemnity of Saint Joseph, Spouse of the Blessed Virgin Mary",
        rank: .generalSolemnity,
        color: .white,
        isSolemnity: true,
        isHolyDayOfObligationInUS: false
    )

    /// 4. Solemnity of the Annunciation of the Lord (March 25)
    public static let theAnnunciation = FixedCelebration(
        month: 3, day: 25,
        title: "Solemnity of the Annunciation of the Lord",
        rank: .generalSolemnity,
        color: .white,
        isSolemnity: true,
        isHolyDayOfObligationInUS: false
    )

    /// 5. Solemnity of the Nativity of Saint John the Baptist (June 24)
    public static let nativityOfJohnTheBaptist = FixedCelebration(
        month: 6, day: 24,
        title: "Solemnity of the Nativity of Saint John the Baptist",
        rank: .generalSolemnity,
        color: .white,
        isSolemnity: true,
        isHolyDayOfObligationInUS: false
    )

    /// 6. Solemnity of Saints Peter and Paul, Apostles (June 29)
    public static let saintsPeterAndPaul = FixedCelebration(
        month: 6, day: 29,
        title: "Solemnity of Saints Peter and Paul, Apostles",
        rank: .generalSolemnity,
        color: .red,
        isSolemnity: true,
        isHolyDayOfObligationInUS: false
    )

    /// 7. Solemnity of the Assumption of the Blessed Virgin Mary (August 15)
    public static let assumptionOfMary = FixedCelebration(
        month: 8, day: 15,
        title: "Solemnity of the Assumption of the Blessed Virgin Mary",
        rank: .generalSolemnity,
        color: .white,
        isSolemnity: true,
        isHolyDayOfObligationInUS: true
    )

    /// 8. Solemnity of All Saints (November 1)
    public static let allSaints = FixedCelebration(
        month: 11, day: 1,
        title: "Solemnity of All Saints",
        rank: .generalSolemnity,
        color: .white,
        isSolemnity: true,
        isHolyDayOfObligationInUS: true
    )

    /// 9. Solemnity of the Immaculate Conception of the Blessed Virgin Mary (December 8)
    /// Principal Patroness of the United States of America.
    public static let immaculateConception = FixedCelebration(
        month: 12, day: 8,
        title: "Solemnity of the Immaculate Conception of the Blessed Virgin Mary",
        rank: .generalSolemnity,
        color: .white,
        isSolemnity: true,
        isHolyDayOfObligationInUS: true
    )

    /// 10. Solemnity of the Nativity of the Lord / Christmas (December 25)
    public static let theNativityOfTheLord = FixedCelebration(
        month: 12, day: 25,
        title: "The Nativity of the Lord (Christmas)",
        rank: .primarySolemnity,
        color: .white,
        isSolemnity: true,
        isHolyDayOfObligationInUS: true
    )

    // MARK: - Key Fixed Feasts of the Lord

    public static let presentationOfTheLord = FixedCelebration(
        month: 2, day: 2,
        title: "The Presentation of the Lord (Candlemas)",
        rank: .feastOfLord,
        color: .white
    )

    public static let transfiguration = FixedCelebration(
        month: 8, day: 6,
        title: "The Transfiguration of the Lord",
        rank: .feastOfLord,
        color: .white
    )

    public static let exaltationOfTheHolyCross = FixedCelebration(
        month: 9, day: 14,
        title: "The Exaltation of the Holy Cross",
        rank: .feastOfLord,
        color: .red
    )

    public static let dedicationOfLateranBasilica = FixedCelebration(
        month: 11, day: 9,
        title: "The Dedication of the Lateran Basilica",
        rank: .feastOfLord,
        color: .white
    )

    // MARK: - Key Fixed Feasts of the Blessed Mother and Apostles

    public static let conversionOfSaintPaul = FixedCelebration(month: 1, day: 25, title: "The Conversion of Saint Paul, Apostle", rank: .feastGeneral, color: .white)
    public static let chairOfSaintPeter = FixedCelebration(month: 2, day: 22, title: "The Chair of Saint Peter, Apostle", rank: .feastGeneral, color: .white)
    public static let saintMark = FixedCelebration(month: 4, day: 25, title: "Saint Mark, Evangelist", rank: .feastGeneral, color: .red)
    public static let saintsPhilipAndJames = FixedCelebration(month: 5, day: 3, title: "Saints Philip and James, Apostles", rank: .feastGeneral, color: .red)
    public static let saintMatthias = FixedCelebration(month: 5, day: 14, title: "Saint Matthias, Apostle", rank: .feastGeneral, color: .red)
    public static let visitationOfMary = FixedCelebration(month: 5, day: 31, title: "The Visitation of the Blessed Virgin Mary", rank: .feastGeneral, color: .white)
    public static let saintThomasApostle = FixedCelebration(month: 7, day: 3, title: "Saint Thomas, Apostle", rank: .feastGeneral, color: .red)
    public static let saintMaryMagdalene = FixedCelebration(month: 7, day: 22, title: "Saint Mary Magdalene", rank: .feastGeneral, color: .white)
    public static let saintJamesApostle = FixedCelebration(month: 7, day: 25, title: "Saint James, Apostle", rank: .feastGeneral, color: .red)
    public static let saintLawrence = FixedCelebration(month: 8, day: 10, title: "Saint Lawrence, Deacon and Martyr", rank: .feastGeneral, color: .red)
    public static let saintBartholomew = FixedCelebration(month: 8, day: 24, title: "Saint Bartholomew, Apostle", rank: .feastGeneral, color: .red)
    public static let nativityOfMary = FixedCelebration(month: 9, day: 8, title: "The Nativity of the Blessed Virgin Mary", rank: .feastGeneral, color: .white)
    public static let saintMatthew = FixedCelebration(month: 9, day: 21, title: "Saint Matthew, Apostle and Evangelist", rank: .feastGeneral, color: .red)
    public static let saintsMichaelGabrielRaphael = FixedCelebration(month: 9, day: 29, title: "Saints Michael, Gabriel, and Raphael, Archangels", rank: .feastGeneral, color: .white)
    public static let saintLuke = FixedCelebration(month: 10, day: 18, title: "Saint Luke, Evangelist", rank: .feastGeneral, color: .red)
    public static let saintsSimonAndJude = FixedCelebration(month: 10, day: 28, title: "Saints Simon and Jude, Apostles", rank: .feastGeneral, color: .red)
    public static let allSouls = FixedCelebration(month: 11, day: 2, title: "The Commemoration of All the Faithful Departed (All Souls' Day)", rank: .generalSolemnity, color: .violet)
    public static let saintAndrew = FixedCelebration(month: 11, day: 30, title: "Saint Andrew, Apostle", rank: .feastGeneral, color: .red)
    public static let saintStephen = FixedCelebration(month: 12, day: 26, title: "Saint Stephen, The First Martyr", rank: .feastGeneral, color: .red)
    public static let saintJohnEvangelist = FixedCelebration(month: 12, day: 27, title: "Saint John, Apostle and Evangelist", rank: .feastGeneral, color: .white)
    public static let holyInnocents = FixedCelebration(month: 12, day: 28, title: "The Holy Innocents, Martyrs", rank: .feastGeneral, color: .red)

    // MARK: - United States Proper Calendar Celebrations

    public static let saintElizabethAnnSeton = FixedCelebration(month: 1, day: 4, title: "Saint Elizabeth Ann Seton, Religious", rank: .obligatoryMemorial, color: .white, isUSProper: true)
    public static let saintJohnNeumann = FixedCelebration(month: 1, day: 5, title: "Saint John Neumann, Bishop", rank: .obligatoryMemorial, color: .white, isUSProper: true)
    public static let saintAndreBessette = FixedCelebration(month: 1, day: 6, title: "Saint André Bessette, Religious", rank: .optionalMemorial, color: .white, isUSProper: true)
    public static let saintMarianneCope = FixedCelebration(month: 1, day: 23, title: "Saint Marianne Cope, Virgin", rank: .optionalMemorial, color: .white, isUSProper: true)
    public static let saintKatharineDrexel = FixedCelebration(month: 3, day: 3, title: "Saint Katharine Drexel, Virgin", rank: .optionalMemorial, color: .white, isUSProper: true)
    public static let saintDamienDeVeuster = FixedCelebration(month: 5, day: 10, title: "Saint Damien de Veuster, Priest", rank: .optionalMemorial, color: .white, isUSProper: true)
    public static let saintJuniperoSerra = FixedCelebration(month: 7, day: 1, title: "Saint Junípero Serra, Priest", rank: .optionalMemorial, color: .white, isUSProper: true)
    public static let saintKateriTekakwitha = FixedCelebration(month: 7, day: 14, title: "Saint Kateri Tekakwitha, Virgin", rank: .obligatoryMemorial, color: .white, isUSProper: true)
    public static let saintPeterClaver = FixedCelebration(month: 9, day: 9, title: "Saint Peter Claver, Priest", rank: .obligatoryMemorial, color: .white, isUSProper: true)
    public static let saintFrancesXavierCabrini = FixedCelebration(month: 11, day: 13, title: "Saint Frances Xavier Cabrini, Virgin", rank: .obligatoryMemorial, color: .white, isUSProper: true)
    public static let saintRosePhilippineDuchesne = FixedCelebration(month: 11, day: 18, title: "Saint Rose Philippine Duchesne, Virgin", rank: .optionalMemorial, color: .white, isUSProper: true)
    public static let blessedMiguelPro = FixedCelebration(month: 11, day: 23, title: "Blessed Miguel Agustín Pro, Priest and Martyr", rank: .optionalMemorial, color: .red, isUSProper: true)
    public static let saintJuanDiego = FixedCelebration(month: 12, day: 9, title: "Saint Juan Diego Cuauhtlatoatzin", rank: .optionalMemorial, color: .white, isUSProper: true)
    public static let ourLadyOfGuadalupe = FixedCelebration(month: 12, day: 12, title: "Our Lady of Guadalupe", rank: .feastGeneral, color: .white, isUSProper: true)

    // MARK: - Selected Obligatory Memorials

    public static let saintsBasilAndGregory = FixedCelebration(month: 1, day: 2, title: "Saints Basil the Great and Gregory Nazianzen, Bishops and Doctors", rank: .obligatoryMemorial, color: .white)
    public static let saintAnthonyAbbot = FixedCelebration(month: 1, day: 17, title: "Saint Anthony, Abbot", rank: .obligatoryMemorial, color: .white)
    public static let saintAgnes = FixedCelebration(month: 1, day: 21, title: "Saint Agnes, Virgin and Martyr", rank: .obligatoryMemorial, color: .red)
    public static let saintThomasAquinas = FixedCelebration(month: 1, day: 28, title: "Saint Thomas Aquinas, Priest and Doctor of the Church", rank: .obligatoryMemorial, color: .white)
    public static let saintAgatha = FixedCelebration(month: 2, day: 5, title: "Saint Agatha, Virgin and Martyr", rank: .obligatoryMemorial, color: .red)
    public static let saintPaulMiki = FixedCelebration(month: 2, day: 6, title: "Saint Paul Miki and Companions, Martyrs", rank: .obligatoryMemorial, color: .red)
    public static let saintScholastica = FixedCelebration(month: 2, day: 10, title: "Saint Scholastica, Virgin", rank: .obligatoryMemorial, color: .white)
    public static let saintsCyrilAndMethodius = FixedCelebration(month: 2, day: 14, title: "Saints Cyril, Monk, and Methodius, Bishop", rank: .obligatoryMemorial, color: .white)
    public static let saintPolycarp = FixedCelebration(month: 2, day: 23, title: "Saint Polycarp, Bishop and Martyr", rank: .obligatoryMemorial, color: .red)
    public static let saintCatherineOfSiena = FixedCelebration(month: 4, day: 29, title: "Saint Catherine of Siena, Virgin and Doctor of the Church", rank: .obligatoryMemorial, color: .white)
    public static let saintAthanasius = FixedCelebration(month: 5, day: 2, title: "Saint Athanasius, Bishop and Doctor of the Church", rank: .obligatoryMemorial, color: .white)
    public static let saintPhilipNeri = FixedCelebration(month: 5, day: 26, title: "Saint Philip Neri, Priest", rank: .obligatoryMemorial, color: .white)
    public static let saintJustinMartyr = FixedCelebration(month: 6, day: 1, title: "Saint Justin, Martyr", rank: .obligatoryMemorial, color: .red)
    public static let saintCharlesLwanga = FixedCelebration(month: 6, day: 3, title: "Saint Charles Lwanga and Companions, Martyrs", rank: .obligatoryMemorial, color: .red)
    public static let saintBoniface = FixedCelebration(month: 6, day: 5, title: "Saint Boniface, Bishop and Martyr", rank: .obligatoryMemorial, color: .red)
    public static let saintBarnabas = FixedCelebration(month: 6, day: 11, title: "Saint Barnabas, Apostle", rank: .obligatoryMemorial, color: .red)
    public static let saintAnthonyOfPadua = FixedCelebration(month: 6, day: 13, title: "Saint Anthony of Padua, Priest and Doctor of the Church", rank: .obligatoryMemorial, color: .white)
    public static let saintAloysiusGonzaga = FixedCelebration(month: 6, day: 21, title: "Saint Aloysius Gonzaga, Religious", rank: .obligatoryMemorial, color: .white)
    public static let saintIrenaeus = FixedCelebration(month: 6, day: 28, title: "Saint Irenaeus, Bishop, Martyr, and Doctor of the Church", rank: .obligatoryMemorial, color: .red)
    public static let saintBenedict = FixedCelebration(month: 7, day: 11, title: "Saint Benedict, Abbot", rank: .obligatoryMemorial, color: .white)
    public static let saintBonaventure = FixedCelebration(month: 7, day: 15, title: "Saint Bonaventure, Bishop and Doctor of the Church", rank: .obligatoryMemorial, color: .white)
    public static let saintsJoachimAndAnne = FixedCelebration(month: 7, day: 26, title: "Saints Joachim and Anne, Parents of the Blessed Virgin Mary", rank: .obligatoryMemorial, color: .white)
    public static let saintsMarthaMaryLazarus = FixedCelebration(month: 7, day: 29, title: "Saints Martha, Mary and Lazarus", rank: .obligatoryMemorial, color: .white)
    public static let saintIgnatiusOfLoyola = FixedCelebration(month: 7, day: 31, title: "Saint Ignatius of Loyola, Priest", rank: .obligatoryMemorial, color: .white)
    public static let saintAlphonsusLiguori = FixedCelebration(month: 8, day: 1, title: "Saint Alphonsus Liguori, Bishop and Doctor of the Church", rank: .obligatoryMemorial, color: .white)
    public static let saintJohnVianney = FixedCelebration(month: 8, day: 4, title: "Saint John Vianney, Priest", rank: .obligatoryMemorial, color: .white)
    public static let saintDominic = FixedCelebration(month: 8, day: 8, title: "Saint Dominic, Priest", rank: .obligatoryMemorial, color: .white)
    public static let saintClare = FixedCelebration(month: 8, day: 11, title: "Saint Clare, Virgin", rank: .obligatoryMemorial, color: .white)
    public static let saintMaximilianKolbe = FixedCelebration(month: 8, day: 14, title: "Saint Maximilian Mary Kolbe, Priest and Martyr", rank: .obligatoryMemorial, color: .red)
    public static let saintBernard = FixedCelebration(month: 8, day: 20, title: "Saint Bernard, Abbot and Doctor of the Church", rank: .obligatoryMemorial, color: .white)
    public static let saintPiusX = FixedCelebration(month: 8, day: 21, title: "Saint Pius X, Pope", rank: .obligatoryMemorial, color: .white)
    public static let queenshipOfMary = FixedCelebration(month: 8, day: 22, title: "The Queenship of the Blessed Virgin Mary", rank: .obligatoryMemorial, color: .white)
    public static let saintMonica = FixedCelebration(month: 8, day: 27, title: "Saint Monica", rank: .obligatoryMemorial, color: .white)
    public static let saintAugustine = FixedCelebration(month: 8, day: 28, title: "Saint Augustine, Bishop and Doctor of the Church", rank: .obligatoryMemorial, color: .white)
    public static let passionOfJohnTheBaptist = FixedCelebration(month: 8, day: 29, title: "The Passion of Saint John the Baptist", rank: .obligatoryMemorial, color: .red)
    public static let saintGregoryTheGreat = FixedCelebration(month: 9, day: 3, title: "Saint Gregory the Great, Pope and Doctor of the Church", rank: .obligatoryMemorial, color: .white)
    public static let saintJohnChrysostom = FixedCelebration(month: 9, day: 13, title: "Saint John Chrysostom, Bishop and Doctor of the Church", rank: .obligatoryMemorial, color: .white)
    public static let ourLadyOfSorrows = FixedCelebration(month: 9, day: 15, title: "Our Lady of Sorrows", rank: .obligatoryMemorial, color: .white)
    public static let saintsCorneliusAndCyprian = FixedCelebration(month: 9, day: 16, title: "Saints Cornelius, Pope, and Cyprian, Bishop, Martyrs", rank: .obligatoryMemorial, color: .red)
    public static let saintVincentDePaul = FixedCelebration(month: 9, day: 27, title: "Saint Vincent de Paul, Priest", rank: .obligatoryMemorial, color: .white)
    public static let saintJerome = FixedCelebration(month: 9, day: 30, title: "Saint Jerome, Priest and Doctor of the Church", rank: .obligatoryMemorial, color: .white)
    public static let saintThereseOfLisieux = FixedCelebration(month: 10, day: 1, title: "Saint Thérèse of the Child Jesus, Virgin and Doctor of the Church", rank: .obligatoryMemorial, color: .white)
    public static let holyGuardianAngels = FixedCelebration(month: 10, day: 2, title: "The Holy Guardian Angels", rank: .obligatoryMemorial, color: .white)
    public static let saintFrancisOfAssisi = FixedCelebration(month: 10, day: 4, title: "Saint Francis of Assisi", rank: .obligatoryMemorial, color: .white)
    public static let ourLadyOfTheRosary = FixedCelebration(month: 10, day: 7, title: "Our Lady of the Rosary", rank: .obligatoryMemorial, color: .white)
    public static let saintTeresaOfAvila = FixedCelebration(month: 10, day: 15, title: "Saint Teresa of Jesus, Virgin and Doctor of the Church", rank: .obligatoryMemorial, color: .white)
    public static let saintIgnatiusOfAntioch = FixedCelebration(month: 10, day: 17, title: "Saint Ignatius of Antioch, Bishop and Martyr", rank: .obligatoryMemorial, color: .red)
    public static let saintCharlesBorromeo = FixedCelebration(month: 11, day: 4, title: "Saint Charles Borromeo, Bishop", rank: .obligatoryMemorial, color: .white)
    public static let saintLeoTheGreat = FixedCelebration(month: 11, day: 10, title: "Saint Leo the Great, Pope and Doctor of the Church", rank: .obligatoryMemorial, color: .white)
    public static let saintMartinOfTours = FixedCelebration(month: 11, day: 11, title: "Saint Martin of Tours, Bishop", rank: .obligatoryMemorial, color: .white)
    public static let saintJosaphat = FixedCelebration(month: 11, day: 12, title: "Saint Josaphat, Bishop and Martyr", rank: .obligatoryMemorial, color: .red)
    public static let saintElizabethOfHungary = FixedCelebration(month: 11, day: 17, title: "Saint Elizabeth of Hungary, Religious", rank: .obligatoryMemorial, color: .white)
    public static let presentationOfMary = FixedCelebration(month: 11, day: 21, title: "The Presentation of the Blessed Virgin Mary", rank: .obligatoryMemorial, color: .white)
    public static let saintCecilia = FixedCelebration(month: 11, day: 22, title: "Saint Cecilia, Virgin and Martyr", rank: .obligatoryMemorial, color: .red)
    public static let saintAndrewDungLac = FixedCelebration(month: 11, day: 24, title: "Saint Andrew Dũng-Lạc, Priest, and Companions, Martyrs", rank: .obligatoryMemorial, color: .red)
    public static let saintFrancisXavier = FixedCelebration(month: 12, day: 3, title: "Saint Francis Xavier, Priest", rank: .obligatoryMemorial, color: .white)
    public static let saintAmbrose = FixedCelebration(month: 12, day: 7, title: "Saint Ambrose, Bishop and Doctor of the Church", rank: .obligatoryMemorial, color: .white)
    public static let saintLucy = FixedCelebration(month: 12, day: 13, title: "Saint Lucy, Virgin and Martyr", rank: .obligatoryMemorial, color: .red)
    public static let saintJohnOfTheCross = FixedCelebration(month: 12, day: 14, title: "Saint John of the Cross, Priest and Doctor of the Church", rank: .obligatoryMemorial, color: .white)

    // MARK: - Master Collection

    /// All fixed celebrations catalogued by `(month, day)`.
    public static let celebrationsByMonthAndDay: [CelebrationKey: [FixedCelebration]] = {
        let all: [FixedCelebration] = [
            // Note: In the US Calendar, Epiphany is transferred to the Sunday between Jan 2 and Jan 8,
            // so epiphanyUniversal (Jan 6) is omitted from fixed celebrations to prevent duplicate celebration.
            maryMotherOfGod, saintJoseph, theAnnunciation, nativityOfJohnTheBaptist,
            saintsPeterAndPaul, assumptionOfMary, allSaints, immaculateConception, theNativityOfTheLord,
            presentationOfTheLord, transfiguration, exaltationOfTheHolyCross, dedicationOfLateranBasilica,
            conversionOfSaintPaul, chairOfSaintPeter, saintMark, saintsPhilipAndJames, saintMatthias,
            visitationOfMary, saintThomasApostle, saintMaryMagdalene, saintJamesApostle, saintLawrence,
            saintBartholomew, nativityOfMary, saintMatthew, saintsMichaelGabrielRaphael, saintLuke,
            saintsSimonAndJude, allSouls, saintAndrew, saintStephen, saintJohnEvangelist, holyInnocents,
            saintElizabethAnnSeton, saintJohnNeumann, saintAndreBessette, saintMarianneCope,
            saintKatharineDrexel, saintDamienDeVeuster, saintJuniperoSerra, saintKateriTekakwitha,
            saintPeterClaver, saintFrancesXavierCabrini, saintRosePhilippineDuchesne, blessedMiguelPro,
            saintJuanDiego, ourLadyOfGuadalupe,
            saintsBasilAndGregory, saintAnthonyAbbot, saintAgnes, saintThomasAquinas, saintAgatha,
            saintPaulMiki, saintScholastica, saintsCyrilAndMethodius, saintPolycarp, saintCatherineOfSiena,
            saintAthanasius, saintPhilipNeri, saintJustinMartyr, saintCharlesLwanga, saintBoniface,
            saintBarnabas, saintAnthonyOfPadua, saintAloysiusGonzaga, saintIrenaeus, saintBenedict,
            saintBonaventure, saintsJoachimAndAnne, saintsMarthaMaryLazarus, saintIgnatiusOfLoyola,
            saintAlphonsusLiguori, saintJohnVianney, saintDominic, saintClare, saintMaximilianKolbe,
            saintBernard, saintPiusX, queenshipOfMary, saintMonica, saintAugustine, passionOfJohnTheBaptist,
            saintGregoryTheGreat, saintJohnChrysostom, ourLadyOfSorrows, saintsCorneliusAndCyprian,
            saintVincentDePaul, saintJerome, saintThereseOfLisieux, holyGuardianAngels, saintFrancisOfAssisi,
            ourLadyOfTheRosary, saintTeresaOfAvila, saintIgnatiusOfAntioch, saintCharlesBorromeo,
            saintLeoTheGreat, saintMartinOfTours, saintJosaphat, saintElizabethOfHungary, presentationOfMary,
            saintCecilia, saintAndrewDungLac, saintFrancisXavier, saintAmbrose, saintLucy, saintJohnOfTheCross
        ]

        var dict: [CelebrationKey: [FixedCelebration]] = [:]
        for c in all {
            let key = CelebrationKey(month: c.month, day: c.day)
            dict[key, default: []].append(c)
        }
        return dict
    }()

    public struct CelebrationKey: Hashable, Sendable {
        public let month: Int
        public let day: Int

        public init(month: Int, day: Int) {
            self.month = month
            self.day = day
        }
    }

    // MARK: - Collision and Transfer Engine

    /// Calculates any transferred solemnities for a given civil year according to the Universal Norms for the Liturgical Year.
    ///
    /// The canonical transfer rules implemented:
    /// 1. **Immaculate Conception (December 8):**
    ///    - When Dec 8 falls on a Sunday of Advent (Rank 2), the solemnity is transferred to Monday, December 9.
    /// 2. **Saint Joseph (March 19):**
    ///    - If March 19 falls during Holy Week (Palm Sunday through Holy Saturday), it is transferred to the Saturday before Palm Sunday (UNLY §56f).
    ///    - If March 19 falls on a Sunday of Lent (outside Holy Week), it is transferred to Monday, March 20.
    /// 3. **The Annunciation of the Lord (March 25):**
    ///    - If March 25 falls during Holy Week or the Octave of Easter (both Rank 2), it is transferred to the Monday after the Second Sunday of Easter (Monday after Divine Mercy Sunday).
    ///    - If March 25 falls on a Sunday of Lent (outside Holy Week), it is transferred to Monday, March 26.
    ///
    /// - Parameters:
    ///   - year: The Gregorian year.
    ///   - easterDate: The calculated Easter Sunday `Date` for that year.
    ///   - firstSundayOfAdvent: The calculated First Sunday of Advent `Date` for that year.
    ///   - calendar: The `Calendar` to resolve dates.
    /// - Returns: An array of `TransferredCelebration` instances detailing any transferred solemnities.
    public static func computeTransferredCelebrations(
        year: Int,
        easterDate: Date,
        firstSundayOfAdvent: Date,
        calendar: Calendar
    ) -> [TransferredCelebration] {
        var transfers: [TransferredCelebration] = []

        var gmtCal = Calendar(identifier: .gregorian)
        gmtCal.timeZone = TimeZone(secondsFromGMT: 0) ?? .current

        // 1. Saint Joseph (March 19)
        let stJosephDate = makeDate(year: year, month: 3, day: 19, calendar: gmtCal)
        let palmSunday = gmtCal.date(byAdding: .day, value: -7, to: easterDate)!
        let holySaturday = gmtCal.date(byAdding: .day, value: -1, to: easterDate)!
        let stJosephWeekday = gmtCal.component(.weekday, from: stJosephDate) // 1 = Sunday

        if stJosephDate >= palmSunday && stJosephDate <= holySaturday {
            // Falls in Holy Week -> Transferred to Saturday before Palm Sunday
            let saturdayBeforePalm = gmtCal.date(byAdding: .day, value: -8, to: easterDate)!
            transfers.append(TransferredCelebration(
                celebration: saintJoseph,
                originalMonth: 3,
                originalDay: 19,
                targetDate: saturdayBeforePalm,
                transferReason: "Transferred from March 19 to Saturday before Palm Sunday because it coincided with Holy Week (UNLY §56f)."
            ))
        } else if stJosephWeekday == 1 {
            // Falls on a Sunday of Lent -> Transferred to Monday March 20
            let mondayMar20 = gmtCal.date(byAdding: .day, value: 1, to: stJosephDate)!
            transfers.append(TransferredCelebration(
                celebration: saintJoseph,
                originalMonth: 3,
                originalDay: 19,
                targetDate: mondayMar20,
                transferReason: "Transferred from March 19 to Monday March 20 because it coincided with a Sunday of Lent."
            ))
        }

        // 2. Annunciation of the Lord (March 25)
        let annunciationDate = makeDate(year: year, month: 3, day: 25, calendar: gmtCal)
        let divineMercySunday = gmtCal.date(byAdding: .day, value: 7, to: easterDate)!
        let annunciationWeekday = gmtCal.component(.weekday, from: annunciationDate)

        if annunciationDate >= palmSunday && annunciationDate <= divineMercySunday {
            // Falls in Holy Week or Easter Octave -> Transferred to Monday after Second Sunday of Easter
            let mondayAfterDivineMercy = gmtCal.date(byAdding: .day, value: 8, to: easterDate)!
            transfers.append(TransferredCelebration(
                celebration: theAnnunciation,
                originalMonth: 3,
                originalDay: 25,
                targetDate: mondayAfterDivineMercy,
                transferReason: "Transferred from March 25 to Monday after the Second Sunday of Easter because it coincided with Holy Week or the Easter Octave (UNLY §56f)."
            ))
        } else if annunciationWeekday == 1 {
            // Falls on a Sunday of Lent outside Holy Week -> Transferred to Monday March 26
            let mondayMar26 = gmtCal.date(byAdding: .day, value: 1, to: annunciationDate)!
            transfers.append(TransferredCelebration(
                celebration: theAnnunciation,
                originalMonth: 3,
                originalDay: 25,
                targetDate: mondayMar26,
                transferReason: "Transferred from March 25 to Monday March 26 because it coincided with a Sunday of Lent."
            ))
        }

        // 3. Immaculate Conception (December 8)
        let immendDate = makeDate(year: year, month: 12, day: 8, calendar: gmtCal)
        let immacWeekday = gmtCal.component(.weekday, from: immendDate)
        if immacWeekday == 1 {
            // Dec 8 is a Sunday of Advent (Second Sunday of Advent) -> Transferred to Monday December 9
            let mondayDec9 = gmtCal.date(byAdding: .day, value: 1, to: immendDate)!
            transfers.append(TransferredCelebration(
                celebration: immaculateConception,
                originalMonth: 12,
                originalDay: 8,
                targetDate: mondayDec9,
                transferReason: "Transferred from December 8 to Monday December 9 because it coincided with the Second Sunday of Advent."
            ))
        }

        // 4. Nativity of Saint John the Baptist (June 24) colliding with Sacred Heart
        // UNLY §59 & Congregation for Divine Worship decree (Prot. N. 168/22):
        // Sacred Heart is a Solemnity of the Lord (Rank 3), whereas the Nativity of St. John the Baptist
        // is a Solemnity of a Saint (Rank 4). When they coincide on Friday, Sacred Heart takes precedence,
        // and the Nativity of Saint John the Baptist is transferred to the preceding Thursday, June 23.
        let johnBaptistDate = makeDate(year: year, month: 6, day: 24, calendar: gmtCal)
        let sacredHeartDate = Computus.sacredHeart(year: year)
        if gmtCal.isDate(johnBaptistDate, inSameDayAs: sacredHeartDate) {
            let thursdayJune23 = gmtCal.date(byAdding: .day, value: -1, to: johnBaptistDate)!
            transfers.append(TransferredCelebration(
                celebration: nativityOfJohnTheBaptist,
                originalMonth: 6,
                originalDay: 24,
                targetDate: thursdayJune23,
                transferReason: "Transferred from June 24 to June 23 because it coincided with the Solemnity of the Most Sacred Heart of Jesus (UNLY §59)."
            ))
        }

        return transfers
    }

    /// Helper to construct a normalized date at 12:00 UTC.
    public static func makeDate(year: Int, month: Int, day: Int, calendar: Calendar) -> Date {
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = day
        comps.hour = 12
        comps.minute = 0
        comps.second = 0
        comps.timeZone = TimeZone(secondsFromGMT: 0)
        return calendar.date(from: comps)!
    }
}
