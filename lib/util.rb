def put_blank_line
  puts
end

def clear_screen(scroll: false)
  puts "\e[2J" + (scroll ? '' : "\e[3J") + "\e[H"
end

def ask_yes_no_question(prompt,
  error_message = 'Allowed options are: "y" and "yes" for yes, ' \
  'and "no" and "n" for no (all case-insensitive)')
  answer = nil

  loop do
    print "#{prompt} [Y/n]: "
    answer = gets.chomp.downcase
    break if ['y', 'yes', 'n', 'no'].include?(answer)

    puts error_message
    put_blank_line
  end

  answer == 'y' || answer == 'yes'
end
