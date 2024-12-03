library(tidyverse)
library(ggplot2)

diagnostic_interval <- read_dta("Z:/Prostate_102023/data/diagnostic_interval.dta")

data <- pivot_longer(diagnostic_interval %>% dplyr::select(e_linkedpersonid, remoteness, starts_with("diagnostic_")),
                     cols = !c(e_linkedpersonid, remoteness),
                     names_to = "psa_cutoff",
                     values_to = "result") %>%
  dplyr::mutate(remoteness = ifelse(remoteness == 1, "Metro", "Regional"))

data2 <- data %>% filter(is.na(result) == FALSE)

ggplot(data=data2, aes(x = factor(psa_cutoff, level=c('diagnostic_interval_over3','diagnostic_interval_over4','diagnostic_interval_over10', 
                                                      'diagnostic_interval_over20')),
                      y = result, fill = factor(psa_cutoff, level=c('diagnostic_interval_over3','diagnostic_interval_over4','diagnostic_interval_over10', 
                                                                'diagnostic_interval_over20'))))+
        geom_boxplot() +
        coord_flip()+
  
        stat_summary(fun.y = mean,
                     geom = "point", shape=20, size=10, color="white", fill="white")+
        theme_bw(base_size = 15)+
        theme(legend.position = "none")+
        ylab("Days before prostate cancer diagnosis")+
        xlab(element_blank())+
  
        scale_x_discrete(labels=c('PSA >3', 'PSA >4', 'PSA >10','PSA >20')) +
  facet_grid(~remoteness) +
  scale_fill_manual(values = c("#333399", "#6666FF", "#9999FF", "#CCCCFF")) +
  theme_minimal() +
  theme(legend.position = "none")
                                                 
                                                 
                                                 
                                                 
                                                 
                                                 