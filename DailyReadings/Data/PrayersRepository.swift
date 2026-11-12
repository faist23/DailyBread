//
//  PrayersRepository.swift
//  DailyReadings
//
//  Created for DailyReadings Catholic Daily Readings App.
//  iOS 17+ | Swift 6+
//

import Foundation

/// Repository providing traditional Roman Catholic prayers, devotions,
/// and interactive Holy Rosary meditations in both English and Latin.
public final class PrayersRepository: Sendable {
    
    public static let shared = PrayersRepository()
    
    // MARK: - Prayers Data
    
    public let allPrayers: [Prayer]
    
    public init() {
        self.allPrayers = Self.buildPrayersList()
    }
    
    // MARK: - Query APIs
    
    /// Returns prayers belonging to a given category (or all prayers if `.all`).
    public func prayers(for category: PrayerCategory) -> [Prayer] {
        if category == .all {
            return allPrayers
        }
        return allPrayers.filter { $0.category == category }
    }
    
    /// Searches prayers by title, Latin title, or keyword text.
    public func search(query: String) -> [Prayer] {
        let clean = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !clean.isEmpty else { return allPrayers }
        return allPrayers.filter {
            $0.title.lowercased().contains(clean) ||
            ($0.latinTitle?.lowercased().contains(clean) ?? false) ||
            $0.textEnglish.lowercased().contains(clean) ||
            ($0.source?.lowercased().contains(clean) ?? false)
        }
    }
    
    // MARK: - Holy Rosary Decades
    
