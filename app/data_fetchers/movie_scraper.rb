class MovieScraper

  @zipcode = ""; @day = "0"

  class << self
    attr_accessor :day, :zipcode
  end

  def self.data
    url = "http://google.com/movies?near=#{zipcode}&date=#{day}"
    Nokogiri::HTML(open(url)).css(".theater")
  end

  def self.load
    Theater.reset_all
    Movie.reset_all
    @day = get_day
    @zipcode = get_zipcode
    data.each do |theater_data|
      theater = Theater.new(theater_info(theater_data))
      movies = theater_data.css(".movie")
      movies.each do |movie_data|
        movie_attributes = movie_info(movie_data)
        next unless movie_attributes
        if movie = Movie.find_by_name(movie_attributes[:name])
          movie.update_showtimes(theater, movie_attributes[:showtimes])
        else
          movie = Movie.new(movie_info(movie_data), theater)
          theater.movies << movie
        end
      end
    end
  end

  def self.get_zipcode
    puts "\nPlease enter your " + "zipcode ".colorize(:yellow) + "for search...\n"
    zipcode = get_user_input
    until zipcode.match /^\d{5}$/
      puts "\nZipcode ".colorize(:yellow) +  "must be 5 digits long or enter " + "'exit'...".colorize(:red) +" \n"
      zipcode = get_user_input
    end
    zipcode
  end

  def self.get_day
    movie_day = nil
    today = DateTime.now
    days = (0...7).each_with_object([]) {|i, days| days << today; today = today.next_day}
    puts ""
    days.each_with_index {|day, index| print index == 6 ? "  #{index+1}. #{day.strftime("%A")}\n".colorize(:green) : "  #{index+1}. #{day.strftime("%A")}  ".colorize(:green)+"|"}
    while movie_day.nil?
      puts "\nEnter by " + "day ".colorize(:yellow) +"or " +"index ".colorize(:yellow) +"(up to 7 days)...\n"
      input = get_user_input
      days.each_with_index {|day, index| movie_day = index.to_s if input.match /(#{day.strftime("%A")[0,2]}.*?|#{index+1})/i}
    end
    puts "\nYou selected #{days[movie_day.to_i].strftime("%A %d %Y").colorize(:green)}"
    movie_day
  end

  def self.theater_info(theater)
    contact_info = theater.css("div div").first.text.split(' - ')
    {
      name:  theater.css("h2 a").text,
      address: contact_info[0],
      phone:  contact_info[1],
    }
  end

  def self.movie_info(movie_data)
    info_array = movie_data.css(".info").text.split(" - ")
    return nil if info_array.size != 5
    {
      name: movie_data.css(".name").text,
      duration: info_array[0],
      ratings: info_array[1], 
      genre: info_array[2],
      trailer_link: trailer_url(movie_data),
      imdb_link: imdb_url(movie_data),
      showtimes: movie_data.css(".times .fl").map {|time| [time.text, format_url(time.attributes['href'].value)]}
    }
  end

  def self.format_url(url)
    URI.unescape(url.gsub(/.*(?=http)/, ""))
  end

  def self.trailer_url(movie_data)
    begin 
      format_url(movie_data.css(".fl:nth-child(1)").
      first.attributes['href'].value)
    rescue NoMethodError
    end
  end

  def self.imdb_url(movie_data)
    begin 
      format_url(movie_data.css(".fl:nth-child(2)").
      first.attributes['href'].value)
    rescue NoMethodError
    end
  end

  def self.get_user_input
    print "\n>> "
    input = STDIN.gets.chomp.strip.downcase
    exit if input.match /exit/i
    input
  end
end

