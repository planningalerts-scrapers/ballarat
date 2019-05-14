require 'scraperwiki'
require 'mechanize'

def field(page, name)
  page.at("span:contains(\"#{name}\")").next.inner_text.to_s.strip
end

def scrape(base_url)
  agent = Mechanize.new

  # Select 'Planning Applications Currently on Advertising' and hit Next
  page = agent.get(base_url)
  form = page.forms.first
  form.radiobuttons[0].click
  page = form.submit(form.button_with(:value => /Next/))

  # Hit the Search button
  form = page.forms.first
  page = form.submit(form.button_with(:value => /Search/))

  page.search("tr.ContentPanel, tr.AlternateContentPanel").each do |tr|
    tr.search("a").each do |a|
      address = tr.search("td")[1].inner_text + ", " + tr.search("td")[2].inner_text + ", VIC"

      # detail_page contain `date_received`
      detail_page = agent.get(URI.parse(base_url) + a['href'].to_s)

      record = {
        'council_reference' => field(detail_page, "Application Number"),
        'address' => address,
        'description' => field(detail_page, "Proposed Use or Development"),
        'info_url' => base_url,
        'date_scraped' => Date.today.to_s,
        'date_received' => Date.parse(field(detail_page, "Date Received")).to_s,
      }

      yield record
    end
  end
end

base_url = "https://eservices.ballarat.vic.gov.au/ePathway/Production/Web/GeneralEnquiry/EnquiryLists.aspx?ModuleCode=LAP"

scrape(base_url) do |record|
  puts "Storing " + record['council_reference'] + " - " + record['address']
#      puts record
  ScraperWiki.save_sqlite(['council_reference'], record)
end
