require '../epathway_scraper'

scraper = EpathwayScraper.new(
  base_url: "https://eservices.ballarat.vic.gov.au/ePathway/Production/Web/GeneralEnquiry/EnquiryLists.aspx?ModuleCode=LAP"
)

scraper.scrape_and_save
