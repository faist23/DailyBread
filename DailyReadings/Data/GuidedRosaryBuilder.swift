//
//  GuidedRosaryBuilder.swift
//  DailyReadings
//
//  Created for DailyReadings Catholic Daily Readings App.
//  iOS 17+ | Swift 6+
//

import Foundation

/// Builds the sequential step-by-step bead sequence for an interactive guided Holy Rosary.
public struct GuidedRosaryBuilder: Sendable {
    
    public static func buildSteps(for mysteryType: RosaryMysteryType) -> [GuidedRosaryStep] {
        var steps: [GuidedRosaryStep] = []
        var stepId = 1
        
        let decades = PrayersRepository.decades(for: mysteryType)
        
        let ourFatherText = """
        Our Father, who art in heaven, hallowed be thy name; thy kingdom come; thy will be done on earth as it is in heaven.

        Give us this day our daily bread; and forgive us our trespasses, as we forgive those who trespass against us; and lead us not into temptation, but deliver us from evil.

        Amen.
        """
        
        let hailMaryText = """
        Hail Mary, full of grace, the Lord is with thee; blessed art thou among women, and blessed is the fruit of thy womb, Jesus.

        Holy Mary, Mother of God, pray for us sinners, now and at the hour of our death.

        Amen.
        """
        
        let gloryBeText = """
        Glory be to the Father, and to the Son, and to the Holy Spirit.

        As it was in the beginning, is now, and ever shall be, world without end.

        Amen.
        """
        
        let fatimaPrayerText = """
        O my Jesus, forgive us our sins, save us from the fires of hell, lead all souls to Heaven, especially those most in need of Thy mercy.

        Amen.
        """
        
        // Step 1: Sign of the Cross
        steps.append(GuidedRosaryStep(
            id: stepId,
            beadPosition: "Opening Blessing",
            prayerName: "The Sign of the Cross",
            prayerText: """
            In the name of the Father, and of the Son, and of the Holy Spirit.

            Amen.
            """
        ))
        stepId += 1
        
        // Step 2: Apostles' Creed (at Crucifix)
        steps.append(GuidedRosaryStep(
            id: stepId,
            beadPosition: "At the Crucifix",
            prayerName: "The Apostles' Creed",
            prayerText: """
            I believe in God, the Father almighty, Creator of heaven and earth, and in Jesus Christ, his only Son, our Lord, who was conceived by the Holy Spirit, born of the Virgin Mary, suffered under Pontius Pilate, was crucified, died and was buried; he descended into hell; on the third day he rose again from the dead; he ascended into heaven, and is seated at the right hand of God the Father almighty; from there he will come to judge the living and the dead.

            I believe in the Holy Spirit, the holy catholic Church, the communion of saints, the forgiveness of sins, the resurrection of the body, and life everlasting.

            Amen.
            """
        ))
        stepId += 1
        
        // Step 3: Our Father (First Large Bead)
        steps.append(GuidedRosaryStep(
            id: stepId,
            beadPosition: "First Large Bead",
            prayerName: "The Lord's Prayer (Our Father)",
            prayerText: ourFatherText,
            meditation: "Prayed for the intentions of the Holy Father and the universal Church."
        ))
        stepId += 1
        
        // Steps 4-6: Three Hail Marys (for Faith, Hope, Charity)
        let initialVirtues = [
            ("First Small Bead", "For an increase in the theological virtue of Faith"),
            ("Second Small Bead", "For an increase in the theological virtue of Hope"),
            ("Third Small Bead", "For an increase in the theological virtue of Charity")
        ]
        
        for (pos, intention) in initialVirtues {
            steps.append(GuidedRosaryStep(
                id: stepId,
                beadPosition: pos,
                prayerName: "Hail Mary",
                prayerText: hailMaryText,
                meditation: intention
            ))
            stepId += 1
        }
        
        // Step 7: Glory Be & Fatima Prayer
        steps.append(GuidedRosaryStep(
            id: stepId,
            beadPosition: "On the Chain",
            prayerName: "Glory Be & Fatima Prayer",
            prayerText: "\(gloryBeText)\n\n\(fatimaPrayerText)"
        ))
        stepId += 1
        
        // Steps for each of the 5 Decades
        for (index, decade) in decades.enumerated() {
            let decadeNum = index + 1
            
            // Decade Announcement
            steps.append(GuidedRosaryStep(
                id: stepId,
                beadPosition: "Decade \(decadeNum) • Meditation",
                prayerName: decade.number,
                prayerText: """
                \(decade.title)

                Fruit of the Mystery: \(decade.fruitOfMystery)
                Scripture: \(decade.scriptureRef)

                \(decade.meditation)
                """,
                mysteryTitle: decade.title,
                fruitOfMystery: decade.fruitOfMystery,
                scriptureRef: decade.scriptureRef,
                meditation: decade.meditation,
                decadeNumber: decadeNum,
                beadIndex: nil
            ))
            stepId += 1
            
            // Our Father on large bead
            steps.append(GuidedRosaryStep(
                id: stepId,
                beadPosition: "Decade \(decadeNum) • Large Bead",
                prayerName: "Our Father",
                prayerText: ourFatherText,
                mysteryTitle: decade.title,
                fruitOfMystery: decade.fruitOfMystery,
                decadeNumber: decadeNum,
                beadIndex: nil
            ))
            stepId += 1
            
            // 10 Hail Marys
            for bead in 1...10 {
                steps.append(GuidedRosaryStep(
                    id: stepId,
                    beadPosition: "Decade \(decadeNum) • Bead \(bead) of 10",
                    prayerName: "Hail Mary (\(bead)/10)",
                    prayerText: hailMaryText,
                    mysteryTitle: decade.title,
                    fruitOfMystery: decade.fruitOfMystery,
                    meditation: decade.meditation,
                    decadeNumber: decadeNum,
                    beadIndex: bead
                ))
                stepId += 1
            }
            
            // Glory Be & Fatima Prayer at decade end
            steps.append(GuidedRosaryStep(
                id: stepId,
                beadPosition: "Decade \(decadeNum) • Conclusion",
                prayerName: "Glory Be & Fatima Prayer",
                prayerText: "\(gloryBeText)\n\n\(fatimaPrayerText)",
                mysteryTitle: decade.title,
                fruitOfMystery: decade.fruitOfMystery,
                decadeNumber: decadeNum,
                beadIndex: nil
            ))
            stepId += 1
        }
        
        // Concluding Prayers
        steps.append(GuidedRosaryStep(
            id: stepId,
            beadPosition: "Concluding Prayer",
            prayerName: "Hail, Holy Queen (Salve Regina)",
            prayerText: """
            Hail, holy Queen, Mother of mercy, our life, our sweetness, and our hope. To thee do we cry, poor banished children of Eve; to thee do we send up our sighs, mourning and weeping in this valley of tears.

            Turn then, most gracious advocate, thine eyes of mercy toward us, and after this our exile, show unto us the blessed fruit of thy womb, Jesus.

            O clement, O loving, O sweet Virgin Mary.

            ℣. Pray for us, O Holy Mother of God.
            ℟. That we may be made worthy of the promises of Christ.
            """
        ))
        stepId += 1
        
        steps.append(GuidedRosaryStep(
            id: stepId,
            beadPosition: "Final Blessing",
            prayerName: "Closing Rosary Prayer",
            prayerText: """
            O God, whose only begotten Son, by His life, death, and resurrection, has purchased for us the rewards of eternal life, grant, we beseech Thee, that meditating upon these mysteries of the Most Holy Rosary of the Blessed Virgin Mary, we may imitate what they contain and obtain what they promise, through the same Christ our Lord.

            Amen.

            In the name of the Father, and of the Son, and of the Holy Spirit. Amen.
            """
        ))
        
        return steps
    }
}
