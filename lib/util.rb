def put_blank_line
  puts
end

def clear_screen(scroll: false)
  puts "\e[2J" + (scroll ? '' : "\e[3J") + "\e[H"
end
