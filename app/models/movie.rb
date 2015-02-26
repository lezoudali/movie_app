class Movie
  extend Findable

  attr_reader :name, :genre, :ratings , :trailer, :duration, :showtimes, :imdb
  ShowTime = Struct.new(:time, :url)
  @@movies = []

  def self.reset_all
    @@movies.clear
  end

  def self.all
    @@movies
  end

  def self.list(movies = all)
    movies.each_with_index do |movie, index|
      puts "\n#{index+1}.\t#{movie.name.colorize(:magenta)}"
      puts "\t#{movie.duration}\t#{movie.genre}\t#{movie.ratings}"
      puts "\n"
    end
    movies
  end

  def initialize(attributes, theater)
    @name = attributes[:name]
    @genre = attributes[:genre]
    @ratings = attributes[:ratings]
    @trailer = attributes[:trailer_link]
    @duration = attributes[:duration]
    @showtimes = {theater => attributes[:showtimes].map{|showtime| ShowTime.new(showtime[0], showtime[1])}}
    @imdb = attributes[:imdb_link].gsub(/&.*/, '')
    @@movies << self
  end

  def update_showtimes(theater, showtimes)
    @showtimes.merge!(theater => showtimes.map{|showtime| ShowTime.new(showtime[0], showtime[1])})
    theater.movies << self
  end

  def open_trailer
    system("open", trailer) #only mac, use launchy gem 
  end

  def open_imdb
    system("open", imdb)
  end

  def open_showtime(theater, search_time)
    url = showtimes[theater].find{|showtime| showtime.time == search_time}.url
    system("open", url)
  end

  def theaters
    showtimes.keys
  end

  def get_open_theaters
    theaters.each_with_object([]) do |theater, theater_list|
      next if get_showtimes(theater).empty?
      theater_list << theater
    end
  end

  def get_showtimes(theater)
    times = ""
    showtimes[theater].each {|showtime| times += "#{showtime.time.colorize(:light_blue)}  "}
    times.strip
  end

  def list_showtimes(theaters)
    puts "\n\t#{name}".colorize(:cyan)
    puts "\t#{duration}\t#{genre}\t#{ratings}"
    puts "\n"
    theaters.each_with_index do |theater, index|
      puts "\n#{index+1}.\t" + "#{theater.name}".colorize(:magenta) + "\n\t\t#{get_showtimes(theater).colorize(:light_blue)}\n\n" 
    end
  end
end