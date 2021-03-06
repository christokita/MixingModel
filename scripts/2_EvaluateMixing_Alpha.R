################################################################################
#
# Evaluate ensemble model outputs
#
################################################################################
rm(list = ls())

source("scripts/util/__Util__MASTER.R")

load("output/Rdata/Mix_AThreshM_7.50_7.50_BThreshM_10.00_10.00_deltas_0.60_0.60_threshSlope_7_Aalpha_1.50_1.50_Balpha_2.00_2.00_quitP_0.20.Rdata")

file_name <- "Mix_Alphas_A-inefficient_A-lower-thresh-A7.5"

####################
# Final task distributions
####################
###### Prepare ######
# Raw data
task_dist <- task_dist %>% 
  group_by(n) %>% 
  mutate(set = paste0(Mix, "-", replicate)) %>% 
  mutate(set = factor(set, 
                      levels = c(sort(apply(expand.grid(unique(Mix), unique(replicate)), 1, paste, collapse = "-")))))

# Mix means
task_dist_summary <- task_dist %>% 
  group_by(Mix, set) %>% 
  summarise(Task1 = mean(Task1),
            Task2 = mean(Task2)) %>% 
  group_by(Mix) %>% 
  summarise(Task1_mean = mean(Task1),
            Task1_SD = sd(Task1),
            Task1_SE = sd(Task1) / sqrt(length(Task1)),
            Task2_mean = mean(Task2),
            Task2_SD = sd(Task2),
            Task1_SE = sd(Task2) / sqrt(length(Task2))) %>% 
  filter(!Mix %in% c(0, 1)) %>% 
  mutate(Line = "Mixed",
         Group_mean = TRUE)


# Mix x Line means
task_dist_lines <- task_dist %>% 
  group_by(set, Mix, Line) %>% 
  summarise(Task1 = mean(Task1),
            Task2 = mean(Task2)) %>% 
  group_by(Mix, Line) %>% 
  summarise(Task1_mean = mean(Task1),
            Task1_SD = sd(Task1),
            Task1_SE = sd(Task1) / sqrt(length(Task1)),
            Task2_mean = mean(Task2),
            Task2_SD = sd(Task2),
            Task1_SE = sd(Task2) / sqrt(length(Task2))) %>% 
  mutate(Group_mean = Mix %in% c(0, 1))

#Bind
task_dist_summary <- task_dist_summary %>% 
  bind_rows(task_dist_lines) %>% 
  mutate(Group_mean = as.numeric(Group_mean))

# Null hypothesis lines
null_hypothesis <- task_dist_summary %>% 
  filter(Mix %in% c(0, 1))

###### Plot ######
# Plot raw data
gg_dist <- ggplot(data = task_dist, aes(y = Task1, x = set, color = Line)) +
  geom_point(size = 0.3) +
  theme_classic() +
  labs(x = "Replicate",
       y = "Frequency Task 1") +
  #scale_color_brewer(palette = "Paired") +
  scale_color_manual(values = c("#E52521", "#2B4B9B")) +
  scale_y_continuous(limits = c(0, 1), breaks = seq(0, 1, 0.2)) +
  theme_ctokita() +
  theme(axis.text.x = element_blank(), 
        strip.background = element_rect(color = NA, fill = "grey85")) +
  facet_grid(n~.)
gg_dist

ggsave(filename = paste0("output/Task_dist/", file_name, ".png"), width = 4, height = 2, dpi = 400)

# Plot summary points
gg_dist_sum <- ggplot(data = task_dist_summary, aes(y = Task1_mean, x = Mix, color = Line)) +
  geom_line(data = null_hypothesis, 
            aes(y = Task1_mean, x = Mix, group = NA),
            color = "grey70",
            linetype = "dashed",
            size = 0.3) +
  geom_errorbar(aes(ymin = Task1_mean - Task1_SE, ymax = Task1_mean + Task1_SE), 
                position = position_dodge(width = 0.05),
                width = 0.035,
                size = 0.2) +
  geom_point(aes(size = Group_mean),
             position = position_dodge(width = 0.05)) +
  theme_classic() +
  labs(x = "Fraction of A individuals in colony",
       y = "Frequency Task 1, mean \u00B1 s.e.") +
  scale_color_manual(values = c("#E52521", "#2B4B9B", "#7C217F")) +
  scale_size_continuous(range = c(0.1, 1), 
                        guide = FALSE) +
  # scale_y_continuous(limits = c(0, 0.4), breaks = seq(0, 1, 0.1)) +
  theme_ctokita() +
  theme(legend.position = c(0.9, 0.8),

        legend.background = element_blank())
gg_dist_sum

ggsave(filename = paste0("output/Task_dist/", file_name, "_Means.png"), width = 4, height = 2, dpi = 400)

