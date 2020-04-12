# Read transaction download from Mint and write to S3

suppressPackageStartupMessages(library(tidyverse))
library(aws.s3)
library(janitor)
library(here)
options(stringsAsFactors = F)
options(scipen = 99)


#change these var values as appropriate
transaction_file <- "mint_downloaded_transactions.csv"
output_file <- "transactions.csv"

#AWS auth + s3 info
key <-  "<aws key>"
secret <-  "<aws secret>"
region <-  "<aws region, for example us-east-2>"
bucket <-  '<aws bucket, for example your-aws-bucket>'

###### read + munge transaction file
imprt <- read_csv(transaction_file,                          
                  col_types = cols(
                    Date = col_character(),
                    Description = col_character(),
                    `Original Description` = col_character(),
                    Amount = col_double(),
                    `Transaction Type` = col_character(),
                    Category = col_character(),
                    `Account Name` = col_character(),
                    Labels = col_character(),
                    Notes = col_character())) %>% 
  clean_names() %>% 
  mutate(date = as.Date(if_else(substr(date,2,2) == "/", str_c("0", date), date), format = "%m/%d/%Y"),
         amount = if_else(transaction_type == "debit", amount * -1, amount)) %>% 
  select(-transaction_type, -labels) %>% 
  filter(!(category %in% c('Hide from Budgets & Trends'))) %>% 
  arrange(date)


##### write to s3
s3write_using(imprt,
              write_csv,
              na = "",
              object = output_file, 
              bucket = bucket,
              opts = c(key = key,
                       secret = secret,
                       region = region))
