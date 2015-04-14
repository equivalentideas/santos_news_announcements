# This is a template for a Ruby scraper on Morph (https://morph.io)
# including some code snippets below that you should find helpful

require 'scraperwiki'
require 'mechanize'
# require 'redcarpet'

# def markdown(html)
#   Redcarpet.new(html).html_safe
# end

def trim_item_body(post)
  # TODO: test this works across posts
  post.children[0...3].remove
  post.search('p.backlink').remove

  # TODO: convert to markdown
  return post.to_html
end

def save_news_item(page, domain)
  url = page.uri.to_s

  id = url.to_s[/id=(\d+)/, 1]

  post_div = page.at('div.content + div.content')

  pub_date = post_div.search(:h2)[0] ? post_div.search(:h2)[0].text : nil

  item_body_html = trim_item_body(post_div)

  # Build Array of attached files
  attached_files = post_div.at('.filelist').search(:a).map { |a| domain + a.attr(:href) }

  record = {
    id: id,
    url: url,
    item_title: page.search('h1.pagetitle').text,
    pub_date: pub_date,
    attached_files: attached_files,
    item_body: item_body_html
  }

  p record

  # ScraperWiki.save_sqlite([:id], record)
end

agent = Mechanize.new

base_url = 'http://www.santos.com'
page_address = '/Archive/NewsDetail.aspx?p=121&id=1485'

page = agent.get(base_url + page_address)

save_news_item(page, base_url)

# # Write out to the sqlite database using scraperwiki library
# ScraperWiki.save_sqlite(["name"], {"name" => "susan", "occupation" => "software developer"})
#
# # An arbitrary query against the database
# ScraperWiki.select("* from data where 'name'='peter'")

# You don't have to do things with the Mechanize or ScraperWiki libraries. You can use whatever gems are installed
# on Morph for Ruby (https://github.com/openaustralia/morph-docker-ruby/blob/master/Gemfile) and all that matters
# is that your final data is written to an Sqlite database called data.sqlite in the current working directory which
# has at least a table called data.
