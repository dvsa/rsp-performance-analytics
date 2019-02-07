###########################
##User satisfaction score##
###########################

## Necessary packages to run script
library(data.table)
library(dplyr)
library(WriteXLS)
library(jsonlite)
library(httr)
library(tidyr)

key <- Sys.getenv("SURVEY_KEY")

## Reads dummy data
data <- fread("~/DVSA/RSP-Analytics/data/764583.csv",
              select = c(7, 9:13),
              skip = 3L,
              col.names = c("started",
                            "task",
                            "easy",
                            "feedback",
                            "satisfaction",
                            "overallFeedback"),
              strip.white=TRUE)  %>%
  mutate(started = as.Date(started, format = "%d/%m/%Y")) %>%
  group_by(year_week = format(started, format = "%Y-%W")) %>%
  count(satisfaction) %>%
  ungroup()

# From long to wide format with tidyr::spread()
data_to_wide_format <- spread(data, key = satisfaction, value = n, fill = 0)

# Manipulates data_to_wide_format to offical GDS template for user satisfaction
rsp_user_satisfaction <- data_to_wide_format %>%
  rename(rating_1 = `Very dissatisfied`,
         rating_2 =  Dissatisfied,
         rating_3 = `Neither satisfied nor dissatisfied`,
         rating_4 =  Satisfied,
         rating_5 = `Very satisfied`) %>%
  mutate(total = rating_1 + rating_2 + rating_3 + rating_4 + rating_5,
         `_timestamp` = as.character(as.Date(paste0(year_week, "-1"), "%Y-%W-%w")),
         `_timestamp` = paste0(`_timestamp`, "T00:00:00"),
         period = matrix("week", nrow = 1, ncol = 1),
         service = matrix("roadside-payments", nrow = 1, ncol = 1)) %>%
  select(8, 9, 10, 5, 2, 3, 4, 6, 7) %>%
  jsonlite::toJSON()


##Push data to RSP performance dashboard
PUT(url = "https://www.performance.service.gov.uk/data/roadside-payments/user-satisfaction",
    body = "[]",
    add_headers(Authorization = paste("Bearer", key, sep = " ")),
    content_type_json())

POST(url = "https://www.performance.service.gov.uk/data/roadside-payments/user-satisfaction",
    body = rsp_user_satisfaction,
    add_headers(Authorization = paste("Bearer", key, sep = " ")),
    content_type_json())


## alternatively for a manual push use the following command
## WriteXLS(template, "rsp_user_satisfaction.xlsx", col.names = TRUE, SheetNames = "Sheet1")
