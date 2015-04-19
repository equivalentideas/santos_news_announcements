# This is a template for a Ruby scraper on Morph (https://morph.io)
# including some code snippets below that you should find helpful

require 'scraperwiki'
require 'mechanize'

# TODO: strip whitespace from the end
def trim_item_body(post)
  post.children[0...3].remove
  post.search('p.backlink').remove

  return post.inner_html
end

def make_url_absolute(url, domain)
  url[0] == "/" ? domain + url : url
end

def save_news_item(page, domain)
  url = page.uri.to_s

  id = url.to_s[/id=(\d+)/, 1]

  post_div = page.at('div.content + div.content')

  pub_date = post_div.search(:h2)[0] ? Date.strptime(post_div.search(:h2)[0].text, '%d %b %Y').to_s : nil

  item_body_html = trim_item_body(post_div)

  # Build string from array of attached files and links listed
  # at the end of the post.
  # We need to test for two different ways they attach files
  # sometimes both are present.
  if post_div.search('.filelist').any? || post_div.search('.announcementpdf').any?
    file_links = []
    file_links.push post_div.search('.filelist a')
    file_links.push post_div.search('.announcementpdf a')

    attached_files = attachment_links.map { |a| make_url_absolute(a.attr(:href), domain) }.join("','")
  else
    attached_files = nil
    puts "no attached files found"
  end

  record = {
    pub_date: pub_date,
    item_title: page.search('h1.pagetitle').text,
    item_body: item_body_html,
    attached_files: attached_files,
    url: url,
    id: id
  }

  p record

  ScraperWiki.save_sqlite([:id], record)
end

agent = Mechanize.new

base_url = 'http://www.santos.com'

index = agent.get("http://www.santos.com/share-price-performance/news-announcements.aspx")

index.search('.article .title a').each do |link|
  news_page = agent.get(base_url + link.attr(:href))
  puts "Saving #{link.inner_text}:\n#{news_page.uri.to_s}"
  save_news_item(news_page, base_url)
end

# # Write out to the sqlite database using scraperwiki library
# ScraperWiki.save_sqlite(["name"], {"name" => "susan", "occupation" => "software developer"})
#
# # An arbitrary query against the database
# ScraperWiki.select("* from data where 'name'='peter'")

# You don't have to do things with the Mechanize or ScraperWiki libraries. You can use whatever gems are installed
# on Morph for Ruby (https://github.com/openaustralia/morph-docker-ruby/blob/master/Gemfile) and all that matters
# is that your final data is written to an Sqlite database called data.sqlite in the current working directory which
# has at least a table called data.
