class Board
  WINNING_LINES =  [[1, 2, 3], [4, 5, 6], [7, 8, 9]] + # rows
                   [[1, 4, 7], [2, 5, 8], [3, 6, 9]] + # columns
                   [[1, 5, 9], [3, 5, 7]] #              diagonals
  CENTER_SQUARE = 5

  def initialize
    @squares = {}
    reset
  end

  # rubocop:disable Metrics/AbcSize
  def draw
    board_display = <<~BOARD
       |       |
   #{squares[1]}   |   #{squares[2]}   |   #{squares[3]}
       |       |
-------+-------+-------
       |       |
   #{squares[4]}   |   #{squares[5]}   |   #{squares[6]}
       |       |
-------+-------+-------
       |       |
   #{squares[7]}   |   #{squares[8]}   |   #{squares[9]}
       |       |

    BOARD

    puts board_display
  end
  # rubocop:enable Metrics/AbcSize

  def marked_keys(player = nil)
    return squares.keys.select { |key| squares[key].marker == player } if player
    squares.keys.select { |key| squares[key].marked? }
  end

  def unmarked_keys
    squares.keys.select { |key| squares[key].unmarked? }
  end

  def []=(key, marker)
    squares[key].marker = marker
  end

  def full?
    unmarked_keys.empty?
  end

  def someone_won?
    !!winning_marker
  end

  def winning_marker
    WINNING_LINES.each do |line|
      squares = @squares.values_at(*line)
      return squares.first.marker if three_identical_markers?(squares)
    end
    nil
  end

  def reset
    (1..9).each { |key| squares[key] = Square.new }
  end

  private

  attr_reader :squares

  def three_identical_markers?(squares)
    markers = squares.select(&:marked?).map(&:marker)
    return false if markers.size != 3
    markers.uniq.size == 1
  end
end

class Square
  INITIAL_MARKER = ' '

  attr_accessor :marker

  def initialize(marker = INITIAL_MARKER)
    @marker = marker
  end

  def to_s
    marker
  end

  def unmarked?
    marker == INITIAL_MARKER
  end

  def marked?
    marker != INITIAL_MARKER
  end
end

class Player
  attr_accessor :score, :marker, :name

  def initialize
    set_name
    set_marker
    @score = 0
  end
end

class Computer < Player
  COMPUTER_MARKERS = %w(⁂ ✚ ♞ ✔ ✪ ♬ ㋡)
  COMPUTER_NAMES = ['R2D2', 'Hal', 'Chappie', 'Sonny', 'Number 5']

  def set_name
    @name = ['R2D2', 'Hal', 'Chappie', 'Sonny', 'Number5'].sample
  end

  def set_marker
    @marker = %w(⁂ ✚ ♞ ✔ ✪ ♬).sample
  end

  def best_move(guidelines)
    open_moves = guidelines[:open_moves]
    winning_moves = guidelines[:winning_moves]

    guidelines[:priority_moves].each do |move|
      return move if open_moves.include?(move)
    end

    offensive_move = find_definite_win(guidelines[:computer_moves],
                                       winning_moves, open_moves)
    return offensive_move if offensive_move

    defensive_move = find_definite_win(guidelines[:opponent_moves],
                                       winning_moves, open_moves)
    return defensive_move if defensive_move

    open_moves.sample
  end

  def find_definite_win(player_moves, winning_moves, open_moves)
    winning_moves.each do |win|
      moves_for_win = win.reject { |move| player_moves.include?(move) }
      if moves_for_win.size == 1 && open_moves.include?(moves_for_win.first)
        definite_win = moves_for_win.first
      end
      return definite_win if definite_win
    end
    nil
  end
end

class Human < Player
  SUGGESTED_MARKERS = %w(❋ ✖ ❿ ☯ ✯ ✈ ❉)
  SUGGESTED_MARKER_CODES = %w(1! 2! 3! 4! 5! 6! 7!)

  def set_name
    loop do
      puts "What is your name?"
      self.name = gets.chomp
      break unless name.strip.empty?
      puts "Sorry you must enter a value."
    end
  end

  def set_marker
    loop do
      puts "Choose any one character as your marker."
      show_suggested_markers
      choice = gets.chomp[0..1]
      choice = suggested_marker(choice) if suggested_marker_chosen?(choice)
      self.marker = choice
      break unless choice.strip.empty?
      puts "Sorry you must enter a value."
    end
  end

  def suggested_marker_chosen?(marker_choice)
    SUGGESTED_MARKER_CODES.include?(marker_choice)
  end

  def suggested_marker(choice)
    SUGGESTED_MARKERS[choice[0].to_i - 1]
  end

  def show_suggested_markers
    puts "You can also choose from one of these cool markers:"
    puts "ENTER: #{SUGGESTED_MARKER_CODES.join(' | ')}"
    puts "--------------------------------------------"
    puts "TO BE: #{SUGGESTED_MARKERS.join('  | ')}"
  end

  def choose_move(game_message = nil)
    puts game_message if game_message
    choice = gets.chomp
    return choice unless choice.strip.empty?
  end
