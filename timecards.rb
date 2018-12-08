require 'data_mapper'

class TimeCard
    include DataMapper::Resource
    property :id, Serial
    property :user_id, Integer
    property :complete, Boolean, :default => false
    property :sign_in, DateTime
    property :sign_out, DateTime

    def time_signed_in # function to return the length of time in hours that a user was signed in for
    	return (self.signIn.to_time - self.signOut.to_time) / 3600
    end

end
