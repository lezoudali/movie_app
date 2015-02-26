class Theater
  extend Findable

  attr_reader :name, :address, :phone, :movies
  @@theaters = []

  def self.reset_all
    @@theaters.clear
  end

  def self.all
    @@theaters
  end

  def self.list(theaters = all)
    list = []
    index = 0
    theaters.each do |theater|
      theater.get_all_showtimes
      next if theater.get_all_showtimes.strip.empty? || theater.movies.size.zero? 
      list << theater
      puts "\n#{index+1}.\t#{theater.name.colorize(:magenta)}"
      puts "\t#{theater.address}\t#{theater.phone}"
      puts "\n"
      index += 1
    end
    list
  end

  def initialize(attributes)
    @name = attributes[:name]
    @address = attributes[:address]
    @phone = attributes[:phone]
    @movies = [] 
    @@theaters << self
  end
  
  def get_movies_showing
    movies.each_with_object([]) do |movie, movies|
      next if get_showtimes(movie).empty?
      movies << movie
    end
  end

  def get_showtimes(movie)
    times = ""
    movie.showtimes[self].each {|showtime| times += "#{showtime.time.colorize(:light_blue)}  "}
    times.strip
  end

  def get_all_showtimes
    self.movies.map {|movie| movie.get_showtimes(self)}.join("")
  end

  def list_showtimes(movies)
    puts "\n\t#{name}"
    puts "\t#{address}\t#{phone}"
    puts "\n"
    movies.each_with_index do |movie, index|
      puts "\n#{index+1}\t#{movie.name.colorize(:cyan)}\n\t\t#{get_showtimes(movie).colorize(:light_blue)}\n\n"
    end
  end
end