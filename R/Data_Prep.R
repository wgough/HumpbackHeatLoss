## code to prepare datasets goes here
library(tidyverse)

Morphometrics <- read_csv("data-raw/NP_HW_Morphometrics.csv")
FlukeFlipperMetrics <- read_csv("data-raw/Pic_processing_Hawaii_2023_Final_Truncated.csv")

usethis::use_data(Morphometrics, overwrite = TRUE)
usethis::use_data(FlukeFlipperMetrics, overwrite = TRUE)

