class Phone < ActiveRecord::Base
  has_many :messages
end
