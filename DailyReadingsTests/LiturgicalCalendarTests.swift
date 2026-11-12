//
//  LiturgicalCalendarTests.swift
//  DailyReadingsTests
//
//  Created for DailyReadings Tests.
//  iOS 17+ | Swift 6+
//

import XCTest
@testable import DailyReadings

final class LiturgicalCalendarTests: XCTestCase {
    
    private var calendar: Calendar!
    
    override func setUp() {
        super.setUp()
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        self.calendar = cal
    }
    
    private func makeDate(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = 12
        components.minute = 0
        components.second = 0
        return calendar.date(from: components)!
    }
    
    // MARK: - 1. Advent in November Tests
    
    func testFirstSundayOfAdvent2026InNovember() {
        // November 29, 2026 is the First Sunday of Advent for the 2027 Liturgical Year
        let date = makeDate(year: 2026, month: 11, day: 29)
        let day = LiturgicalCalendar.day(for: date, calendar: calendar)
        
        XCTAssertEqual(day.season, .advent, "Nov 29, 2026 must be in the Advent season")
        XCTAssertEqual(day.seasonWeek, 1, "Nov 29, 2026 must be the 1st week of Advent")
        XCTAssertEqual(day.color, .violet, "First Sunday of Advent must be violet")
        XCTAssertEqual(day.title, "First Sunday of Advent")
        XCTAssertEqual(day.rank, .primarySolemnity)
        XCTAssertEqual(day.sundayCycle, .B, "2026 Advent begins Year B (Liturgical Year 2027)")
    }
    
    func testAdventWeekdayInLateNovember2026() {
        // Monday, November 30, 2026 (St. Andrew Feast or Advent Weekday)
        let date = makeDate(year: 2026, month: 11, day: 30)
        let day = LiturgicalCalendar.day(for: date, calendar: calendar)
        
        XCTAssertEqual(day.season, .advent, "Nov 30, 2026 must be in Advent")
        XCTAssertEqual(day.seasonWeek, 1)
    }
    
    func testFirstSundayOfAdvent2027InNovember() {
        // November 28, 2027 is the First Sunday of Advent for the 2028 Liturgical Year
        let date = makeDate(year: 2027, month: 11, day: 28)
        let day = LiturgicalCalendar.day(for: date, calendar: calendar)
        
        XCTAssertEqual(day.season, .advent, "Nov 28, 2027 must be in Advent")
        XCTAssertEqual(day.seasonWeek, 1)
        XCTAssertEqual(day.color, .violet)
        XCTAssertEqual(day.title, "First Sunday of Advent")
        XCTAssertEqual(day.sundayCycle, .C, "2027 Advent begins Year C (Liturgical Year 2028)")
    }
    
    // MARK: - 2. Epiphany in the US Calendar (No duplicate on Jan 6)
    
    func testEpiphanyCelebratedOnSundayInUS() {
        // In 2027, the Sunday between Jan 2 and Jan 8 is January 3
        let sundayDate = makeDate(year: 2027, month: 1, day: 3)
        let epiphanyDay = LiturgicalCalendar.day(for: sundayDate, calendar: calendar)
        
        XCTAssertEqual(epiphanyDay.title, "The Epiphany of the Lord")
        XCTAssertEqual(epiphanyDay.color, .white)
        XCTAssertTrue(epiphanyDay.isSolemnity)
    }
    
    func testJanuary6IsNotDuplicateEpiphanyInUS() {
        // In 2027, Epiphany was celebrated on Jan 3. January 6 should NOT be Epiphany again.
        let jan6 = makeDate(year: 2027, month: 1, day: 6)
        let day = LiturgicalCalendar.day(for: jan6, calendar: calendar)
        
        XCTAssertNotEqual(day.title, "The Epiphany of the Lord", "Jan 6 must not repeat Epiphany when celebrated on Sunday in the US")
        XCTAssertEqual(day.season, .christmas)
    }
    
    // MARK: - 3. Lenten Friday Solemnity Abstinence Exemption (Canon 1251)
    
    func testStJosephSolemnityOnLentenFridayWaivesAbstinence() {
        // In 2027, March 19 (Solemnity of St. Joseph) falls on a Friday during Lent.
        // Canon 1251: Abstinence is to be observed on all Fridays, UNLESS a solemnity should fall on a Friday.
        let stJosephDate = makeDate(year: 2027, month: 3, day: 19)
        let day = LiturgicalCalendar.day(for: stJosephDate, calendar: calendar)
        
        XCTAssertTrue(day.title.contains("Saint Joseph"), "March 19 must be Saint Joseph")
        XCTAssertTrue(day.rank.isSolemnity, "Saint Joseph is a solemnity")
        XCTAssertFalse(day.isAbstinence, "Canon 1251: Friday abstinence is waived on a solemnity!")
    }
    
    func testOrdinaryLentenFridayRequiresAbstinence() {
        // Friday, March 12, 2027 is a regular Friday of Lent (no solemnity).
        let normalLentenFriday = makeDate(year: 2027, month: 3, day: 12)
        let day = LiturgicalCalendar.day(for: normalLentenFriday, calendar: calendar)
        
        XCTAssertEqual(day.season, .lent)
        XCTAssertTrue(day.isAbstinence, "Ordinary Friday of Lent requires abstinence from meat")
    }
    
    // MARK: - 4. Post-Pentecost Ordinary Time Week Continuity
    
    func testMaryMotherOfChurchMatchesResumedOrdinaryTimeWeek() {
        // In 2026, Pentecost is May 24.
        // Monday, May 25 is Memorial of the Blessed Virgin Mary, Mother of the Church.
        // Tuesday, May 26 is Weekday of the 8th Week in Ordinary Time.
        let mondayDate = makeDate(year: 2026, month: 5, day: 25)
        let tuesdayDate = makeDate(year: 2026, month: 5, day: 26)
        
        let mondayDay = LiturgicalCalendar.day(for: mondayDate, calendar: calendar)
        let tuesdayDay = LiturgicalCalendar.day(for: tuesdayDate, calendar: calendar)
        
        XCTAssertTrue(mondayDay.title.contains("Mother of the Church"))
        XCTAssertEqual(mondayDay.seasonWeek, tuesdayDay.seasonWeek, "Monday and Tuesday must have the same Ordinary Time week number for psalter continuity!")
        XCTAssertEqual(mondayDay.seasonWeek, 8, "In 2026, Ordinary Time resumes at Week 8")
    }
    
    // MARK: - 5. Solemnity Collision (Sacred Heart vs St. John the Baptist in 2033)
    
    func testSacredHeartAndStJohnTheBaptistCollision2033() {
        // In 2033, Easter is April 17, and Pentecost is June 5.
        // Sacred Heart falls on Friday, June 24, colliding with the Nativity of St. John the Baptist.
        // UNLY §59 / Roman Congregation norm: Sacred Heart (Solemnity of the Lord) stays on Friday June 24.
        // Nativity of St. John the Baptist transfers to Thursday, June 23.
        let june23 = makeDate(year: 2033, month: 6, day: 23)
        let june24 = makeDate(year: 2033, month: 6, day: 24)
        
        let day23 = LiturgicalCalendar.day(for: june23, calendar: calendar)
        let day24 = LiturgicalCalendar.day(for: june24, calendar: calendar)
        
        XCTAssertTrue(day24.title.contains("Sacred Heart"), "June 24, 2033 must celebrate the Sacred Heart of Jesus")
        XCTAssertTrue(day23.title.contains("John the Baptist"), "Nativity of St. John the Baptist must be transferred to June 23, 2033")
    }
}
