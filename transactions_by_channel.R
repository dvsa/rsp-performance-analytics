library(data.table)
library(dplyr)
library(tidyr)
library(WriteXLS)

data <- fread("/Users/argryioschristakopoulos/DVSA/RSP-Analytics/dummy_data_transactions_by_channel.csv") %>%
  mutate(received = as.Date(received, format = "%d/%m/%Y")) %>%
  arrange(received) %>%
  group_by(received) %>%
  count(channel = channel) %>%
  ungroup(received)

data2 <- data %>% 
  spread(key = channel, value = n, fill = 0) %>%
  mutate(received = format(received, format = "%Y-%m")) %>%
  group_by(received = received) %>%
  summarise(phone = sum(applied_via_phone), 
            digital = sum(applied_via_selfserve)) %>%
  gather(channel, count,-received) %>%
  arrange(received) %>%
  mutate(timestamp = paste0(received, "-01"),
         `_timestamp` = paste0(timestamp, "T00:00:00+00:00"),
         service = matrix("vehicle_operator_service", ncol = 1, nrow =1),
         period = matrix("month", ncol = 1, nrow =1)) %>%
  select(`_timestamp`, service, period, channel, count)


WriteXLS(data2, "transactions-by-channel.xlsx", col.names = TRUE, SheetNames = "Sheet1")
