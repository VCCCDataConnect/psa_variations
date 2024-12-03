library(dplyr)
library(arrow)
library(varhandle)
library(ggplot2)
library(stringr)

# filenames
filename <- "Z:/ID200/id200_patron_ivx_idvl_tst_release.csv"
filename_ivx_grp <- "Z:/ID200/id200_patron_ivx_grp_tst_release.csv" # can ignore
filename_lookup <- "Z:/ID200/id200_cohort_lookup_table_release.csv"
filename_patient <- "Z:/ID200/id200_patron_pat_dtl_release.csv"

# too big for memory
pathology <- open_csv_dataset(filename)
cohort_lookup <- open_csv_dataset(filename_lookup)
patron_patient <- open_csv_dataset(filename_patient)

# only relevant pathology data columns
columns_pathology <- c("Patient_PPN", 
                       "masterID", 
                       "newMasterId", 
                       "Results_ID",
                       "e_result_date", 
                       "Result_Name", 
                       "LOINC_Code",
                       "Result_Value", 
                       "Result_Numeric", 
                       "Result_Units")

# only relevant patron_patient columns (to get the e_linkedpersonid)
columns_patient <- c("Patient_PPN", 
                     "masterID")

# select subset of columns
patron_patient <- patron_patient %>% 
  select(columns_patient) %>% 
  collect()

cohort_lookup <- cohort_lookup %>% 
  select(Patient_UUID, e_linkedpersonid) %>% 
  collect()

# now join to the patron patient table to get the e_linkedpersonid
patron_patient <- merge(x=patron_patient, 
                        y=cohort_lookup, 
                        by.x='masterID', 
                        by.y='Patient_UUID', all.x=TRUE)

# all distinct Result_Name values: 10670
all_result_names <- pathology %>% 
  select("Result_Name") %>% 
  unique() %>% 
  collect()

# those that relate to PSA
key_terms <- c("PSA", "PROSTATE SPECIFIC ANTIGEN", "PROSTATIC SPECIFIC ANTIGEN")

results_filtered <- all_result_names$Result_Name %>% 
  toupper() %>%
  str_subset(paste0(key_terms, collapse="|"))

# how many of each of these are there in the data
psa_results <- pathology %>% 
  select(all_of(columns_pathology)) %>% 
  mutate(Result_Name = str_to_upper(Result_Name)) %>%
  filter(Result_Name %in% results_filtered) %>%
  collect()

psa_results %>% group_by(Result_Name) %>%
  count() %>%
  arrange(desc(n))

# remove additional spaces in result and loinc columns
psa_results <- psa_results %>% 
  mutate(LOINC_Code = str_trim(LOINC_Code),
         Result_Value = str_trim(Result_Value),
         Result_Name = str_trim(Result_Name))

# free vs total psa: don't need LOINC codes

# 2857-1 PSA in serum or plasma (y)
# 19199-9 PSA in semen (n)
# 12841-3 PSA free / total in serum or plasma (y)
# 10866-0 PSA free in serum or plasma (y)
# 14120-0 Deprecated PSA free / total in serum or plasma (y)
# 19201-3 PSA free in serum or plasma (y)
# 19205-4 PSA free in semen (n)
# for the uncommon LOINC codes what proportion of data do these represent?

# check if psa is ratio or free: don't need these
common_loinc_psa <- c("2857-1", 
                      "19199-9", 
                      "12841-3", 
                      "10866-0", 
                      "", 
                      "14120-0", 
                      "19205-4", 
                      "19201-3")

# check all those with free have 2857-1
# 487339 test results out of 518973 (93%)
top_loinc_counts <- psa_results %>% 
  filter(LOINC_Code %in% common_loinc_psa) %>% 
  group_by(LOINC_Code) %>% 
  count()


# clean the result values
# find all those that don't fit a numeric value: 84576
numeric_values <- check.numeric(psa_results$Result_Value)

# all those that are numeric: what are the units?
psa_results[numeric_values, ] %>% group_by(Result_Units) %>% count()

# drop all of these
# complexed psa
# epsa
# psacalc (check distribution)
# p2psa
# new calculated psa
# 
# drop all those free without ratio
# () lab name usually
# units which are valid
valid_units <- c("ug/L", 
                 "%", 
                 "ng/mL", 
                 "", 
                 "µg/L", 
                 "µg/L^µg/L", 
                 "Âµg/L", 
                 "ng/L", 
                 "^", 
                 "%^%", 
                 "\\XB5\\g/L", 
                 "Ratio", 
                 "?g/L")

# all the same units

# those that are not numeric values: 84576 results, 3914 distinct
psa_results[numeric_values == FALSE, ] %>% group_by(Result_Value) %>% count() %>% arrange(desc(n))

# '<' ones likely prostectomy patients, undetectable PSA levels
# create a result_value_cleaned column
# replace non-numeric characters
psa_results <- psa_results %>% 
  mutate(Result_Value_Cleaned = Result_Value) %>%
  mutate(Result_Value_Cleaned = str_replace_all(Result_Value_Cleaned, '[ ]+', '')) %>% 
  mutate(Result_Value_Cleaned= str_replace_all(Result_Value_Cleaned, 'S', '')) %>%
  mutate(Result_Value_Cleaned = str_replace_all(Result_Value_Cleaned, "R", "")) %>% 
  mutate(Result_Value_Cleaned = str_replace_all(Result_Value_Cleaned, "\\\\", "")) %>%
  mutate(Result_Value_Cleaned = str_replace_all(Result_Value_Cleaned, "<", "")) %>%
  mutate(Result_Value_Cleaned = str_replace_all(Result_Value_Cleaned, "\\^", "")) %>%
  mutate(Result_Value_Cleaned = str_replace_all(Result_Value_Cleaned, "\\*", "")) %>%
  mutate(Result_Value_Cleaned = str_replace_all(Result_Value_Cleaned, "A", "")) %>%
  mutate(Result_Value_Cleaned = str_replace_all(Result_Value_Cleaned, ">", ""))

