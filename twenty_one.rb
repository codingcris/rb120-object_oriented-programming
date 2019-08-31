module Frameable
  PADDING = 2
  def display_framed_message(message)
    lines = message.split("\n")
    longest_line_size = lines.map(&:size).max
    puts '-' * (longest_line_size + (PADDING * 2))
    lines.each { |line| puts "#{' ' * PADDING}#{line}#{' ' * PADDING}" }
    puts '-' * (longest_line_size + (PADDING * 2))
  end
end

class Participant
  include Frameable

  private

  attr_writer :name, :cards

  def initialize
    @cards = []
    @hand_value = 0
    set_name
  end

  def display_cards_heading
    heading = "#{name}'s cards are:"
    display_framed_message(heading)
  end

  public

  attr_reader :name, :cards
  attr_accessor :hand_value

  def add_new_card(new_card)
    cards << new_card
  end

  def display_cards
    display_cards_heading
    cards.each { |card| puts "\t#{card}" }
  end

  def display_hand_value
    puts "TOTAL => #{hand_value}"
  end

  def reset
    self.cards = []
    self.hand_value = 0
  end
end

class Player < Participant
  def choose_move(game_message)
    puts game_message
    gets.chomp
  end

  private

  def set_name
    loop do
      puts "Enter your name:"
      self.name = gets.chomp
      break unless name.strip.empty?
      puts "Sorry, you must enter a value."
    end
  end
end

class Dealer < Participant
  COMPUTER_NAMES = ['R2D2', 'Hal', 'Chappie', 'Sonny', 'Number 5']

  # number of cards parameter indicates the number of cards I want to display.
  # By default it is all of the cards, but may be passed an argument to display
  # a partial number of cards with the rest of the deck obscured by ??
  def display_cards(number_of_cards = cards.size)
    if number_of_cards == cards.size
      super()
    else
      display_cards_heading
      number_of_cards.times { |index| puts "\t#{cards[index]}" }
      puts "\t???"
    end
  end

  def display_hand_value(value_conceal = nil)
    if value_conceal
      puts "TOTAL => #{value_conceal}"
    else
      super()
    end
  end

  private

  def set_name
    self.name = COMPUTER_NAMES.sample
  end
end

class Card
  SUITS = %w(Hearts Clubs Spades Diamonds)
  FACES = [2, 3, 4, 5, 6, 7, 8, 9, 'Joker', 'Queen', 'King', 'Ace']

  attr_reader :suit, :face

  def initialize(suit, face)
    @suit = suit
    @face = face
  end

  def to_s
    "#{face} of #{suit}"
  end
end

class Deck
  def initialize
    @deck = shuffled_deck
  end

  def deal_card
    Card.new(*deck.pop)
  end

  private

  attr_reader :deck

  def shuffled_deck
    Card::SUITS.product(Card::FACES).shuffle
  end
end

