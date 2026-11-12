#!/usr/bin/env python3
"""Builds DailyReadings/Resources/versification.json.

The Lectionary cites Scripture in Hebrew ("original") verse numbering. The bundled
Bibles do not: WEB-C uses English numbering, Douay-Rheims uses Vulgate numbering.
This script turns the Copenhagen Alliance standard mappings (eng.json, org.json,
vul.json from github.com/Copenhagen-Alliance/versification-specification) into a
verse-level lookup from Lectionary numbering to each Bible's numbering.

A book is only mapped when the bundled SQLite file has exactly the chapter lengths
the standard table expects; otherwise it is left unmapped (identity).

Usage: build_versification.py <dir with eng.json org.json vul.json and usfm/20-PSAeng-web-c.usfm> <Resources dir>
(The USFM file comes from https://ebible.org/Scriptures/eng-web-c_usfm.zip.)
"""
import json, re, sqlite3, sys

CODES = ("GEN EXO LEV NUM DEU JOS JDG RUT 1SA 2SA 1KI 2KI 1CH 2CH EZR NEH TOB JDT EST JOB PSA PRO ECC SNG "
         "WIS SIR ISA JER LAM BAR EZK DAN HOS JOL AMO OBA JON MIC NAM HAB ZEP HAG ZEC MAL 1MA 2MA "
         "MAT MRK LUK JHN ACT ROM 1CO 2CO GAL EPH PHP COL 1TH 2TH 1TI 2TI TIT PHM HEB JAS 1PE 2PE 1JN 2JN 3JN JUD REV").split()
BOOK_ID = {c: i + 1 for i, c in enumerate(CODES)}
# Books where the Lectionary does not follow Hebrew numbering (Greek additions, lettered chapters).
NOT_HEBREW = {"DAN", "EST", "TOB", "JDT", "WIS", "SIR", "BAR", "1MA", "2MA"}
# Douay-Rheims books already handled by hand-written, test-pinned mappings in BibleDatabase.swift.
HAND_MAPPED_VUL = {"PSA", "JOL", "MAL"}

REF = re.compile(r"^(\w+) (\d+):(\d+)(?:-(\d+))?$")

def expand(ref):
    m = REF.match(ref)
    if not m:
        return None
    book, ch, a, b = m.group(1), int(m.group(2)), int(m.group(3)), m.group(4)
    return book, ch, list(range(a, (int(b) if b else a) + 1))

def db_lengths(path):
    con = sqlite3.connect(path)
    out = {}
    for book, ch, mx, n in con.execute("select book_id, chapter, max(verse), count(*) from verses group by book_id, chapter"):
        out.setdefault(book, {})[ch] = mx
    return out

def build(target, org, db, skip, extra):
    """Returns {bookId: [[lectionaryChapter, lectionaryVerse, bibleChapter, bibleVerse], ...]}.

    bibleVerse 0 means "this Lectionary verse is a psalm title with no verse of its own here".
    One Lectionary verse can map to more than one Bible verse (a verse split across a chapter break).
    """
    table, mapped_books, rejected = {}, [], set()
    for code, book_id in BOOK_ID.items():
        if code in NOT_HEBREW or code in skip or code not in target["maxVerses"]:
            continue
        expected = [int(x) for x in target["maxVerses"][code]]
        actual = db.get(book_id, {})
        rows = set()
        for tref, oref in list(target["mappedVerses"].items()) + extra.get(code, []):
            t, o = expand(tref), expand(oref)
            if not t or not o or t[0] != code or o[0] != code:
                continue
            (_, tch, tvs), (_, och, ovs) = t, o
            # Only trust a row when the bundled text has the chapter length the table expects.
            if (tref, oref) not in extra.get(code, []) and (tch > len(expected) or actual.get(tch) != expected[tch - 1]):
                rejected.add(f"{code} {tch}")
                continue
            if len(tvs) == len(ovs):
                rows.update((och, ov, tch, tv) for tv, ov in zip(tvs, ovs))
            elif len(tvs) == 1:
                rows.update((och, ov, tch, tvs[0]) for ov in ovs)
        # A row that points past the end of a chapter in the bundled text means the standard table
        # does not describe this book as bundled. Leave the whole book unmapped.
        if any(tv > actual.get(tch, 0) for _, _, tch, tv in rows):
            rejected.add(f"{code} (whole book)")
            continue
        # A psalm title that is its own verse in Hebrew numbering is verse 0 in the target: drop it,
        # and drop any earlier title verse the table does not mention.
        mentioned = {(och, ov) for och, ov, _, _ in rows}
        for och, ov, tch, tv in list(rows):
            if tv == 0:
                rows.update((och, earlier, tch, 0) for earlier in range(1, ov) if (och, earlier) not in mentioned)
        # A verse that maps to itself and nowhere else needs no row.
        targets = {}
        for och, ov, tch, tv in rows:
            targets.setdefault((och, ov), set()).add((tch, tv))
        rows = {r for r in rows if targets[(r[0], r[1])] != {(r[0], r[1])}}
        if rows:
            table[str(book_id)] = sorted(list(r) for r in rows)
            mapped_books.append(code)
    return table, mapped_books, sorted(rejected)

