defmodule SameThingTest do
  use ExUnit.Case
  alias SameThing

  setup do
    {:ok, server} = SameThing.start()
    {:ok, server: server}
  end

  test "create_users/2 creates new users with initial balance", %{server: server} do
    SameThing.create_users(server, ["user1", "user2"])

    expected_state = %{
      "user1" => %{currency: "USD", balance: 100_000},
      "user2" => %{currency: "USD", balance: 100_000}
    }

    state = GenServer.call(server, :get_state)

    assert state == expected_state
  end

  test "win/2 processes a win and updates balance", %{server: server} do
    SameThing.create_users(server, ["user1"])

    GenServer.call(server, {:win, %{user: "user1", transaction_uuid: "txn123", amount: 1000}})

    expected_state = %{
      "user1" => %{currency: "USD", balance: 101_000}
    }

    state = GenServer.call(server, :get_state)

    assert state == expected_state
  end
end
