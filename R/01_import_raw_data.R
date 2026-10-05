
# ============================================================
# 01_import_raw_data.R
# Import and combine eye-tracking data
# ============================================================

# Packages ---------------------------------------------------

library(tidyverse)
library(readxl)
library(janitor)


# 1. Import stimulus information --------------------------------

stimuli <- readxl::read_excel(
  "data/raw/exp_stimuli.xlsx"
)


# 2. Import eye-tracking data -----------------------------------

results_01_08 <- read_csv(
  "data/raw/PartlyCleanData_Part1-8.csv",
  show_col_types = FALSE
)

results_09_16 <- read_csv(
  "data/raw/PartlyCleanData_Part9-16.csv",
  show_col_types = FALSE
)


# 3. Inspect imported data --------------------------------------

# Dimensions
dim(results_01_08)
dim(results_09_16)

# Variable names
names(results_01_08)
names(results_09_16)

# Data structure
glimpse(results_01_08)
glimpse(results_09_16)


# 4. Combine eye-tracking datasets ------------------------------

results_raw <- bind_rows(
  results_01_08,
  results_09_16
)

dim(results_raw)
glimpse(results_raw)


# 5. Save combined dataset --------------------------------------

dir.create(
  "data/processed",
  showWarnings = FALSE,
  recursive = TRUE
)

saveRDS(
  results_raw,
  "data/processed/results_raw.rds"
)

