// Single-page resume on one cream background:
//   top:    name, headline and a personalized summary, full width; any company
//           from the experience list named in the summary is set in bold blue
//   left:   skills and education
//   middle: the experience timeline, drawn in gold, a bullet or so per role
//   right:  contact, then interests in smaller type
// and, if set, a one-line disclaimer in the bottom margin.
//
// Data arrives as a JSON string in `sys.inputs.data` (see render.py). Compiled
// on its own it falls back to mock.yaml, so the layout can be iterated on with:
//   typst watch templates/personalized-three-column/resume.typ --font-path fonts --ignore-system-fonts
//
// ATS notes: keep tracking <= 0.08em (wider tracking is extracted as
// "S P A C E D" text), ligatures off ("ﬁ" glyphs break keyword matching),
// hyphenation off ("Type-Script" breaks it too) and kerning off (Space
// Grotesk tightens "tt" enough that some parsers read "cut ting"). Text order
// follows source order: top section, then the left, middle and right columns.

#let data = if "data" in sys.inputs {
  json(bytes(sys.inputs.data))
} else {
  yaml("mock.yaml")
}

#let cream = rgb("#fcffe7")  // page background
#let blue = rgb("#3657d9")   // name, section titles, company names in the summary
// Exact complement of the blue (hue 48°). Shapes only: as text it is 1.6:1
// on cream, too faint to read.
#let gold = rgb("#f5c919")   // headline bar, experience timeline
#let ink = rgb("#262626")    // body text
#let muted = rgb("#5c5f52")  // secondary text, labels

#let font = "Space Grotesk"

#let get(d, key) = d.at(key, default: none)
// YAML turns values like `2016` into numbers; text needs strings.
#let txt(v) = if type(v) == str { v } else { str(v) }

#set document(title: data.name + " – Resume", author: data.name)
#set page(paper: "us-letter", margin: (x: 0.5in, top: 0.5in, bottom: 0.45in), fill: cream)
// The disclaimer sits in the bottom margin as a footer, so it never takes room
// from the columns or pushes the resume onto a second page.
#set page(footer: if get(data, "disclaimer") != none {
  text(size: 7pt, weight: "bold", tracking: 0.06em, fill: blue, "DISCLAIMER")
  h(6pt)
  text(size: 7.5pt, fill: muted, txt(data.disclaimer))
})
#set text(
  font: font,
  size: 8.75pt,
  fill: ink,
  kerning: false,
  ligatures: false,
  hyphenate: false,
)
#set par(leading: 0.55em, spacing: 0.55em)
#set list(indent: 0pt, body-indent: 5pt, spacing: 0.4em)
#set heading(bookmarked: false)
#show heading: it => block(above: 0pt, below: 0pt, it.body)

// ---------- Shared pieces ----------

#let section-title(title) = block(sticky: true, below: 6pt, {
  heading(level: 2, text(size: 10pt, weight: "bold", tracking: 0.06em, fill: blue, upper(title)))
  v(3pt)
  line(length: 100%, stroke: 0.75pt + blue)
})

#let label(body) = text(size: 7pt, tracking: 0.06em, fill: muted, upper(body))

// Shrinks a value such as an email or URL to fit on one line instead of
// wrapping: a line break inside an address splits it in extracted text.
// Below 80% it would be unreadable, so a value that still doesn't fit wraps.
#let fit(body) = layout(size => {
  let scale = calc.max(0.8, size.width / measure(body).width)
  if scale >= 1 { body } else { text(size: 1em * scale, body) }
})

// Sets every mention of the given names in bold blue. The text itself is
// unchanged, so extracted text reads as a plain sentence.
#let emphasize(s, names) = {
  let parts = (s,)
  // Longest first, so a name that contains another is matched whole.
  for name in names.sorted(key: n => -n.len()) {
    parts = parts
      .map(p => if type(p) == str {
        p.split(name).intersperse(text(weight: "bold", fill: blue, name))
      } else { (p,) })
      .flatten()
  }
  parts.join()
}

#let companies = data.experience.map(e => txt(e.heading)).dedup()

// ---------- Top section ----------

#let top = {
  text(size: 34pt, weight: "bold", tracking: -0.02em, fill: blue, data.name)
  let headline = get(data, "headline")
  let subheadline = get(data, "subheadline")
  if headline != none {
    v(-5pt)
    text(size: 12pt, tracking: 0.08em, upper(headline))
  }
  if subheadline != none {
    v(if headline != none { -3pt } else { -5pt })
    text(size: 9.5pt, fill: muted, subheadline)
  }
  if headline != none or subheadline != none {
    v(2pt)
    line(length: 0.55in, stroke: 3pt + gold)
  }
  if get(data, "summary") != none {
    v(6pt)
    // The summary is the personalized pitch for this application.
    par(justify: true, text(size: 9.5pt, emphasize(txt(data.summary), companies)))
  }
}

// ---------- Left column ----------

#let left-column = {
  if get(data, "skills") != none and data.skills.len() > 0 {
    section-title("Skills")
    for g in data.skills {
      label(g.name)
      linebreak()
      // Each item stays on one line ("CSS/SCSS", not "CSS/" + "SCSS"), so
      // lines only break between items.
      g.items.map(i => box(txt(i))).join(", ")
      v(6pt)
    }
  }

  if get(data, "education") != none and data.education.len() > 0 {
    v(10pt)
    section-title("Education")
    data.education.map(e => {
      txt(e.heading)
      if get(e, "subheading") != none { linebreak(); txt(e.subheading) }
      if get(e, "dates") != none { linebreak(); text(size: 8pt, fill: muted, txt(e.dates)) }
    }).join(v(6pt))
  }
}

// ---------- Middle column ----------

#let entry(e) = block(breakable: false, width: 100%, {
  place(dx: -12.5pt, dy: 2pt, circle(radius: 3pt, fill: gold))
  grid(
    columns: (1fr, auto),
    column-gutter: 6pt,
    text(size: 9.5pt, weight: "bold", e.heading),
    if get(e, "dates") != none { text(size: 8pt, fill: muted, txt(e.dates)) },
  )
  if get(e, "subheading") != none {
    v(-2pt)
    text(fill: muted, {
      e.subheading
      if get(e, "location") != none [ · #e.location]
    })
  }
  if get(e, "bullets") != none and e.bullets.len() > 0 {
    v(1pt)
    list(..e.bullets.map(txt))
  }
})

#let middle-column = {
  section-title("Experience")
  let entries = data.experience.map(entry).join(v(8pt))
  // The whole timeline is gold: the line as well as the dots.
  pad(left: 3pt, block(inset: (left: 9.5pt), stroke: (left: 1.5pt + gold), entries))
}

// ---------- Right column ----------

#let right-column = {
  section-title("Contact")
  for c in data.contact {
    label(c.label)
    linebreak()
    fit(if get(c, "href") != none { link(c.href, txt(c.value)) } else { txt(c.value) })
    v(5pt)
  }

  if get(data, "interests") != none {
    v(10pt)
    section-title("Interests")
    text(size: 7.75pt, txt(data.interests))
  }
}

// ---------- Page ----------

#top
#v(14pt)
#grid(
  columns: (1.9in, 1fr, 1.8in),
  column-gutter: 0.2in,
  left-column, middle-column, right-column,
)
