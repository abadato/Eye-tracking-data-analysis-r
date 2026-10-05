
# ============================================================
# 04_aggregate_and_visualize.R
# Aggregate gaze measures across participants and generate
# time-course visualizations of the log gaze probability ratio.
# ============================================================


# Packages ---------------------------------------------------

library(tidyverse)


# 1. Configuration -------------------------------------------

# Smoothing constant used when a probability is zero
EPSILON <- 0.005


# 2. Load processed data -------------------------------------

et_data <- readRDS(
  "data/processed/et_data_joined.rds"
)


# 3. Calculate participant-level gaze probabilities -----------

participant_bins <- et_data %>%
  filter(
    !is.na(time_bin),
    !is.na(condition)
  ) %>%
  group_by(
    participant,
    time_bin,
    condition
  ) %>%
  summarise(
    
    # Proportion of fixations directed toward each target
    p_recent = mean(
      recent_hit,
      na.rm = TRUE
    ),
    
    p_future = mean(
      future_hit,
      na.rm = TRUE
    ),
    
    .groups = "drop"
  )


# 4. Calculate log gaze probability ratio --------------------

# Log probability ratio:
#
#   ln(P_recent / P_future)
#
# Positive values indicate relatively greater gaze probability
# for the Recent target.
#
# Negative values indicate relatively greater gaze probability
# for the Future target.
#
# A value of zero indicates equal gaze probabilities.

participant_log_ratios <- participant_bins %>%
  mutate(
    
    # Replace zero probabilities to avoid log(0)
    p_recent_adj = if_else(
      p_recent == 0,
      EPSILON,
      p_recent
    ),
    
    p_future_adj = if_else(
      p_future == 0,
      EPSILON,
      p_future
    ),
    
    log_ratio = log(
      p_recent_adj / p_future_adj
    )
  )


# 5. Aggregate across participants ---------------------------

timecourse_summary <- participant_log_ratios %>%
  group_by(
    time_bin,
    condition
  ) %>%
  summarise(
    
    mean_log_ratio = mean(
      log_ratio,
      na.rm = TRUE
    ),
    
    se_log_ratio = sd(
      log_ratio,
      na.rm = TRUE
    ) / sqrt(n()),
    
    n_participants = n_distinct(
      participant
    ),
    
    .groups = "drop"
  )


# 6. Define event timings -------------------------------------

# Approximate event timings in milliseconds relative to
# trial onset.

NP1_OFFSET <- 1245
VERB_ONSET <- 1490
ADV_ONSET  <- 2485
NP2_ONSET  <- 3363


# 7. Create time-course visualization -------------------------

