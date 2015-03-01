class MovieScraper
  extend CommandPrompt

  def self.get_data
    url = "http://google.com/movies?near=#{get_zipcode}&date=#{get_day}"
    Nokogiri::HTML(open(url)).css(".theater")
  end

  def self.load
    reset
    get_data.each do |theater_data|
      theater = Theater.new(theater_info(theater_data))
      movies = theater_data.css(".movie")
      movies.each do |movie_data|
        movie_attributes = get_movie_attributes(movie_data)
        next unless movie_attributes
        if movie = Movie.find_by_name(movie_attributes[:name])
          movie.update_showtimes(theater, movie_attributes[:showtimes])
        else
          movie = Movie.new(get_movie_attributes(movie_data), theater)
          theater.movies << movie
        end
      end
    end
  end

  def self.get_zipcode
    puts "\nPlease enter your " + "zipcode ".colorize(:yellow) + "for search...\n\n"
    error_message = "\nZipcode ".colorize(:yellow) +  "must be 5 digits long or enter " + "'exit'...".colorize(:red) +" \n"
    command_prompt do |zipcode|
      return zipcode if zipcode.match(/^\d{5}$/)
      puts(error_message)
    end
  end

  def self.stringify_days(days)
    days.map.with_index {|day, index|  "#{index+1}. #{day.strftime("%A")[0,2]}"}
  end

  def self.get_day
    days = get_days
    message = "\nEnter by " + "day ".colorize(:yellow) +"or " +"index ".colorize(:yellow) +"(up to 7 days)...\n\n"
    day_pair = Hash[stringify_days(days).zip(days)]
    puts message
    command_prompt do |entered_date|
      if day = command_match(entered_date, day_pair.keys)
        puts "\nYou selected #{day_pair[day].strftime("%A %d %Y").colorize(:green)}"
        return day_pair.keys.index(day)
      end
      puts message
    end
  end

  def self.get_days 
    day = DateTime.now
    puts ''
    (0...7).each_with_object([]) do |index, days| 
      print index == 6 ? "  #{index+1}. #{day.strftime("%A")}\n".colorize(:green) : "  #{index+1}. #{day.strftime("%A")}  ".colorize(:green)+"|"
      days << day; day = day.next_day
    end
  end

  def self.theater_info(theater)
    contact_info = theater.css("div div").first.text.split(' - ')
    {
      name:  theater.css("h2 a").text,
      address: contact_info[0],
      phone:  contact_info[1],
    }
  end

  def self.get_movie_attributes(movie_data)
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

  def self.reset
    Theater.reset_all
    Movie.reset_all
  end
end

