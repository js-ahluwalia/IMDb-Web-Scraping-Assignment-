require "httparty"
require "nokogiri"
require "byebug"

url = "https://m.imdb.com/chart/top/"
headers = {
  "User-Agent" => "Mozilla/5.0",  
  "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
  "Accept-Language" => "en-US,en;q=0.5",
  "Connection" => "keep-alive",
  
}
t=true
while (t)
  response = HTTParty.get(url, headers: headers)
  puts "Enter N:"
  n = gets.chomp.to_i
  puts n.to_s 
  break if n.to_s == "0"
  doc = Nokogiri::HTML(response.body)
  imdb_ids=[]
  movies=[]

  for i in 0...n do
    movies.push(doc.css('li.ipc-metadata-list-summary-item div.ipc-metadata-list-summary-item__c div.ipc-metadata-list-summary-item__tc div.sc-b189961a-0 div.ipc-title')[i].children.children.children.text.strip)
    imdb_ids.push(doc.css('li.ipc-metadata-list-summary-item div.ipc-metadata-list-summary-item__c div.ipc-metadata-list-summary-item__tc div.sc-b189961a-0 div.ipc-title')[i].children.first['href'].split('/')[2])
  end  

  actors ={}

  for i in 0...n do 
    url_cast ="https://m.imdb.com/title/" + imdb_ids[i] + "/?ref_=chttp_t_1"
    response_cast = HTTParty.get(url_cast, headers: headers)
    doc_cast = Nokogiri::HTML(response_cast.body)
    size=doc_cast.css('li.ipc-metadata-list__item.ipc-metadata-list-item--link div.ipc-metadata-list-item__content-container ul.ipc-inline-list.ipc-inline-list--show-dividers.ipc-inline-list--inline.ipc-metadata-list-item__list-content.baseAlt li.ipc-inline-list__item a.ipc-metadata-list-item__list-content-item.ipc-metadata-list-item__list-content-item--link').children.count
    size/=2
    
    for j in 0...size do
      actor_name=doc_cast.css('li.ipc-metadata-list__item.ipc-metadata-list-item--link div.ipc-metadata-list-item__content-container ul.ipc-inline-list.ipc-inline-list--show-dividers.ipc-inline-list--inline.ipc-metadata-list-item__list-content.baseAlt li.ipc-inline-list__item a.ipc-metadata-list-item__list-content-item.ipc-metadata-list-item__list-content-item--link').children[j].text
      actors[actor_name] =[] unless actors[actor_name]
        actors[actor_name] << movies[i]
    end 

  end 

  puts 
  puts "Enter Actor Name:"
  str = gets.chomp
  puts
  puts "Enter M:"
  puts 
  m = gets.chomp.to_i
  puts "Here is the list of Top #{m} Movies of your requested Actor:"
  puts 
  
  for i in 0...m do
    if actors[str]!=nil 
      if i < actors[str].size 
        puts actors[str][i]
      end  
    end 
  end 

end  

