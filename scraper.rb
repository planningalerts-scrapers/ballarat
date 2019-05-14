require 'scraperwiki'
require 'mechanize'

base_url    = "https://eservices.ballarat.vic.gov.au/ePathway/Production/Web/GeneralEnquiry/EnquiryLists.aspx?ModuleCode=LAP"

agent = Mechanize.new
agent.verify_mode = OpenSSL::SSL::VERIFY_NONE

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
    # detail_page contain `date_received`
    detail_page = agent.get(URI.parse(base_url) + a['href'].to_s)
    date = detail_page.at('span.AlternateContentHeading:contains("Date Received")').next.inner_text.to_s.strip
    record = {
      'council_reference' => tr.search("a")[0].inner_text,
      'address' => tr.search("td")[1].inner_text + ", " + tr.search("td")[2].inner_text + ", VIC",
      'description' => tr.search("span.ContentText, span.AlternateContentText")[1].inner_text,
      'info_url' => base_url,
      'date_scraped' => Date.today.to_s,
      'date_received' => Date.parse(date).to_s,
    }

    puts "Storing " + record['council_reference'] + " - " + record['address']
#      puts record
    ScraperWiki.save_sqlite(['council_reference'], record)
  end
end
