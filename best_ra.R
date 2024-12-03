# some SA2's span multiple RA's
# want to know which RA has the largest share of the SA2 population for each
# of these type of SA2
library(dplyr)
library(ggplot2)
library(stringr)
library(arrow)
library(sf)

# load up the ra_to_sa2 mapping
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

# load up SA1 census data to get population for each SA1
sa1_population <- 
  read_csv_arrow(filename_sa1_2016_pop) %>% 
  select(SA1_7DIGITCODE_2016, Tot_P_P)

sa1_with_ra_pop <- merge(x=sa1_with_ra,
                         y=sa1_population,
                         by.x="SA1_7DIG16",
                         by.y="SA1_7DIGITCODE_2016") %>%
  select(SA1_7DIG16, SA1_MAIN16, SA2_MAIN16, SA2_5DIG16, SA2_NAME16, RA_CODE_2016, RA_NAME_2016, Tot_P_P) %>%
  st_drop_geometry() %>%
  unique()

# group by sa2 and ra and sum over the population
sa2_ra_pop <- sa1_with_ra_pop %>% 
  group_by(SA2_MAIN16, SA2_NAME16, RA_NAME_2016) %>%
  summarise(Population=sum(Tot_P_P, na.rm = TRUE))

# calculate the proportion that each RA contributes to each SA2
sa2_pop_total <- sa2_ra_pop %>%
  group_by(SA2_NAME16) %>%
  mutate(Total_P_SA2 = sum(Population)) %>% 
  ungroup()

sa2_ra_pop_with_prop <- sa2_pop_total %>%
  group_by(SA2_NAME16, RA_NAME_2016) %>%
  mutate(Prop_P_SA2 = Population / Total_P_SA2) %>%
  ungroup()

sa2_ra_pop_with_prop %>% write_csv_arrow("E:/projects/Prostate_102023/data/sa2_ra_pop_with_prop.csv")

# for each SA2 find the RA that has the highest proportion
sa2_best_ra <- sa2_ra_pop_with_prop %>%
  group_by(SA2_MAIN16, SA2_NAME16) %>%
  summarise(Prop_P_SA2_max = max(Prop_P_SA2),
            RA_best = RA_NAME_2016[which.max(Prop_P_SA2)])

sa2_best_ra %>% write_csv_arrow("E:/projects/Prostate_102023/data/sa2_best_ra.csv")