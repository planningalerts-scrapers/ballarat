require 'epathway_scraper'

EpathwayScraper::Scraper.scrape_and_save(
  "https://eservices.ballarat.vic.gov.au/ePathway/Production",
  list_type: :advertising
)
