require 'scraperwiki'
require 'mechanize'

base_url    = "https://eservices.ballarat.vic.gov.au/ePathway/Production/Web/GeneralEnquiry/EnquiryLists.aspx?ModuleCode=LAP"
detail_url  = "https://eservices.ballarat.vic.gov.au/ePathway/Production/Web/GeneralEnquiry/"
comment_url = 'mailto:ballcity@ballarat.vic.gov.au'

agent = Mechanize.new
agent.verify_mode = OpenSSL::SSL::VERIFY_NONE

# Select 'Planning Applications Currently on Advertising' and hit Next
page = agent.get(base_url)
form = page.form_with(id: "aspnetForm")
form['mDataGrid:Column0:Property'] = 'ctl00$MainBodyContent$mDataList$ctl01$mDataGrid$ctl02$ctl00'
form['ctl00$MainBodyContent$mContinueButton'] = 'Next'
page = form.submit()

# Hit the Search button
form = page.form_with(id: "aspnetForm")
form['ctl00$MainBodyContent$mGeneralEnquirySearchControl$mSearchButton'] = 'Search'
page = form.submit()

page.search("tr.ContentPanel, tr.AlternateContentPanel").each do |tr|
  tr.search("a").each do |a|
    # detail_page contain `date_received`
    detail_page = agent.get(detail_url + a['href'].to_s)
    date = detail_page.search('span.AlternateContentHeading:contains("Date Received")').first.parent.parent.search('div.AlternateContentText').inner_text.to_s.strip

    record = {
      'council_reference' => tr.search("a")[0].inner_text,
      'address' => tr.search("td")[1].inner_text + ", " + tr.search("td")[2].inner_text + ", VIC",
      'description' => tr.search("span.ContentText, span.AlternateContentText")[1].inner_text,
      'info_url' => base_url,
      'comment_url' => comment_url,
      'date_scraped' => Date.today.to_s,
      'date_received' => Date.parse(date).to_s,
    }

    puts "Storing " + record['council_reference'] + " - " + record['address']
#      puts record
    ScraperWiki.save_sqlite(['council_reference'], record)
  end
end
