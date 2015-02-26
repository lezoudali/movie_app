class Runner

  def initialize
    MovieScraper.load
  end

  def self.run
    runner = Runner.new 
    puts "\nSearch by " + "movie(s) ".colorize(:yellow) + "or by " + "theater(s)".colorize(:yellow) + "..."
    puts "\nEnter command or 'help' to get list of commands\n\n".colorize(:green)
    user_input = runner.get_user_input
    while runner.main_commands(user_input).nil?
      puts "\nCommand or Search not found...".colorize(:red)
      puts "Enter "+"'help'".colorize(:green)+" for instructions"
      user_input = runner.get_user_input
      exit if user_input.match /exit/i
    end
  end
  
  def get_user_input
    print ">> "
    input = STDIN.gets.chomp.strip.downcase
    return exit if input.match /exit/i
    return Runner.run if input.match /home/i
    while input.match /^help/i
      caller.grep(/.*get_tickets.*/).empty? ? main_instructions : main_instructions(true)
      print "\n>> "
      input = STDIN.gets.chomp.strip.downcase
    end
    input
  end

  def main_instructions(flag = false)
    puts "Main..."
    puts "\n\tEnter "+"help".colorize(:green)
    puts "\n\tEnter "+"exit".colorize(:green)+" to exit the app"
    puts "\n\tEnter "+"home".colorize(:green)+" to restart with new zipcode"
    puts "\nSearching...."
    puts "\n\tEnter "+"search -m <movie name>".colorize(:green)
    puts "\n\tEnter "+"search -t <theater name>".colorize(:green)
    puts "\n\tEnter "+"search -m".colorize(:green)+" to list movies"
    puts "\n\tEnter "+"search -t".colorize(:green)+" to list theaters"
    if flag
      puts "\nMovie and Theater selected...."
      puts "\n\tEnter "+"trailer".colorize(:green)+", "+"imdb".colorize(:green)+", or "+"purchase <(hh:mm)>".colorize(:green)+" enter 'pm' if shown.'\n"
    end
  end

  def main_commands(input)
    case input
    when /^search -t .+/i
      arg = input.gsub(/search -t\s*/, "")
      theaters = self.search(arg, Theater)
      theaters.nil? ? nil : search_by_theaters(theaters)
    when /^search -m .+/i
      arg = input.gsub(/search -m\s*/, "")
      movies = self.search(arg, Movie)
      movies.nil? ? nil : search_by_movies(movies)
    when /^search -m$/i
      search_by_movies Movie.list
    when /^search -t$/i
      search_by_theaters Theater.list 
    when /home/i
      Runner.run 
    when /exit/i
      exit
    else
      puts "\nI don't understand that command, check spelling".colorize(:red)
    end
  end

  def search(user_input, model)
    list = model.find_all_by_name(user_input)
    unless list.empty?
      list.each_with_index{ |item, index| puts "#{index+1}.   #{item.name}" }
      puts ''
    end
    list.empty? ? nil : list
  end

  def search_by_theaters(theaters = Theater.all)
    return no_data_found if theaters.size.zero?
    theater = select_from(theaters)
    movies = theater.get_movies_showing
    theater.list_showtimes(movies)
    movie = select_from(theater.movies)
    until movies.include? movie
      movie = select_from(theater.movies)
    end
    get_tickets(movie, theater)
  end

  def search_by_movies(movies = Movie.all)
    return no_data_found if movies.size.zero?
    movie = select_from(movies)
    theaters = movie.get_open_theaters
    movie.list_showtimes(theaters)
    theater = select_from(movie.theaters)
    until theaters.include? theater 
      theater = select_from(movie.theaters)
    end
    get_tickets(movie, theater)
  end

  def no_data_found
    puts "Google did not find any movies/theaters in your area... please enter a new date and zipcode :( ...".colorize(:red)
    Runner.run
  end

  def select_from(list)
    user_input = selection_prompt.to_i
    selection = list.each_with_index.find{|x, index| index+1 == user_input}
    until selection
      user_input = selection_prompt.to_i
      selection = list.each_with_index.find{|x, index| index+1 == user_input}
    end
    selection.first
  end

  def selection_prompt
    puts "\nPlease enter correct ID from list...\n".colorize(:red)
    get_user_input
  end

  def get_tickets(movie, theater)
    times = movie.showtimes[theater].map{|showtime| showtime.time}
    puts "\n\tEnter "+"trailer".colorize(:green)+", "+"imdb".colorize(:green)+", or "+"purchase <(hh:mm)>".colorize(:green)+" enter 'pm' if shown.'\n\n"
    puts "\n#{movie.name}".upcase.colorize(:cyan) + "\t " + "#{theater.name.upcase}".colorize(:magenta) + "\t #{movie.get_showtimes(theater)}".colorize(:light_blue) 
    puts "\n\n"

    loop do 
      user_input = get_user_input
      case user_input
      when /trailer/i then movie.open_trailer 
      when /imdb/i then movie.open_imdb 
      when /purchase\s+\d+:\d+/
        time = user_input.gsub(/purchase\s+/, "")
        puts "Select time from above (including <pm> if last one)" unless times.include? time
        movie.open_showtime(theater, time) if times.include? time
      when /home/i then Runner.run
      when /exit/i then exit
      else puts "\nCommand not found..."
      end
    end
  end
end
