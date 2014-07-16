# <?xml version="1.0"?>
#   <response version="3.0" protocol="wmp" type="submit">
#   <error code="2" description="Message successfully queued." resolution=""/>
#   <ticket id="4413W-1125E-1417T-24J4E" transmit="1" 
#           price="0.072" total="0.072" fee="0.072" pin="+16123816295"/>
# </response>
 
class SmsController < ApplicationController
  skip_before_filter :verify_authenticity_token
  respond_to :xml

  def create
    puts "**** in create *************************"
    source_phone_number = params[:request][:source][:address]
    dest_phone_number   = params[:request][:destination][:address]
    dest_carrier        = params[:request][:destination][:carrier]
    message = params[:request][:message][:text]

    phone = Phone.find_by_phone_number(dest_phone_number)
    if !phone
      phone = Phone.create(phone_number: dest_phone_number, phone_carrier: dest_carrier)
    end
    message = Message.new(content: message, source: 'remote')
    message.save
    phone.messages << message

    puts "**** should raise exception #{message.id}" if message.id % 2 == 0
    raise Exception if message.id % 2 == 0

    xml = Nokogiri::XML::Builder.new do |xml|
            xml.response      version: '3.0', protocol: 'wmp', type: 'submit' do
              xml.error       code: '2', description: 'Message successfully queued.'
              xml.ticket      id: '123456'
            end
          end

    respond_to do |format|
      format.xml { render xml: xml }
    end
  end
end
