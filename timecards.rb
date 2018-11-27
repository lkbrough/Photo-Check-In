require 'data_mapper'

if ENV['DATABASE_URL']
  DataMapper::setup(:default, ENV['DATABASE_URL'] || 'postgres://localhost/timecards')
else
  DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/timecards.db")
end

class TimeCard
    include DataMapper::Resource
    property :id, Serial
    property :user, Integer
    property :complete, Boolean
    property :signIn, DateTime
    property :signOut, DateTime

    def time_signed_in # function to return the length of time in hours that a user was signed in for

    end
end

# Perform basic sanity checks and initialize all relationships
# Call this when you've defined all your models
DataMapper.finalize

# automatically create the post table
TimeCard.auto_upgrade!
