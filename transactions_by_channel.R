library(data.table)
library(dplyr)
library(tidyr)
library(WriteXLS)

data <- fread("data/Applications_received_and_decided.csv", col.names = c("applicationID",
                                                                          "leadTA",
                                                                          "licencenumber",
                                                                          "organisation",
                                                                          "licencestatus",
                                                                          "applicationstatus",
                                                                          "licencetype",
                                                                          "recieved",
                                                                          "published",
                                                                          "decision",
                                                                          "pireqdate",
                                                                          "pinotificationdate",
                                                                          "haspi",
                                                                          "numberofdaysrecieved",
                                                                          "numberofdayspinotify",
                                                                          "noofobjections",
                                                                          "numberofreps",
                                                                          "sladate",
                                                                          "channel")
              ) %>%
  select(recieved, channel) %>%
  mutate(recieved = as.Date(recieved, format = "%d/%m/%Y")) %>%
  arrange(recieved) %>%
  group_by(recieved) %>%
  count(channel = channel) %>%
  ungroup(recieved)

data2 <- data %>% 
  spread(key = channel, value = n, fill = 0) %>%
  mutate(recieved = format(recieved, format = "%Y-%m")) %>%
  group_by(recieved = recieved) %>%
  summarise(phone = sum(applied_via_phone), 
            digital = sum(applied_via_selfserve), 
            post = sum(applied_via_post) ) %>%
  gather(channel, count,-recieved) %>%
  arrange(recieved) %>%
  mutate(timestamp = paste0(recieved, "-01"),
         timestamp = paste0(timestamp, "T00:00:00+00:00"),
         service = matrix("vehicle_operator_service", ncol = 1, nrow =1),
         period = matrix("month", ncol = 1, nrow =1)) %>%
  select(timestamp, service, period, channel, count)


WriteXLS(data2, "transactions-by-channel.xlsx", col.names = TRUE, SheetNames = "Sheet1")
