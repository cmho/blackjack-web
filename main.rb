require 'rubygems'
require 'sinatra'

set :sessions, true

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

	redirect '/game'
end

get '/game' do
	erb :game
end

post '/game' do
	erb :game
end