library(dplyr)
library(ggplot2)
library(arrow)
library(sf)
library(readxl)
library(stringr)

# map each of the 2016 SA2's to a 2016 RA (remoteness area)
filename_sa2_2016_shapes <- "E:/auxiliary_datasets/shapefiles_2016/sa2/SA2_2016_AUST.shp"
filename_ra_2016 <- "E:/auxiliary_datasets/geographic_mapping/RA_2016_AUST.csv"
filename_sa1_2016_shapes <- "E:/auxiliary_datasets/shapefiles_2016/sa1/SA1_2016_AUST.shp"

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

sa2_to_ra <- 
  sa1_with_ra %>% 
  select(SA2_MAIN16, SA2_5DIG16, SA2_NAME16, RA_CODE_2016, RA_NAME_2016) %>%
  st_drop_geometry() %>%
  unique()

# some sa2 values map to multiple ra values
sa2_to_ra %>% st_drop_geometry() %>% group_by(SA2_MAIN16) %>%  count() %>% arrange(desc(n))

sa1_with_ra %>% st_drop_geometry() %>% filter(SA2_MAIN16 == 205051104)

sa2_to_ra %>% write_csv_arrow("E:/projects/Prostate_102023/data/sa2_to_ra_2016.csv")