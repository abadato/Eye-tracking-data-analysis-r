
# ============================================================
# 03_prepare_and_bin_data.R
# Prepare eye-tracking data for time-course analysis
# ============================================================


# Packages ---------------------------------------------------

library(tidyverse)
library(readxl)
library(janitor)


# 1. Configuration -------------------------------------------

# Time-bin width in milliseconds
BIN_DURATION <- 20

# Participants excluded from the analysis
EXCLUDED_PARTICIPANTS <- c("part2")


# 2. Load input data ------------------------------------------

results_clean <- readRDS(
  "data/processed/results_clean.rds"
) %>%
  clean_names()


stimuli <- read_excel(
  "data/raw/exp_stimuli.xlsx"
)


# 3. Standardize input data -----------------------------------

# Standardize stimulus identifier
if ("items" %in% names(stimuli)) {
  stimuli <- stimuli
} else if ("Items" %in% names(stimuli)) {
  stimuli <- stimuli %>%
    rename(items = Items)
}

# Remove automatically generated row index if present
if ("x1" %in% names(results_clean)) {
  results_clean <- results_clean %>%
    select(-x1)
}


# 4. Filter and calculate relative onset times ----------------

results_binned <- results_clean %>%
  filter(
    eye_movement_type == "Fixation",
    !is.na(participant_name),
    !is.na(presented_stimulus_name),
    !participant_name %in% EXCLUDED_PARTICIPANTS
  ) %>%
  group_by(
    participant_name,
    presented_stimulus_name
  ) %>%
  mutate(
    item_onset_time = min(
      recording_timestamp,
      na.rm = TRUE
    ),
    
    relative_time = recording_timestamp - item_onset_time,
    
    time_bin = BIN_DURATION *
      round(relative_time / BIN_DURATION)
  ) %>%
  ungroup() %>%
  rename(
    items = presented_stimulus_name
  )


# 5. Standardize variables and create spatial AOI indicators --

et_data_joined <- results_binned %>%
  rename(
    participant = participant_name,
    aoi_label = aoi
  ) %>%
  mutate(
    left = if_else(
      aoi_label == "Left",
      1,
      0,
      missing = 0
    ),
    
    right = if_else(
      aoi_label == "Right",
      1,
      0,
      missing = 0
    )
  )


# 6. Join stimulus metadata ----------------------------------

et_data_joined <- et_data_joined %>%
  left_join(
    stimuli,
    by = "items"
  )


# 7. Map spatial AOIs to conceptual categories ---------------

et_data_joined <- et_data_joined %>%
  mutate(
    
    # Map the image presented on the left side
    # to its conceptual category.
    aoi1 = case_when(
      image_left == past_image ~ "Recent",
      image_left == future_image ~ "Future",
      TRUE ~ "Other"
    ),
    
    # Map the image presented on the right side
    # to its conceptual category.
    aoi2 = case_when(
      image_right == past_image ~ "Recent",
      image_right == future_image ~ "Future",
      TRUE ~ "Other"
    )
  )


# 8. Create target-hit variables ------------------------------

et_data_joined <- et_data_joined %>%
  mutate(
    
    recent_hit = if_else(
      (aoi1 == "Recent" & left == 1) |
        (aoi2 == "Recent" & right == 1),
      1,
      0,
      missing = 0
    ),
    
    future_hit = if_else(
      (aoi1 == "Future" & left == 1) |
        (aoi2 == "Future" & right == 1),
      1,
      0,
      missing = 0
    ),
    
    my_roi = case_when(
      recent_hit == 1 ~ "Recent",
      future_hit == 1 ~ "Future",
      TRUE ~ "out"
    )
  )


# 9. Define experimental condition ----------------------------

et_data_joined <- et_data_joined %>%
  mutate(
    condition = str_to_title(tense)
  )


# 10. Data-quality audit ---------------------------------------

unmatched_conditions <- sum(
  is.na(et_data_joined$condition)
)

n_fixations <- nrow(
  et_data_joined
)

n_participants <- n_distinct(
  et_data_joined$participant
)

n_items <- n_distinct(
  et_data_joined$items
)


cat("\n==================================================\n")
cat("             STEP 03 DATA AUDIT                  \n")
cat("==================================================\n")

cat(
  "Unmatched condition rows :", 
  unmatched_conditions, 
  "\n"
)

cat(
  "Processed fixation rows  :", 
  n_fixations, 
  "\n"
)

cat(
  "Unique participants      :", 
  n_participants, 
  "\n"
)

cat(
  "Unique items             :", 
  n_items, 
  "\n"
)

cat("\nTarget ROI distribution:\n")

print(
  table(
    et_data_joined$my_roi,
    useNA = "ifany"
  )
)

cat("==================================================\n\n")


# 11. Save processed data -------------------------------------

dir.create(
  "data/processed",
  showWarnings = FALSE,
  recursive = TRUE
)

saveRDS(
  et_data_joined,
  "data/processed/et_data_joined.rds"
)

write_tsv(
  et_data_joined,
  "data/processed/et_data_joined.tsv"
)