#initial things
require_relative 'stripe_keys'
require 'stripe'
require 'json'
require 'SQLite3'


Stripe.api_key = $PRIVATE_TEST_KEY


#Fetches data from Database and forces it into products
db = SQLite3::Database.new "stripe_store.db"
db.execute("PRAGMA foreign_keys = ON")

products_db = db.execute( "select * from products" ) 
products = Array.new

products_db.each do |prod|
	products << {:id => prod[0], :description => prod[1], :price => prod[2].to_i}
end

#declares coupons, and tax free states

coupons =[
	{:code => "SUMMERSALE", :discount_in_cents => 500},
	{:code => "FLASHSALE", :discount_in_cents => 7002}]

states_tax_free = ["AK", "DE", "MO", "NH", "OR"] 

#FUNCTION LIST
#defines display_products to print out products 
	
def display_products(productarray)
	puts "AVAILABLE PRODUCTS"	
	productarray.each_with_index do |arr,i|
		puts "Product Number:#{i+1} \n #{arr[:description]} -- $#{arr[:price]/100.0}"
	end
end

#defines get_user_choice to display the products, get customer's order and store in user_cart
def get_user_choice(arr_prod_list)
	
	#first, displays the products list
	display_products(arr_prod_list)
	
	#asks for order and loops to fill cart
	puts "What would you like to buy? Enter the product number, followed by [ENTER]. Hit 0 when done."
	user_order=[]
	loop do
		user_input = gets.to_i
		#checks user input for bad values or end
		if user_input < 0 || user_input > arr_prod_list.size
			puts "Bad input. Don't be a troll"
		elsif user_input == 0
			break
		else 
			user_order << user_input
		end
	end
	return user_order
end

#calculates total based on cart and prices
def calculate_total(local_arr_user_cart, local_arr_products)	
	local_user_total = 0
	local_arr_user_cart.each do |i|
		puts "One order of: #{local_arr_products[i-1][:description]} -- $#{local_arr_products[i-1][:price]/100.0}"
		local_user_total += local_arr_products[i-1][:price]
	end
	
	puts "Your subtotal is $#{local_user_total/100.00}!" 
	
	return local_user_total
end

#write purchase info to SQL db

def write_to_purchases(charge_local, user_cart_local, db_local)
	db_local.execute("INSERT INTO purchases (email, created_at, product_id, amount, description, status, transfer) 
            VALUES (?, ?, ?, ?, ?, ?, ?)", ["me@janedoe.com", charge_local[:created], user_cart_local[0], charge_local[:amount], charge_local[:description], charge_local[:status], charge_local[:transfer]])

end


#END FUNCTION LIST 

user_cart = get_user_choice(products)

user_total = calculate_total(user_cart,products)

puts "Would you like to enter a coupon? Hit 'NO' if not."


#checks for coup

user_coupon = gets.chomp.upcase
invalid_coupon = true

if user_coupon == "NO"
	puts "No coupon . Continuing..."
else
	coupons.each do |x|
		if user_coupon == x[:code]
			user_total -= x[:discount_in_cents]
			invalid_coupon = false
			puts "**Coupon applied**"
			puts "New user total: $#{user_total/100.0}"
			break
		end
	end
	if invalid_coupon == true
		puts "Invalid coupon. Please enter the correct coupon."
		user_coupon = gets.chomp.upcase
		coupons.each do |x|
			if user_coupon == x[:code]
				user_total -= x[:discount_in_cents]
				puts "**Coupon applied**"
				puts "New user total: $#{user_total/100.0}"
				break
			end
		end
	end
end

#asks for state and computes sales tax 

puts "For tax purposes, please enter your state (AL or NY for example)."



while true
	user_state = gets.chomp
	break if user_state.size == 2
	puts "Put in a real state, ya chump."
end
	


sales_tax = rand(5.0..9.0).round(2)
sales_tax_owed = true

states_tax_free.each do |x|
	if user_state == x 
		sales_tax_owed = false
		break
	end
end

if sales_tax_owed == true
	puts "Sales Tax for your purchase has been determined to be #{sales_tax}%"
		user_total -= ((sales_tax/100) * user_total)
else
	puts "No sales tax owed, you lucky dog."
end

puts "Your final total is $#{(user_total/100).round(2)}."

#defines getCardInfo which gets the payment information from the customer and returns it in a hash 

def getCardInfo()
	user_card = {}
	#asks customer for payment info
	puts "Please input your payment information as follows (ignore that PCI, boy):"
	puts "Card number:"
	
	while true 
		user_PAN_input = gets.chomp
		if user_PAN_input.size == 16
			user_card[:number] = user_PAN_input.to_i
			break
		end
		puts "You need all 16 digits, buddy."
	end
	
	user_card[:last4] = user_card[:number].to_s[-4..-1]
	
	puts "Expiration month (MM):"
	while true 
		user_exp_month_input = gets.chomp
		if user_exp_month_input.size == 2
			user_card[:exp_month] = user_exp_month_input.to_i
			break
		end
		puts "Don't be a troll."
	end
	
	puts "Expiration year:"
		while true 
			user_exp_year_input = gets.chomp
			if user_exp_year_input.size == 4
				user_card[:exp_year] = user_exp_year_input.to_i
				break
			end
			puts "Stop being a troll."
		end
	puts "CVC:"
		while true 
			user_cvc_input = gets.chomp
			if user_cvc_input.size == 3
				user_card[:cvc] = user_cvc_input.to_i
				break
			end
			puts "Cut it with the tomfoolery."
		end
	return user_card
end




payment_card = getCardInfo()

#Ask customer if their ready to make payment. Then, charge them. 

puts "Ready to finalize your purchase of #{user_total}?"
gets.chomp
sleep 0.5
puts "whatever! Doing it anyways."

#Create token with payment_card

begin
	token = Stripe::Token.create(:card => payment_card)
rescue Stripe::CardError => e
	body = e.json_body
	err = body[:error]
	puts "Status is: #{e.http_status}"
  	puts "Type is: #{err[:type]}"
  	puts "Code is: #{err[:code]}"
  	getCardInfo()
end

puts "Token to be charged is:" + token["id"]

#Charge token and display result

begin 
	charge = Stripe::Charge.create(
		:amount => user_total.to_i, 
		:currency => "usd",
		:source => token["id"],
		:description => "This charge came from Ruby!"
	)
	#call log to purchases db 
	write_to_purchases(charge, user_cart, db)
rescue Stripe::CardError => e
	body = e.json_body
	err = body[:error]
	puts "Status is: #{e.http_status}"
  	puts "Type is: #{err[:type]}"
  	puts "Code is: #{err[:code]}"
  	getCardInfo()
end
p charge.status

