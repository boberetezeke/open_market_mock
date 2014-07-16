class Phone < ActiveRecord::Base
  validates :phone_number, presence: true, format: {with: /\A1\d{10,10}\z/, message: 'must start with a 1 and have 11 digits'}
  validates :phone_carrier, presence: true, format: {with: /\A\d\d\z/, message: 'must be two digits'}

  has_many :messages
end
