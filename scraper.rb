require 'scraperwiki'
require 'mechanize'

def scrape
  base_url    = "https://eservices.ballarat.vic.gov.au/ePathway/Production/Web/GeneralEnquiry/EnquiryLists.aspx?ModuleCode=LAP"

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

      date_received = detail_page.at('span:contains("Date Received")').next.inner_text.to_s.strip
      council_reference = detail_page.at('span:contains("Application Number")').next.inner_text.to_s.strip
      description = detail_page.at('span:contains("Proposed Use or Development")').next.inner_text.to_s.strip

      record = {
        'council_reference' => council_reference,
        'address' => address,
        'description' => description,
        'info_url' => base_url,
        'date_scraped' => Date.today.to_s,
        'date_received' => Date.parse(date_received).to_s,
      }

      yield record
    end
  end
end

scrape do |record|
  puts "Storing " + record['council_reference'] + " - " + record['address']
#      puts record
  ScraperWiki.save_sqlite(['council_reference'], record)
end
