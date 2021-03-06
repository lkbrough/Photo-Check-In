require 'sinatra'
require_relative "user.rb"

enable :sessions

set :session_secret, 'super secret'

get "/login" do
	erb :"authentication/login"
end

post "/process_login" do
	email = params[:email]
	password = params[:password]

	user = User.first(email: email.downcase)

	if(user && user.login(password))
		session[:user_id] = user.id
		if(user.flag == 2)
			flash[:error] = "Change your password!"
			redirect "/newpass"
		end
		flash[:success] = "Successfully logged in!"
		redirect "/"
	else
		erb :"authentication/invalid_login"
	end
end

get "/logout" do
	session[:user_id] = nil
	session[:require_log_in] = nil
	redirect "/"
end

get "/sign_up" do
	erb :"authentication/sign_up"
end


post "/register" do
	email = params[:email]
	password = params[:password]
	company_name = params[:company_name]

	u = User.new
	u.email = email.downcase
	u.password =  password
	u.company_name = company_name
	u.save

	session[:user_id] = u.id

	erb :"authentication/successful_signup"

end

get "/re_enter_password" do
	authenticate!

	@loggedin = current_user.name

	erb :"reenter_password"
end

post "/check_password" do
	authenticate!

	if current_user.login(params[:password])
		redirect "/"
	else
		flash[:error] = "Incorrect Password.  Try again."
		redirect "/reenter_password"
	end
end

#This method will return the user object of the currently signed in user
#Returns nil if not signed in
def current_user
	if(session[:user_id])
		@u ||= User.first(id: session[:user_id])
		return @u
	else
		return nil
	end
end

#if the user is not signed in, will redirect to login page
def authenticate!
	if !current_user
		redirect "/login"
	end
end

def administrator!
	authenticate!
	if !current_user.administrator
		flash[:error] = "Not an adminsitrator. This incident has been reported."
		redirect "/"
	end
end