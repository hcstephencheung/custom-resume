// Single-page resume on one cream background:
//   top:   name, headline and summary, full width
//   fit:   a full-width, gold-bordered "Why I'm a fit" panel with the
//          personalized points, company names highlighted in blue
//   left:  contact and education
//   right: the experience timeline (roles only, no bullets), drawn in gold,
//          then skills, then interests in smaller type
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
// follows source order: top section, the fit panel, then the left and right
// columns.

#let data = if "data" in sys.inputs {
  json(bytes(sys.inputs.data))
} else {
  yaml("mock.yaml")
}

#let cream = rgb("#fcffe7")  // page background
#let blue = rgb("#3657d9")   // name, section titles, company names in "Why I'm a fit"
// Exact complement of the blue (hue 48°). Shapes only: as text it is 1.6:1
// on cream, too faint to read.
#let gold = rgb("#f5c919")   // headline bar, timeline, "Why I'm a fit" border
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

#let section-title(title, rule: blue, size: 10pt) = block(sticky: true, below: 6pt, {
  heading(level: 2, text(size: size, weight: "bold", tracking: 0.06em, fill: blue, upper(title)))
  v(3pt)
  line(length: 100%, stroke: 0.75pt + rule)
})

#let label(body) = text(size: 7pt, tracking: 0.06em, fill: muted, upper(body))

// Shrinks a value such as an email or URL to fit on one line instead of
// wrapping: a line break inside an address splits it in extracted text.
// Below 80% it would be unreadable, so a value that still doesn't fit wraps.
#let fit(body) = layout(size => {
  let scale = calc.max(0.8, size.width / measure(body).width)
  if scale >= 1 { body } else { text(size: 1em * scale, body) }
})

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
    par(justify: true, text(size: 9.5pt, data.summary))
  }
}

// ---------- "Why I'm a fit" row ----------

// A full-width, gold-bordered panel holding the points written for this
// application. Its title and text are set 20% larger than the columns below
// so the note leads the page.
#let fit-panel = block(width: 100%, stroke: 1pt + gold, radius: 6pt, inset: 10pt, {
  section-title("Why I'm a fit", size: 12pt)
  // A point can name the company it comes from; the sentence mentions the
  // company in its own words, and each mention is set in bold blue. The text
  // itself stays plain, so extracted text reads naturally.
  let point(p) = if type(p) == dictionary {
    let company = text(weight: "bold", fill: blue, txt(p.company))
    txt(p.text).split(txt(p.company)).join(company)
  } else {
    txt(p)
  }
  text(size: 10.5pt, {
    let note = data.personalized
    if type(note) == array { list(..note.map(point)) } else { txt(note) }
  })
})

// ---------- Left column ----------

#let left-column = {
  section-title("Contact")
  for c in data.contact {
    label(c.label)
    linebreak()
    fit(if get(c, "href") != none { link(c.href, txt(c.value)) } else { txt(c.value) })
    v(5pt)
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

// ---------- Right column ----------

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
  // No bullets: achievements live in the "Why I'm a fit" panel, each tied to
  // its company, so the timeline stays a compact list of roles.
})

#let right-column = {
  section-title("Experience")
  let entries = data.experience.map(entry).join(v(7pt))
  // The whole timeline is gold: the line as well as the dots.
  pad(left: 3pt, block(inset: (left: 9.5pt), stroke: (left: 1.5pt + gold), entries))

  // Skills as label / items rows: the wide right column fits each group on a
  // line or two.
  if get(data, "skills") != none and data.skills.len() > 0 {
    v(12pt)
    section-title("Skills")
    grid(
      // The name column sizes to the longest name, so names never wrap.
      columns: (auto, 1fr),
      column-gutter: 8pt,
      row-gutter: 4pt,
      ..data.skills.map(g => (
        pad(top: 1.5pt, label(g.name)),
        // Each item stays on one line ("CSS/SCSS", not "CSS/" + "SCSS"), so
        // lines only break between items.
        g.items.map(i => box(txt(i))).join(", "),
      )).flatten(),
    )
  }

  if get(data, "interests") != none {
    v(12pt)
    section-title("Interests")
    text(size: 7.75pt, txt(data.interests))
  }
}

// ---------- Page ----------

#top
#v(14pt)
#if get(data, "personalized") != none {
  fit-panel
  v(14pt)
}
#grid(
  columns: (2.3in, 1fr),
  column-gutter: 0.25in,
  left-column, right-column,
)

