#import "@preview/cetz:0.3.4"

{
#let x-pattern = tiling(size: (2pt, 10pt), spacing: (-0.4pt, -2pt))[
  #place(line(start: (0%, 100%), end: (100%, 0%), stroke: 0.5pt + black))
]
    
#let symbol-library = (
  "z": (
    lines: (
      ((0, 0.5), (1, 0.5)),
    ),
    start: "mid",
    end: "mid"
  ),
  "_": (
    lines: (
      ((0, 0), (1, 0)),
    ),
    start: "low",
    end: "low"
  ),
  "‾": (
    lines: (
      ((0, 1), (1, 1)),
    ),
    start: "high",
    end: "high"
  ),
  "=": (
    lines: (
      ((0, 0), (1, 0)),
      ((0, 1), (1, 1)),
    ),
    start: "both",
    end: "both"
  ),
  "x": (
    lines: (
      ((0, 0), (1, 0)),
      ((0, 1), (1, 1)),
    ),
    start: "both",
    end: "both",
    fill: x-pattern
  ),
)

#let transition-library = (
  low: (
    high: (
      lines: (
        ((0, 0), (1, 1)),
      ),
    ),
    both: (
      lines: (
        ((0, 0), (1, 0)),
        ((0, 0), (1, 1)),
      ),
    ),
    mid: (
      lines: (
        ((0, 0), (1, 0.5)),
      )
    ),
  ),
  high: (
    low: (
      lines: (
        ((0, 1), (1, 0)),
      ),
    ),
    both: (
      lines: (
        ((0, 1), (1, 0)),
        ((0, 1), (1, 1)),
      ),
    ),
    mid: (
      lines: (
        ((0, 1), (1, 0.5)),
      )
    ),
  ),
  both: (
    low: (
      lines: (
        ((0, 0), (1, 0)),
        ((0, 1), (1, 0)),
      ),
      fills: (
        left: ((0, 1), (1, 0), (0, 0)),
      )
    ),
    high: (
      lines: (
        ((0, 0), (1, 1)),
        ((0, 1), (1, 1)),
      ),
      fills: (
        left: ((0, 1), (1, 1), (0, 0)),
      )
    ),
    both: (
      lines: (
        ((0, 0), (1, 1)),
        ((0, 1), (1, 0)),
      ),
      fills: (
        left: ((0, 1), (0.5, 0.5), (0, 0)),
        right: ((1, 1), (0.5, 0.5), (1, 0))
      )
    ),
    mid: (
      lines: (
        ((0, 0), (1, 0.5)),
        ((0, 1), (1, 0.5)),
      )
    ),
  ),
  mid: (
    low: (
      lines: (
        ((0, 0.5), (1, 0)),
      ),
    ),
    high: (
      lines: (
        ((0, 0.5), (1, 1)),
      ),
    ),
    both: (
      lines: (
        ((0, 0.5), (1, 1)),
        ((0, 0.5), (1, 0)),
      ),
      fills: (
        right: ((1, 1), (0, 0.5), (1, 0))
      )
    ),
  ),
)

#let timing(specs, label-style: (:), custom: () => {}) = {
  cetz.canvas({
    import cetz.draw: *
    
    // for i in range(0, 25) {
    //   line((i*1em, 5), (rel: (0, -10)), stroke: .2pt + gray)
    // }

    for (s, (label, spec)) in specs.enumerate() {
      let symbols = ()
      for char in spec.timing {
        symbols.push(char)
      }

      scope({
        set-origin((0, (specs.len() - s - 1) * 2em))
      
        content((0, 0.5), label, anchor: "east", ..label-style)

        for i in range(symbols.len()) {
          let symbol = symbols.at(i)
          let current = (
            symbol: symbol,
            proto: symbol-library.at(symbol),
            group: spec.at("groups", default: "").at(i, default: none)
          )

          let previous = none
          if i > 0 {
            let previous-symbol = symbols.at(i - 1)
            previous = (
              symbol: previous-symbol,
              proto: symbol-library.at(previous-symbol),
              group: spec.at("groups", default: "").at(i - 1, default: none)
            )
          }
            
          scope({
            if previous != none and ((previous.symbol != current.symbol) or (previous.group != current.group)) {
              let transition = transition-library.at(previous.proto.end).at(current.proto.start)
              let transition-width = spec.at("transition-width", default: 20%)
              scope({
                set-origin((i * 1em, 0))
                scale(x: transition-width)

                for l in transition.lines {
                  line(..l, stroke: (cap: "round"))
                }
                if "fill" in current.proto {
                  on-layer(-1, {
                    line(..transition.fills.right, stroke: none, fill: current.proto.fill)
                  })
                }
                if "fill" in previous.proto {
                  on-layer(-1, {
                    let fill-path = transition.at("fills", default: (:)).at("left", default: ((0, 0), (0, 0)))
                    line(..fill-path, stroke: none, fill: previous.proto.fill)
                  })
                }
              })
              set-origin((i * 1em + transition-width * 1em, 0))
              scale(x: 100% - transition-width)
            } else {
              set-origin((i * 1em, 0))
            }

            if "fill" in current.proto {
              on-layer(-1, {
                rect((0, 0), (1, 1), stroke: none, fill: current.proto.fill)
              })
            }

            for l in current.proto.lines {
              let coords = ()
              for c in l {
                coords.push(c)
              }
              line(..coords, stroke: (cap: "round"))
            }
          })
        }

        // labels
        for (group, label) in spec.at("labels", default: ()) {
          let m = spec.groups.match(regex(group + "+"))
          scope({
            set-origin((0, 0))
            content(
              ((m.start + m.end) / 2 * 1em + 0.5em * spec.at("transition-width", default: 20%), 0.5),
              text(size: 0.8em)[#label],
              anchor: "mid"
            )
          })
        }
      })
    }

    // execute custom drawing code
    custom()
  }, length: 1em)
}

#let waveform(timing, groups: (), labels: (:), transition-width: 20%) = {
  return (
    timing: timing,
    groups: groups,
    labels: labels,
    transition-width: transition-width
  )
}
