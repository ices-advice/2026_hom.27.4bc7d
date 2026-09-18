## Extract results of interest, render TAF diagnostics reports

## Before: model/*.RData
## After:  output/plots_diagnostics_<run>.html

library(icesTAF)
library(rmarkdown)

mkdir("output")

#- Model runs to diagnose: RData file -> run label used in the output filename
runs <- list(
  "model/model_benchmark.RData"   = "run_benchmark",
  "model/model_obsvarpool.RData"  = "run_obsvarpool",
  "model/model_final.RData"       = "run_final"
  
)

for (model_file in names(runs)) {
  if (!file.exists(model_file)) {
    message("Skipping ", runs[[model_file]], ": ", model_file, " not found")
    next
  }

  run <- runs[[model_file]]
  message("Rendering diagnostics for run: ", run)

  render("output_diagnostics.Rmd",
         params      = list(model_file = model_file, run = run, refyy = 2025),
         output_file = paste0("plots_diagnostics_", run, ".html"),
         output_dir  = "output",
         envir       = new.env())
}

