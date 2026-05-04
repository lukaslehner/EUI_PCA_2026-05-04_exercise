# ===========================================================================
# Fetch real OECD LMP data via SDMX API and write almp_data.csv
# Lukas Lehner — EUI Workshop, 4 May 2026
# ===========================================================================
#
# Source: OECD Labour Market Programmes database (DSD_LMP@DF_LMP)
# https://data-explorer.oecd.org/vis?df[ds]=DisseminateFinalDMZ&df[id]=DSD_LMP@DF_LMP&df[ag]=OECD.ELS.JAI
#
# Variable: public expenditure (EXP), % of GDP (PT_B1GQ)
# Programmes (categories 1, 2, 4-7 — the six "active" ALMP categories):
#   LMP_10   PES and administration
#   LMP_20   training
#   LMP_40   employment incentives
#   LMP_50   supported & sheltered employment, rehabilitation
#   LMP_60   direct job creation
#   LMP_70   start-up incentives
#
# We average the latest five years (2018-2022) per country and convert each
# country's vector to spending shares of total ALMP spending.
# ---------------------------------------------------------------------------

library(tidyverse)

# ---- 1. Pull from OECD SDMX -----------------------------------------------

api_url <- paste0(
  "https://sdmx.oecd.org/public/rest/data/",
  "OECD.ELS.JAI,DSD_LMP@DF_LMP,1.0/",
  ".EXP.LMP_10+LMP_20+LMP_40+LMP_50+LMP_60+LMP_70.PT_B1GQ",
  "?startPeriod=2018&endPeriod=2022",
  "&dimensionAtObservation=AllDimensions",
  "&format=csvfilewithlabels"
)

tmp <- tempfile(fileext = ".csv")
download.file(api_url, tmp, quiet = TRUE)
raw <- read_csv(tmp, show_col_types = FALSE)

# ---- 2. Clean --------------------------------------------------------------

prog_lookup <- c(
  LMP_10 = "pes_admin",
  LMP_20 = "training",
  LMP_40 = "emp_incentives",
  LMP_50 = "supported_emp",
  LMP_60 = "direct_job_creation",
  LMP_70 = "start_up_incentives"
)

european_iso3 <- c(
  "AUT","BEL","BGR","CHE","CZE","DEU","DNK","ESP","EST","FIN",
  "FRA","GRC","HRV","HUN","IRL","ISL","ITA","LTU","LUX","LVA",
  "NLD","NOR","POL","PRT","ROU","SVK","SVN","SWE","TUR"
)

shares <- raw |>
  filter(REF_AREA %in% european_iso3) |>
  mutate(category = prog_lookup[PROGRAMME]) |>
  group_by(REF_AREA, category) |>
  summarise(mean_pct_gdp = mean(OBS_VALUE, na.rm = TRUE), .groups = "drop") |>
  group_by(REF_AREA) |>
  mutate(share = 100 * mean_pct_gdp / sum(mean_pct_gdp, na.rm = TRUE)) |>
  ungroup() |>
  select(country = REF_AREA, category, share) |>
  pivot_wider(names_from = category, values_from = share)

# Keep only countries with non-zero spending in every category
shares <- shares |>
  drop_na() |>
  filter(if_all(-country, ~ !is.nan(.) & is.finite(.))) |>
  arrange(country)

# Round to 2 decimals so the CSV stays readable
shares_rounded <- shares |>
  mutate(across(-country, \(x) round(x, 2)))

print(shares_rounded, n = Inf)

# ---- 3. Write --------------------------------------------------------------

write_csv(shares_rounded, "almp_data.csv")

cat(sprintf("\nWrote almp_data.csv with %d countries.\n", nrow(shares_rounded)))
