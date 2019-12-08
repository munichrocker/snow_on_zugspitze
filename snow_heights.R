# Get snow heights data from DWD
# Loading the needed libraries
library(tidyverse) # for data analysis
library(DatawRappr) # for uploading to Datawrapper

# using setwd() here to specify the working directory on the server.
# better use here() for larger projects

setwd("XXX")

# download weather data 
# delete old weather data
unlink("input/*.txt")

# download file from German Meteorological Service
download.file("https://opendata.dwd.de/climate_environment/CDC/observations_germany/climate/daily/kl/recent/tageswerte_KL_05792_akt.zip", destfile = "input/zugspitze.zip")

# unzip only the file with the data (no metadata files)
zipped_txt_name <- grep('produkt.+\\.txt$', unzip('input/zugspitze.zip', list=TRUE)$Name, 
                         ignore.case = TRUE, value = TRUE)

unzip("input/zugspitze.zip", files = zipped_txt_name, overwrite = TRUE, exdir = "input/")

# load data file into R
df_snow <- read.csv2(paste0("input/", list.files("input/", pattern = "\\.txt")))

# specify format of date manually
df_snow$datum <- as.Date(as.character(df_snow$MESS_DATUM), format = "%Y%m%d")

# prepare data for Datawrapper (only select the columns needed)
df_snow %>% 
  select(datum, SHK_TAG) %>% 
  filter(SHK_TAG != -999) %>% 
  filter(datum > as.Date("2018-12-01")) %>% 
  mutate(datum = as.character(datum)) %>% 
  rename(date = datum, `snow height` = SHK_TAG)  -> df_snow_upload


# check for headlines in the data:

# update date for annotation:
text_date_update <- paste0("This chart has been updated on ", as.POSIXct(Sys.time()), ".")

# create an empty headline, in case the input data breaks
headline <- NULL

# get the snow data
snow_yesterday <- df_snow[df_snow$datum == last(df_snow$datum),]$SHK_TAG
snow_day_before <- df_snow[df_snow$datum == last(lag(df_snow$datum)),]$SHK_TAG

# simple headline rules:

if (snow_yesterday > snow_day_before) {
  headline <- "It has been snowing on the Zugspitze yesterday" 
} else if (snow_yesterday < snow_day_before) {
  headline <- paste0("The Zugspitze lost ", abs(snow_yesterday - snow_day_before), "cm of snow during the last two days")
} else {
  headline <- paste0("Yesterday there've been ", snow_yesterday, "cm of snow on the Zugspitze")
}

# Send to Datawrapper

# do we have a API-key saved locally? test with :
# dw_get_api_key()

# if not, we can use: datawrapper_auth() to save a key in our environment.
# then we don't have to specify api_key in the DatawRappr-function calls

# I'm setting the key explicitly here, as I don't want to save my key on the server
api_key <- XXX

# Create chart - use only once! (That's why it's commented out):
# zugspitze_chart <- dw_create_chart(api_key = api_key, title = "Snow on the Zugspitze", type = "d3-lines")

# uploading data to newly created chart
dw_data_to_chart(df_snow_upload, "3EW5r", api_key = api_key)

# edit the titles on the chart
dw_edit_chart("3EW5r", api_key = api_key, title = headline, intro = "snow height in centimeters",
              annotate = text_date_update, source_name = "German Meteorological Service",
              source_url = "https://opendata.dwd.de/climate_environment/CDC/observations_germany/climate/daily/kl/recent/")

# (re-)publish chart:
dw_publish_chart("3EW5r", api_key = api_key, return_urls = FALSE)