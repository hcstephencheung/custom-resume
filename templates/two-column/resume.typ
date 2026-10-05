// Two-column resume: a 25% charcoal sidebar for contact details and keyword
// groups, and a main column that renders any number of sections.
//
// Data arrives as a JSON string in `sys.inputs.data` (see render.py). Compiled
// on its own it falls back to mock.yaml, so the layout can be iterated on with:
//   typst watch templates/two-column/resume.typ --font-path fonts --ignore-system-fonts
//
// ATS notes: keep tracking <= 0.08em (wider tracking is extracted as
// "S P A C E D" text), ligatures off ("ﬁ" glyphs break keyword matching) and
// hyphenation off ("Type-Script" breaks it too). Kerning is off because
// Space Grotesk tightens "tt" enough that some parsers read "cut ting".

#let data = if "data" in sys.inputs {
  json(bytes(sys.inputs.data))
} else {
  yaml("mock.yaml")
}

#let cream = rgb("#fdfff1")  // page background, text on blue
#let blue = rgb("#3657d9")   // sidebar, name, section titles
// Exact complement of the blue (hue 48°). Shapes only: as text it is
// 1.6:1 on cream and 3.8:1 on blue, too faint to read.
#let gold = rgb("#f5c919")   // headline bar, timeline dots
#let ink = rgb("#262626")    // body text
#let muted = rgb("#5c5f52")  // secondary text on cream
#let rule = rgb("#b4c0ef")   // timeline line
#let sidebar-ink = cream
#let sidebar-muted = rgb("#d0d8f7")
#let sidebar-rule = rgb("#7f95e8")

#let font = "Space Grotesk"

// 25% of the US Letter page width.
#let sidebar-width = 2.125in

#let get(d, key) = d.at(key, default: none)
// YAML turns values like `2016` into numbers; text needs strings.
#let txt(v) = if type(v) == str { v } else { str(v) }

#set document(title: data.name + " – Resume", author: data.name)
#set page(
  paper: "us-letter",
  // The main column flows in the page body; the sidebar sits in the left margin.
  margin: (top: 0.6in, bottom: 0.5in, left: sidebar-width + 0.5in, right: 0.6in),
  fill: cream,
  // Drawn as a page background so the sidebar colour repeats on every page.
  background: place(left + top, rect(width: sidebar-width, height: 100%, fill: blue)),
)
#set text(font: font, size: 9.5pt, fill: ink, kerning: false, ligatures: false, hyphenate: false)
#set par(leading: 0.6em, spacing: 0.6em)
#set list(indent: 0pt, body-indent: 6pt, spacing: 0.45em)
#set heading(bookmarked: false)

// ---------- Sidebar ----------

#let sidebar-section(title, body) = {
  // Sticky keeps a section title on the same page as its first line of content.
  block(sticky: true, below: 6pt, {
    heading(level: 2, text(size: 11pt, weight: "bold", tracking: 0.06em, upper(title)))
    v(3pt)
    line(length: 100%, stroke: 0.75pt + sidebar-rule)
  })
  body
  v(18pt)
}

// Shrinks a value such as an email or URL to fit on one line instead of
// wrapping: a line break inside an address splits it in extracted text.
// Below 80% it would be unreadable, so a value that still doesn't fit wraps.
#let fit(body) = layout(size => {
  let scale = calc.max(0.8, size.width / measure(body).width)
  if scale >= 1 { body } else { text(size: 1em * scale, body) }
})

#let sidebar-label(body) = text(size: 7pt, tracking: 0.06em, fill: sidebar-muted, upper(body))

#let sidebar = {
  set text(fill: sidebar-ink, size: 8.75pt)

  sidebar-section("Contact", {
    for c in data.contact {
      sidebar-label(c.label)
      linebreak()
      fit(if get(c, "href") != none { link(c.href, txt(c.value)) } else { txt(c.value) })
      v(6pt)
    }
  })

  for s in data.sidebar {
    sidebar-section(s.title, {
      if get(s, "groups") != none {
        for g in s.groups {
          // Same label style as the contact fields above.
          sidebar-label(g.name)
          linebreak()
          g.items.map(txt).join(", ")
          v(7pt)
        }
      } else if get(s, "entries") != none {
        for e in s.entries {
          // Heading and subheading share the plain body style.
          txt(e.heading)
          if get(e, "subheading") != none { linebreak(); txt(e.subheading) }
          if get(e, "dates") != none { linebreak(); text(size: 8pt, fill: sidebar-muted, txt(e.dates)) }
          v(8pt)
        }
      } else if get(s, "items") != none {
        for item in s.items {
          txt(item)
          v(4pt)
        }
      } else if get(s, "text") != none {
        txt(s.text)
      }
    })
  }
}

// ---------- Main ----------

#let header = {
  text(size: 38pt, weight: "bold", tracking: -0.02em, fill: blue, data.name)
  let headline = get(data, "headline")
  let subheadline = get(data, "subheadline")
  if headline != none {
    v(-6pt)
    text(size: 12pt, tracking: 0.08em, upper(headline))
  }
  if subheadline != none {
    v(if headline != none { -3pt } else { -6pt })
    text(size: 9.5pt, fill: muted, subheadline)
  }
  if headline != none or subheadline != none {
    v(2pt)
    line(length: 0.55in, stroke: 3pt + gold)
  }
  v(18pt)
}

#let entry(e, timeline: false) = block(breakable: false, width: 100%, {
  if timeline {
    place(dx: -14pt, dy: 2pt, circle(radius: 3pt, fill: gold))
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
  if get(e, "stack") != none and e.stack.len() > 0 {
    v(1pt)
    text(size: 8.5pt, fill: muted)[Stack: #e.stack.map(txt).join(", ")]
  }
})

#let main-section(s) = {
  block(sticky: true, below: 7pt, {
    heading(level: 2, text(size: 11pt, weight: "bold", tracking: 0.08em, fill: blue, upper(s.title)))
    v(4pt)
    line(length: 100%, stroke: 0.75pt + blue)
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

// Source order sets the PDF's text order: name, then sidebar, then main, at any
// length. The sidebar is pinned into the left margin of page 1, so it must fit
// on one page; the main column flows onto as many pages as it needs.
#header
#place(
  top + left,
  dx: -(sidebar-width + 0.5in),
  block(width: sidebar-width, inset: (left: 0.3in, right: 0.2in), sidebar),
)
#main
