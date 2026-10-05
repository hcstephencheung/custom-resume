// Single-page resume on one cream background. A full-width top section holds
// the name, headline and summary; below it, three columns:
//   left:   contact, skills, education (the `sidebar` sections)
//   middle: a blue-bordered panel with the personalized note and, at its
//           foot, interests in smaller type
//   right:  the experience timeline, drawn in gold
//
// Data arrives as a JSON string in `sys.inputs.data` (see render.py). Compiled
// on its own it falls back to mock.yaml, so the layout can be iterated on with:
//   typst watch templates/personalized-three-column/resume.typ --font-path fonts --ignore-system-fonts
//
// ATS notes: keep tracking <= 0.08em (wider tracking is extracted as
// "S P A C E D" text), ligatures off ("ﬁ" glyphs break keyword matching),
// hyphenation off ("Type-Script" breaks it too) and kerning off (Space
// Grotesk tightens "tt" enough that some parsers read "cut ting"). Text order
// follows source order: top section, then left, middle and right columns.

#let data = if "data" in sys.inputs {
  json(bytes(sys.inputs.data))
} else {
  yaml("mock.yaml")
}

#let cream = rgb("#fcffe7")  // page background
#let blue = rgb("#3657d9")   // name, section titles, middle panel border
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

#let section-title(title, rule: blue) = block(sticky: true, below: 6pt, {
  heading(level: 2, text(size: 10pt, weight: "bold", tracking: 0.06em, fill: blue, upper(title)))
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

// ---------- Left column ----------

#let left-column = {
  section-title("Contact")
  for c in data.contact {
    label(c.label)
    linebreak()
    fit(if get(c, "href") != none { link(c.href, txt(c.value)) } else { txt(c.value) })
    v(5pt)
  }
  v(10pt)

  for s in data.sidebar {
    section-title(s.title)
    if get(s, "groups") != none {
      for g in s.groups {
        label(g.name)
        linebreak()
        g.items.map(txt).join(", ")
        v(6pt)
      }
    } else if get(s, "entries") != none {
      for e in s.entries {
        txt(e.heading)
        if get(e, "subheading") != none { linebreak(); txt(e.subheading) }
        if get(e, "dates") != none { linebreak(); text(size: 8pt, fill: muted, txt(e.dates)) }
        v(6pt)
      }
    } else if get(s, "items") != none {
      for item in s.items {
        txt(item)
        v(4pt)
      }
    } else if get(s, "text") != none {
      txt(s.text)
    }
    v(10pt)
  }
}

// ---------- Middle column ----------

// Takes an explicit height: inside a grid, `height: 100%` (and even `layout`)
// resolves against the whole page body, so the panel would run past the
// bottom margin.
#let middle-column(height) = block(
  width: 100%,
  height: height,
  stroke: 1pt + blue,
  radius: 6pt,
  inset: 10pt,
  {
    if get(data, "personalized") != none {
      section-title("Personalized")
      par(justify: true, txt(data.personalized))
    }
    // Pushes interests to the foot of the panel.
    v(1fr)
    if get(data, "interests") != none {
      section-title("Interests")
      text(size: 7.75pt, txt(data.interests))
    }
  },
)

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
  if get(e, "bullets") != none and e.bullets.len() > 0 {
    v(1pt)
    list(..e.bullets.map(txt))
  }
})

#let right-column = {
  section-title("Experience")
  let entries = data.experience.map(entry).join(v(9pt))
  // The whole timeline is gold: the line as well as the dots.
  pad(left: 3pt, block(inset: (left: 9.5pt), stroke: (left: 1.5pt + gold), entries))
}

// ---------- Page ----------

// The columns fill the rest of the page so the middle panel's border runs to
// the bottom margin; their height is the page body minus the measured top
// section. The resume is meant to fit on this one page.
#let gap = 14pt
#layout(page => {
  let columns-height = page.height - measure(block(width: page.width, top)).height - gap
  stack(
    spacing: gap,
    block(width: 100%, top),
    grid(
      columns: (1.75in, 2.25in, 1fr),
      rows: columns-height,
      column-gutter: 0.2in,
      // Side columns start at the panel's inset so all three titles line up.
      pad(top: 10pt, left-column), middle-column(columns-height), pad(top: 10pt, right-column),
    ),
  )
})
