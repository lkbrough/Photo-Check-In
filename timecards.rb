require 'data_mapper'

class TimeCard
    include DataMapper::Resource
    property :id, Serial
    property :user, Integer
    property :complete, Boolean, :default => false
    property :signIn, DateTime
    property :signOut, DateTime

    def time_signed_in # function to return the length of time in hours that a user was signed in for

    end
end
