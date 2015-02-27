class Runner
  def initialize
    MovieScraper.load
    run
  end

  def run 
    search_list = prompt_search
    return no_data_found if search_list.size.zero?
    movie, theater = get_movie_theater(search_list)
    get_tickets(movie, theater)
  end

  def prompt_search
    puts "\nSearch by movie(s) " + "'search -m | search -m <movie name>' ".colorize(:yellow) + "or by theater(s)" + " search -t | search -t <theater name>".colorize(:yellow) + "..."
    puts "\nEnter command or 'help' to get list of commands\n\n".colorize(:green) 
    error_message = "Invalid Search Command...".colorize(:red)
    input = get_user_input(error_message, *search_options)
    run_command(input)
  end
  
  def get_user_input(error_message, *validation_list)
    print ">> "
    input = STDIN.gets.chomp.strip.downcase 
    return input if validation_list.empty?
    until match?(input, validation_list)
      help?(input) ? instructions : puts(error_message)
      print ">> "
      input = STDIN.gets.chomp.strip.downcase
    end
    input
  end

  def get_movie_theater(categories = all)
    return no_data_found if categories.size.zero?
    category = select_from(categories)
    options = category.get_options
    category.list_showtimes(options)
    option = select_from(options)
    until options.include? option
      option = select_from(options)
    end
    [option,category].sort_by{|selection| selection.to_s}
  end

  def instructions
    puts "Main..."
    puts "\n\tEnter "+"help".colorize(:green)
    puts "\n\tEnter "+"exit".colorize(:green)+" to exit the app"
    puts "\n\tEnter "+"home".colorize(:green)+" to restart with new zipcode"
    puts "\nSearching...."
    puts "\n\tEnter "+"search -m <movie name>".colorize(:green)
    puts "\n\tEnter "+"search -t <theater name>".colorize(:green)
    puts "\n\tEnter "+"search -m".colorize(:green)+" to list movies"
    puts "\n\tEnter "+"search -t".colorize(:green)+" to list theaters"
    puts "\nMovie and Theater selected...."
    puts "\n\tEnter "+"trailer".colorize(:green)+", "+"imdb".colorize(:green)+", or "+"purchase <(hh:mm)>".colorize(:green)+" enter 'pm' if shown.'\n"
  end

  def purchase_ticket(user_input, movie, theater)
    times = movie.get_showtimes(theater)
    time = retrieve_time(user_input)
    if times.include? time
      movie.open_showtime(theater, time)
      puts "Goodbye and enjoying your movie...".colorize(:yellow)
      exit
    else
      puts "Select time from above (including <pm|am> if shown)"
    end
  end

  def get_tickets(movie, theater)
    puts "\n\tEnter "+"trailer".colorize(:green)+", "+"imdb".colorize(:green)+", or "+"purchase <(hh:mm)>".colorize(:green)+" enter 'pm' if shown.'\n\n"
    puts "\n#{movie.name}".upcase.colorize(:cyan) + "\t " + "#{theater.name.upcase}".colorize(:magenta) + "\t #{movie.get_showtimes(theater).join(" ")}".colorize(:light_blue) + "\n\n"
    error_message = "\n\tWrong command... \n".colorize(:red) + "Enter "+"trailer".colorize(:green)+", "+"imdb".colorize(:green)+", or "+"purchase <(hh:mm)>"
    loop do 
      user_input = get_user_input(error_message, *get_ticket_options)
      break if run_command(user_input, movie, theater)
    end
    exit
  end

  def list_all_movies
    Movie.list
  end

  def list_all_theaters
    Theater.list 
  end

  private  
  
  def commands
    {
      search:
              {
                theater:        /^search -t .+/i,
                movie:          /^search -m .+/i,
                all_movies:     /^search -m$/i,
                all_theaters:   /^search -t$/i,
                home:           /home/i,
                exit:           /exit/i
              },
      open: 
              {
                trailer:        /trailer/i,
                imdb:           /imdb/i,
                ticket_link:    /purchase\s+\d+:\d+/,
                home:           /home/i,
                exit:           /exit/i
              }
    }
  end

  def run_command(user_input, movie = nil, theater = nil)
    case user_input
      when commands[:search][:theater]       then search_from(Theater, user_input)
      when commands[:search][:movie]         then search_from(Movie, user_input)
      when commands[:search][:all_movies]    then list_all_movies
      when commands[:search][:all_theaters]  then list_all_theaters
      when commands[:open][:home]            then restart_app
      when commands[:open][:exit]            then exit
      when commands[:open][:trailer]         then movie.open_trailer
      when commands[:open][:imdb]            then movie.open_imdb 
      when commands[:open][:ticket_link]     then purchase_ticket(user_input, movie, theater) 
    end
  end

  def select_from(models)
    error_message = "\nPlease enter correct ID from list...\n".colorize(:red)
    ids = get_ids(models.size)
    user_input = get_user_input(error_message, *ids)
    models.find{|model| models.index(model) == (user_input.to_i-1)}
  end

  def search_from(model, user_input)
    query = get_search_query(user_input)
    model.list model.find_all_by_name(query)
  end

  def get_search_query(input)
    input.gsub(/search -(m|t)\s*/, "")
  end

  def search_options
    commands[:search].values
  end

  def get_ticket_options
    commands[:open].values
  end

  def help?(input)
    input.match(/help/)
  end

  def match?(string, matchings)
    matchings.any?{|matching| matching =~ string }
  end


  def restart_app
    run
  end

  def no_data_found
    puts "Google did not find any movies/theaters in your area... please enter a new date and zipcode :( ...".colorize(:red)
    restart_app
  end

  def get_ids(size)
    (1..size).map{|id| Regexp.new(id.to_s)} << /exit/i << /home/i
  end

  def retrieve_time(user_input)
    user_input.gsub(/purchase\s+/, "")
  end

end

