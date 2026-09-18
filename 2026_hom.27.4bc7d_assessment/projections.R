## Short-term forecast (STF) report, one HTML per model run

## Before: model/*.RData
## After:  report/projections_<run>.html, forecast/<run>/*.csv

library(icesTAF)
library(rmarkdown)

mkdir("report")

# which model runs to project - edit this vector to add/drop runs.
# Only the final run (the run WGWIDE selected to provide advice) is projected.
runs <- c("model/model_final.RData")

for (model_file in runs) {
  run <- sub("^model_", "", tools::file_path_sans_ext(basename(model_file)))
  message("Rendering projections.Rmd for run: ", run)

  render("projections.Rmd",
         params      = list(model_file = model_file),
         output_file = paste0("projections_", run, ".html"),
         output_dir  = "report",
         envir       = new.env())
}
