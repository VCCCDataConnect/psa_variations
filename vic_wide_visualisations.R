# visualisations for Victorian ABS data
library(dplyr)
library(ggplot2)
library(stringr)
library(arrow)
library(sf)
library(haven)

folder_path <- "E:/auxiliary_datasets/"
filename_sa2_2016_shapes <- paste0(folder_path, 
                                   "shapefiles_2016/sa2/SA2_2016_AUST.shp")
filename_ra_2016 <- paste0(folder_path, 
                           "geographic_mapping/RA_2016_AUST.csv")
filename_sa1_2016_shapes <- paste0(folder_path, 
                                   "shapefiles_2016/sa1/SA1_2016_AUST.shp")
filename_sa1_2016_pop <- paste0(folder_path, 
                                "/census_2016/2016 Census GCP All Geographies for AUST/SA1/AUST/2016Census_G01_AUS_SA1.csv")

# load up the mapping
ra_mapping <- read_csv_arrow(filename_ra_2016) %>% filter(STATE_CODE_2016 == 2)

# SA2 shapefile load
sa2_shapes <- st_read(filename_sa2_2016_shapes)

# SA1 shapefile load
sa1_shapes <- 
  st_read(filename_sa1_2016_shapes) %>% 
  filter(STE_CODE16 == 2) %>%
  select(c("SA1_MAIN16", "SA1_7DIG16", "SA2_MAIN16", "SA2_5DIG16", "SA2_NAME16"))

# join with ra file
sa1_with_ra <- merge(x=sa1_shapes, 
                     y=ra_mapping,
                     by.y="SA1_MAINCODE_2016",
                     by.x="SA1_MAIN16")

# SA1 SEIFA distribution by quintile (comparing region and metro)

# load up the PSA cohort
cohort <- read_csv_arrow("Z:/Prostate_102023/data/VCA_Patron_Cohort_with_RA_PSA_140224.csv")

# best RA for each of the SA2_NAME16 values
sa2_best_ra <- read_csv_arrow("Z:/Prostate_102023/data/sa2_best_ra.csv")

# 
cohortid2 <- cohort$e_linkedpersonid %>% unique()

cohortid1 <- 
  cohort %>% 
  select(e_linkedpersonid, ageatdiagnosis, SA2_NAME16) %>% 
  merge(sa2_best_ra, by.x="SA2_NAME16", by.y="SA2_NAME16") %>%
  unique() %>% select(e_linkedpersonid)

cohortid1 <- cohortid1$e_linkedpersonid

# which e_linkedpersonid disappear after merge?
# these don't have a diagnosis sa2
id_different <- setdiff(cohortid2, cohortid1)

# visualisation of PSA cohort by age group and geography
cohort_age_ra <- cohort %>% 
  select(e_linkedpersonid, ageatdiagnosis, SA2_NAME16) %>% 
  merge(sa2_best_ra, by.x="SA2_NAME16", by.y="SA2_NAME16") %>%
  unique() %>%
  mutate(geography = ifelse(RA_best == "Major Cities of Australia", "Metro", "Rural")) %>%
  mutate(agegroup_new = case_when(
    ageatdiagnosis == "35-39" ~ "<40",
    ageatdiagnosis %in% c("40-44", "45-49") ~ "40-49",
    ageatdiagnosis %in% c("50-54", "55-59") ~ "50-59",
    ageatdiagnosis %in% c("60-64", "65-69") ~ "60-69",
    ageatdiagnosis %in% c("70-74", "75-79") ~ "70-79",
    ageatdiagnosis %in% c("80-84", "85+") ~ "80+"
  )) %>%
  group_by(geography, agegroup_new) %>%
  count()

ggplot(cohort_age_ra, aes(x = agegroup_new, y = n)) + 
  geom_bar(stat="identity", fill='salmon') + 
  geom_text(aes(label = n), vjust = -0.5, size = 4) + 
  facet_wrap(~geography, scales="fixed") + 
  labs(x = "Age Group", y = "Number of patients") +
  theme_minimal(base_size = 14)

# bar plot for all of CCV
ccv_age_group <- c("<40", "40-49", "50-59", "60-69", "70-79", "80+")
ccv_numbers <- c(4, 97, 887, 2307, 2127, 819)
cohort_ccv <- data.frame(agegroup = ccv_age_group, n = ccv_numbers)

ggplot(cohort_age_ra, aes(x = agegroup_new, y = n)) + 
  geom_bar(stat="identity", fill='salmon') + 
  geom_text(aes(label = n), vjust = -0.5, size = 4) + 
  facet_wrap(~geography, scales="fixed") + 
  labs(x = "Age Group", y = "Number of patients") +
  theme_minimal(base_size = 14)

ggplot(cohort_ccv, aes(x = agegroup, y = n)) +
  geom_bar(stat='identity', fill='salmon') + 
  geom_text(aes(label = n), vjust = -0.5, size=4) + 
  labs(x = "Age Group", y = "Number of patients") + 
  theme_minimal(base_size = 14)

