## code to prepare datasets goes here
library(tidyverse)

Morphometrics <- read_csv("data-raw/NP_HW_Morphometrics.csv")
FlukeFlipperMetrics <- read_csv("data-raw/Pic_processing_Hawaii_2023_Final_Truncated.csv") %>%
  filter(!is.na(Mean_Flipper_Area_m2), !is.na(Mean_Fluke_Area_m2))
CATSMomCalfFMR <- read_csv("data-raw/AllEnergyBalanceFMRMethodSensitivity_Mom_Calf.csv")
CATSMomCalfVentilation <- read_csv("data-raw/Tagged_Humpback_Breath_Data.csv") %>%
  filter(!is.na(Body_Length_m), !is.na(FR_Overall))

usethis::use_data(Morphometrics, overwrite = TRUE)
usethis::use_data(FlukeFlipperMetrics, overwrite = TRUE)
usethis::use_data(CATSMomCalfFMR, overwrite = TRUE)
usethis::use_data(CATSMomCalfVentilation, overwrite = TRUE)

