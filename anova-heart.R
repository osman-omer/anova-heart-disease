# ------------------------------------------------------------
# Project 4: Group Comparison (ANOVA Framework / Kruskal-Wallis)
# Research Question:
# Does cholesterol differ across chest pain types (cp)?
#
# Variables:
# - chol: Continuous outcome
# - cp: Categorical factor with 4 levels
#
# Decision rules:
# - Check normality within each group (QQ plots)
# - Check homogeneity of variance (Levene's test)
# - Use One-way ANOVA if assumptions are met
# - Use Kruskal–Wallis if assumptions are violated
# ------------------------------------------------------------

# 0) Load packages
library(tidyverse)
library(rstatix)
library(ggpubr) 

# 1) Read data
data <- read_csv("heart.csv")

# 2) Quick structure check
glimpse(data)

# 3) Inspect chest pain codes
table(data$cp)

# 4) Convert cp to factor with labels and order
data <- data %>% 
  mutate(cp = factor(cp, 
                     labels = c("Typical angina", 
                                "Atypical angina",
                                "Non-anginal pain", 
                                "Asymptomatic")))

# Check conversion
table(data$cp)

# 5) Descriptive statistics by chest pain type
des_by_cp <- data %>% 
  group_by(cp) %>% 
  summarise(
    n = n(),
    mean_chol = mean(chol, na.rm = TRUE),
    sd_chol = sd(chol, na.rm = TRUE),
    median_chol = median(chol, na.rm = TRUE),
    iqr_chol = IQR(chol, na.rm = TRUE),
    .groups = "drop"
  )

des_by_cp

# 6) Initial visualization (boxplot)
box_anova <- ggplot(data, aes(x = cp, y = chol)) +
  geom_boxplot() +
  labs(
    x = "Chest pain type",
    y = "Cholesterol (mg/dL)",
    title = "Cholesterol by Chest Pain Type"
  ) 

box_anova

# 7) Normality check: QQ plots by group
ggqqplot_group <- function(data, grp) {
  data %>% 
    ggplot(aes(sample = chol)) +
    stat_qq() +
    stat_qq_line() +
    facet_wrap(vars({{ grp }}), nrow = 2) +
    labs(title = "QQ Plots of Cholesterol by Chest Pain Type")
}

ggqqplot_group(data, cp)

# 8) Homogeneity of variance (Levene's test)
levene_res <- data %>% 
  levene_test(chol ~ cp)
levene_res

# 9) Kruskal–Wallis test (used because assumptions violated)
kruskal_res <- data %>% 
  kruskal_test(chol ~ cp)
kruskal_res

# 10) Post-hoc Dunn test with Bonferroni correction
posthoc <- data %>% 
  dunn_test(chol ~ cp, p.adjust.method = "bonferroni")
posthoc

# 11) Effect size (epsilon squared)
ef_size <- data %>% 
  kruskal_effsize(chol ~ cp)
ef_size

# 12) Final visualization with significance stars
stat.test <- posthoc %>% add_xy_position(x = "cp")  # determines star positions

fin_vis <- ggboxplot(data, x = "cp", y = "chol", 
                     fill = "cp", palette = "jco",
                     add = "jitter", alpha = 0.6) +
  stat_pvalue_manual(stat.test, label = "p.adj.signif", hide.ns = TRUE) + # hide non-significant
  labs(
    x = "Chest pain type", 
    y = "Cholesterol (mg/dL)",
    title = "Significant Differences in Cholesterol Levels"
  ) +
  theme_minimal()

fin_vis

# 13) Return all main results as a list (optional)
list(
  descriptives = des_by_cp,
  levene = levene_res,
  kruskal = kruskal_res,
  posthoc = posthoc,
  effect_size = ef_size
)

# 14) Save plots
ggsave("plots/box_anova.png", plot = box_anova,
       width = 6, height = 4, dpi = 300)

ggsave("plots/qq_plots.png", plot = ggqqplot_group(data, cp),
       width = 8, height = 6, dpi = 300)

ggsave("plots/final_plot.png", plot = fin_vis,
       width = 6, height = 4, dpi = 300)
