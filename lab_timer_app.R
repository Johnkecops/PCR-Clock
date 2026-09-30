# Lab Timer dashboard (Shiny): PCR thermocycler / incubation countdown in the browser.
# Run:  shiny::runApp("lab_timer_app.R")     (from this folder; RStudio: "Run App")
# Self-contained: schedule logic and dashboard drawing are defined below.

library(shiny)

# Protocols: one row per step. cycles > 1 repeats the whole "block".
protocols <- list(
  pcr = list(
    list(name = "Initial denaturation", temp = 95, sec = 180, block = "init"),
    list(name = "Denaturation",         temp = 95, sec = 30,  block = "cycle"),
    list(name = "Annealing",            temp = 55, sec = 30,  block = "cycle"),
    list(name = "Extension",            temp = 72, sec = 60,  block = "cycle"),
    list(name = "Final extension",      temp = 72, sec = 300, block = "final"),
    list(name = "Hold",                 temp = 4,  sec = 60,  block = "hold")
  ),
  incubation = list(
    list(name = "Incubate 37 C", temp = 37, sec = 3600, block = "init")
  )
)
n_cycles <- c(pcr = 30, incubation = 1)

# Expand protocol into a flat schedule with start times and cycle numbers.
build_schedule <- function(steps, cycles) {
  df <- do.call(rbind, lapply(steps, as.data.frame, stringsAsFactors = FALSE))
  pre  <- df[df$block == "init", ]
  cyc  <- df[df$block == "cycle", ]
  post <- df[df$block %in% c("final", "hold"), ]
  cyc_all <- if (nrow(cyc)) {
    do.call(rbind, lapply(seq_len(cycles), function(i) transform(cyc, cycle = i)))
  }
  pre$cycle <- rep(0L, nrow(pre)); post$cycle <- rep(0L, nrow(post))
  s <- rbind(pre, cyc_all, post)
  s$end   <- cumsum(s$sec)
  s$start <- s$end - s$sec
  s$cycle <- as.integer(s$cycle)
  rownames(s) <- NULL
  s
}

# Row of the schedule active at `elapsed` seconds (last row once finished).
current_step <- function(s, elapsed) {
  i <- which(elapsed < s$end)[1]
  if (is.na(i)) nrow(s) else i
}

fmt_mmss <- function(x) sprintf("%02d:%02d", as.integer(x) %/% 60, as.integer(x) %% 60)

# Blue (cold) to red (hot) by temperature.
temp_col <- function(t) {
  f <- pmin(pmax((t - 4) / (95 - 4), 0), 1)
  rgb(f, 0.2, 1 - f)
}

draw_timer <- function(s, elapsed, title) {
  total <- max(s$end)
  done  <- elapsed >= total
  i     <- current_step(s, elapsed)
  st    <- s[i, ]
  left  <- if (done) 0 else st$end - elapsed
  frac  <- if (done) 1 else (elapsed - st$start) / st$sec
  ncyc  <- max(s$cycle)

  plot.new()
  plot.window(xlim = c(-1.2, 1.2), ylim = c(-1.5, 1.3), asp = 1)

  # countdown ring: grey track + colored arc of elapsed step fraction
  th <- seq(0, 2 * pi, length.out = 300)
  lines(cos(th), sin(th), col = "grey85", lwd = 14)
  arc <- seq(pi / 2, pi / 2 - 2 * pi * frac, length.out = 300)
  if (frac > 0) lines(cos(arc), sin(arc), col = temp_col(st$temp), lwd = 14)

  text(0, 0.30, if (done) "DONE" else st$name, cex = 1.3, font = 2)
  text(0, 0.00, fmt_mmss(left), cex = 3, font = 2)
  text(0, -0.30, sprintf("%d C", st$temp), cex = 1.6, col = temp_col(st$temp))
  if (ncyc > 0 && st$cycle > 0)
    text(0, -0.55, sprintf("cycle %d / %d", st$cycle, ncyc), cex = 1.1)

  # timeline bar: each step colored by temperature, marker = now
  x0 <- -1.1; x1 <- 1.1; y0 <- -1.15; y1 <- -1.0
  xs <- x0 + (x1 - x0) * cbind(s$start, s$end) / total
  rect(xs[, 1], y0, xs[, 2], y1, col = temp_col(s$temp), border = NA)
  xn <- x0 + (x1 - x0) * min(elapsed, total) / total
  segments(xn, y0 - 0.05, xn, y1 + 0.05, lwd = 3)
  text(0, -1.3, sprintf("elapsed %s   remaining %s",
                        fmt_mmss(min(elapsed, total)), fmt_mmss(max(total - elapsed, 0))),
       cex = 0.9)
  title(main = title)
}

beep_js <- "
Shiny.addCustomMessageHandler('beep', function(n) {
  var ctx = new (window.AudioContext || window.webkitAudioContext)();
  for (var k = 0; k < n; k++) {
    var o = ctx.createOscillator(); o.frequency.value = 880; o.connect(ctx.destination);
    o.start(ctx.currentTime + k * 0.3); o.stop(ctx.currentTime + k * 0.3 + 0.15);
  }
});"

ui <- fluidPage(
  tags$head(tags$script(HTML(beep_js))),
  titlePanel("Lab Timer"),
  sidebarLayout(
    sidebarPanel(
      width = 3,
      selectInput("protocol", "Protocol", c("PCR" = "pcr", "Incubation (37 C, 60 min)" = "incubation")),
      conditionalPanel("input.protocol == 'pcr'",
                       numericInput("cycles", "PCR cycles", 30, min = 1, max = 60)),
      numericInput("speed", "Speed (1 = real time)", 1, min = 1, max = 3600),
      actionButton("start", "Start / Pause", class = "btn-primary"),
      actionButton("reset", "Reset"),
      tags$p(tags$small("Beeps at each step change. Browser may need one click first to allow sound."))
    ),
    mainPanel(plotOutput("dash", height = "560px"))
  )
)

server <- function(input, output, session) {
  st <- reactiveValues(running = FALSE, acc = 0, t0 = NULL, last_step = 0)

  schedule <- reactive({
    cycles <- if (input$protocol == "pcr") max(1, floor(req(input$cycles))) else 1
    build_schedule(protocols[[input$protocol]], cycles)
  })

  reset <- function() { st$running <- FALSE; st$acc <- 0; st$t0 <- NULL; st$last_step <- 0 }
  observeEvent(list(input$protocol, input$cycles, input$speed, input$reset), reset(), ignoreInit = TRUE)

  observeEvent(input$start, {
    if (st$running) { st$acc <- st$acc + as.numeric(difftime(Sys.time(), st$t0, units = "secs")); st$running <- FALSE }
    else { st$t0 <- Sys.time(); st$running <- TRUE }
  })

  elapsed <- reactive({
    if (st$running) invalidateLater(250, session)
    real <- st$acc + if (st$running) as.numeric(difftime(Sys.time(), st$t0, units = "secs")) else 0
    real * max(1, req(input$speed))
  })

  observe({  # beep on step change / completion
    e <- elapsed(); s <- isolate(schedule())
    if (!isolate(st$running)) return()
    i <- current_step(s, e)
    if (i != isolate(st$last_step)) {
      if (isolate(st$last_step) != 0) session$sendCustomMessage("beep", 1)
      st$last_step <- i
    }
    if (e >= max(s$end)) {
      session$sendCustomMessage("beep", 3)
      st$acc <- max(s$end) / max(1, isolate(input$speed)); st$running <- FALSE
    }
  })

  output$dash <- renderPlot(draw_timer(schedule(), elapsed(), toupper(input$protocol)))
}

shinyApp(ui, server)
