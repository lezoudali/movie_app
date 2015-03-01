class Runner
  include CommandPrompt

  def initialize
    MovieScraper.load
    run
  end

  def run 
    search_list = search_prompt
    return no_data_found if search_list.size.zero?
    movie, theater = get_movie_theater(search_list)
    get_tickets(movie, theater)
  end

  def search_prompt
    puts "\nSearch by movie(s) " + "'search -m | search -m <movie name>' ".colorize(:yellow) + "or by theater(s)" + " search -t | search -t <theater name>".colorize(:yellow) + "...\n\n"
    error_message = "Invalid Search Command...".colorize(:red)
    command_prompt do |command| 
      return run_command(command) if command.match Regexp.union(search_commands)
      help?(command) ? show_instructions : puts(error_message)
    end
  end

  def get_movie_theater(categories)
    return no_data_found if categories.size.zero?
    category = selection_prompt(categories)
    options = category.get_options
    category.list_showtimes(options)
    option = selection_prompt(options)
    [option,category].sort_by{|selection| selection.to_s}
  end

  def show_instructions
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
      puts "Goodbye and enjoy your movie... :)\n".colorize(:yellow)
      exit
    else
      puts "Select time from above (including <pm|am> if shown)"
    end
  end

  def get_tickets(movie, theater)
    puts "\n\tEnter "+"trailer".colorize(:green)+", "+"imdb".colorize(:green)+", or "+"purchase <(hh:mm)>".colorize(:green)+" enter 'pm/am' if shown.'\n"
    puts "\n#{movie.name}".upcase.colorize(:cyan) + "\t " + "#{theater.name.upcase}".colorize(:magenta) + "\t #{movie.get_showtimes(theater).join(" ")}".colorize(:light_blue) + "\n\n"
    error_message = "Enter "+"trailer".colorize(:green)+", "+"imdb".colorize(:green)+", or "+"purchase <(hh:mm)>".colorize(:green)+" enter 'pm/am' if shown.'\n\n"
    loop do 
      command_prompt do |command| 
        command.match Regexp.union(get_ticket_options) ? run_command(command, movie, theater) : puts(error_message)
        show_instructions if help?(command)
      end
    end
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
                theater:        /^search -?t .+/i,
                movie:          /^search -?m .+/i,
                all_movies:     /^search -?m$/i,
                all_theaters:   /^search -?t$/i,
                home:           /home/i
              },
      open: 
              {
                trailer:        /trailer/i,
                imdb:           /imdb/i,
                ticket_link:    /purchase\s+\d+:\d+/,
                home:           /home/i
              }
    }
  end

  def run_command(command, movie = nil, theater = nil)
    case command
      when commands[:search][:theater]       then search_from(Theater, command)
      when commands[:search][:movie]         then search_from(Movie, command)
      when commands[:search][:all_movies]    then list_all_movies
      when commands[:search][:all_theaters]  then list_all_theaters
      when commands[:open][:home]            then restart_app
      when commands[:open][:trailer]         then movie.open_trailer
      when commands[:open][:imdb]            then movie.open_imdb 
      when commands[:open][:ticket_link]     then purchase_ticket(command, movie, theater) 
    end
  end

  def find_selection(options, id)
    options.find{|option| options.index(option) == id}
  end

  def selection_prompt(options)
    error_message = "\nPlease enter correct ID from list...\n".colorize(:red)
    ids = options.map.with_index{|opt, index| (index + 1).to_s}
    command_prompt do |id|  
      return find_selection(options, id.to_i - 1) if id.match Regexp.union(ids)
      help?(command) ? show_instructions : puts(error_message)
    end
  end

  def search_from(model, user_input)
    query = get_search_query(user_input)
    model.list model.find_all_by_name(query)
  end

  def get_search_query(input)
    input.gsub(/search -?(m|t)\s*/, "")
  end

  def search_commands
    commands[:search].values
  end

  def get_ticket_options
    commands[:open].values
  end

  def help?(input)
    input.match(/help/)
  end

  def restart_app
    run
  end

  def no_data_found
    puts "Google did not find any movies/theaters in your area... please enter a new date and zipcode :( ...".colorize(:red)
    restart_app
  end

  def retrieve_time(user_input)
    user_input.gsub(/purchase\s+/, "")
  end
end

