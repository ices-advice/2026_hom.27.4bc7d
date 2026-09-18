# Refp_relative - relative reference levels for hom.27.4bc7d --------------------
#
# Recomputes "assessment summary - relative reference levels.csv" from the
# assessment object, i.e. the companion file to "assessment summary - relative.csv"
# that sag_2026.R reads via getref(). The relative-biomass chunk in projections.Rmd
# writes only the means + Blim/Bpa; this script adds the Fbar rows and the
# Iloss / Itrigger rows and keeps the whole file in one reproducible place.
#
# Everything is on the SAME scale as the relative series: each quantity divided
# by mean SSB over the reference period (model start .. terminal data year).
#
# ICES notes on Iloss / Itrigger
#  - Itrigger = 1.4 x Iloss is the biomass safeguard from the ICES empirical
#    advice rules for category 2/3 stocks (rb / rfb / chr; ICES Technical
#    Guidelines). In those rules Iloss is the lowest value of a *survey biomass
#    index*; here it is applied to the analytical SAM SSB because this stock is
#    a downgrade reported on a relative basis (cf. cod.27.22-24), not a true
#    index-based assessment. Verify the 1.4 factor and the terminal-year
#    treatment against the current Technical Guidelines before relying on it.
#  - Both Iloss variants are reported: over the full series, and excluding the
#    terminal year (the standard when the last point is the series minimum).
#  - Itrigger is ALSO given as = Bpa. sag_2026.R currently uploads the =Bpa
#    value (CustomLimitValue3); 1.4 x Iloss is there for comparison.
#
# Input  : model/model_final.RData        (NSHOM, NSHOM.sam)
# Output : forecast/<run>/assessment summary - relative reference levels.csv
# -----------------------------------------------------------------------------

rm(list = ls())

library(FLCore)
library(FLSAM)

## 1. Configuration -----------------------------------------------------------
model_file   <- "model/model_final.RData"
refpts       <- c(Blim = 179580, Bpa = 269555)   # ICES (2024); no F ref points defined
ILOSS_FACTOR <- 1.4                               # ICES empirical Itrigger multiplier

run_name <- sub("^model_", "", tools::file_path_sans_ext(basename(model_file)))
FC_DIR   <- file.path("forecast", run_name)
dir.create(FC_DIR, showWarnings = FALSE, recursive = TRUE)
out_file <- file.path(FC_DIR, "assessment summary - relative reference levels.csv")

## 2. Assessment time series (SAM) ------------------------------------------
load(model_file)                                  # NSHOM, NSHOM.sam, ...
termYr <- NSHOM@range[["maxyear"]]                # last data year - series end here

sam_series <- function(fn) {
  d <- as.data.frame(fn(NSHOM.sam))              # year, value, CV, lbnd, ubnd
  d[, c("year", "value")]
}
ssb_s  <- sam_series(FLCore::ssb)
rec_s  <- sam_series(FLCore::rec)
fbar_s <- sam_series(FLCore::fbar)
cat_s  <- as.data.frame(catch(NSHOM))[, c("year", "data")]   # observed catch (t)
names(cat_s) <- c("year", "catch")

yrs   <- sort(ssb_s$year[ssb_s$year <= termYr])   # reference period
ssb   <- ssb_s$value [match(yrs, ssb_s$year)]
rec   <- rec_s$value [match(yrs, rec_s$year)]
fbar  <- fbar_s$value[match(yrs, fbar_s$year)]
catch <- cat_s$catch [match(yrs, cat_s$year)]
hr    <- catch / ssb                              # harvest rate = catch / SSB

## 3. Reference levels ------------------------------------------------------
ssb_bar   <- mean(ssb)
rec_bar   <- mean(rec)
hr_bar    <- mean(hr)
fbar_bar  <- mean(fbar)
fbar_term <- fbar[yrs == termYr]

iloss_all  <- min(ssb)                            # lowest SSB over the whole series
iloss_notl <- min(ssb[yrs != termYr])             # lowest SSB excluding the terminal year
itrig_iloss <- ILOSS_FACTOR * iloss_all           # ICES empirical safeguard
itrig_bpa   <- refpts[["Bpa"]]                    # alternative: Itrigger = Bpa

rel <- function(x) round(x / ssb_bar, 4)          # put a quantity on the relative scale

## 4. Assemble (row order / labels match the file sag_2026.R reads) --------
ref_levels <- data.frame(
  Quantity = c(
    "mean SSB (t)",
    "mean recruitment (thousands)",
    "mean harvest rate (catch/SSB)",
    "mean Fbar (ages 2-8)",
    "Blim (t)",
    "Bpa (t)",
    "Blim relative to mean SSB",
    "Bpa relative to mean SSB",
    "Fbar 2-8 in termYr",
    "Fbar 2-8 relative to mean (termYr)",
    "Iloss = min SSB over series (t)",
    "Iloss excl. terminal year (t)",
    "Itrigger = 1.4 x Iloss (t)",
    "Itrigger (1.4 x Iloss) relative to mean SSB",
    "Itrigger = Bpa (t)",
    "Itrigger (=Bpa) relative to mean SSB",
    "Years"
  ),
  Value = c(
    round(ssb_bar),
    round(rec_bar / 1000),
    round(hr_bar, 4),
    round(fbar_bar, 4),
    refpts[["Blim"]],
    refpts[["Bpa"]],
    rel(refpts[["Blim"]]),
    rel(refpts[["Bpa"]]),
    round(fbar_term, 4),
    round(fbar_term / fbar_bar, 4),
    round(iloss_all),
    round(iloss_notl),
    round(itrig_iloss),
    rel(itrig_iloss),
    itrig_bpa,
    rel(itrig_bpa),
    sprintf("%d-%d", min(yrs), termYr)
  ),
  stringsAsFactors = FALSE
)

## 5. Optional cross-check against the relative series file ----------------
rel_file <- file.path(FC_DIR, "assessment summary - relative.csv")
if (file.exists(rel_file)) {
  rs <- read.csv(rel_file, check.names = FALSE)
  d  <- max(abs(rs$SSB_t[match(yrs, rs$Year)] - ssb), na.rm = TRUE)
  if (isTRUE(d > 1))
    warning(sprintf("SSB series differs from %s by up to %.1f t - is the run current?",
                    basename(rel_file), d))
}

## 6. Write + report -----------------------------------------------------
write.csv(ref_levels, out_file, row.names = FALSE)
cat("wrote", out_file, "\n\n")
print(ref_levels, row.names = FALSE)