class TwentyOneGame
  include Frameable

  TARGET_TOTAL = 21
  DEALER_TARGET = 17
  MAX_WINS = 5

  def initialize
    clear
    @deck = Deck.new
    @player = Player.new
    @player_score = 0
    @dealer = Dealer.new
    @dealer_score = 0
    @dealer_move_history = []
    @current_participant = @player
    @win = { winner: nil,
             win_type: nil }
  end

  def play
    display_welcome_message

    loop do
      display_scores
      deal_initial_cards
      display_initial_hands

      play_round
      print_round_over_info

      if game_over?
        display_grand_champion
        break unless play_again?
      end
      enter_to_continue unless game_over?

      reset
    end
    display_goodbye_message
  end

  private

  attr_reader :player, :dealer
  attr_accessor :deck, :dealer_move_history, :current_participant, :win,
                :player_score, :dealer_score

  def display_scores
    scores_message = <<~SCORE
      FIRST TO #{MAX_WINS} IS GRAND WINNER!
      CURRENT SCORE:
      \t#{player.name} => #{player_score}
      \t#{dealer.name} => #{dealer_score}
    SCORE
    display_framed_message(scores_message)
  end

  def clear
    system("clear")
  end

  def display_welcome_message
    clear
    display_framed_message("Welcome to Twenty One! Let's play!")
  end

  def deal_initial_cards
    puts "\nDealing cards..."
    puts
    sleep(2)

    [player, dealer].each do |participant|
      2.times do
        new_card = deck.deal_card
        participant.add_new_card(new_card)
        update_total(participant)
      end
    end
  end

  def update_total(participant)
    newest_card = participant.cards.last
    total_increment = case newest_card.face
                      when 'Joker', 'Queen', 'King' then 10
                      when 'Ace'
                        participant.hand_value + 11 > TARGET_TOTAL ? 1 : 11
                      else
                        newest_card.face
                      end
    participant.hand_value += total_increment
  end

  def display_initial_hands
    display_participant_hand(player)
    puts
    dealer.display_cards(1)
    print "\t"
    dealer.display_hand_value('??')
  end

  def display_participant_hand(participant)
    participant.display_cards
    print "\t"
    participant.display_hand_value
  end

  def play_round
    loop do
      if busted? || someone_won?
        determine_win
        update_score
        break
      end
      participant_turn
      clear
      display_participant_hand(player) if current_participant == player
    end
  end

  def participant_turn
    case current_participant
    when player then player_turn
    when dealer then dealer_turn
    end
  end

  def player_turn
    choice = nil
    loop do
      choice = player.choose_move("\nChoose to (H)IT or (S)TAY: ").upcase
      break if ['H', 'S'].include?(choice)
      puts "\nInvalid choice. Enter 'H' to hit or 'S' to stay."
    end

    case choice
    when 'H' then hit(player)
    when 'S' then stay
    end
  end

  def dealer_turn
    puts "Dealer is thinking..."
    sleep(1)
    dealer.hand_value >= DEALER_TARGET ? stay : hit(dealer)
    sleep(1)
  end

  def hit(participant)
    dealer_move_history << 'H' if participant == dealer
    puts "#{participant.name} hits."
    participant.add_new_card(deck.deal_card)
    update_total(participant)
  end

  def stay
    dealer_move_history << 'S' if current_participant == dealer
    puts "#{current_participant.name} stays."
    self.current_participant = dealer if current_participant == player
  end

  def busted?
    current_participant.hand_value > TARGET_TOTAL
  end

  def someone_won?
    busted? || player.hand_value == TARGET_TOTAL ||
      dealer.hand_value == TARGET_TOTAL || dealer_move_history.last == 'S'
  end

  def determine_win
    if busted?
      bust_win
    elsif player.hand_value == TARGET_TOTAL
      target_win(player)
    elsif dealer.hand_value == TARGET_TOTAL
      target_win(dealer)
    else
      total_win
    end
  end

  def update_score
    case win[:winner]
    when player then self.player_score = player_score + 1
    when dealer then self.dealer_score = dealer_score + 1
    end
  end

  def bust_win
    win[:winner] = case current_participant
                   when player then dealer
                   when dealer then player
                   end
    win[:win_type] = :bust
  end

  def target_win(winner)
    win[:winner] = winner
    win[:win_type] = :target
  end

  def total_win
    case player.hand_value <=> dealer.hand_value
    when 1
      win[:winner] = player
    when -1
      win[:winner] = dealer
    end

    win[:win_type] = :total
  end

  def display_winner
    puts case win[:win_type]
         when :bust then "#{current_participant.name} busts."
         when :target then "#{win[:winner].name} reached 21!"
         when :total then "#{win[:winner].name} is the closest to 21."
         else "Player and dealer hands are equal. Tie game."
         end
    puts "#{win[:winner].name} wins!" if win[:winner]
  end

  def display_grand_champion
    sleep(2)

    grand_champ_msg = <<~MSG
      #{win[:winner].name} has reached #{MAX_WINS} wins!
      #{win[:winner].name} is grand champion!
    MSG

    puts
    display_framed_message(grand_champ_msg)
  end

  def play_again?
    choice = nil
    loop do
      puts "\nWould you like to play again? (Y/N)"
      choice = gets.chomp.upcase
      break if ['Y', 'N'].include?(choice)
      puts "Sorry you must enter Y for yes or N for no"
    end
    choice == 'Y'
  end

  def reset
    clear
    self.deck = Deck.new
    self.dealer_move_history = []
    self.current_participant = player
    self.win = { winner: nil,
                 win_type: nil }
    if game_over?
      self.player_score = 0
      self.dealer_score = 0
    end
    player.reset
    dealer.reset
  end

  def print_round_over_info
    clear
    display_winner
    display_participant_hand(player)
    puts
    display_participant_hand(dealer)
  end

  def enter_to_continue
    puts "\nPress ENTER to continue."
    gets.chomp
  end

  def game_over?
    player_score == MAX_WINS || dealer_score == MAX_WINS
  end

  def display_goodbye_message
    puts "Thanks for playing Twenty One! Goodbye."
  end
end

game = TwentyOneGame.new
game.play