# visualisation of counts by seifa and geography
cohort_seifa_ra <- cohort %>%
  select(e_linkedpersonid, diagnosis_seifa_quintle, SA2_NAME16) %>% 
  merge(sa2_best_ra, by.x="SA2_NAME16", by.y="SA2_NAME16") %>%
  unique() %>%
  mutate(geography = ifelse(RA_best == "Major Cities of Australia", 
                            "Metro", "Regional")) %>%
  group_by(geography, diagnosis_seifa_quintle) %>%
  count()

# calculate the percentages
cohort_seifa_ra <- transform(cohort_seifa_ra, percentage = n / tapply(n, geography, sum)[geography] * 100) %>%
  mutate(cohort = "VCR")

  
ggplot(cohort_seifa_ra, aes(x = diagnosis_seifa_quintle, y = percentage)) + 
  geom_bar(stat="identity", fill=brewer.pal(12, "Paired")[2]) + 
  facet_wrap(~geography, scales="fixed") + 
  labs(x = "SEIFA quintile", 
       y = "% of patients") +
  scale_y_continuous(limits = c(0, 40)) +
  theme_minimal(base_size = 14)

# do the same for the whole of Vic population
# calculated from ABS 2016 Census
vic_seifa_ra <- data.frame(geography = c(rep("Metro", 5), rep("Rural", 5)),
                           diagnosis_seifa_quintle = rep(c(1, 2, 3, 4, 5), 2),
                           n = c(649276, 731018, 911345, 1128547, 1120118, 
                                 323428, 335904, 331776, 244525, 120427),
                           percentage = c(14.3, 16.1, 20.1, 24.9, 24.7,
                                          23.9, 24.8, 24.5, 18.0, 8.88)) %>%
  mutate(cohort = "Victoria")

vic_vcr_seifa_ra <- rbind(vic_seifa_ra, cohort_seifa_ra)

ggplot(vic_seifa_ra, aes(x = factor(diagnosis_seifa_quintle),
                             y = percentage)) +
  geom_bar(stat = "identity", position = "dodge", fill = brewer.pal(12, "Paired")[2]) +
  facet_wrap(vars(geography)) +
  scale_y_continuous(limits = c(0, 40)) +
  labs(x = "SEIFA quintile", 
       y = "% of population") +
  theme_minimal(base_size = 14)

# by stage and geography
cohort_stage_ra <- cohort %>%
  select(e_linkedpersonid, stagederived, SA2_NAME16) %>% 
  filter(is.na(stagederived) == FALSE) %>%
  merge(sa2_best_ra, by.x="SA2_NAME16", by.y="SA2_NAME16") %>%
  unique() %>%
  mutate(geography = ifelse(RA_best == "Major Cities of Australia", 
                            "Metro", "Regional"),
         stagederived = str_sub(stagederived, 1, 1)) %>% 
  group_by(geography, stagederived) %>%
  count()

ggplot(cohort_stage_ra %>% filter(stagederived %in% c("1", "2", "3", "4")), 
       aes(x = stagederived, y = n)) + 
  geom_bar(stat="identity", fill='salmon') + 
  facet_wrap(~geography, scales="fixed") + 
  labs(x = "Stage", y = "Number of patients") +
  theme_minimal()

# by gleason and geography
cohort_gleason_ra <- cohort %>%
  select(e_linkedpersonid, totalgleason, SA2_NAME16) %>% 
  merge(sa2_best_ra, by.x="SA2_NAME16", by.y="SA2_NAME16") %>%
  unique() %>%
  mutate(geography = ifelse(RA_best == "Major Cities of Australia", 
                            "Metro", "Regional")) %>%
  mutate(gleason_new = case_when(
    totalgleason %in% c(1, 2, 3, 4, 5, 6) ~ "1-6",
    totalgleason == 7 ~ "7",
    totalgleason == 8 ~ "8",
    totalgleason == 9 ~ "9",
    totalgleason == 10 ~ "10",
    is.na(totalgleason) ~ "missing"
  )) %>%
  mutate(gleason_new = factor(gleason_new, levels = c("1-6", "7", "8", "9", "10", "missing"))) %>%
  group_by(geography, gleason_new) %>%
  count()

ggplot(cohort_gleason_ra, aes(x = gleason_new, y = n)) + 
  geom_bar(stat="identity", fill='salmon') + 
  facet_wrap(~geography, scales="fixed") + 
  labs(x = "Gleason score", y = "Number of patients") +
  theme_minimal()

# PSA testing
# values in 5 years before diagnosis
psa_values <- read_dta("E:/projects/Prostate_102023/data/psa_5year.dta")

# change remoteness values 1: Metro, 0: Regional
psa_values$remoteness <- as.character(psa_values$remoteness)
psa_values[psa_values$remoteness == 0, "remoteness"] <- "Regional"
psa_values[psa_values$remoteness == 1, "remoteness"] <- "Metro"

psa_values_filtered <- psa_values %>% filter(result_value_cleaned <= 20)

