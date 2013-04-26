require 'rubygems'
require 'sinatra'

set :sessions, true

helpers do
	def setup_game
		suits = ["H", "D", "S", "C"]
		values = ["A", 2, 3, 4, 5, 6, 7, 8, 9, 10, "J", "Q", "K"]
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

	def calculate_total(hand)
		total = 0
		ace_count = 0
		hand.each do |card|
			value = card[1]
			if value == "A"
				total += 11
				ace_count += 1
			elsif value == ("J" or "Q" or "K")
				total += 10
			else
				total += value
			end
			if ace_count > 1 and total > 21
				total -= (ace_count-1)*10
			end
		end
	end
end

get '/' do
	erb :home
end

get '/new_player' do
	erb :new_player
end

post '/new_player' do
	if params[:name].nil? or params[:name].empty?
		@error = "You must enter your name."
		halt erb(:new_player)
	end
	# Do setup tasks
	session[:player_name] = params[:name]
	session[:player_score] = 0
	session[:player_wins] = 0
	redirect '/game'
end

get '/game' do
	erb :game
end

post '/game' do
	erb :game
end