end

class TTTGame
  CLEAR_SCREEN = Gem.win_platform? ? "cls" : "clear"
  MAX_WINS = 5
  COIN = ['heads', 'tails']

  def initialize
    @board = Board.new
    @human = Human.new
    @computer = Computer.new
    @first_move = first_to_move
    @current_marker = first_move.marker
  end

  def play
    clear
    display_welcome_message

    loop do
      display_board
      loop do
        current_player_moves
        break if board.full? || board.someone_won?
        clear_screen_and_display_board
      end

      display_result
      if grand_winner?
        play_again? ? reset_first_to_move : break
      end
      reset
    end

    display_goodbye_message
  end

  def clear
    system(CLEAR_SCREEN)
  end

  private

  attr_reader :board, :human, :computer
  attr_accessor :current_marker, :first_move

  def first_to_move
    choice = coin_toss_choice
    winner = coin_toss_winner
    first = determine_first_player(winner, choice)
    puts "You chose #{COIN.select { |side| side.start_with?(choice) }[0]}.\
 Coin landed on #{winner}. #{first.name} goes first."
    sleep(3)
    first
  end

  def coin_toss_choice
    puts "Coin toss will determine who goes first."
    choice = ''
    loop do
      puts "Choose heads or tails (H/T)"
      choice = gets.chomp.downcase
      break if choice == 'h' || choice == 't'
      puts "Invalid choice. Enter 'H' for heads or 'T' for tails."
    end
    choice
  end

  def coin_toss_winner
    COIN.sample
  end

  def determine_first_player(winner, player_choice)
    winner.start_with?(player_choice) ? human : computer
  end

  def display_welcome_message
    puts "Welcome to Tic Tac Toe!"
    puts
  end

  def display_goodbye_message
    puts "Thanks for playing Tic Tac Toe! Goodbye!"
  end

  def display_board
    display_score
    puts "You're a #{human.marker}. Computer is a #{computer.marker}"
    board.draw
  end

  def display_score
    puts "-------------------------------"
    puts "FIRST TO #{MAX_WINS} WINS IT ALL!!!"
    puts "CURRENT SCORE:"
    puts "  #{human.name} => #{human.score}"
    puts "  #{computer.name} => #{computer.score}"
    puts "-------------------------------"
    puts ""
  end

  def clear_screen_and_display_board
    clear
    display_board
  end

  def join_or(collection)
    return collection.join if collection.size <= 1
    collection[0...-1].join(', ') + " or #{collection[-1]}"
  end

  def current_player_moves
    case current_marker
    when human.marker then human_moves
    when computer.marker then computer_moves
    end
    update_current_marker
    update_score(board.winning_marker) if board.someone_won?
  end

  def human_moves
    loop do
      puts "Choose a square from: #{join_or(board.unmarked_keys)}"
      choice = human.choose_move.to_i
      if board.unmarked_keys.include?(choice)
        board[choice.to_i] = human.marker
        break
      end
      puts 'Sorry, that is not a valid choice.'
    end
  end

  def computer_moves
    human_squares = board.marked_keys(human.marker)
    computer_squares = board.marked_keys(computer.marker)

    best_move_guidelines = { priority_moves: [Board::CENTER_SQUARE],
                             winning_moves: Board::WINNING_LINES,
                             open_moves: board.unmarked_keys,
                             computer_moves: computer_squares,
                             opponent_moves: human_squares }

    best_move = computer.best_move(best_move_guidelines)
    board[best_move] = computer.marker
  end

  def update_current_marker
    self.current_marker = case current_marker
                          when human.marker then computer.marker
                          when computer.marker then human.marker
                          end
  end

  def display_result
    clear_screen_and_display_board
    winning_marker = board.winning_marker
    puts case winning_marker
         when human.marker then "#{human.marker} wins!"
         when computer.marker then "#{computer.marker} wins!"
         else "Board is full. It's a tie!"
         end
    sleep(3)
    display_grand_winner if grand_winner?
  end

  def display_grand_winner
    grand_winner = case board.winning_marker
                   when human.marker then human.name
                   when computer.marker then computer.name
                   end
    puts "-------------------------------"
    puts "#{grand_winner} reached #{MAX_WINS} wins!"
    puts "Grand champion: #{grand_winner}"
    puts "-------------------------------"
  end

  def play_again?
    choice = nil

    loop do
      puts "Would you like to play again?"
      choice = gets.chomp.downcase
      break if ['y', 'n'].include?(choice)
      puts "Sorry, must be y/n"
    end

    choice == 'y'
  end

  def reset
    board.reset
    self.current_marker = first_move.marker
    if grand_winner?
      human.score = 0
      computer.score = 0
    end
    clear
  end

  def update_score(winning_marker)
    case winning_marker
    when human.marker then human.score += 1
    when computer.marker then computer.score += 1
    end
  end

  def grand_winner?
    human.score == MAX_WINS || computer.score == MAX_WINS
  end

  def reset_first_to_move
    self.first_move = first_to_move
  end
end

game = TTTGame.new
game.play