# scatter plot of psa values vs result_time for geography
ggplot(psa_values_filtered, aes(x = -result_timing, y = result_value_cleaned)) + 
  geom_point(colour = "blue", alpha = 0.5, size = 0.1) + 
  geom_smooth(method = "lm", se = FALSE, colour = "red") +
  geom_hline(yintercept = 3, size=1, linetype = "dotted", colour = "red") + 
  facet_wrap(~remoteness) + 
  labs(x = "Days before diagnosis", y = "PSA (ng/ml)") + 
  coord_cartesian(ylim = c(0, 20))

# get the earliest PSA value before diagnosis for each patient
# create psa_threshold category
psa_values_under3 <- psa_values %>% 
  filter(psa_over3 == FALSE) %>% 
  mutate(psa_category = "Under 3")

psa_values3 <- psa_values %>% 
  filter(psa_over3 == TRUE) %>%
  mutate(psa_category = "Over 3")

psa_values4 <- psa_values %>% 
  filter(psa_over4 == TRUE) %>%
  mutate(psa_category = "Over 4")

psa_values10 <- psa_values %>% 
  filter(psa_over10 == TRUE) %>%
  mutate(psa_category = "Over 10")

psa_values50 <- psa_values %>% 
  filter(psa_over50 == TRUE) %>%
  mutate(psa_category = "Over 50")

psa_values_tidier <- rbind(psa_values_under3, 
                           psa_values3, 
                           psa_values4, 
                           psa_values10, 
                           psa_values50)

# now plot it out
psa_values_tidier$psa_category <- factor(psa_values_tidier$psa_category, 
                                         levels = c("Under 3", "Over 3", "Over 4", "Over 10", "Over 50"))

# remove the under 3 ones
psa_values_tidier <- psa_values_tidier %>% filter(psa_category != "Under 3")

# for each patient get the earliest psa value before diagnosis that is > 3
psa_first <- 
  psa_values %>% 
  arrange(e_linkedpersonid, desc(result_timing)) %>%
  group_by(e_linkedpersonid) %>%
  slice(1) %>% 
  ungroup()
  
psa_values_under3 <- psa_first %>% 
  filter(psa_over3 == FALSE) %>% 
  mutate(psa_category = "Under 3")

psa_values3 <- psa_first %>% 
  filter(psa_over3 == TRUE) %>%
  mutate(psa_category = "Over 3")

psa_values4 <- psa_first %>% 
  filter(psa_over4 == TRUE) %>%
  mutate(psa_category = "Over 4")

psa_values10 <- psa_first %>% 
  filter(psa_over10 == TRUE) %>%
  mutate(psa_category = "Over 10")

psa_values50 <- psa_first %>% 
  filter(psa_over50 == TRUE) %>%
  mutate(psa_category = "Over 50")

psa_values_tidier <- rbind(psa_values_under3, 
                           psa_values3, 
                           psa_values4, 
                           psa_values10, 
                           psa_values50)

# now plot it out
psa_values_tidier$psa_category <- factor(psa_values_tidier$psa_category, 
                                         levels = c("Under 3", "Over 3", "Over 4", "Over 10", "Over 50"))

# remove the under 3 ones
psa_values_tidier <- psa_values_tidier %>% filter(psa_category != "Under 3")


psa2 <- psa_values_tidier %>% select(e_linkedpersonid, 
                                     result_timing, 
                                     psa_category, 
                                     remoteness)

ggplot(psa2, aes(x = result_timing, y = psa_category)) + 
  geom_boxplot(fill = "salmon") + 
  facet_wrap(~remoteness) + 
  labs(x = "Days before prostate cancer diagnosis", 
       y = "PSA threshold")

# box and whisker of delays by PSA threshold
diagnostic_interval <- read_csv_arrow("E:/projects/Prostate_102023/data/diagnostic_interval.csv")

psa_cutoffs <- c('diagnostic_interval_over3',
                 'diagnostic_interval_over4',
                 'diagnostic_interval_over10', 
                 'diagnostic_interval_over50')

interval_tidy <- 
  diagnostic_interval %>%
  select(e_linkedpersonid, 
         remoteness, 
         starts_with("diagnostic_")) %>%
  mutate(remoteness = ifelse(remoteness == "major city", 
                             "Metro", 
                             "Regional")) %>% 
  pivot_longer(cols = !c(e_linkedpersonid, remoteness),
               names_to = "psa_cutoff",
               values_to = "result") %>%
  mutate(psa_cutoff = factor(psa_cutoff, levels=psa_cutoffs))

ggplot(data=interval_tidy, 
       aes(y = psa_cutoff, x = result, fill = psa_cutoff)) +
  geom_boxplot() +
  stat_summary(fun.y = mean, geom = "point", size=3, colour="white") +
  xlab("Days before diagnosis of prostate cancer") +
  ylab("PSA level") +
  theme(legend.position = "none") +
  facet_grid(~remoteness) +
  scale_y_discrete(labels = c("PSA > 3", "PSA > 4", "PSA > 10", "PSA > 50")) +
  scale_fill_manual(values = c("#333399", "#6666FF", "#9999FF", "#CCCCFF"))

