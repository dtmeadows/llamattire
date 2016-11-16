require 'stripe'
require_relative 'stripe_keys'

Stripe.api_key = $PRIVATE_TEST_KEY

tokens = []
10.times do |i|
	begin
		token = Stripe::Token.create(:card => {
	    :number => "4242424242424242",
	    :exp_month => 10,
	    :exp_year => 2017,
	    :cvc => "123"
	  	})
	  	tokens << token[:id]
	  	p "#{token[:object]}#{i+1}:#{token[:id]}"
	rescue Stripe::CardError => e
		body = e.json_body
		err = body[:error]
		puts "Status is: #{e.http_status}"
	  	puts "Type is: #{err[:type]}"
	  	puts "Code is: #{err[:code]}"
	  	getCardInfo()
	end
	
end

