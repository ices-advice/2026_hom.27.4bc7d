## Prepare plots and tables for report

## Before: model/*.RData, data/input.RData
## After:  report/report_<run>.html, report/model_comparison.html

library(icesTAF)
library(rmarkdown)

mkdir("report")

#- extract only the files actually used below from the InterCatch export
zip_file <- list.files(taf.data.path(), pattern="\\.zip$", full.names=TRUE)
if(length(zip_file) == 0)
  zip_file <- list.files(pattern="\\.zip$", full.names=TRUE)
if(length(zip_file) > 0) {
  needed <- c("canum.txt", "weca.txt", "caton.txt", "CatchAndSampleDataTables.txt")
  avail  <- intersect(needed, unzip(zip_file[1], list=TRUE)$Name)
  unzip(zip_file[1], files=avail, exdir=taf.data.path(), overwrite=TRUE)
}

#- Render the diagnostics report for each model run found in model/
model_files <- list.files("model", pattern="\\.RData$", full.names=TRUE)

for (model_file in model_files) {
  run <- sub("^model_", "", tools::file_path_sans_ext(basename(model_file)))
  message("Rendering report.Rmd for run: ", run)

  render("report.Rmd",
         params      = list(model_file = model_file),
         output_file = paste0("report_", run, ".html"),
         output_dir  = "report",
         envir       = new.env())
}

#- Render the cross-model / previous-assessment comparison report
message("Rendering model_comparison.Rmd")

render("model_comparison.Rmd",
       output_file = "model_comparison.html",
       output_dir  = "report",
       envir       = new.env())
