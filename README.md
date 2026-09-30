# Lab Timer: PCR and Incubation Countdown (Shiny)

A browser dashboard, written in R with Shiny, that counts down a PCR thermocycler
programme or a fixed-temperature incubation. It shows the current step, its
temperature, the cycle number, and a colour-coded timeline of the whole run.

> **For teaching only. Not validated for research or laboratory use.** See
> [Intended use and limitations](#intended-use-and-limitations).

## Motivation

PCR-based detection depends on well-designed primers and a correctly timed
thermal programme. Chandra and Parikesit (2021) describe in-silico design of PCR
primers for the SARS-CoV-2 S gene, walking through parameters such as %GC,
hairpins, dimers and melting temperature (Tm) [1]. Tambunan and Parikesit
(2010) argue that bioinformatics tools reduce the cost and time of wet-lab
work, while stressing that computational designs must still be verified at the
bench [2]. Parikesit et al. (2017) make a similar case for affordable, standard
computing resources in health and agriculture research [3].

This app extends that teaching line. Students who design primers on screen also
need to see what the designed reaction does at the bench: the denaturation,
annealing and extension steps, how many cycles run, and how long the whole
programme takes. The timer makes that sequence visible and lets a class step
through a full 30-cycle programme in about a minute by raising the speed
multiplier. The full BibTeX entries are in [PCR.bib](PCR.bib).

## Requirements

- R (4.1 or newer recommended)
- The `shiny` package

```r
install.packages("shiny")
```

## Usage

Open `lab_timer_app.R` in RStudio and click **Run App**. Or run from this folder:

```bash
Rscript -e 'shiny::runApp("lab_timer_app.R")'
```

The app opens in your default browser.

| Control | What it does |
|---|---|
| Protocol | PCR, or Incubation (37 °C for 60 min) |
| PCR cycles | Number of denaturation/annealing/extension cycles (default 30) |
| Speed | Time multiplier. 1 = real time; 30 = 30 times faster, for demonstrations |
| Start / Pause | Starts the run; press again to pause and resume |
| Reset | Returns to the start. Changing protocol, cycles or speed also resets |

The browser beeps at each step change and three times at the end. Browsers
usually need one click on the page before they allow sound.

### Default PCR programme

| Step | Temperature | Time |
|---|---|---|
| Initial denaturation | 95 °C | 3 min |
| Denaturation (each cycle) | 95 °C | 30 s |
| Annealing (each cycle) | 55 °C | 30 s |
| Extension (each cycle) | 72 °C | 60 s |
| Final extension | 72 °C | 5 min |
| Hold | 4 °C | 1 min |

These values are generic classroom numbers. Real programmes depend on the
polymerase, the primers (especially their Tm), and the amplicon length. To change
them, edit the `protocols` list near the top of `lab_timer_app.R`; each step is
one line.

## Project structure

```
.
├── lab_timer_app.R   # Shiny app: schedule logic, dashboard drawing, UI and server
├── clock.R           # Original analog clock (base R graphics), kept unchanged
├── PCR.bib           # BibTeX references cited in this README
├── LICENSE.md        # MIT license
├── .gitignore        # Files kept out of version control
└── README.md         # This file
```

## Intended use and limitations

This software is for **teaching and demonstration only**. It has not been
validated, calibrated or verified for research, clinical, diagnostic or any
other laboratory use.

- It is a **countdown display**. It does not connect to, read from, or control a
  thermocycler, incubator or any other instrument.
- Times are computed from the computer clock in the browser session. Timing
  accuracy is not guaranteed; a sleeping laptop, a background browser tab or a
  busy machine can delay updates.
- The bundled programmes are illustrative. Do not use them as a protocol for real
  experiments. Follow the polymerase manufacturer's instructions and your
  laboratory's validated protocols.
- Any result that matters must come from a calibrated instrument and validated
  procedures, not from this app.

## AI disclosure

This application and its documentation were developed with the assistance of an
AI coding assistant (Claude, by Anthropic, used through Claude Code). The AI
drafted and revised the code, the tests, and this README, including fixing
graphics-window problems found during development. AI-generated code can contain
mistakes. The built-in checks cover the schedule arithmetic and the app's basic
start, pause and reset logic; they do not prove correctness in every case. The
application has not been independently audited. Review the code before relying on
it, and see the limitations above.

## References

1. Chandra N, Parikesit AA. Chapter 2: The S Gene Primer Design for the Detection
   of SARS-CoV-2 Virus. In: *Updates in Internal Sciences for 2021*. Ankara:
   Iksad Publishing House; 2021. p. 334. ISBN 978-625-7562-94-2.
   <https://iksadyayinevi.com/home/updates-in-internal-sciences-for-2021/>
   (BibTeX key `Chandra2021`)
2. Tambunan USF, Parikesit AA. Cracking the genetic code of human virus by using
   open source bioinformatics tools. *Malaysian Journal of Fundamental and
   Applied Sciences*. 2010;6(1):42-50. doi:10.11113/mjfas.v6n1.175
   (BibTeX key `Tambunan2010b`)
3. Parikesit AA, Anurogo D, Putranto RA. Pemanfaatan bioinformatika dalam bidang
   pertanian dan kesehatan (The utilization of bioinformatics in the field of
   agriculture and health). *E-Jurnal Menara Perkebunan*. 2017;85(2).
   doi:10.22302/iribb.jur.mp.v85i2.237 (BibTeX key `PARIKESIT2017`)

## License

Released under the MIT License. See [LICENSE.md](LICENSE.md).

**AI Assistance Disclaimer:** This codebase was developed with the assistance of Claude Code. While the AI provided code generation, debugging, and structural support, the human developer maintains full responsibility for reviewing, testing, and maintaining all content and functionality
