require 'data_mapper'

class TimeCard
    include DataMapper::Resource
    property :id, Serial
    property :user_id, Integer
    property :employer, Integer
    property :complete, Boolean, :default => false
    property :bold_sign_in, Boolean, :default => false
    property :bold_sign_out, Boolean, :default => false
    property :sign_in, DateTime
    property :sign_out, DateTime
    property :date, Date
end