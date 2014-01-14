json.array!(@phones) do |phone|
  json.extract! phone, :id, :phone_number, :phone_carrier
  json.url phone_url(phone, format: :json)
end
