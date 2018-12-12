require "sinatra"
require 'sinatra/flash'
require_relative "authentication.rb"
require 'stripe'
require_relative "timecards.rb"
require 'mailgun'
require 'rest-client'

PUBLISHABLE_KEY = "pk_test_8YqvkifbSgszGnS7WjZ6r8qA"
SECRET_KEY = "sk_test_1SsI7rr3CuGeXMsNXW1UxPcY"

set :publishable_key, ENV['PUBLISHABLE_KEY']
set :secret_key, ENV['SECRET_KEY']

set :private_key, ENV['MAILGUN_API_KEY']

Stripe.api_key = "sk_test_1SsI7rr3CuGeXMsNXW1UxPcY"

#the following urls are included in authentication.rb
# GET /login
# GET /logout
# GET /sign_up

# authenticate! will make sure that the user is signed in, if they are not they will be redirected to the login page
# if the user is signed in, current_user will refer to the signed in user object.
# if they are not signed in, current_user will be nil

get "/" do
	erb :index
end

get "/pay_to_sign_up" do
	authenticate!
	erb :pay_to_sign_up
end

get "/employee_check_in" do
	authenticate!
	administrator!

	@admin = current_user.company_name
	session[:require_log_in] = true

	erb :employee_check_in

end

get "/employee_check_out" do
	authenticate!
	administrator!

	@admin = current_user.company_name
	session[:require_log_in] = true

	erb :employee_check_out
end

get "/add_employee" do
	authenticate!
	administrator!
	erb :add_employee
end

get "/photo_upload" do
	authenticate!
	administrator!
	erb :photo_upload
end

get "/reenter_password" do
	authenticate!
	@email = current_user.email
	erb :reenter_password
end


post "/register_new_employee" do
	authenticate!
	administrator!
	newUser = User.new
	if(params[:email] && params[:password] && params[:first_name] && params[:last_name])
		newUser.email = params[:email].downcase
		newUser.password = params[:password]
		newUser.first_name = params[:first_name]
		newUser.last_name = params[:last_name]
		newUser.flag = 2;
		newUser.employee = true
		newUser.employer = current_user.id
		newUser.company_name = current_user.company_name
		newUser.save
	end
	flash[:success] = "Successfully added employee!"
	redirect "/"
end

get "/newpass" do
	erb :change_password
end

post "/change_password" do
	if(params[:newPassword])
		current_user.password = params[:newPassword]
		current_user.flag = 0;
		current_user.save
		flash[:success] = "Successfully changed password!"
		redirect "/"
	end
end

post "/charge" do
	# Amount in cents
	@amount = 10000
  
	customer = Stripe::Customer.create(
	  :email => 'customer@example.com',
	  :source  => params[:stripeToken]
	)
  
	charge = Stripe::Charge.create(
	  :amount      => @amount,
	  :description => 'Sinatra Charge',
	  :currency    => 'usd',
	  :customer    => customer.id
	)

	current_user.administrator = true;
	current_user.save
	flash[:success] = "Successfully became an administrator!"
	redirect "/"
end

post "/employee_checking_in" do
	authenticate!
	administrator!

	username = User.first(email: params[:email].downcase)
	if(username && username.login(params[:password]))
		timecard = TimeCard.new
		timecard.date = DateTime.now.to_date
		timecard.sign_in = DateTime.now
		timecard.user_id = username.id
		timecard.save
		@check_in_name = username.first_name + " " + username.last_name
	else
		flash[:error] = "Incorrect Password.  Please try again."
		redirect "/employee_check_in"
	end

	redirect "/photo_upload"
end

post "/password_re_enter" do
	authenticate!

	if(current_user.login(params[:password]))
		session[:require_log_in] = false
		redirect "/"
	else
		flash[:error] = "Incorrect Password.  Please try again."
		redirect "/reenter_password"
	end
end

post "/employee_checking_out" do
	authenticate!
	administrator!

	username = User.first(email: params[:email].downcase)
	if(username && username.login(params[:password]))
		timecard = TimeCard.first(user_id: username.id, complete: false)
		if(timecard)
			timecard.update(sign_out: DateTime.now)
			timecard.update(complete: true)
			flash[:success] = "Successfully signed out! Have a good day!"
		else
			flash[:error] = "Time Card not found!"
		end
	else
		flash[:error] = "Incorrect Password!"
	end

	redirect "/employee_check_out"
end

