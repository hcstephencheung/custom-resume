// Two-column resume: a 25% charcoal sidebar for contact details and keyword
// groups, and a main column that renders any number of sections.
//
// Data arrives as a JSON string in `sys.inputs.data` (see render.py). Compiled
// on its own it falls back to mock.yaml, so the layout can be iterated on with:
//   typst watch templates/two-column/resume.typ --font-path fonts --ignore-system-fonts
//
// ATS notes: keep tracking <= 0.08em (wider tracking is extracted as
// "S P A C E D" text) and ligatures off ("ﬁ" glyphs break keyword matching).

#let data = if "data" in sys.inputs {
  json(bytes(sys.inputs.data))
} else {
  yaml("mock.yaml")
}

#let paper = rgb("#e4e2de")
#let ink = rgb("#2b2b2b")
#let muted = rgb("#5a5956")
#let rule = rgb("#b9b7b3")
#let sidebar-ink = paper
#let sidebar-muted = rgb("#a9a7a3")
#let sidebar-rule = rgb("#6b6a67")

#let display-font = "Bebas Neue"
#let body-font = "Glacial Indifference"

#let get(d, key) = d.at(key, default: none)
// YAML turns values like `2016` into numbers; text needs strings.
#let txt(v) = if type(v) == str { v } else { str(v) }

#set document(title: data.name + " – Resume", author: data.name)
#set page(
  paper: "us-letter",
  margin: (top: 0.6in, bottom: 0.5in, x: 0pt),
  fill: paper,
  // Drawn as a page background so the sidebar colour repeats on every page.
  background: place(left + top, rect(width: 25%, height: 100%, fill: ink)),
)
#set text(font: body-font, size: 9.5pt, fill: ink, ligatures: false)
#set par(leading: 0.6em, spacing: 0.6em)
#set list(indent: 0pt, body-indent: 6pt, spacing: 0.45em)
#set heading(bookmarked: false)

// ---------- Sidebar ----------

#let sidebar-section(title, body) = {
  // Sticky keeps a section title on the same page as its first line of content.
  block(sticky: true, below: 6pt, {
    heading(level: 2, text(font: display-font, size: 15pt, weight: "regular", tracking: 0.06em, title))
    v(3pt)
    line(length: 100%, stroke: 0.75pt + sidebar-rule)
  })
  body
  v(18pt)
}

#let sidebar-label(body) = text(size: 7pt, tracking: 0.06em, fill: sidebar-muted, upper(body))

#let sidebar = {
  set text(fill: sidebar-ink, size: 8.75pt)

  sidebar-section("Contact", {
    for c in data.contact {
      sidebar-label(c.label)
      linebreak()
      if get(c, "href") != none { link(c.href, txt(c.value)) } else { txt(c.value) }
      v(6pt)
    }
  })

  for s in data.sidebar {
    sidebar-section(s.title, {
      if get(s, "groups") != none {
        for g in s.groups {
          text(size: 8pt, weight: "bold", tracking: 0.06em, upper(g.name))
          linebreak()
          g.items.map(txt).join(", ")
          v(7pt)
        }
      } else if get(s, "entries") != none {
        for e in s.entries {
          text(weight: "bold", upper(e.heading))
          if get(e, "subheading") != none { linebreak(); e.subheading }
          if get(e, "dates") != none { linebreak(); text(size: 8pt, fill: sidebar-muted, txt(e.dates)) }
          v(8pt)
        }
      } else if get(s, "items") != none {
        for item in s.items {
          txt(item)
          v(4pt)
        }
      }
    })
  }
}

// ---------- Main ----------

#let header = {
  text(font: display-font, size: 46pt, tracking: 0.04em, data.name)
  if get(data, "headline") != none {
    v(-6pt)
    text(size: 12pt, tracking: 0.08em, upper(data.headline))
    v(2pt)
    line(length: 0.55in, stroke: 3pt + ink)
  }
  v(18pt)
}

#let entry(e, timeline: false) = block(breakable: false, width: 100%, {
  if timeline {
    place(dx: -14pt, dy: 2pt, circle(radius: 3pt, fill: ink))
  }
  grid(
    columns: (1fr, auto),
    column-gutter: 8pt,
    text(size: 10pt, weight: "bold", e.heading),
    if get(e, "dates") != none { text(size: 8.5pt, fill: muted, txt(e.dates)) },
  )
  if get(e, "subheading") != none {
    v(-2pt)
    text(fill: muted, {
      e.subheading
      if get(e, "location") != none [ · #e.location]
    })
  }
  if get(e, "bullets") != none {
    v(1pt)
    list(..e.bullets.map(txt))
  }
})

#let main-section(s) = {
  block(sticky: true, below: 7pt, {
    heading(level: 2, text(size: 11pt, weight: "bold", tracking: 0.08em, upper(s.title)))
    v(4pt)
    line(length: 100%, stroke: 0.75pt + ink)
  })
  if get(s, "text") != none {
    par(justify: true, s.text)
  } else if get(s, "entries") != none {
    let timeline = get(s, "timeline") == true
    let entries = s.entries.map(e => entry(e, timeline: timeline)).join(v(10pt))
    if timeline {
      pad(left: 3pt, block(inset: (left: 11pt), stroke: (left: 0.75pt + rule), entries))
    } else {
      entries
    }
  }
  v(16pt)
}

#let main = {
  for s in data.sections { main-section(s) }
}

// ---------- Page ----------

#show heading: it => block(above: 0pt, below: 0pt, it.body)

// The header cell is listed first so the name comes first in the PDF's text
// order; explicit x/y places it visually at the top of the right column.
#grid(
  columns: (25%, 1fr),
  grid.cell(x: 1, y: 0, inset: (left: 0.5in, right: 0.6in), header),
  grid.cell(x: 0, y: 0, rowspan: 2, inset: (left: 0.3in, right: 0.25in), sidebar),
  grid.cell(x: 1, y: 1, inset: (left: 0.5in, right: 0.6in), main),
)
