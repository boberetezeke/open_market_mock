class MessagesController < ApplicationController
  def create
    @message = Message.new(message_params)
    @message.source = 'local'
    @message.phone = Phone.find(params[:phone_id])
    @message.save

    if params[:image].present? 
      #url = "http://localhost:3000/api/v2/sms/open_market/mms" 
      url = "http://localhost:3000/cosoa/services/mmsMessagingService"
      data = receive_mms_data(@message.phone.phone_number, @message.phone.phone_carrier, @message.content, params[:image])
      #puts "data = #{data}"
      begin 
        RestClient.post(url, data, "Content-Type" => "multipart/related; start=\"soap-start\"; type=\"text/xml\"; boundary=\"----=_Part_400406_2002992991.1390260809098\"", 'X-OpenMarket-Carrier-Id' => @message.phone.phone_carrier)
        #RestClient.post(url, file: File.new("#{Rails.root}/flower-tiny.jpg"))
      rescue Exception => e
        puts "EXCEPTION: #{e}"
        #puts "backtrace: " + e.backtrace.join("\n")
      end
    else
      #url = "https://stage.citizenobserver.com/api/v2/sms/open_market/sms" 
      url = "http://localhost:3000/api/v2/sms/open_market/sms" 
      #url = "http://localhost:3000/cosoa/app/ezsmsreceive.jsp"
      #url = "https://www.citizenobserver.com/cosoa/app/ezsmsreceive.jsp"
puts "****** @message.content = #{@message.content}"
      xml = receive_sms_xml(@message.phone.phone_number, @message.phone.phone_carrier, @message.content).to_xml
puts "****** @message.content(xml) = #{xml}"
      #RestClient::Request.execute(url: url, method: :post, verify_ssl: false)
      RestClient.post(url, xml: xml)
    end

    redirect_to @message.phone
  end

  private

  def message_params
    params.require(:message).permit(:content)
  end

  def receive_sms_xml(source_phone_number, source_phone_carrier, text)
    data = text.gsub(/(.)/m) { "%2.2x" % $1.ord }
    #data = "050003ce0401737470343131205020494e464f20202020696e666f726d6174696f6e206f6e2061207375737065637420696e766f6c76656420696e206120686f6d6520696e766173696f6e2079657374657264617920617420333530332062656c6c65207465727261636520492063757272656e746c79205345454e2074686520737573706563742077697468206b6e6f776e2032206c6170746f7020616e"
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

  # <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
  # <ns1:Envelope xmlns:ns1="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ns3="http://www.3gpp.org/ftp/Specs/archive/23_series/23.140/schema/REL-6-MM7-1-4">
  #   <ns1:Header>
  #     <ns3:TransactionID ns1:mustUnderstand="1">338841079632240640</ns3:TransactionID>
  #   </ns1:Header>
  #   <ns1:Body>
  #     <ns3:DeliverReq>
  #       <ns3:MM7Version>6.8.0</ns3:MM7Version>
  #       <ns3:LinkedID>338841079632240640</ns3:LinkedID>
  #       <ns3:Sender>
  #         <ns3:Number>16123816295</ns3:Number>
  #       </ns3:Sender>
  #       <ns3:Recipients>
  #         <ns3:To>
  #           <ns3:Number displayOnly="false">10958</ns3:Number>
  #         </ns3:To>
  #       </ns3:Recipients>
  #       <ns3:TimeStamp>2014-01-20T23:33:28.670Z</ns3:TimeStamp>
  #       <ns3:Priority>Normal</ns3:Priority>
  #       <ns3:Content href="cid:default.cid" allowAdaptations="true"/>
  #     </ns3:DeliverReq>
  #   </ns1:Body>
  # </ns1:Envelope>

  SOAP_ENVELOPE_URI = "http://schemas.xmlsoap.org/soap/envelope/"
  MMS_URI = "http://www.3gpp.org/ftp/Specs/archive/23_series/23.140/schema/REL-6-MM7-1-4"
  def receive_mms_xml(source_phone_number, source_phone_carrier)
    transaction_id = "20999"
    Nokogiri::XML::Builder.new do |xml|
      xml.Envelope("xmlns:ns1" => SOAP_ENVELOPE_URI, "xmlns:ns3" => MMS_URI) do
        xml.parent.namespace = xml.parent.namespace_definitions.first; 
        xml['ns1'].Header do
          xml['ns3'].TransactionID(transaction_id, 
                            'xmlns' => 'http://www.3gpp.org/ftp/Specs/archive/23_series/23.140/schema/REL-6-MM7-1-4', 
                            'ns1:mustUnderstand' =>'1')
        end
        xml['ns1'].Body do
          xml['ns3'].DeliveryReq do
            xml.MM7Version '6.8.0'
            xml.LinkedID '338841079632240640'
            xml.Sender do
              xml.Number source_phone_number
            end
            xml.Recipients do
              xml.To do
                xml.ShortCode '11234567890'
              end
            end
            xml.TimeStamp '2014-01-20T23:33:28.670Z'
            xml.Priority 'Normal'
            xml.Content(href: 'cid:default.cid', allowAdaptations: 'true')
          end
        end
      end
    end
  end

  def receive_mms_data(source_phone_number, source_phone_carrier, message_text, image_name)
    xml = receive_mms_xml(source_phone_number, source_phone_carrier).to_xml
    puts("xml = #{xml}")
    "------=_Part_400406_2002992991.1390260809098\r\n" +
    "Content-Type: text/xml\r\n" + 
    "Content-ID: <soap-start>\r\n" + 
    "\r\n" +
    xml + "\r\n" +
    "------=_Part_400406_2002992991.1390260809098\r\n" + 
    "Content-Type: multipart/mixed; boundary=\"----=_Part_400407_349549365.1390260809098\"\r\n" +
    "Content-ID: <default.cid>\r\n" +
    "\r\n" + 
    "------=_Part_400407_349549365.1390260809098\r\n" +
    "Content-Type: text/plain\r\n" + 
    "Content-Transfer-Encoding: binary\r\n" +
    "Content-ID: text_0.txt\r\n" +
    "\r\n" + 
    message_text +
    "\r\n" + 
    "------=_Part_400407_349549365.1390260809098\r\n" +
    "Content-Type: #{(image_name =~ /mov$/) ? 'video/quicktime' : 'image/jpeg'}\r\n" +
    "Content-Transfer-Encoding: binary\r\n" + 
    "Content-ID: IMG_7243.jpg\r\n" +
    "\r\n" + 
    File.read("#{Rails.root}/#{image_name}", encoding: 'ascii-8bit') +
    "\r\n" + 
    "------=_Part_400407_349549365.1390260809098\r\n" +
    "\r\n" + 
    "------=_Part_400406_2002992991.1390260809098\r\n"
  end
end
