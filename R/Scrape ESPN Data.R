library(dplyr)
library(readr)
library(nflreadr)
library(espnscrapeR)
# Scrape ESPN Data

YEAR <- get_current_season()
WEEK <- get_current_week()

sched <- load_schedules(seasons = YEAR)

espn_ids <- sched |> 
  filter(!is.na(result)) |> 
  pull(espn)

nflverse_ids <- sched |> 
  filter(!is.na(result)) |> 
  pull(game_id)

espn_data_raw <- data.frame()

for(i in seq_along(espn_ids)){
  espn_game_data <- espnscrapeR::get_nfl_boxscore(game_id = espn_ids[i]) |> 
    rename(espn_game_id = game_id, team_abbr = team_abb) |> 
    mutate(game_id = nflverse_ids[i], .before = espn_game_id)
  
  espn_data_raw <- bind_rows(espn_data_raw, espn_game_data)
}

espn_data_raw <- espn_data_raw |> 
  mutate(team_abbr = nflreadr::clean_team_abbrs(team_abbr)) |> 
  # redzone_att and redzone_conv values are flipped when scraped. 
  mutate(redzone_att1 = if_else(redzone_att >= redzone_conv, redzone_att, redzone_conv)) |> 
  mutate(redzone_conv = if_else(redzone_att >= redzone_conv, redzone_conv, redzone_att)) |> 
  mutate(redzone_att = redzone_att1) |> 
  select(-redzone_att1)

write_csv(espn_data_raw, paste0("Data/", YEAR, "_espn_game_data.csv"))

