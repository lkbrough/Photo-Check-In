require 'data_mapper'

class TimeCard
    include DataMapper::Resource
    property :id, Serial
    property :user_id, Integer
    property :complete, Boolean, :default => false
    property :is_bold, Boolean, :default => false
    property :sign_in, DateTime
    property :sign_out, DateTime
    property :date, Date
end