post "/photo_post" do
	cnt = 0
	key = ""
	value = ""
	env_file = "config/local_env.txt"
	f = File.exists?(env_file)?File.open(env_file):nil
	if !f.nil?
		f.each_line do |line|
			ENV[key.to_s] = value.to_s if cnt > 0 and cnt % 2 == 0
			key = line.strip if cnt % 2 == 0
			value = line.strip if cnt % 2 == 1
			cnt = cnt + 1
		end
		ENV[key.to_s] = value.to_s
	end

	authenticate!
	administrator!

	tempfile = params[:picture][:tempfile]
	f = Tempfile.new(['picture', '.jpg'])
	f.write(tempfile.read)

	private_key = ENV['MAILGUN_API_KEY']
	puts "https://api:#{private_key.to_s}"

	RestClient.post "https://api:#{private_key}"\
	"@api.mailgun.net/v3/sandbox342c77ab45434677a6e24132490ac206.mailgun.org/messages",
  	:from => "Photo Check In<mailgun@sandbox342c77ab45434677a6e24132490ac206.mailgun.org>",
  	:to => current_user.email.downcase,
  	:subject => "Employee Checked In!",
  	:text => "Your employee just checked in! Attached is a photo for proof.",
  	:attachment => File.new(tempfile.path)

	f.close!

	flash[:success] = "Successfully Signed In!"
	redirect '/employee_check_in'
end

get "/timesheets" do
	authenticate!
	administrator!

	if session[:require_log_in] == true
		redirect "/reenter_password"
	end

	@temp = DateTime.now.to_date
	@temp = params[:date] if params[:date]
	@max = 1
  	TimeCard.all(date: @temp).each do |x|
		@max = x.user_id if x.user_id > @max
  	end
  	maxi = 1
	maxj = 1
	for k in 1..@max do
		if TimeCard.first(user_id: k, date: @temp)
			i = 0
			j = 0
			TimeCard.all(user_id: k, date: @temp).each do |x|
				i += 1 if x.sign_in
				j += 1 if x.sign_out
			end
			maxi = i if i > maxi
			maxj = j if j > maxj
		end
	end
	@maxk = maxi > maxj ? maxi : maxj
	erb :timesheet
end

get "/edit" do
	authenticate!
	administrator!
	@date = Date.parse params[:date]
	@user_id = params[:user_id].to_i
	maxi = 0
	maxj = 0
	TimeCard.all(date: @date, user_id: @user_id).each do |x|
		maxi += 1 if x.sign_in
		maxj += 1 if x.sign_out
	end
	@maxk = maxi > maxj ? maxi : maxj
	erb :time_edit
end

post "/edit" do
	authenticate!
	administrator!
	redirect "/timesheets" if !params[:type] || !params[:date] || !params[:user_id]
	if params[:type] == "change_time_in" && params[:change_date] && params[:time_in]
		x = TimeCard.first(date: params[:date], user_id: params[:user_id], sign_in: params[:sign_in])
		x.update(date: params[:change_date], sign_in: params[:time_in])
		x.update(complete: true) if x.sign_out
	elsif params[:type] == "change_time_out" && params[:change_date] && params[:time_out]
		x = TimeCard.first(date: params[:date], user_id: params[:user_id], sign_out: params[:sign_out])
		x.update(date: params[:change_date], sign_out: params[:time_out])
		x.update(complete: true) if x.sign_in
	elsif params[:type] == "delete_time_in"
		TimeCard.first(date: params[:date], user_id: params[:user_id], sign_in: params[:sign_in]).destroy
	elsif params[:type] == "delete_time_out"
		TimeCard.first(date: params[:date], user_id: params[:user_id], sign_out: params[:sign_out]).destroy
	end
	redirect "/timesheets?date=#{params[:date]}" if params[:date]
	redirect "/timesheets"
end

get "/employees" do
	authenticate!
	administrator!

	if session[:require_log_in] == true
		redirect "/reenter_password"
	end

	@employee = User.all(employer: current_user.id)
	erb :employees
end

post "/temporary_password" do
	authenticate!
	administrator!
	@id = params['id']
	erb :temporary_password_change
end

post "/change_password_temporary" do
	authenticate!
	administrator!

	if(params['newPassword'])
		user = User.first(id: params['id'])
		if !user.nil?
			user.password = params['newPassword']
			user.flag = 2
			user.save
			flash[:success] = "Successfully changed password! Will need to be changed again upon next login."
		else
			flash[:error] = "Please try again later"
		end

		redirect "/employees"
	end
end


post "/delete_account" do
	authenticate!
	administrator!

	if session[:require_log_in] == true
		redirect "/reenter_password"
	end

	if params['id']
		user = User.get(params['id'].to_i)
	end

	if user
		user.destroy
		flash[:success] = "Employee Deleted"
	else
		flash[:error] = "Employee Not Deleted, please try again"
	end

	redirect "/employees"
end