require 'sinatra'
require 'stripe'
require 'sqlite3'
require 'json'
require 'rest-client'

require_relative 'stripe_keys'

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

#endpoint for Stripe Connect Oauth
get '/connect' do 
  #gets two params from Stripe OAUTH
  scope = params[:scope]
  auth_code = params[:code]

  #stores params unnecessarily in a db 

  db = SQLite3::Database.new("stripe_store.db")
  db.execute("Insert INTO Accounts (authorization_code) VALUES (?)", [auth_code])
  p scope
  p auth_code 

  #creates account with Stripe 

  response = RestClient.post 'https://connect.stripe.com/oauth/token', {
    client_secret: $PRIVATE_TEST_KEY,
    code: auth_code, 
    grant_type: 'authorization_code'}
  p response.to_s
  "Jen this totally worked."
end

get '/purchase_confirmation' do
  "Thank you for your purchase."
end




