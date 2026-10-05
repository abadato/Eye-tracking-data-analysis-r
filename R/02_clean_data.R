
# ============================================================
# 02_clean_data.R
# Inspect and clean eye-tracking data
# ============================================================


# Packages ---------------------------------------------------

library(tidyverse)


# 1. Load combined data ---------------------------------------

results_raw <- readRDS(
  "data/processed/results_raw.rds"
)


# 2. Inspect dataset structure -------------------------------

# Dataset dimensions
dim(results_raw)

# Variable names
names(results_raw)

# Data structure
glimpse(results_raw)


# 3. Inspect participants -------------------------------------

# Number of unique participants
n_distinct(results_raw$`Participant name`)

# Participant identifiers
unique(results_raw$`Participant name`)

# Number of observations per participant
results_raw %>%
  count(`Participant name`, name = "n_rows")


# 4. Check for duplicate observations -------------------------

# Number of identical rows
sum(duplicated(results_raw))


# 5. Inspect eye-movement types -------------------------------

results_raw %>%
  count(
    `Eye movement type`,
    sort = TRUE
  )


# 6. Inspect Areas of Interest (AOIs) -------------------------

results_raw %>%
  count(
    AOI,
    sort = TRUE
  )


# 7. Inspect data validity ------------------------------------

results_raw %>%
  count(
    `Validity left`,
    sort = TRUE
  )

results_raw %>%
  count(
    `Validity right`,
    sort = TRUE
  )


# 8. Inspect stimuli ------------------------------------------

# Number of unique stimuli
n_distinct(
  results_raw$`Presented Stimulus name`
)

# Observations per stimulus
results_raw %>%
  count(
    `Presented Stimulus name`,
    sort = TRUE
  )


# 9. Inspect fixation durations -------------------------------

summary(
  results_raw$`Gaze event duration`
)


# 10. Apply fixation-duration criteria -------------------------

# Retain fixations between 80 and 2000 ms.
#
# Fixations shorter than 80 ms and longer than 2000 ms
# are excluded as potential artifacts.

results_clean <- results_raw %>%
  filter(
    `Gaze event duration` >= 80,
    `Gaze event duration` <= 2000
  )


# 11. Evaluate the cleaning step -------------------------------

# Number of observations before and after filtering
nrow(results_raw)
nrow(results_clean)

# Percentage of observations retained
retention_rate <- nrow(results_clean) / nrow(results_raw) * 100

retention_rate

# Percentage of observations removed
removal_rate <- 100 - retention_rate

removal_rate


# Compare fixation-duration distributions before and after
summary(
  results_clean$`Gaze event duration`
)


# 12. Save cleaned dataset -------------------------------------

dir.create(
  "data/processed",
  showWarnings = FALSE,
  recursive = TRUE
)

saveRDS(
  results_clean,
  "data/processed/results_clean.rds"
)