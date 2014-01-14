class MessagesController < ApplicationController
  def create
    @message = Message.new(message_params)
    @message.source = 'local'
    @message.phone = Phone.find(params[:phone_id])
    @message.save

    url = "http://localhost:3000/api/v2/sms/open_market/sms" 
    RestClient.post(url, xml: receive_sms_xml(@message.phone.phone_number, @message.phone.phone_carrier, @message.content).to_xml)

    redirect_to @message.phone
  end

  private

  def message_params
    params.require(:message).permit(:content)
  end

  def receive_sms_xml(source_phone_number, source_phone_carrier, text)
    data = text.gsub(/(.)/) { "%2.2x" % $1.ord }
    puts "text = #{text}"
    puts "data = #{data}"
    Nokogiri::XML::Builder.new do |xml|
      xml.request       version: '3.0', protocol: 'wmp', type: 'deliver' do
        xml.user        agent: 'XML/SMS/1.0.0'
        xml.account     id: '000-000-108-11751'
        xml.destination ton: '3', address: '847411'
        xml.source      ton: '0', address: source_phone_number, carrier: source_phone_carrier 
        xml.message     udhi: 'false', data: data
      end
    end
  end
end
