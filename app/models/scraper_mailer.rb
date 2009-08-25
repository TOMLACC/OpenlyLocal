class ScraperMailer < ActionMailer::Base
  helper :scrapers

  def auto_scraping_report(report_hash)
    subject    "OpenlyLocal :: Auto Scraping Report :: #{report_hash[:summary]}"
    recipients 'countculture@googlemail.com'
    from       'countculture@googlemail.com'
    sent_on    Time.now
    
    body       :report => report_hash[:report]
  end

  def scraping_report(scraper)
    subject    "OpenlyLocal :: Scraping Report :: #{scraper.title}"
    recipients 'countculture@googlemail.com'
    from       'countculture@googlemail.com'
    sent_on    Time.now
    content_type "text/html"
    
    body       :scraper => scraper
  end

end
