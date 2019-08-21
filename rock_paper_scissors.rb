require 'pry'
PROBABILITY_CHANGE = 5
class Player
  attr_accessor :move, :name, :score
  attr_reader :move_history

  def initialize
    @move = nil
    @move_history = []
    @score = 0
    set_name
  end

  def scored_win
    self.score += 1
  end

  def winner?
    self.score == 10
  end

  def display_move_history
    puts "#{name} move history:"
    move_history.each { |el| puts "\t#{el}" }
  end
end

class Human < Player
  def set_name
    loop do
      puts "What is your name?"
      self.name = gets.chomp
      break unless name.empty?
      puts "Sorry you must enter a value."
    end
  end

  def choose
    choice = nil
    loop do
      puts "Please choose rock, paper, scissors, lizard, or spock:"
      choice = gets.chomp.downcase
      break if ['rock', 'paper', 'scissors', 'lizard', 'spock'].include?(choice)
      puts "Sorry invalid choice."
    end
    self.move = Move.new(choice)
    move_history << move
  end
end

class Computer < Player
  attr_accessor :move_result, :move_probabilities

  def initialize
    super
    probability_by_personality
  end

  def set_name
    self.name = ['R2D2', 'Hal', 'Chappie', 'Sonny', 'Number 5'].sample
  end

  # R2D2 is just happy to be playing. His first move is random
  # Hal was meant to serve humans, even half humans. Hal always begins by
  # picking spock.
  # Chappie's creators made him violent, he has an affinity for sharp objects.
  # Sonny wants to prove his humanity by writing a symphony. He always begins
  # by picking paper. Now if he could only get a pencil...
  # Number 5 wants to try everything. First move is completely random.
  def probability_by_personality
    self.move_probabilities = case name
                              when 'R2D2'
                                { 'rock' => 20, 'paper' => 20, 'scissors' => 20,
                                  'lizard' => 20, 'spock' => 20 }
                              when 'Hal'
                                { 'rock' => 0, 'paper' => 0, 'scissors' => 0,
                                  'lizard' => 0, 'spock' => 100 }
                              when 'Chappie'
                                { 'rock' => 0, 'paper' => 0, 'scissors' => 100,
                                  'lizard' => 0, 'spock' => 0 }
                              when 'Sonny'
                                { 'rock' => 0, 'paper' => 100, 'scissors' => 0,
                                  'lizard' => 0, 'spock' => 0 }
                              when 'Number 5'
                                { 'rock' => 20, 'paper' => 20, 'scissors' => 20,
                                  'lizard' => 20, 'spock' => 20 }
                              end
  end

  def choose
    # if a move result (win, loss or tie) has been achieved (it is after the
    # first round) use that result to update the probabilities of each move in
    # @move_probabilities
    update_probabilities if move_result

    choice = rand(100)
    probability_ranges.each do |move, probability_range|
      choice = move if probability_range.cover?(choice)
    end

    self.move = Move.new(choice)
    move_history << move.to_s
  end

  # returns an array of ranges based on the probability of each move in
  # @move_probabilities so that a random number will fall into one of
  # these ranges and indicate the computer's move.
  def probability_ranges
    start_of_range = 0
    probability_ranges = {}
    move_probabilities.each do |move_choice, probability_percent|
      new_range = (start_of_range...(start_of_range + probability_percent))
      probability_ranges[move_choice] = new_range
      start_of_range = new_range.last
    end
    probability_ranges
  end

  def update_probabilities
    last_move = move_history[-1]
    case move_result
    when :win
      increase_probability(last_move)
    when :loss
      decrease_probability(last_move)
    end
    p move_probabilities
  end

  # called if a move results in a win, will increase the probability of that
  # move being chosen by the computer again

  def increase_probability(winning_move)
    move_probabilities.each do |move_choice, move_probability|
      if move_choice != winning_move && move_probability >= PROBABILITY_CHANGE
        move_probabilities[winning_move] += PROBABILITY_CHANGE
        move_probabilities[move_choice] -= PROBABILITY_CHANGE
      end
    end
  end

  # called if a move results in a loss, will decrease the probability of that
  # move being chosen by the computer again

  def decrease_probability(losing_move)
    move_probabilities.each do |move_choice, move_probability|
      break if move_probabilities[losing_move] == 0
      if move_choice != losing_move && move_probability <= 95
        move_probabilities[losing_move] -= PROBABILITY_CHANGE
        move_probabilities[move_choice] += PROBABILITY_CHANGE
      end
    end
  end
end

class RPSGame
  attr_accessor :human, :computer, :round_winner

  def initialize
    @human = Human.new
    @computer = Computer.new
  end

  def display_welcome_message
    puts "Welcome to Rock, Paper, Scissors!"
  end

  def display_goodbye_message
    puts "Thanks for playing Rock, Paper, Scissors!"
  end

  def display_moves
    puts "#{human.name} chose #{human.move}."
    puts "#{computer.name} chose #{computer.move}."
  end

  def display_winner
    determine_winner
    puts round_winner ? "#{round_winner} wins!" : "It's a tie!"
  end

  def determine_winner
    human_move = human.move
    computer_move = computer.move

    if human_move > computer_move
      self.round_winner = human.name
      computer.move_result = :loss
    elsif human_move < computer_move
      self.round_winner = computer.name
      computer.move_result = :win
    else
      self.round_winner = nil
      computer.move_result = :tie
    end
  end

  def update_score
    case round_winner
    when human.name then human.scored_win
    when computer.name then computer.scored_win
    end
  end

  def display_grand_winner
    grand_winner = human.score > computer.score ? human.name : computer.name
    puts "#{grand_winner} HAS REACHED 10 WINS! #{grand_winner} WINS IT ALL!"
  end

  def display_score
    sleep(3)
    system(Gem.win_platform? ? "cls" : "clear")
    score = <<~SCORE
      ---------------------------------------
      First to 10 wins it all!
      Current Score:
      \t#{human.name} : #{human.score}
      \t#{computer.name} : #{computer.score}
      ---------------------------------------
    SCORE

    puts score
  end

  def play_again?
    answer = nil
    loop do
      puts "Would you like to play again?"
      answer = gets.chomp
      break if ['y', 'n'].include?(answer.downcase)
      puts "Enter y or n."
    end
    human.score = 0
    computer.score = 0
    answer == 'y'
  end

  def players_choose_moves
    human.choose
    computer.choose
  end

  def play
    display_welcome_message
    loop do
      while !human.winner? && !computer.winner?
        display_score
        players_choose_moves
        display_moves
        display_winner
        update_score
      end
      display_score
      display_grand_winner
      break unless play_again?
    end
    display_goodbye_message
  end
end

class Move
  include Comparable
  attr_reader :value
  WINNING_PAIRS = { 'rock' => ['scissors', 'lizard'],
                    'paper' => ['rock', 'spock'],
                    'scissors' => ['paper', 'lizard'],
                    'lizard' => ['spock', 'paper'],
                    'spock' => ['rock', 'scissors'] }
  def initialize(value)
    @value = value
  end

  def >(other_move)
    WINNING_PAIRS[value].include?(other_move.to_s)
  end

  def <(other_move)
    WINNING_PAIRS[other_move.to_s].include?(value)
  end

  def to_s
    value.to_s
  end
end

game = RPSGame.new
game.play