psa_results <- psa_results %>%
  mutate(Result_Name = str_replace_all(str_trim(Result_Name), '[ ]+', ''))

# calculate numeric values for these
numeric_values <- check.numeric(psa_results$Result_Value_Cleaned)

# how many non-numeric now? 54
numeric_values %>% length() - sum(numeric_values)

# consider only numeric ones
psa_results <- psa_results[numeric_values, ]

# look at distributions of different LOINC code values: don't need this
#psa_results_common <- psa_results %>% filter(LOINC_Code %in% common_loinc_psa)

# convert to numeric
psa_results <- psa_results %>% 
  mutate(Result_Value_Cleaned = as.numeric(Result_Value_Cleaned)) %>%
  filter(is.na(Result_Value_Cleaned) == FALSE)

result_name_remove <- c("FREE PSA (MEASURED)", 
                        "S FREE PSA:", 
                        "FREE PSA (CENTAUR)", 
                        "FREE PSA (IMMULITE)", 
                        "FREE PSA", 
                        "COMPLEXED PSA", 
                        "FREE PSA (CALC)", 
                        "EPSA", 
                        "PSACALC", 
                        "FREE PSA(CALC)", 
                        "COMMENT PSA", 
                        "FREE PSA.", 
                        "FREE PSA (ACCESS)", 
                        "P2PSA (ACCESS)", 
                        "FPSA", 
                        "PROSTATE SPECIFIC ANTIGEN FREE", 
                        "FRPSA")

psa_results <- psa_results %>% filter(Result_Name %in% result_name_remove == FALSE)

# summary stats for each result name value look quite different
summary_stats_result_name <- psa_results %>%
  group_by(Result_Name) %>%
  summarise(
    Mean = mean(Result_Value_Cleaned),
    Median = median(Result_Value_Cleaned),
    Min = min(Result_Value_Cleaned),
    Max = max(Result_Value_Cleaned),
    Iqr = IQR(Result_Value_Cleaned)
  )

# remove those that have weird values
result_name_remove2 <- c("FPSA/PSA RATIO", 
                         "FREE/TOTAL PSA", 
                         "FREE:TOTAL PSA IMMULITE")

psa_results <- psa_results %>% 
  filter(Result_Name %in% result_name_remove2 == FALSE)

# group together results based on whether they:
# are free / total (%), 
# free / total (ratio),
# or total

ratio_perc <- c("%FREE PSA", 
                "F/TPSARATIO", 
                "F/TPSRATIO.", 
                "FPSA%", 
                "FREE:TOTALPSA", 
                "FREEPSA%", 
                "FREEPSARATIO", 
                "FREEPSARATIO(ACS)", 
                "FREETOTOTALPSA%", 
                "PSACOBAS", 
                "PSAFREE/TOTAL", 
                "PSAPERCENTAGE")

ratio_prop <- c("FREE/TOTALPSARATIO:", 
                "FREE:TOTALPSA(CENTAUR)", 
                "FREE:TOTALPSA(IMMULITE)", 
                "FREEPSA/PSARATIO")

# everything else is total PSA
total_psa <- setdiff(psa_results$Result_Name, c(ratio_prop, ratio_perc))

# cut off for biologically 10000 (?) check Meena's code.
# check search terms

psa_results_final <- psa_results %>%
  mutate(Result_Name_Cleaned = case_when(
    Result_Name %in% ratio_perc ~ "FREE PSA (%)",
    Result_Name %in% ratio_prop ~ "FREE PSA",
    TRUE ~ "TOTAL PSA"
  ))

# scale the % FREE ones by 0.01
psa_results_final_perc <- psa_results_final %>% filter(Result_Name_Cleaned == "FREE PSA (%)")
psa_results_final_other <- psa_results_final %>% filter(Result_Name_Cleaned != "FREE PSA (%)")

psa_results_final_perc$Result_Value_Cleaned = psa_results_final_perc$Result_Value_Cleaned * 0.01
psa_results_final_perc$Result_Name_Cleaned = "FREE PSA"

psa_results_final2 <- rbind(psa_results_final_other, psa_results_final_perc)

# now let's look at some stats
summary_stats_result_name <- psa_results_final2 %>%
  group_by(Result_Name_Cleaned) %>%
  summarise(
    Mean = mean(Result_Value_Cleaned),
    Median = median(Result_Value_Cleaned),
    Min = min(Result_Value_Cleaned),
    Max = max(Result_Value_Cleaned),
    Iqr = IQR(Result_Value_Cleaned)
  )

# let's look at the distributions
ggplot(data = psa_results_final2 %>% 
         filter(Result_Name_Cleaned == "TOTAL PSA") %>% 
         filter(Result_Value_Cleaned < 10), 
       aes(x = Result_Value_Cleaned)) + 
  geom_histogram(color = "black", fill = "orange")

# how many values above 1000 for total PSA: 323 -> remove
psa_results_tidy <- psa_results_final2 %>% filter(Result_Value_Cleaned < 1000)

# join with the patron patient table to get the e_linkedpersonid
psa_results_tidy <- merge(x=psa_results_tidy, 
                          y=patron_patient,
                          by.x='newMasterId',
                          by.y='masterID', 
                          all.x=TRUE)
# write the data
#psa_results_tidy %>% write_csv_arrow("psa_cleaned_140224.csv")

#psa_results_tidy %>% write_csv_arrow("psa_cleaned_080224.csv")