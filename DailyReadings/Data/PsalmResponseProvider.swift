//
//  PsalmResponseProvider.swift
//  DailyReadings
//
//  Created for DailyReadings Catholic Daily Readings App.
//  iOS 17+ | Swift 6+
//

import Foundation

/// Provides official Roman Catholic Lectionary Responsorial Psalm responses (antiphons)
/// for daily and Sunday Mass readings.
public struct PsalmResponseProvider: Sendable {
    
    // MARK: - Public Lookup API
    
    /// Returns the canonical liturgical response for a given Responsorial Psalm citation and text.
    public static func response(for citation: ReadingCitation, text: String = "") -> String {
        // 1. Check for specific citation overrides (e.g. specific feasts or seasons)
        let normalizedRef = citation.reference
            .replacingOccurrences(of: "Psalm ", with: "Psalms ")
            .replacingOccurrences(of: "Ps ", with: "Psalms ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            
        for (pattern, resp) in specificCitationOverrides {
            if normalizedRef.localizedCaseInsensitiveContains(pattern) {
                return resp
            }
        }
        
        // 2. Check for Canticles used as Responsorial Psalms (Exodus, Isaiah, Daniel, Luke, etc.)
        let bookLower = citation.book.lowercased()
        for (canticleKey, resp) in canticleResponses {
            if bookLower.contains(canticleKey) {
                return resp
            }
        }
        
        // 3. Check psalm chapter in the standard Catholic Lectionary psalter dictionary
        if let chapter = citation.chapter, let resp = psalmChapterResponses[chapter] {
            return resp
        }
        
        // 4. Try extracting from Psalm text if it contains an explicit rubric or antiphon mark
        if let extracted = extractResponseFromText(text) {
            return extracted
        }
        
        // 5. Reverent fallback: Use the opening line/verse of the psalm
        let fallback = deriveOpeningVerseFallback(from: text)
        if !fallback.isEmpty {
            return fallback
        }
        
        return "The Lord is my light and my salvation."
    }
    
    // MARK: - Specific Citation Overrides
    
    /// Overrides for Psalms that have distinct, well-known responses depending on the liturgical pericope.
    private static let specificCitationOverrides: [(pattern: String, response: String)] = [
        // Psalm 19
        ("19:8", "Your words, Lord, are Spirit and life."),
        ("19:2", "Their message goes out through all the earth."),
        ("19:9", "The precepts of the Lord give joy to the heart."),
        
        // Psalm 22
        ("22:8", "My God, my God, why have you abandoned me?"),
        ("22:26", "I will praise you, Lord, in the assembly of your people."),
        
        // Psalm 23
        ("23:", "The Lord is my shepherd; there is nothing I shall want."),
        
        // Psalm 24
        ("24:1", "Lord, this is the people that longs to see your face."),
        ("24:7", "Who is this king of glory? It is the Lord!"),
        
        // Psalm 25
        ("25:4", "Teach me your ways, O Lord."),
        ("25:6", "Remember your mercies, O Lord."),
        ("25:", "To you, O Lord, I lift my soul."),
        
        // Psalm 27
        ("27:1", "The Lord is my light and my salvation."),
        ("27:13", "I believe that I shall see the good things of the Lord in the land of the living."),
        
        // Psalm 31
        ("31:5", "Father, into your hands I commend my spirit."),
        ("31:2", "Lord, be my rock of safety."),
        
        // Psalm 33
        ("33:22", "Lord, let your mercy be on us, as we place our trust in you."),
        ("33:12", "Blessed the people the Lord has chosen to be his own."),
        
        // Psalm 34
        ("34:8", "Taste and see the goodness of the Lord."),
        ("34:18", "The Lord hears the cry of the poor."),
        ("34:2", "Taste and see the goodness of the Lord."),
        
        // Psalm 37
        ("37:", "The salvation of the just comes from the Lord."),
        
        // Psalm 40
        ("40:", "Here I am, Lord; I come to do your will."),
        
        // Psalm 51
        ("51:3", "Be merciful, O Lord, for we have sinned."),
        ("51:12", "A clean heart create for me, O God."),
        ("51:17", "My sacrifice, O God, is a contrite spirit."),
        
        // Psalm 67
        ("67:", "May God bless us in his mercy."),
        
        // Psalm 80
        ("80:", "Lord, make us turn to you; let us see your face and we shall be saved."),
        
        // Psalm 90
        ("90:1", "In every age, O Lord, you have been our refuge."),
        ("90:14", "Fill us with your love, O Lord, and we will sing for joy!"),
        
        // Psalm 91
        ("91:", "Be with me, Lord, when I am in trouble."),
        
        // Psalm 95
        ("95:", "If today you hear his voice, harden not your hearts."),
        
        // Psalm 96
        ("96:3", "Proclaim his marvelous deeds to all the nations."),
        ("96:7", "Give the Lord glory and honor."),
        ("96:10", "The Lord is king; let the earth rejoice."),
        
        // Psalm 98
        ("98:1", "Sing to the Lord a new song, for he has done marvelous deeds."),
        ("98:2", "The Lord has made known his salvation."),
        ("98:3", "All the ends of the earth have seen the saving power of God."),
        
        // Psalm 103
        ("103:8", "The Lord is kind and merciful."),
        ("103:1", "Bless the Lord, O my soul!"),
        ("103:19", "The Lord has set his throne in heaven."),
        
        // Psalm 104
        ("104:30", "Lord, send out your Spirit, and renew the face of the earth."),
        ("104:1", "Bless the Lord, O my soul!"),
        
        // Psalm 116
        ("116:12", "Our blessing-cup is a communion with the Blood of Christ."),
        ("116:9", "I will walk before the Lord, in the land of the living."),
        ("116:17", "To you, Lord, I will offer a sacrifice of praise."),
        
        // Psalm 118
        ("118:24", "This is the day the Lord has made; let us rejoice and be glad."),
        ("118:1", "Give thanks to the Lord for he is good, his love is everlasting."),
        ("118:22", "The stone which the builders rejected has become the cornerstone."),
        
        // Psalm 122
        ("122:", "Let us go rejoicing to the house of the Lord."),
        
        // Psalm 126
        ("126:", "The Lord has done great things for us; we are filled with joy."),
        
        // Psalm 128
        ("128:", "Blessed are those who fear the Lord."),
        
        // Psalm 130
        ("130:", "With the Lord there is mercy and fullness of redemption."),
        
        // Psalm 131
        ("131:", "In you, Lord, I have found my peace."),
        
        // Psalm 145
        ("145:1", "I will praise your name for ever, my king and my God."),
        ("145:16", "The hand of the Lord feeds us; he answers all our needs."),
        ("145:18", "The Lord is near to all who call upon him."),
        
        // Psalm 146
        ("146:", "Praise the Lord, my soul!"),
        
        // Psalm 147
        ("147:12", "Praise the Lord, Jerusalem."),
        ("147:1", "Praise the Lord, who heals the brokenhearted.")
    ]
    
    // MARK: - Biblical Canticles Used as Responsorial Psalms
    
    private static let canticleResponses: [String: String] = [
        "exodus": "Let us sing to the Lord; he has covered himself in glory.",
        "1 samuel": "My heart exults in the Lord, my Savior.",
        "1 sam": "My heart exults in the Lord, my Savior.",
        "1 chronicles": "We praise your glorious name, O Lord our God.",
        "1 chron": "We praise your glorious name, O Lord our God.",
        "tobit": "Blessed be God who lives for ever.",
        "judith": "You are great, O Lord, and glorious in power.",
        "isaiah": "You will draw water joyfully from the springs of salvation.",
        "is": "You will draw water joyfully from the springs of salvation.",
        "daniel": "Glory and praise for ever!",
        "dan": "Glory and praise for ever!",
        "habakkuk": "O Lord, I have heard your renown, and feared your work.",
        "hab": "O Lord, I have heard your renown, and feared your work.",
        "luke": "My soul rejoices in my God."
    ]
    
    // MARK: - Canonical Lectionary Psalter (Psalms 1 to 150)
    
    private static let psalmChapterResponses: [Int: String] = [
        1: "Blessed are they who hope in the Lord.",
        2: "Blessed are all who take refuge in the Lord.",
        3: "Salvation comes from the Lord.",
        4: "Lord, let the light of your face shine upon us.",
        5: "Lead me in your justice, Lord.",
        6: "Turn, O Lord, and deliver my soul.",
        7: "O Lord, my God, in you have I taken refuge.",
        8: "O Lord, our God, how wonderful your name in all the earth!",
        9: "The Lord will judge the world with justice.",
        10: "Lord, do not forget the poor.",
        11: "The Lord is in his holy temple; the Lord's throne is in heaven.",
        12: "You, O Lord, will keep us and preserve us always.",
        13: "I trust in your merciful love, O Lord.",
        14: "The fool says in his heart, 'There is no God.'",
        15: "He who does justice will live in the presence of the Lord.",
        16: "You are my inheritance, O Lord.",
        17: "Lord, when your glory appears, my joy will be full.",
        18: "I love you, Lord, my strength.",
        19: "Your words, Lord, are Spirit and life.",
        20: "May the Lord answer you in time of trial.",
        21: "Lord, in your strength the king is glad.",
        22: "My God, my God, why have you abandoned me?",
        23: "The Lord is my shepherd; there is nothing I shall want.",
        24: "Lord, this is the people that longs to see your face.",
        25: "To you, O Lord, I lift my soul.",
        26: "Redeem me, O Lord, and have mercy on me.",
        27: "The Lord is my light and my salvation.",
        28: "Hear the voice of my pleading, O Lord.",
        29: "The Lord will bless his people with peace.",
        30: "I will praise you, Lord, for you have rescued me.",
        31: "Father, into your hands I commend my spirit.",
        32: "Lord, forgive the wrong I have done.",
        33: "Lord, let your mercy be on us, as we place our trust in you.",
        34: "Taste and see the goodness of the Lord.",
        35: "My soul shall be joyful in the Lord.",
        36: "How precious is your mercy, O God!",
        37: "The salvation of the just comes from the Lord.",
        38: "O Lord, do not forsake me; my God, be not far from me.",
        39: "Lord, let me know my end, and what is the measure of my days.",
        40: "Here I am, Lord; I come to do your will.",
        41: "Lord, heal my soul, for I have sinned against you.",
        42: "My soul is thirsting for the living God.",
        43: "My soul is thirsting for the living God.",
        44: "Redeem us, Lord, because of your merciful love.",
        45: "The queen stands at your right hand, arrayed in gold.",
        46: "The waters of the river gladden the city of God, the holy dwelling of the Most High.",
        47: "God mounts his throne to shouts of joy: a blare of trumpets for the Lord.",
        48: "Great is the Lord, and highly to be praised in the city of our God.",
        49: "Blessed the poor in spirit; the kingdom of heaven is theirs!",
        50: "To the upright I will show the saving power of God.",
        51: "Be merciful, O Lord, for we have sinned.",
        52: "I trust in the mercy of God for ever.",
        53: "God looks down from heaven upon the children of men.",
        54: "The Lord upholds my life.",
        55: "Cast your burden upon the Lord, and he will sustain you.",
        56: "In God I trust; I will not be afraid.",
        57: "Have mercy on me, God, have mercy; for in you my soul takes refuge.",
        58: "Truly there is a God who judges on earth.",
        59: "Deliver me from my enemies, O my God.",
        60: "Grant us help against the foe, for worthless is the help of man.",
        61: "From the ends of the earth I call to you; lead me to the rock that is higher than I.",
        62: "Rest in God alone, my soul.",
        63: "My soul is thirsting for you, O Lord my God.",
        64: "Hear, O God, the voice of my complaint.",
        65: "The seed that falls on good ground will yield a fruitful harvest.",
        66: "Let all the earth cry out to God with joy.",
        67: "May God bless us in his mercy.",
        68: "God, in your goodness, you have made a home for the poor.",
        69: "Lord, in your great love, answer me.",
        70: "O God, make haste to save me; O Lord, make haste to help me.",
        71: "My mouth will tell of your salvation.",
        72: "Lord, every nation on earth will adore you.",
        73: "Whom have I in heaven but you? Having you, I want nothing on earth.",
        74: "Remember your congregation, Lord, which you bought of old.",
        75: "We give you thanks, O God, we give thanks, for your name is near.",
        76: "Glorious are you, O Lord, and majestic.",
        77: "I cry aloud to God, that he may hear me.",
        78: "Do not forget the works of the Lord!",
        79: "Help us, O God our savior, for the glory of your name.",
        80: "Lord, make us turn to you; let us see your face and we shall be saved.",
        81: "Sing with joy to God our help.",
        82: "Rise up, O God, judge the earth.",
        83: "O God, do not be silent; be not quiet, O God.",
        84: "How lovely is your dwelling place, Lord, mighty God!",
        85: "Lord, let us see your kindness, and grant us your salvation.",
        86: "Lord, you are good and forgiving.",
        87: "Glorious things are said of you, O city of God!",
        88: "Let my prayer come before you, Lord; incline your ear to my cry.",
        89: "For ever I will sing the goodness of the Lord.",
        90: "In every age, O Lord, you have been our refuge.",
        91: "Be with me, Lord, when I am in trouble.",
        92: "Lord, it is good to give thanks to you.",
        93: "The Lord is king; he is robed in majesty.",
        94: "The Lord will not abandon his people.",
        95: "If today you hear his voice, harden not your hearts.",
        96: "Proclaim his marvelous deeds to all the nations.",
        97: "The Lord is king, the Most High over all the earth.",
        98: "All the ends of the earth have seen the saving power of God.",
        99: "Holy is the Lord our God.",
        100: "We are his people, the sheep of his flock.",
        101: "I will sing of faithful love and justice; to you, O Lord, I will make melody.",
        102: "The Lord will build up Zion again, and appear in all his glory.",
        103: "The Lord is kind and merciful.",
        104: "Lord, send out your Spirit, and renew the face of the earth.",
        105: "The Lord remembers his covenant for ever.",
        106: "Give thanks to the Lord, for he is good; his mercy endures for ever.",
        107: "Give thanks to the Lord, his love is everlasting.",
        108: "My heart is ready, O God; I will sing and give praise.",
        109: "Help me, O Lord my God; save me according to your faithful love.",
        110: "You are a priest for ever, in the line of Melchizedek.",
        111: "The Lord is gracious and merciful.",
        112: "Blessed the man who fears the Lord.",
        113: "Praise the Lord who lifts up the poor.",
        114: "When Israel came forth from Egypt, alleluia.",
        115: "Not to us, Lord, but to your name give the glory.",
        116: "Our blessing-cup is a communion with the Blood of Christ.",
        117: "Go out to all the world and tell the Good News.",
        118: "Give thanks to the Lord for he is good, his love is everlasting.",
        119: "Blessed are they who follow the law of the Lord!",
        120: "In my trouble I cried to the Lord, and he answered me.",
        121: "Our help is from the Lord, who made heaven and earth.",
        122: "Let us go rejoicing to the house of the Lord.",
        123: "Our eyes are fixed on the Lord, pleading for his mercy.",
        124: "Our soul has been rescued like a bird from the fowler's snare.",
        125: "The Lord does good to those who are good.",
        126: "The Lord has done great things for us; we are filled with joy.",
        127: "Unless the Lord build the house, they labor in vain who build it.",
        128: "Blessed are those who fear the Lord.",
        129: "Blessed be the Lord from Zion.",
        130: "With the Lord there is mercy and fullness of redemption.",
        131: "In you, Lord, I have found my peace.",
        132: "The Lord has chosen Zion for his dwelling.",
        133: "How good and pleasant it is when brothers live together in unity!",
        134: "Praise the Lord, all you servants of the Lord.",
        135: "Praise the name of the Lord!",
        136: "His love endures for ever.",
        137: "Let my tongue be silenced, if I ever forget you!",
        138: "Lord, your love is eternal; do not forsake the work of your hands.",
        139: "Guide me, Lord, along the everlasting way.",
        140: "Rescue me, Lord, from evil men.",
        141: "Lord, let my prayer come like incense before you.",
        142: "You are my refuge, Lord; my portion in the land of the living.",
        143: "Lord, hear my prayer, in your justice answer me.",
        144: "Blessed be the Lord, my Rock!",
        145: "I will praise your name for ever, my king and my God.",
        146: "Praise the Lord, my soul!",
        147: "Praise the Lord, Jerusalem.",
        148: "Praise the Lord from the heavens.",
        149: "The Lord takes delight in his people.",
        150: "Let everything that has breath give praise to the Lord!"
    ]
    
    // MARK: - In-Text Extraction Helpers
    
    private static func extractResponseFromText(_ text: String) -> String? {
        let lines = text.components(separatedBy: "\n")
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.starts(with: "℟.") || trimmed.starts(with: "R.") || trimmed.starts(with: "Response:") {
                let cleaned = trimmed
                    .replacingOccurrences(of: "^(℟\\.|R\\.|Response:)\\s*", with: "", options: .regularExpression)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if !cleaned.isEmpty {
                    return cleaned
                }
            }
        }
        return nil
    }
    
    private static func deriveOpeningVerseFallback(from text: String) -> String {
        let cleaned = text
            .replacingOccurrences(of: "\\[\\[[^\\]]+\\]\\]", with: "", options: .regularExpression)
            .replacingOccurrences(of: "\\[\\d+\\]", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return "" }
        
        let firstLine = cleaned.components(separatedBy: "\n").first ?? cleaned
        let trimmed = firstLine.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count > 5 {
            return trimmed.hasSuffix(".") ? trimmed : "\(trimmed)."
        }
        return ""
    }
}
