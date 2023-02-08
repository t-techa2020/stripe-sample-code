require 'stripe'
require 'sinatra'

# This is your test secret API key.
Stripe.api_key = ENV['STRIPE_TEST_SECRET_KEY']
endpoint_secret = ENV['STRIPE_ENDPOINT_SECRET']

set :static, true
set :port, 4242


YOUR_DOMAIN = 'http://localhost:4242'.freeze

post '/create-checkout-session' do
  content_type 'application/json'

  session = Stripe::Checkout::Session.create(
    {
      line_items: [
        {
          # Provide the exact Price ID (e.g. pr_1234) of the product you want to sell
          price: 'price_1MXaYiKbfbmHq8e4U0bTyCXI',
          quantity: 1,
          adjustable_quantity: {
            enabled: true,
            maximum: 10,
            minimum: 1
          }
        },
        {
          # Provide the exact Price ID (e.g. pr_1234) of the product you want to sell
          price: 'price_1MY3g2KbfbmHq8e4ucHQcJ1k',
          quantity: 1,
          adjustable_quantity: {
            enabled: true,
            maximum: 10
          }
        }
      ],
      mode: 'payment',
      customer_creation: 'always',
      success_url: "#{YOUR_DOMAIN}/success.html?session_id={CHECKOUT_SESSION_ID}",
      cancel_url: "#{YOUR_DOMAIN}/cancel.html?session_id={CHECKOUT_SESSION_ID}"
    })
  redirect session.url, 303
end

get '/order-info' do
  session = Stripe::Checkout::Session.retrieve(params[:session_id])
  customer = Stripe::Customer.retrieve(session.customer)
  line_items = Stripe::Checkout::Session.list_line_items(session.id, { limit: 100 })

  {
    session: session,
    customer: customer,
    line_items: line_items
  }.to_json
end

post '/return-to-checkout' do
  session = Stripe::Checkout::Session.retrieve(params[:session_id])
  redirect session.url, 303
end

post '/webhook' do
  payload = request.body.read
  sig_header = request.env['HTTP_STRIPE_SIGNATURE']
  event = nil

  begin
    event = Stripe::Webhook.construct_event(
      payload, sig_header, endpoint_secret
    )
  rescue JSON::ParserError => e
    # Invalid payload
    status 400
    return
  rescue Stripe::SignatureVerificationError => e
    # Invalid signature
    status 400
    return
  end

  # Handle the event
  case event.type
  when 'checkout.session.completed'
    checkout_session = event.data.object
    create_order(checkout_session)

    if checkout_session.payment_status == 'paid'
      fulfill_order(checkout_session)
    end

    # ... handle other event types
  when 'checkout.session.async_payment_succeeded'
    checkout_session = event.data.object
    fulfill_order(checkout_session)
  when 'checkout.session.async_payment_failed'
    checkout_session = event.data.object
    email_customer_about_failed_payment(checkout_session)
  else
    puts "Unhandled event type: #{event.type}"
  end

  status 200
end

def fulfill_order(checkout_session)
  puts "Fulfilling order for #{checkout_session.inspect}"
  line_items = Stripe::Checkout::Session.list_line_items(
    checkout_session.id, { limit: 100 }
  )
  puts "Line items for order #{line_items.data.inspect}"
end

def create_order(checkout_session)
  puts "Creating order for #{checkout_session.inspect}"
end

def email_customer_about_failed_payment(checkout_session)
  puts "Email customer about failed payment #{checkout_session.inspect}"
end