    public static func decades(for type: RosaryMysteryType) -> [RosaryDecade] {
        switch type {
        case .joyful:
            return [
                RosaryDecade(
                    number: "1st Decade",
                    title: "The Annunciation",
                    fruitOfMystery: "Humility",
                    scriptureRef: "Luke 1:26-38",
                    meditation: "The Angel Gabriel announces to Mary that she will conceive the Son of God. Mary responds: 'Behold the handmaid of the Lord; be it done unto me according to thy word.'"
                ),
                RosaryDecade(
                    number: "2nd Decade",
                    title: "The Visitation",
                    fruitOfMystery: "Love of Neighbor",
                    scriptureRef: "Luke 1:39-56",
                    meditation: "Mary visits her cousin Elizabeth. At Mary’s greeting, John the Baptist leaps in Elizabeth’s womb, and Elizabeth proclaims: 'Blessed are you among women!'"
                ),
                RosaryDecade(
                    number: "3rd Decade",
                    title: "The Nativity",
                    fruitOfMystery: "Poverty of Spirit",
                    scriptureRef: "Luke 2:1-20",
                    meditation: "Jesus Christ is born in a humble stable in Bethlehem. Angels sing 'Glory to God in the highest,' and shepherds come in adoration."
                ),
                RosaryDecade(
                    number: "4th Decade",
                    title: "The Presentation",
                    fruitOfMystery: "Purity & Obedience",
                    scriptureRef: "Luke 2:22-38",
                    meditation: "Mary and Joseph present the child Jesus in the Temple. Simeon takes the Lord in his arms and proclaims Him 'a light for revelation to the Gentiles.'"
                ),
                RosaryDecade(
                    number: "5th Decade",
                    title: "The Finding in the Temple",
                    fruitOfMystery: "Piety & Joy in Finding Jesus",
                    scriptureRef: "Luke 2:41-52",
                    meditation: "After three days of sorrowful searching, Mary and Joseph find the boy Jesus in the Temple, seated among the teachers, listening and asking questions."
                )
            ]
            
        case .luminous:
            return [
                RosaryDecade(
                    number: "1st Decade",
                    title: "The Baptism in the Jordan",
                    fruitOfMystery: "Openness to the Holy Spirit",
                    scriptureRef: "Matthew 3:13-17",
                    meditation: "Jesus is baptized by John. The heavens open, the Holy Spirit descends like a dove, and the Father proclaims: 'This is my beloved Son, with whom I am well pleased.'"
                ),
                RosaryDecade(
                    number: "2nd Decade",
                    title: "The Wedding at Cana",
                    fruitOfMystery: "To Jesus through Mary",
                    scriptureRef: "John 2:1-12",
                    meditation: "At Mary’s request ('Do whatever he tells you'), Christ performs His first sign, turning water into wine and revealing His glory."
                ),
                RosaryDecade(
                    number: "3rd Decade",
                    title: "The Proclamation of the Kingdom",
                    fruitOfMystery: "Repentance & Trust in God",
                    scriptureRef: "Mark 1:14-15",
                    meditation: "Jesus proclaims the Good News of God: 'The time is fulfilled, and the kingdom of God is at hand; repent, and believe in the Gospel.'"
                ),
                RosaryDecade(
                    number: "4th Decade",
                    title: "The Transfiguration",
                    fruitOfMystery: "Desire for Holiness",
                    scriptureRef: "Matthew 17:1-8",
                    meditation: "On Mount Tabor, Jesus is transfigured before Peter, James, and John. His face shines like the sun, and the voice of the Father commands: 'Listen to him!'"
                ),
                RosaryDecade(
                    number: "5th Decade",
                    title: "The Institution of the Eucharist",
                    fruitOfMystery: "Eucharistic Adoration",
                    scriptureRef: "Luke 22:14-20",
                    meditation: "At the Last Supper, Christ offers His Body and Blood under the signs of bread and wine, instituting the Sacrament of the Holy Eucharist: 'Do this in memory of me.'"
                )
            ]
            
        case .sorrowful:
            return [
                RosaryDecade(
                    number: "1st Decade",
                    title: "The Agony in the Garden",
                    fruitOfMystery: "Sorrow for Sin & Conformity to God's Will",
                    scriptureRef: "Luke 22:39-46",
                    meditation: "In the Garden of Gethsemane, Jesus prays in anguish, His sweat falling like great drops of blood: 'Father, if you are willing, remove this chalice; yet not my will, but yours be done.'"
                ),
                RosaryDecade(
                    number: "2nd Decade",
                    title: "The Scourging at the Pillar",
                    fruitOfMystery: "Mortification & Purity",
                    scriptureRef: "John 19:1",
                    meditation: "Pilate orders Jesus to be scourged. The spotless Lamb of God endures the brutal lashes of the soldiers to atone for our sins of the flesh."
                ),
                RosaryDecade(
                    number: "3rd Decade",
                    title: "The Crowning with Thorns",
                    fruitOfMystery: "Moral Courage & Humility",
                    scriptureRef: "Matthew 27:27-31",
                    meditation: "Soldiers twist a crown of sharp thorns and press it onto Christ's head, placing a reed in His hand and mocking Him: 'Hail, King of the Jews!'"
                ),
                RosaryDecade(
                    number: "4th Decade",
                    title: "The Carrying of the Cross",
                    fruitOfMystery: "Patience in Bearing Crosses",
                    scriptureRef: "John 19:16-17",
                    meditation: "Jesus takes up the heavy wood of the Cross and walks the sorrowful Way to Calvary, meeting His sorrowful Mother along the path."
                ),
                RosaryDecade(
                    number: "5th Decade",
                    title: "The Crucifixion and Death",
                    fruitOfMystery: "Self-Giving Love & Forgiveness",
                    scriptureRef: "Luke 23:33-46",
                    meditation: "Nailed to the Cross, Jesus forgives His executioners, gives Mary to us as our Mother, and breathes His last: 'Father, into your hands I commend my spirit.'"
                )
            ]
            
        case .glorious:
            return [
                RosaryDecade(
                    number: "1st Decade",
                    title: "The Resurrection",
                    fruitOfMystery: "Faith & Spiritual Joy",
                    scriptureRef: "Mark 16:1-8",
                    meditation: "On the third day, Christ triumphs over sin and death, rising gloriously from the tomb as He promised. Alleluia!"
                ),
                RosaryDecade(
                    number: "2nd Decade",
                    title: "The Ascension",
                    fruitOfMystery: "Hope & Desire for Heaven",
                    scriptureRef: "Acts 1:6-11",
                    meditation: "Forty days after Easter, in the presence of the Apostles, Jesus ascends into Heaven and is seated at the right hand of the Father."
                ),
                RosaryDecade(
                    number: "3rd Decade",
                    title: "The Descent of the Holy Spirit",
                    fruitOfMystery: "Zeal for the Gospel & Wisdom",
                    scriptureRef: "Acts 2:1-13",
                    meditation: "On Pentecost, the Holy Spirit descends upon the Apostles gathered with Mary in the Upper Room in tongues as of fire, filling them with courage to preach to the world."
                ),
                RosaryDecade(
                    number: "4th Decade",
                    title: "The Assumption of Mary",
                    fruitOfMystery: "Grace of a Happy Death",
                    scriptureRef: "Revelation 12:1",
                    meditation: "At the end of her earthly life, the Blessed Virgin Mary is assumed body and soul into heavenly glory, anticipating the resurrection of all the faithful."
                ),
                RosaryDecade(
                    number: "5th Decade",
                    title: "The Coronation of Mary",
                    fruitOfMystery: "Trust in Mary's Intercession",
                    scriptureRef: "Revelation 12:1",
                    meditation: "Mary is crowned Queen of Heaven and Earth by her Divine Son, shining as the Queen of Angels and Saints, our merciful Advocate."
                )
            ]
        }
    }
    
    // MARK: - Master Prayer Treasury
    
