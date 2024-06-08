# FoodVotingAI

## Description
This application allows you to create a voting room with your friends, it connects with an OpenAI assistant that looks at a CSV of all food trucks in Sao Francisco
with that, you can ask for different types of food trucks, select what you guys want to vote for and create a voting room.
When all participants finish voting the application is going to return the most voted options with a Google Maps link showing how to find the food truck. Hope you like it!

## Application Screenshots
<img width="1385" alt="Home Page" src="https://github.com/BrunoRibeiro147/food_voting/assets/43683632/65971076-15df-4d52-b091-486ec9d6237c">

<img width="1303" alt="Open Voting Room Page" src="https://github.com/BrunoRibeiro147/food_voting/assets/43683632/5e551d5f-8a36-4737-89dc-405297f2aff5">

<img width="1152" alt="Voting Room Page" src="https://github.com/BrunoRibeiro147/food_voting/assets/43683632/01dc1329-64cd-4980-9b0b-eb64c16f9a0b">

<img width="701" alt="Finished Voting Room Page" src="https://github.com/BrunoRibeiro147/food_voting/assets/43683632/566fc345-f3a3-4a63-ad3d-ad2482902c99">

## To start your Phoenix server:

  * Run `mix setup` to install and setup dependencies
  * Run `source .env` to evaluate the enviroment variables
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Technologies Used

- Phoenix
- Phoenix LiveView
- Phoenix PubSub
- Phoenix Presence
- Elixir
- Postgres
- GenServers (OTP)
- Tesla (HTTP Client)
