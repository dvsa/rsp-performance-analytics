library(data.table)
library(dplyr)
library(tidyr)
library(WriteXLS)
library(zoo)

data <- fread("/Users/argryioschristakopoulos/DVSA/RSP-Analytics/dummy_data_transactions_by_channel.csv") %>%
  mutate(received = as.Date(received, format = "%d/%m/%Y"),
         received = as.yearqtr(received, format = "%Y-%Q")) %>%
  arrange(received) %>%
  group_by(received) %>%
  count(channel = channel) %>%
  summarise(transaction_volumes = sum(n)) %>%
  mutate(period = matrix("quarter", nrow = 1, ncol = 1),
         start_at = received,
         end_at = received,
         cost_per_transaction = matrix("", nrow = 1, ncol =1),
         total_cost = matrix("", nrow = 1, ncol = 1))

x <- do.call(rbind, lapply(unique(data$received), function(d)
  data.frame(start_at = as.Date(d),
             end_at = lubridate::floor_date(as.Date(as.yearqtr(as.numeric(d) + .25)) - 0, "months"))))


data <- data[,c(1, 3, 4, 5, 2, 6, 7)]

data2 <- data %>% mutate(timestamp = paste0(x$start_at, "T00:00:00+00:00"),
                         start_at = paste0(x$start_at, "T00:00:00+00:00"),
                         end_at = paste0(x$end_at, "T00:00:00+00:00")) 

data2 <- data2[,c(8, 2, 3, 4, 5, 6, 7)]

WriteXLS(data2, "final-cost-per-transaction.xlsx", col.names = TRUE, SheetNames = "Sheet1")
