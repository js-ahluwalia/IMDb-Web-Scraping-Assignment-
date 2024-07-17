require "httparty"
require "nokogiri"
require "byebug"
require "parallel"
require 'etc'
require 'sorted_set'
require 'set'
require_relative 'SortedPairSet'

class IMDbScraper
  def initialize
    @url = "https://m.imdb.com/chart/top/"
    @headers = {
      "User-Agent" => "Mozilla/5.0",  
      "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
      "Accept-Language" => "en-US,en;q=0.5",
      "Connection" => "keep-alive",
    }
    @movies = []
    @imdb_ids = []
    @actors ||= Hash.new { |hash, key| hash[key] = SortedPairSet.new }
  end

  def fetch_top_movies(n)
    response = HTTParty.get(@url, headers: @headers)
    doc = Nokogiri::HTML(response.body, nil, nil, Nokogiri::XML::ParseOptions::HUGE | Nokogiri::XML::ParseOptions::RECOVER) 
    for i in 0...n do
      @movies.push(doc.css('li.ipc-metadata-list-summary-item div.ipc-metadata-list-summary-item__c div.ipc-metadata-list-summary-item__tc div.sc-b189961a-0 div.ipc-title')[i].children.children.children.text.strip)
      @imdb_ids.push(doc.css('li.ipc-metadata-list-summary-item div.ipc-metadata-list-summary-item__c div.ipc-metadata-list-summary-item__tc div.sc-b189961a-0 div.ipc-title')[i].children.first['href'].split('/')[2])
    end
   
  end

  def build_actor_database(n)
    ##parallel programming
    num_cores = Etc.nprocessors
    num_threads = num_cores * 2
    Parallel.each_with_index(@movies, in_threads: num_threads) { |movie,index| fetch_actors_for_movie(@imdb_ids[index], movie,index) }
    puts @actors
  end

  def fetch_actors_for_movie(imdb_id, movie,index)
    url_cast = "https://m.imdb.com/title/#{imdb_id}/?ref_=chttp_t_1"
    response_cast = HTTParty.get(url_cast, headers: @headers)
    doc_cast = Nokogiri::HTML(response_cast.body, nil, nil, Nokogiri::XML::ParseOptions::HUGE | Nokogiri::XML::ParseOptions::RECOVER)
    actor_nodes = doc_cast.css('li.ipc-metadata-list__item.ipc-metadata-list-item--link div.ipc-metadata-list-item__content-container ul.ipc-inline-list.ipc-inline-list--show-dividers.ipc-inline-list--inline.ipc-metadata-list-item__list-content.baseAlt li.ipc-inline-list__item a.ipc-metadata-list-item__list-content-item.ipc-metadata-list-item__list-content-item--link')
    actor_names = actor_nodes.children.map{|node| node.text}.uniq
    actor_names.each do |actor_name|
      @actors[actor_name] ||= {}
      @actors[actor_name].add({movie: movie, index: index})
    end
  end

  def display_top_movies_for_actor(actor_name, m)
    if @actors[actor_name]
      top_movies = @actors[actor_name].to_a.take(m)
      puts "Here is the list of Top #{top_movies.size} Movie(s) of your requested Actor:"
      top_movies.each { |pair| puts "Movie: #{pair[:movie]}" }
    else
      puts "No movies found for actor #{actor_name}."
    end
  end

  def run
      puts "Enter N:"
      n = gets.chomp.to_i
      fetch_top_movies(n)
      build_actor_database(n)
      t=1
      while t==1  
        puts "Enter Actor Name (or Press 0 to exit):"
        actor_name = gets.chomp
        break if actor_name=='0'
        puts "Enter M:"
        m = gets.chomp.to_i
        display_top_movies_for_actor(actor_name, m)
      end
  end
end

scraper = IMDbScraper.new
scraper.run
