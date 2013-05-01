require 'rubygems'
require 'sinatra'
require 'pry'

set :sessions, true

# STATUSES, FOR MY REFERENCE:
# 0 = Nothing interesting has happened yet
# 1 = Blackjack!
# 2 = Total score exactly equal to 21
# 3 = Staying
# 4 = Busted

helpers do
	def setup_game
		suits = ["hearts", "diamonds", "spades", "clubs"]
		values = ["ace", 2, 3, 4, 5, 6, 7, 8, 9, 10, "jack", "queen", "king"]
		deck = []
		suits.each do |suit|
			values.each do |value|
				deck << [suit, value]
			end
		end
		session[:deck] = deck.shuffle!
		session[:player_hand] = session[:deck].pop(2)
		session[:dealer_hand] = session[:deck].pop(2)
	end

	def get_card_image(card)
		return card[0]+"_"+card[1].to_s+".jpg"
	end

	def print_hand(hand)
		images = ""
		hand.each do |card|
			images += "<img src='/images/cards/#{get_card_image(card)}' class='img-rounded' />"
		end
		return images
	end

	def print_dealer_hand
		hand = session[:dealer_hand]
		images = ""
		cards_in_hand = hand.length
		hand.each_with_index do |card, i|
			if i == 0
				images += "<img src='/images/cards/cover.jpg' class='img-rounded' />"
			else
				images += "<img src='/images/cards/#{get_card_image(card)}' class='img-rounded' />"
			end
		end
		return images
	end

	def dealer_turn
		if session[:dealer_score] < 17
			session[:dealer_hand] += session[:deck].pop(1)
		else
			session[:dealer_status] = 3
		end
	end

	def determine_winner
		session[:player_score] = calculate_total(session[:player_hand])
		if session[:player_score] == 21 and session[:player_hand].length == 2
			session[:player_status] = 1
		elsif session[:player_score] == 21
			session[:player_status] = 2
		elsif session[:player_score] > 21
			session[:player_status] = 4
		end

		session[:dealer_score] = calculate_total(session[:dealer_hand])
		if session[:dealer_score] == 21 and session[:dealer_hand].length == 2
			session[:dealer_status] = 1
		elsif session[:dealer_score] == 21
			session[:dealer_status] = 2
		elsif session[:dealer_score] > 21
			session[:dealer_status] = 4
		end

		if session[:player_status] == 1
			if session[:dealer_status] == 1
				session[:current_winner] = "tie"
			else
				session[:current_winner] = "player"
				session[:player_wins] += 1
			end
		elsif session[:dealer_status] == 1
			session[:current_winner] = "dealer"
		elsif session[:player_status] == 2
			if session[:dealer_status] == 2
				if session[:player_hand].length < session[:dealer_hand].length
					session[:current_winner] = "player"
					session[:player_wins] += 1
				elsif session[:playerhand.length] > session[:dealer_hand].length
					session[:current_winner] = "dealer"
				else
					session[:current_winner] = "tie"
				end
			else
				session[:current_winner] = "player"
				session[:player_wins] += 1
			end
		elsif session[:dealer_status] == 2
			session[:current_winner] = "dealer"
		elsif session[:player_status] == 3 and session[:dealer_status] == 3
			if session[:player_score] > session[:dealer_score]
				session[:current_winner] = "player"
				session[:player_wins] += 1
			elsif session[:dealer_score] > session[:player_score]
				session[:current_winner] = "dealer"
			else
				session[:current_winner] = "tie"
			end
		elsif session[:player_status] == 4 and session[:dealer_status] != 4
			session[:current_winner] = "dealer"
		elsif session[:player_status] != 4 and session[:dealer_status] == 4
			session[:current_winner] = "player"
			session[:player_wins] += 1
		end
	end

	def process_bet
		if session[:current_winner] == "player"
			session[:player_money] += session[:player_bet]
		elsif session[:current_winner] == "dealer"
			session[:player_money] -= session[:player_bet]
		end
	end

	def calculate_total(hand)
		total = 0
		ace_count = 0

		hand.each do |card|
			value = card[1]
			if value == "ace"
				total += 11
				ace_count += 1
			elsif value == "jack" or value == "queen" or value == "king"
				total += 10
			else
				total += value
			end

			if ace_count > 1 and total > 21
				total -= (ace_count-1)*10
			end
		end
		return total
	end
end

get '/' do
	if session[:player_name].nil?
		erb :new_player
	else
		redirect '/game'
	end
end

get '/new_player' do
	erb :new_player
end

post '/new_player' do
	if params[:name].nil? or params[:name].empty?
		@error = "You must enter your name."
		halt erb(:new_player)
	end
	# Do initialization tasks
	session[:player_name] = params[:name]
	session[:player_score] = 0
	session[:player_wins] = 0
	session[:player_status] = 0
	session[:player_money] = 500
	session[:dealer_score] = 0
	session[:dealer_status] = 0
	session[:current_winner] = nil
	# Do setup tasks
	setup_game
	# Redirect to gameplay
	redirect '/enter_bet'
end

get '/enter_bet' do
	if session[:player_name].nil?
		redirect '/new_player'
	else
		erb :enter_bet
	end
end

post '/enter_bet' do
	if params[:bet].nil?
		@error = "You need to enter an integer."
		halt erb(:enter_bet)
	elsif not(params[:bet].to_i > 0)
		@error = "Your bet needs to be more than zero."
		halt erb(:enter_bet)
	elsif params[:bet].to_i > session[:player_money]
		@error = "You can't bet more money than you have."
		halt erb(:enter_bet)
	end

	session[:player_bet] = params[:bet].to_i

	redirect '/game'
end

get '/game' do

	determine_winner

	if session[:current_winner] == "player"
		session[:player_money] += session[:player_bet]
	elsif session[:current_winner] == "dealer"
		session[:player_money] -= session[:player_bet]
	end

	erb :game
end

post '/game' do
	# Do player stuff based on what button they hit
	if params[:action] == "Hit"
		session[:player_hand] += session[:deck].pop(1)
	elsif params[:action] == "Stay"
		session[:player_status] = 3
	end

	dealer_turn

	redirect '/game'
end

post '/game/hit' do
	session[:player_hand] += session[:deck].pop(1)

	dealer_turn

	determine_winner

	process_bet

	erb :game, :layout => false
end

post '/game/stay' do
	session[:player_status] = 3

	dealer_turn

	determine_winner

	process_bet

	erb :game, :layout => false
end

post '/new_game' do
	session[:player_score] = 0
	session[:dealer_score] = 0
	session[:player_status] = 0
	session[:dealer_status] = 0
	session[:current_winner] = nil
	session[:player_bet] = 0

	setup_game

	redirect '/enter_bet'
end

post '/reset' do
	session[:player_name] = 0
	session[:player_wins] = 0
	session[:player_status] = 0
	session[:player_hand] = []
	session[:player_score] = 0
	session[:player_money] = 0
	session[:player_bet] = 0
	session[:current_winner] = nil

	redirect :new_player
end