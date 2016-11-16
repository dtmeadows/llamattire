require_relative 'stripe_keys'
require 'sinatra'
require 'stripe'
require 'sqlite3'
require 'json'

Stripe.api_key = $PRIVATE_TEST_KEY

# home page route
get '/' do
  # get list of products -- we'll include these
  # on our store page eventually
  db = SQLite3::Database.new("stripe_store.db")
  db.results_as_hash = true
  @products = db.execute("SELECT * from products")
  erb :index

end

# order submission route
post '/purchase' do
  # put form data into variables
  token = params[:stripeToken]
  product_id = params[:product_id].to_i
  customer_email = params[:email]
  product_id = 1
  # look up price of product
  db = SQLite3::Database.new("stripe_store.db")
  db.results_as_hash = true
  product = db.execute("SELECT * from PRODUCTS where id=?", product_id).last
  p product
  price = product['amount']
  p price 
  # create the charge
  begin
    charge = Stripe::Charge.create(
      :amount => price,
      :currency => "usd",
      :source => token,
      :description => customer_email
    )
    p charge
  rescue Stripe::CardError => e 
    body = e.json_body
    err = body[:error]

    puts "Status is: #{e.http_status}"
    puts "Type is: #{err[:type]}"
    puts "Code is: #{err[:code]}"

  end
  # print the charge to the server console
  p charge[:succeeded]
  if charge[:succeeded]  
    redirect '/purchase_confirmation'
  else 
    "Charge declined"
  end


end

get '/purchase_confirmation' do
  "Thank you for your purchase."
end