p_timecourse <- ggplot(
  timecourse_summary,
  aes(
    x = time_bin,
    y = mean_log_ratio,
    linetype = condition,
    group = condition
  )
) +
  
  # Reference line indicating equal gaze probability
  geom_hline(
    yintercept = 0,
    linetype = "solid",
    color = "grey55",
    linewidth = 0.6
  ) +
  
  # Experimental event markers
  geom_vline(
    xintercept = NP1_OFFSET,
    linetype = "dashed",
    color = "grey40",
    linewidth = 0.6
  ) +
  
  geom_vline(
    xintercept = VERB_ONSET,
    linetype = "dashed",
    color = "grey40",
    linewidth = 0.6
  ) +
  
  geom_vline(
    xintercept = ADV_ONSET,
    linetype = "dashed",
    color = "grey40",
    linewidth = 0.6
  ) +
  
  geom_vline(
    xintercept = NP2_ONSET,
    linetype = "dashed",
    color = "grey40",
    linewidth = 0.6
  ) +
  
  # Event labels
  annotate(
    "text",
    x = NP1_OFFSET,
    y = -5.1,
    label = "NP1 Offset",
    hjust = 0,
    fontface = "bold",
    size = 3.3,
    color = "grey20"
  ) +
  
  annotate(
    "text",
    x = VERB_ONSET,
    y = -5.1,
    label = "Verb Onset",
    hjust = 0,
    fontface = "bold",
    size = 3.3,
    color = "grey20"
  ) +
  
  annotate(
    "text",
    x = ADV_ONSET,
    y = -5.1,
    label = "Adverb Onset",
    hjust = 0,
    fontface = "bold",
    size = 3.3,
    color = "grey20"
  ) +
  
  annotate(
    "text",
    x = NP2_ONSET,
    y = -5.1,
    label = "NP2 Onset",
    hjust = 0,
    fontface = "bold",
    size = 3.3,
    color = "grey20"
  ) +
  
  # Smoothed time-course curves
  geom_smooth(
    method = "loess",
    span = 0.25,
    se = TRUE,
    color = "black",
    fill = "grey75",
    alpha = 0.35,
    linewidth = 0.95
  ) +
  
  # Condition-specific line types
  scale_linetype_manual(
    values = c(
      "Past" = "dotted",
      "Future" = "solid"
    ),
    labels = c(
      "Past" = "Recent Condition (Past Tense)",
      "Future" = "Future Condition (Futuric Present)"
    )
  ) +
  
  # X-axis
  scale_x_continuous(
    breaks = seq(
      0,
      max(
        timecourse_summary$time_bin,
        na.rm = TRUE
      ),
      by = 300
    )
  ) +
  
  # Labels
  labs(
    title = "Time Course of Gaze Allocation",
    subtitle = "Log gaze probability ratio across 20-ms time bins",
    x = "Time (ms)",
    y = "ln(P(Recent) / P(Future))",
    linetype = "Condition",
    caption = paste(
      "Positive values indicate relatively greater gaze probability",
      "for the Recent target; negative values indicate relatively",
      "greater gaze probability for the Future target."
    )
  ) +
  
  # Plot theme
  theme_classic(
    base_size = 12
  ) +
  
  theme(
    legend.position = "top",
    legend.title = element_blank(),
    legend.key.width = unit(
      2.5,
      "lines"
    ),
    plot.title = element_text(
      face = "bold",
      size = 14
    ),
    plot.subtitle = element_text(
      color = "grey30",
      size = 10,
      margin = margin(
        b = 10
      )
    ),
    axis.title = element_text(
      face = "bold"
    ),
    axis.text = element_text(
      color = "black"
    ),
    plot.caption = element_text(
      color = "grey40",
      size = 8.5,
      margin = margin(
        t = 12
      )
    )
  )


# 8. Display plot ---------------------------------------------

print(p_timecourse)


# 9. Create output directories -------------------------------

dir.create(
  "results/figures",
  showWarnings = FALSE,
  recursive = TRUE
)

dir.create(
  "results/tables",
  showWarnings = FALSE,
  recursive = TRUE
)


# 10. Save figures --------------------------------------------

# PNG for GitHub and presentations
ggsave(
  filename = "results/figures/log_ratio_timecourse.png",
  plot = p_timecourse,
  width = 9.5,
  height = 5.5,
  dpi = 300,
  bg = "white"
)

# PDF for publication/manuscript use
ggsave(
  filename = "results/figures/log_ratio_timecourse.pdf",
  plot = p_timecourse,
  width = 9.5,
  height = 5.5
)


# 11. Save summary data ---------------------------------------

write_csv(
  timecourse_summary,
  "results/tables/log_ratio_20ms_summary.csv"
)


# 12. Analysis summary ----------------------------------------

cat("\n==================================================\n")
cat("             STEP 04 COMPLETE                     \n")
cat("==================================================\n")
cat(
  "Participants:",
  n_distinct(participant_log_ratios$participant),
  "\n"
)
cat(
  "Conditions:",
  n_distinct(participant_log_ratios$condition),
  "\n"
)
cat(
  "Time bins:",
  n_distinct(participant_log_ratios$time_bin),
  "\n"
)
cat(
  "Figure:",
  "results/figures/log_ratio_timecourse.png\n"
)
cat(
  "Summary table:",
  "results/tables/log_ratio_20ms_summary.csv\n"
)
cat("==================================================\n\n")
