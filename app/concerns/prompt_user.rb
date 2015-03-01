module CommandPrompt
  def get_user_input
    print ">> "
    input = STDIN.gets.chomp.strip.downcase
    exit if input.match(/^exit$/i)
    input
  end

  def command_prompt
    return get_user_input unless block_given?
    loop do 
      yield(get_user_input)
    end
  end

  def command_match(given_command, commands)
    commands.each {|command| return command if command =~ Regexp.new(given_command) }
    nil
  end
end