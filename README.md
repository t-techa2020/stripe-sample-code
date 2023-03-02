[https://stripe.com/docs/videos/checkout-101](https://stripe.com/docs/videos/checkout-101)

# Accept a Payment with Stripe Checkout

Stripe Checkout is the fastest way to get started with payments. Included are some basic build and run scripts you can use to start up the application.

## Running the sample

1. Build the server

~~~
bundle install
~~~

2. Run the server

~~~
ruby server.rb 
~~~

3. Forward events to local machine

~~~
stripe listen --forward-to localhost:4242/webhook
~~~

4. Go to [http://localhost:4242/checkout.html](http://localhost:4242/checkout.html)

or

4. Use the CLI to trigger events

~~~
stripe trigger payment_intent.succeeded
~~~
