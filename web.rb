require 'sinatra'
require 'stripe'
require 'sqlite3'
require 'json'
require 'rest-client'
require 'pry'

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
  price = product['amount']
  # create the charge
  begin
    charge = Stripe::Charge.create(
      :amount => price,
      :currency => "usd",
      :source => token,
      :description => customer_email
    )
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

  p scope
  p auth_code


  #creates account with Stripe or returns error to Sinatra 

  begin
    response = RestClient.post 'https://connect.stripe.com/oauth/token', {
      client_secret: $PRIVATE_TEST_KEY,
      code: auth_code, 
      grant_type: 'authorization_code'}
 

    response = JSON.parse(response.to_s)

    db = SQLite3::Database.new("stripe_store.db")
    db.execute("INSERT INTO accounts (
      authorization_code,
      token_type,
      stripe_publishable_key,
      scope,
      livemode,
      stripe_user_id,
      refresh_token,
      access_token) VALUES (?, ?, ?, ?, ?, ?, ?, ?)", [
      auth_code, 
      response['token_type'], 
      response['stripe_publishable_key'], 
      response['scope'],
      response['livemode'].to_s,
      response['stripe_user_id'],
      response['refresh_token'],
      response['access_token']
      ])
    
    puts "Account #{response['stripe_user_id']} created." 

    redirect "/account_confirmation?acct_id=#{response['stripe_user_id']}"

  #error handling for restclient and other errors (not really)
  rescue => e 
    if e.class.to_s == 'RestClient::BadRequest'
      e = JSON.parse(e.response.to_s)
      p e.class
      "#{e['error']}: #{e['error_description']}"
    else
      p e.class
      p e.to_s
      p e.cause 
      p e.message
      p e.backtrace


    end
  end 
end

get '/purchase_confirmation' do
  "Thank you for your purchase."
end

get '/account_confirmation' do 

  #full confirmation page

  db = SQLite3::Database.new("stripe_store.db")
  db.results_as_hash = true
  @account = db.execute("SELECT * from accounts where stripe_user_id = ?", params[:acct_id]).last

  erb :account_confirmation
end




