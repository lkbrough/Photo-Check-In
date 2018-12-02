require 'data_mapper'
require_relative "timecards.rb" # metagem, requires common plugins too.

# need install dm-sqlite-adapter
# if on heroku, use Postgres database
# if not use sqlite3 database I gave you
if ENV['DATABASE_URL']
  DataMapper::setup(:default, ENV['DATABASE_URL'] || 'postgres://localhost/mydb')
else
  DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/app.db")
end

class User
    include DataMapper::Resource
    property :id, Serial
    property :email, String
    property :password, String
    property :administrator, Boolean, :default => false
    property :employer, Integer
    property :name, String
    property :flag, Integer, :default => 0

    def login(password)
    	return self.password == password
    end

    def cleared
        return self.flag == 0
    end

    def send_picture_to_administrator
        return self.flag == 1
    end

    def change_password
        return self.flag == 2
    end

    def send_pic_and_change_password
        return self.flag == 3
    end

end

# Perform basic sanity checks and initialize all relationships
# Call this when you've defined all your models
DataMapper.finalize

# automatically create the post table
User.auto_upgrade!
TimeCard.auto_upgrade!

