# Dynamic Analog Clock
# Continuously updates in real-time
# Click the stop button in RStudio console to stop

# Ensure we have an active graphics device
if (dev.cur() == 1) {
  if (Sys.info()["sysname"] == "Darwin") {
    quartz(width = 6, height = 6)
  } else if (Sys.info()["sysname"] == "Windows") {
    windows(width = 6, height = 6)
  } else {
    X11(width = 6, height = 6)
  }
}

# Function to draw the complete clock
draw_clock <- function(clock_time) {
  hours <- as.numeric(format(clock_time, "%H"))
  minutes <- as.numeric(format(clock_time, "%M"))
  seconds <- as.numeric(format(clock_time, "%S"))
  
  hours12 <- hours %% 12
  
  hour_angle <- pi / 2 - 2 * pi * (hours12 + minutes / 60) / 12
  minute_angle <- pi / 2 - 2 * pi * (minutes + seconds / 60) / 60
  second_angle <- pi / 2 - 2 * pi * seconds / 60
  
  plot.new()
  
  plot.window(
    xlim = c(-1.2, 1.2),
    ylim = c(-1.2, 1.2),
    asp = 1
  )
  
  circle <- seq(0, 2 * pi, length.out = 300)
  
  lines(
    cos(circle),
    sin(circle),
    col = "black",
    lwd = 2
  )
  
  for (number in 1:12) {
    angle <- pi / 2 - 2 * pi * number / 12
    
    text(
      x = 0.82 * cos(angle),
      y = 0.82 * sin(angle),
      labels = number
    )
  }
  
  segments(
    0, 0,
    0.50 * cos(hour_angle),
    0.50 * sin(hour_angle),
    col = "black",
    lwd = 6
  )
  
  segments(
    0, 0,
    0.75 * cos(minute_angle),
    0.75 * sin(minute_angle),
    col = "blue",
    lwd = 4
  )
  
  segments(
    0, 0,
    0.90 * cos(second_angle),
    0.90 * sin(second_angle),
    col = "red",
    lwd = 2
  )
  
  points(
    0, 0,
    pch = 16,
    cex = 1.5
  )
  
  title(
    main = format(clock_time, "%H:%M:%S")
  )
}

# Main loop: continuously update the clock
tryCatch({
  repeat {
    draw_clock(Sys.time())
    Sys.sleep(0.1)  # Update 10 times per second for smooth motion
  }
}, interrupt = function(e) {
  cat("\nClock stopped.\n")
}, error = function(e) {
  cat("Error:", conditionMessage(e), "\n")
})
