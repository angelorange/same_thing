# Challenge

## What the challenge is about

#### This project is an implementation of an API for managing a Wallet. The main objective is to enable the creation of users and the execution of simulated financial transactions. It is built using Elixir and GenServer to manage the state of the application in a concurrent and scalable way.

* As a developer at Hub88, I'll be working with Hub88 APIs, including the "Game Providers APIs" and the "Operators APIs." 

* An "Operator" is responsible for implementing the API as defined by the Operator Documentation to manage requests received from Game Providers via Hub88.

What operators are about: https://hub88.io/docs/operator.


## How to test manually:
- Open the iex:
```
iex -S mix
```
- Start the genserver:
````
{:ok, server} = Challenge.start()
````
- Create a user:
````
Challenge.create_users(server, ["user1", "user2"])
````
- If you want to check the Genserver actual state:
````
GenServer.call(server, :get_state)
````
- To test the function bet/2:
`````
{:ok, response} = Challenge.bet(server, %{
  user: "user1",
  transaction_uuid: "txn124",
  amount: 500,
  currency: "USD"
})
`````
- Verify the response and the bet state:
`````
IO.inspect(response)

state = GenServer.call(server, :get_state)

IO.inspect(state)

`````

- Make a win:
`````
Challenge.win(server, %{
  user: "user1",
  transaction_uuid: "txn123",
  amount: 1000
})

`````

- Verify the response and win state:
`````
IO.inspect(response)

state = GenServer.call(server, :get_state)

IO.inspect(state)

`````