# Rows the standard table does not carry. WEB places the Romans doxology after 14:23.
EXTRA_WEBC = {"ROM": [("ROM 14:24-26", "ROM 16:25-27")]}

def psalm_titles(usfm_path, db_path):
    """WEB-C prints each psalm title at the start of verse 1. Returns {psalm: title} for every
    title that is an exact prefix of verse 1 in the bundled text, so it can be removed when a
    psalm is read as a responsorial psalm (the Lectionary never includes the title)."""
    con = sqlite3.connect(db_path)
    first = dict(con.execute("select chapter, text from verses where book_id = 21 and verse = 1"))
    titles, chapter, skipped = {}, None, []
    for line in open(usfm_path, encoding="utf-8"):
        if line.startswith("\\c "):
            chapter = int(line.split()[1])
        elif line.startswith("\\d ") and chapter:
            raw = line[3:]
            raw = re.sub(r"\\f .*?\\f\*", "", raw)                 # footnotes
            raw = re.sub(r"\\\+?w ([^|\\]*)\|[^\\]*\\\+?w\*", r"\1", raw)  # word-level markup
            raw = re.sub(r"\\\+?[a-z0-9]+\*?", "", raw)             # any remaining markers
            title = " ".join(raw.split())
            if title and first.get(chapter, "").startswith(title):
                titles[str(chapter)] = title
            elif title:
                skipped.append(chapter)
    return titles, skipped

def main(src, resources):
    eng, org, vul = (json.load(open(f"{src}/{n}.json")) for n in ("eng", "org", "vul"))
    out = {"source": "Copenhagen Alliance versification-specification standard mappings (eng, org, vul)",
           "lectionaryMaxVerses": {str(BOOK_ID[c]): [int(x) for x in v] for c, v in org["maxVerses"].items()
                                   if c in BOOK_ID and c not in NOT_HEBREW}}
    for name, target, dbfile, skip, extra in (("webc", eng, "bible_webc.sqlite", set(), EXTRA_WEBC), ("drb", vul, "bible_drb.sqlite", HAND_MAPPED_VUL, {})):
        table, mapped, rejected = build(target, org, db_lengths(f"{resources}/{dbfile}"), skip, extra)
        out[name] = table
        print(f"{name}: mapped {len(mapped)} books ({sum(len(v) for v in table.values())} verses): {' '.join(mapped)}")
        print(f"{name}: chapters left unmapped because the bundled text does not match the standard table: {', '.join(rejected) or 'none'}")
    titles, skipped = psalm_titles(f"{src}/usfm/20-PSAeng-web-c.usfm", f"{resources}/bible_webc.sqlite")
    out["webcPsalmTitles"] = titles
    print(f"webc: {len(titles)} psalm titles recorded; not matched to verse 1: {skipped or 'none'}")
    json.dump(out, open(f"{resources}/versification.json", "w"), separators=(",", ":"))

if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