    private static func buildPrayersList() -> [Prayer] {
        return [
            // ==========================================
            // 1. DAILY RHYTHM
            // ==========================================
            Prayer(
                id: "morning-offering",
                title: "Morning Offering",
                category: .daily,
                textEnglish: """
                O Jesus, through the Immaculate Heart of Mary, I offer you my prayers, works, joys, and sufferings of this day, for all the intentions of your Sacred Heart, in union with the Holy Sacrifice of the Mass throughout the world, for the salvation of souls, the reparation of sins, the reunion of all Christians, and in particular for the intentions of the Holy Father this month.

                Amen.
                """,
                source: "Apostleship of Prayer (Fr. François-Xavier Gautrelet, S.J.)",
                rubricNote: "Traditionally recited upon waking to consecrate the whole day to God."
            ),
            
            Prayer(
                id: "the-angelus",
                title: "The Angelus",
                latinTitle: "Angelus Domini",
                category: .daily,
                textEnglish: """
                ℣. The Angel of the Lord declared unto Mary.
                ℟. And she conceived of the Holy Spirit.

                Hail Mary, full of grace, the Lord is with thee; blessed art thou among women, and blessed is the fruit of thy womb, Jesus. Holy Mary, Mother of God, pray for us sinners, now and at the hour of our death. Amen.

                ℣. Behold the handmaid of the Lord.
                ℟. Be it done unto me according to thy word.

                Hail Mary...

                ℣. And the Word was made flesh.
                ℟. And dwelt among us.

                Hail Mary...

                ℣. Pray for us, O Holy Mother of God.
                ℟. That we may be made worthy of the promises of Christ.

                Let us pray:
                Pour forth, we beseech thee, O Lord, thy grace into our hearts; that we, to whom the Incarnation of Christ, thy Son, was made known by the message of an Angel, may by his Passion and Cross be brought to the glory of his Resurrection. Through the same Christ our Lord.

                Amen.
                """,
                textLatin: """
                ℣. Angelus Dómini nuntiávit Maríæ.
                ℟. Et concépit de Spíritu Sancto.

                Ave María, grátia plena, Dóminus tecum; benedícta tu in muliéribus, et benedíctus fructus ventris tui, Iesus. Sancta María, Mater Dei, ora pro nobis peccatóribus, nunc et in hora mortis nostræ. Amen.

                ℣. Ecce ancílla Dómini.
                ℟. Fiat mihi secúndum verbum tuum.

                Ave María...

                ℣. Et Verbum caro factum est.
                ℟. Et habitávit in nobis.

                Ave María...

                ℣. Ora pro nobis, Sancta Dei Génetrix.
                ℟. Ut digni efficiámur promissiónibus Christi.

                Orémus:
                Grátiam tuam, qu\'æsumus, Dómine, méntibus nostris infúnde; ut qui, Angelo nuntiánte, Christi Fílii tui incarnatiónem cognóvimus, per passiónem eius et crucem, ad resurrectiónis glóriam perducámur. Per eúndem Christum Dóminum nostrum.

                Amen.
                """,
                source: "Traditional Roman Devotion",
                rubricNote: "Traditionally prayed at 6:00 AM, 12:00 PM, and 6:00 PM throughout the liturgical year except Eastertide."
            ),
            
            Prayer(
                id: "regina-caeli",
                title: "Regina Caeli (Queen of Heaven)",
                latinTitle: "Regina Cæli",
                category: .daily,
                textEnglish: """
                ℣. Queen of Heaven, rejoice, alleluia.
                ℟. For he whom you did merit to bear, alleluia.

                ℣. Has risen, as he said, alleluia.
                ℟. Pray for us to God, alleluia.

                ℣. Rejoice and be glad, O Virgin Mary, alleluia.
                ℟. For the Lord has truly risen, alleluia.

                Let us pray:
                O God, who gave joy to the world through the resurrection of your Son, our Lord Jesus Christ, grant we beseech you, that through his Mother, the Virgin Mary, we may obtain the joys of everlasting life. Through the same Christ our Lord.

                Amen.
                """,
                textLatin: """
                ℣. Regína cæli, lætáre, allelúia.
                ℟. Quia quem meruísti portáre, allelúia.

                ℣. Resurréxit, sicut dixit, allelúia.
                ℟. Ora pro nobis Deum, allelúia.

                ℣. Gaude et lætáre, Virgo María, allelúia.
                ℟. Quia surréxit Dóminus vere, allelúia.

                Orémus:
                Deus, qui per resurrectiónem Fílii tui, Dómini nostri Iesu Christi, mundum lætificáre dignátus es: præsta, qu\'æsumus; ut per eius Genetrícem Vírginem Maríam, perpétuæ capiámus gáudia vitæ. Per eúndem Christum Dóminum nostrum.

                Amen.
                """,
                source: "Marian Antiphon for Easter Season",
                rubricNote: "Replaces the Angelus at morning, noon, and evening throughout Eastertide until Pentecost."
            ),
            
            Prayer(
                id: "grace-before-meals",
                title: "Grace Before Meals",
                latinTitle: "Benedictio Mensæ",
                category: .daily,
                textEnglish: """
                Bless us, O Lord, and these thy gifts, which we are about to receive from thy bounty, through Christ our Lord.

                Amen.
                """,
                textLatin: """
                Bénedic, Dómine, nos et hæc tua dona, quæ de tua largitáte sumus sumptúri. Per Christum Dóminum nostrum.

                Amen.
                """,
                source: "Traditional Roman Table Blessing",
                rubricNote: "Prayed before dining in thanksgiving for bodily and spiritual nourishment."
            ),
            
            Prayer(
                id: "act-of-contrition",
                title: "Act of Contrition",
                category: .daily,
                textEnglish: """
                O my God, I am heartily sorry for having offended thee, and I detest all my sins because of thy just punishments, but most of all because they offend thee, my God, who art all good and deserving of all my love.

                I firmly resolve, with the help of thy grace, to sin no more and to avoid the near occasion of sin.

                Amen.
                """,
                source: "Rituale Romanum (Rite of Penance)",
                rubricNote: "Prayed daily during evening examen and in the Sacrament of Reconciliation."
            ),
            
            Prayer(
                id: "night-prayer-compline",
                title: "Night Prayer (Compline Refrain)",
                latinTitle: "In Manus Tuas",
                category: .daily,
                textEnglish: """
                Into your hands, Lord, I commend my spirit.
                You have redeemed us, Lord God of truth.

                Protect us, Lord, as we stay awake; watch over us as we sleep, that awake we may keep watch with Christ, and asleep, rest in his peace.

                Visit, we beseech you, O Lord, this dwelling, and drive far from it all the snares of the enemy; let your holy angels dwell herein to preserve us in peace, and let your blessing be always upon us. Through Christ our Lord.

                Amen.
                """,
                textLatin: """
                In manus tuas, Dómine, comméndo spíritum meum.
                Redemísti nos, Dómine, Deus veritátis.

                Salva nos, Dómine, vigilántes, custódi nos dormiéntes, ut vigilémus cum Christo, et requiescámus in pace.

                Visita, qu\'æsumus, Dómine, habitatiónem istam, et omnes insídias inimíci ab ea longe repélle: Angeli tui sancti hábitent in ea, qui nos in pace custódiant; et benedíctio tua sit super nos semper. Per Christum Dóminum nostrum.

                Amen.
                """,
                source: "Liturgy of the Hours (Compline)",
                rubricNote: "Prayed before sleep to place the night and soul under God’s protection."
            ),
            
            // ==========================================
            // 2. FOUNDATIONAL & CREEDAL
            // ==========================================
            Prayer(
                id: "our-father",
                title: "Our Father (The Lord's Prayer)",
                latinTitle: "Pater Noster",
                category: .foundational,
                textEnglish: """
                Our Father, who art in heaven, hallowed be thy name; thy kingdom come; thy will be done on earth as it is in heaven.

                Give us this day our daily bread; and forgive us our trespasses, as we forgive those who trespass against us; and lead us not into temptation, but deliver us from evil.

                Amen.
                """,
                textLatin: """
                Pater noster, qui es in cælis: sanctificétur nomen tuum; advéniat regnum tuum; fiat volúntas tua, sicut in cælo, et in terra.

                Panem nostrum cotidiánum da nobis hódie; et dimítte nobis débita nostra, sicut et nos dimíttimus debitóribus nostris; et ne nos indúcas in tentatiónem; sed líbera nos a malo.

                Amen.
                """,
                source: "Matthew 6:9-13",
                rubricNote: "The model of all Christian prayer, given directly by our Lord Jesus Christ."
            ),
            
            Prayer(
                id: "hail-mary",
                title: "Hail Mary",
                latinTitle: "Ave Maria",
                category: .foundational,
                textEnglish: """
                Hail Mary, full of grace, the Lord is with thee; blessed art thou among women, and blessed is the fruit of thy womb, Jesus.

                Holy Mary, Mother of God, pray for us sinners, now and at the hour of our death.

                Amen.
                """,
                textLatin: """
                Ave María, grátia plena, Dóminus tecum; benedícta tu in muliéribus, et benedíctus fructus ventris tui, Iesus.

                Sancta María, Mater Dei, ora pro nobis peccatóribus, nunc et in hora mortis nostræ.

                Amen.
                """,
                source: "Luke 1:28, 42 / Council of Trent",
                rubricNote: "The angelic salutation combining the words of Gabriel and Elizabeth with the Church's petition."
            ),
            
            Prayer(
                id: "glory-be",
                title: "Glory Be (Doxology)",
                latinTitle: "Gloria Patri",
                category: .foundational,
                textEnglish: """
                Glory be to the Father, and to the Son, and to the Holy Spirit.

                As it was in the beginning, is now, and ever shall be, world without end.

                Amen.
                """,
                textLatin: """
                Glória Patri, et Fílio, et Spirítui Sancto.

                Sicut erat in princípio, et nunc, et semper, et in s\'ǽcula sæculórum.

                Amen.
                """,
                source: "Ancient Christian Trinitarian Doxology",
                rubricNote: "Recited at the conclusion of all Psalms and decades in Catholic prayer."
            ),
            
            Prayer(
                id: "apostles-creed",
                title: "The Apostles' Creed",
                latinTitle: "Symbolum Apostolorum",
                category: .foundational,
                textEnglish: """
                I believe in God, the Father almighty, Creator of heaven and earth, and in Jesus Christ, his only Son, our Lord, who was conceived by the Holy Spirit, born of the Virgin Mary, suffered under Pontius Pilate, was crucified, died and was buried; he descended into hell; on the third day he rose again from the dead; he ascended into heaven, and is seated at the right hand of God the Father almighty; from there he will come to judge the living and the dead.

                I believe in the Holy Spirit, the holy catholic Church, the communion of saints, the forgiveness of sins, the resurrection of the body, and life everlasting.

                Amen.
                """,
                textLatin: """
                Credo in Deum Patrem omnipoténtem, Creatórem cæli et terræ. Et in Iesum Christum, Fílium eius únicum, Dóminum nostrum, qui concéptus est de Spíritu Sancto, natus ex María Vírgine, passus sub Póntio Piláto, crucifíxus, mórtuus, et sepúltus, descéndit ad ínferos, tértia die resurréxit a mórtuis, ascéndit ad cælos, sedet ad déxteram Dei Patris omnipoténtis, inde ventúrus est iudicáre vivos et mórtuos.

                Credo in Spíritum Sanctum, sanctam Ecclésiam cathólicam, sanctórum communiónem, remissiónem peccatórum, carnis resurrectiónem, vitam ætérnam.

                Amen.
                """,
                source: "Roman Baptismal Creed (c. 2nd Century)",
                rubricNote: "The ancient baptismal summary of the Christian faith."
            ),
            
            Prayer(
                id: "nicene-creed",
                title: "The Nicene Creed",
                latinTitle: "Credo in Unum Deum",
                category: .foundational,
                textEnglish: """
                I believe in one God, the Father almighty, maker of heaven and earth, of all things visible and invisible.

                I believe in one Lord Jesus Christ, the Only Begotten Son of God, born of the Father before all ages. God from God, Light from Light, true God from true God, begotten, not made, consubstantial with the Father; through him all things were made. For us men and for our salvation he came down from heaven, and by the Holy Spirit was incarnate of the Virgin Mary, and became man. For our sake he was crucified under Pontius Pilate, he suffered death and was buried, and rose again on the third day in accordance with the Scriptures. He ascended into heaven and is seated at the right hand of the Father. He will come again in glory to judge the living and the dead and his kingdom will have no end.

                I believe in the Holy Spirit, the Lord, the giver of life, who proceeds from the Father and the Son, who with the Father and the Son is adored and glorified, who has spoken through the prophets.

                I believe in one, holy, catholic and apostolic Church. I confess one Baptism for the forgiveness of sins and I look forward to the resurrection of the dead and the life of the world to come.

                Amen.
                """,
                textLatin: """
                Credo in unum Deum, Patrem omnipoténtem, factórem cæli et terræ, visibílium ómnium et invisibílium.

                Et in unum Dóminum Iesum Christum, Fílium Dei unigénitum, et ex Patre natum ante ómnia s\'ǽcula. Deum de Deo, lumen de lúmine, Deum verum de Deo vero, génitum, non factum, consubstantiálem Patri: per quem ómnia facta sunt. Qui propter nos hómines et propter nostram salútem descéndit de cælis. Et incarnátus est de Spíritu Sancto ex María Vírgine, et homo factus est. Crucifíxus étiam pro nobis sub Póntio Piláto; passus et sepúltus est, et resurréxit tértia die, secúndum Scriptúras, et ascéndit in cælum, sedet ad déxteram Patris. Et íterum ventúrus est cum glória, iudicáre vivos et mórtuos, cuius regni non erit finis.

                Et in Spíritum Sanctum, Dóminum et vivificántem: qui ex Patre Filióque procédit. Qui cum Patre et Fílio simul adorátur et conglorificátur: qui locútus est per prophétas.

                Et unam, sanctam, cathólicam et apostólicam Ecclésiam. Confíteor unum baptísma in remissiónem peccatórum. Et expécto resurrectiónem mortuórum, et vitam ventúri s\'ǽculi.

                Amen.
                """,
                source: "Councils of Nicaea (325 AD) & Constantinople (381 AD)",
                rubricNote: "Solemnly proclaimed at Holy Mass on Sundays and Solemnities."
            ),
            
            // ==========================================
            // 3. MARIAN & DEVOTIONAL
            // ==========================================
            Prayer(
                id: "how-to-pray-the-rosary",
                title: "How to Pray the Rosary",
                category: .rosary,
                textEnglish: """
                A comprehensive beginner's guide to praying the Holy Rosary:
                • The 6 step-by-step sequential prayers
                • The physical anatomy of beads (Crucifix, opening beads, 5 decades, centerpiece)
                • The weekly mystery schedule (Joyful, Sorrowful, Glorious, Luminous)
                • Spiritual advice for contemplative prayer and overcoming distractions

                Tap to open the illustrated tutorial and start the interactive bead-by-bead prayer companion.
                """,
                source: "Catholic Devotional Tradition",
                rubricNote: "Includes the 6-step sequential guide, bead anatomy, and interactive companion.",
                isRosaryGuide: true
            ),
            
            Prayer(
                id: "holy-rosary-guide",
                title: "The Holy Rosary Guide",
                category: .rosary,
                textEnglish: """
                The Holy Rosary is a Scripture-based contemplative prayer walking through the life, passion, and glory of Jesus Christ through the eyes of His Mother.

                It is composed of twenty mysteries, divided into four sets of five decades:
                • The Joyful Mysteries (Mondays & Saturdays)
                • The Luminous Mysteries (Thursdays)
                • The Sorrowful Mysteries (Tuesdays & Fridays)
                • The Glorious Mysteries (Wednesdays & Sundays)

                Tap 'Explore Today's Mysteries' below to view scripture meditations and fruits for each decade.
                """,
                source: "Tradition of Saint Dominic & Pope St. John Paul II",
                rubricNote: "Enriched with a plenary indulgence when prayed devoutly in a church, family, or religious community.",
                isRosaryGuide: true
            ),
            
            Prayer(
                id: "memorare",
                title: "The Memorare",
                latinTitle: "Memorare",
                category: .marian,
                textEnglish: """
                Remember, O most gracious Virgin Mary, that never was it known that anyone who fled to thy protection, implored thy help, or sought thy intercession was left unaided.

                Inspired by this confidence, I fly unto thee, O Virgin of virgins, my Mother; to thee do I come, before thee I stand, sinful and sorrowful. O Mother of the Word Incarnate, despise not my petitions, but in thy mercy hear and answer me.

                Amen.
                """,
                textLatin: """
                Memoráre, o piíssima Virgo María, a s\'ǽculo non esse audítum, quemquam ad tua curréntem præsídia, tua implorántem auxília, tua peténtem suffrágia, esse derelíctum.

                Ego tali animátus confidéntia, ad te, Virgo Vírginum, Mater, curro, ad te vénio, coram te gemens peccátor assísto. Noli, Mater Verbi, verba mea despícere; sed áudi propítia et exáudi.

                Amen.
                """,
                source: "Attributed to St. Bernard of Clairvaux (c. 12th Century)",
                rubricNote: "A beloved prayer of powerful Marian intercession in times of pressing need."
            ),
            
            Prayer(
                id: "hail-holy-queen",
                title: "Hail, Holy Queen",
                latinTitle: "Salve Regina",
                category: .marian,
                textEnglish: """
                Hail, holy Queen, Mother of mercy, our life, our sweetness, and our hope. To thee do we cry, poor banished children of Eve; to thee do we send up our sighs, mourning and weeping in this valley of tears.

                Turn then, most gracious advocate, thine eyes of mercy toward us, and after this our exile, show unto us the blessed fruit of thy womb, Jesus.

                O clement, O loving, O sweet Virgin Mary.

                ℣. Pray for us, O Holy Mother of God.
                ℟. That we may be made worthy of the promises of Christ.
                """,
                textLatin: """
                Salve, Regína, Mater misericórdiæ, vita, dulcédo, et spes nostra, salve. Ad te clamámus, éxsules fílii Hevæ. Ad te suspirámus, geméntes et flentes in hac lacrimárum valle.

                Eia ergo, advocáta nostra, illos tuos misericórdes óculos ad nos convérte. Et Iesum, benedíctum fructum ventris tui, nobis post hoc exsílium osténde.

                O clemens, o pia, o dulcis Virgo María.

                ℣. Ora pro nobis, Sancta Dei Génetrix.
                ℟. Ut digni efficiámur promissiónibus Christi.
                """,
                source: "Attributed to Hermann of Reichenau (c. 11th Century)",
                rubricNote: "Traditionally recited at the conclusion of the Holy Rosary and at Compline."
            ),
            
            Prayer(
                id: "the-magnificat",
                title: "The Magnificat (Canticle of Mary)",
                latinTitle: "Magnificat",
                category: .marian,
                textEnglish: """
                My soul proclaims the greatness of the Lord,
                my spirit rejoices in God my Savior;
                for he has looked with favor on his lowly servant.

                From this day all generations will call me blessed:
                the Almighty has done great things for me,
                and holy is his Name.

                He has mercy on those who fear him
                in every generation.
                He has shown the strength of his arm,
                he has scattered the proud in their conceit.

                He has cast down the mighty from their thrones,
                and has lifted up the lowly.
                He has filled the hungry with good things,
                and the rich he has sent away empty.

                He has come to the help of his servant Israel
                for he has remembered his promise of mercy,
                the promise he made to our fathers,
                to Abraham and his children for ever.

                Glory be to the Father...
                """,
                textLatin: """
                Magníficat ánima mea Dóminum,
                et exsultávit spíritus meus in Deo salvatóre meo,
                quia respéxit humilitátem ancíllæ suæ.

                Ecce enim ex hoc beátam me dicent omnes generatiónes,
                quia fecit mihi magna, qui potens est,
                et sanctum nomen eius,
                et misericórdia eius in progénies et progénies timéntibus eum.

                Fecit poténtiam in bráchio suo,
                dispérsit supérbos mente cordis sui;
                depósuit poténtes de sede
                et exaltávit húmiles;
                esuriéntes implévit bonis
                et dívites dimísit inánes.

                Suscépit Israel púerum suum,
                recordátus misericórdiæ,
                sicut locútus est ad patres nostros,
                Abraham et sémini eius in s\'ǽcula.

                Glória Patri, et Fílio, et Spirítui Sancto...
                """,
                source: "Luke 1:46-55",
                rubricNote: "The great gospel canticle of Evening Prayer (Vespers)."
            ),
            
            Prayer(
                id: "divine-mercy-chaplet",
                title: "The Divine Mercy Chaplet",
                category: .devotions,
                textEnglish: """
                Prayed on ordinary Rosary beads:

                Opening Prayers:
                You expired, Jesus, but the source of life gushed forth for souls, and the ocean of mercy opened up for the whole world. O Fount of Life, unfathomable Divine Mercy, envelop the whole world and empty Yourself out upon us.

                (Repeat three times):
                O Blood and Water, which gushed forth from the Heart of Jesus as a fountain of Mercy for us, I trust in You!

                On the Our Father Beads:
                Eternal Father, I offer you the Body and Blood, Soul and Divinity of Your Dearly Beloved Son, Our Lord, Jesus Christ, in atonement for our sins and those of the whole world.

                On the 10 Hail Mary Beads:
                For the sake of His sorrowful Passion, have mercy on us and on the whole world.

                Concluding Doxology (Repeat three times):
                Holy God, Holy Mighty One, Holy Immortal One, have mercy on us and on the whole world.

                Closing Prayer:
                Eternal God, in whom mercy is endless and the treasury of compassion inexhaustible, look kindly upon us and increase Your mercy in us, that in difficult moments we might not despair nor become despondent, but with great confidence submit ourselves to Your holy will, which is Love and Mercy itself.

                Amen.
                """,
                source: "St. Maria Faustina Kowalska (Diary, 1935)",
                rubricNote: "Traditionally prayed at the Hour of Great Mercy (3:00 PM)."
            ),
            
            // ==========================================
            // 4. SAINTS & SPIRITUAL PROTECTION
            // ==========================================
            Prayer(
                id: "st-michael-prayer",
                title: "Prayer to St. Michael the Archangel",
                latinTitle: "Sancte Michael Archangele",
                category: .saints,
                textEnglish: """
                Saint Michael the Archangel, defend us in battle. Be our protection against the wickedness and snares of the devil.

                May God rebuke him, we humbly pray; and do thou, O Prince of the heavenly host, by the power of God, cast into hell Satan and all the evil spirits who prowl about the world seeking the ruin of souls.

                Amen.
                """,
                textLatin: """
                Sancte Míchael Archángele, defénde nos in pr\'ǽlio, contra nequítiam et insídias diáboli esto præsídium.

                Ímperet illi Deus, súpplices deprecámur: tuque, Princeps milítiæ cæléstis, Sátanam aliósque spíritus malígnos, qui ad perditiónem animárum pervagántur in mundo, divína virtúte, in inférnum detrúde.

                Amen.
                """,
                source: "Pope Leo XIII (1886)",
                rubricNote: "Composed after a prophetic vision of spiritual warfare; recited for spiritual protection."
            ),
            
            Prayer(
                id: "anima-christi",
                title: "Anima Christi (Soul of Christ)",
                latinTitle: "Anima Christi",
                category: .saints,
                textEnglish: """
                Soul of Christ, sanctify me.
                Body of Christ, save me.
                Blood of Christ, inebriate me.
                Water from the side of Christ, wash me.
                Passion of Christ, strengthen me.
                O good Jesus, hear me.
                Within your wounds hide me.
                Separated from you let me never be.
                From the evil enemy defend me.
                At the hour of my death call me.
                And close to you bid me,
                That with your saints I may praise you
                For ever and ever.

                Amen.
                """,
                textLatin: """
                Anima Christi, sanctífica me.
                Corpus Christi, salva me.
                Sanguis Christi, inébria me.
                Aqua láteris Christi, lava me.
                Pássio Christi, confórta me.
                O bone Iesu, exáudi me.
                Intra tua vúlnera abscónde me.
                Ne permíttas me separári a te.
                Ab hoste malígno defénde me.
                In hora mortis meæ voca me.
                Et iube me veníre ad te,
                ut cum Sanctis tuis laudem te
                in s\'ǽcula sæculórum.

                Amen.
                """,
                source: "Popularized by St. Ignatius of Loyola (c. 14th Century)",
                rubricNote: "A beloved post-Communion prayer of intimacy with Christ's sacred humanity."
            ),
            
            Prayer(
                id: "prayer-of-st-francis",
                title: "Peace Prayer of St. Francis",
                category: .saints,
                textEnglish: """
                Lord, make me an instrument of your peace:
                where there is hatred, let me sow love;
                where there is injury, pardon;
                where there is doubt, faith;
                where there is despair, hope;
                where there is darkness, light;
                where there is sadness, joy.

                O divine Master, grant that I may not so much seek
                to be consoled as to console,
                to be understood as to understand,
                to be loved as to love.

                For it is in giving that we receive,
                it is in pardoning that we are pardoned,
                and it is in dying that we are born to eternal life.

                Amen.
                """,
                source: "Franciscan Devotional Tradition",
                rubricNote: "A classic Franciscan prayer of charity and self-renunciation."
            ),
            
            Prayer(
                id: "angel-of-god",
                title: "Guardian Angel Prayer",
                latinTitle: "Angele Dei",
                category: .saints,
                textEnglish: """
                Angel of God, my guardian dear,
                to whom God's love commits me here,
                ever this day be at my side,
                to light and guard, to rule and guide.

                Amen.
                """,
                textLatin: """
                Angele Dei, qui custos es mei,
                me, tibi commíssum pietáte supérna,
                illúmina, custódi, rege et gubérna.

                Amen.
                """,
                source: "Traditional Roman Catholic Children's & Family Prayer",
                rubricNote: "Prayed daily in morning and evening to honor our personal Guardian Angel."
            ),
            
            Prayer(
                id: "prayer-to-st-joseph",
                title: "Ancient Prayer to St. Joseph",
                category: .saints,
                textEnglish: """
                O St. Joseph, whose protection is so great, so strong, so prompt before the Throne of God, I place in you all my interests and desires.

                O St. Joseph, do assist me by your powerful intercession and obtain for me from your divine Son all spiritual blessings through Jesus Christ, Our Lord; so that having engaged here below your heavenly power, I may offer my thanksgiving and homage to the most loving of Fathers.

                O St. Joseph, I never weary contemplating you and Jesus asleep in your arms. I dare not approach while He reposes near your heart. Press Him in my name and kiss His fine Head for me, and ask Him to return the kiss when I draw my dying breath.

                St. Joseph, patron of departing souls, pray for us.

                Amen.
                """,
                source: "Traditional Novena to St. Joseph",
                rubricNote: "Tradition dates this intercessory prayer to the first century of the Church."
            ),
            
            Prayer(
                id: "st-patrick-breastplate",
                title: "Breastplate of St. Patrick (Lorica)",
                category: .saints,
                textEnglish: """
                Christ with me, Christ before me, Christ behind me,
                Christ in me, Christ beneath me, Christ above me,
                Christ on my right, Christ on my left,
                Christ when I lie down, Christ when I sit down, Christ when I arise,
                Christ in the heart of every man who thinks of me,
                Christ in the mouth of everyone who speaks of me,
                Christ in every eye that sees me,
                Christ in every ear that hears me.

                Salvation is of the Lord. Salvation is of Christ.
                May your salvation, Lord, be with us always.

                Amen.
                """,
                source: "St. Patrick of Ireland (c. 5th Century)",
                rubricNote: "Ancient Celtic invocation for protection, divine presence, and spiritual victory."
            )
        ]
    }
}
