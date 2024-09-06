defmodule ChallengeTest do
  use ExUnit.Case
  alias Challenge

  setup do
    {:ok, server} = Challenge.start()
    {:ok, server: server}
  end

  describe "create_users/2" do
    test "creates new users with initial balance", %{server: server} do
      Challenge.create_users(server, ["user1", "user2"])

      expected_state = %{
        "user1" => %{currency: "USD", balance: 100_000},
        "user2" => %{currency: "USD", balance: 100_000}
      }

      state = GenServer.call(server, :get_state)

      assert state == expected_state
    end
  end

  describe "win/2" do
    test "processes a win and updates balance", %{server: server} do
      Challenge.create_users(server, ["user1"])

      GenServer.call(server, {:win, %{user: "user1", transaction_uuid: "txn123", amount: 1000}})

      expected_state = %{
        "user1" => %{currency: "USD", balance: 101_000}
      }

      state = GenServer.call(server, :get_state)

      assert state == expected_state
    end
  end

  describe "bet/2 success cases" do
    test "processes a bet and updates balance", %{server: server} do
      Challenge.create_users(server, ["user1"])

      {:ok, response} =
        Challenge.bet(server, %{
          user: "user1",
          transaction_uuid: "txn124",
          amount: 500,
          currency: "USD"
        })

      expected_state = %{
        "user1" => %{currency: "USD", balance: 99_500}
      }

      state = GenServer.call(server, :get_state)

      assert state == expected_state
      assert response == %{status: "RS_OK", balance: 99_500, transaction_uuid: "txn124"}
    end

    test "allows bet when user has exact balance", %{server: server} do
      Challenge.create_users(server, ["user1"])

      {:ok, response} =
        Challenge.bet(server, %{
          user: "user1",
          transaction_uuid: "txn132",
          amount: 100_000,
          currency: "USD"
        })

      expected_state = %{
        "user1" => %{currency: "USD", balance: 0}
      }

      state = GenServer.call(server, :get_state)

      assert state == expected_state

      assert response == %{
               status: "RS_OK",
               balance: 0,
               transaction_uuid: "txn132"
             }
    end
  end

  describe "bet/2 unsuccessfull cases" do
    test "returns an error for insufficient balance", %{server: server} do
      Challenge.create_users(server, ["user1"])

      {:error, response} =
        Challenge.bet(server, %{
          user: "user1",
          transaction_uuid: "txn125",
          amount: 200_000,
          currency: "USD"
        })

      assert response == %{
               status: "RS_ERROR_NOT_ENOUGH_MONEY",
               balance: 100_000,
               transaction_uuid: "txn125"
             }
    end

    test "returns an error for incorrect currency", %{server: server} do
      Challenge.create_users(server, ["user1"])

      {:error, response} =
        Challenge.bet(server, %{
          user: "user1",
          transaction_uuid: "txn126",
          amount: 500,
          currency: "EUR"
        })

      assert response == %{
               status: "RS_ERROR_WRONG_CURRENCY",
               balance: 100_000,
               transaction_uuid: "txn126"
             }
    end

    test "returns an error for non-existent user", %{server: server} do
      {:error, response} =
        Challenge.bet(server, %{
          user: "non_existent_user",
          transaction_uuid: "txn127",
          amount: 500,
          currency: "USD"
        })

      assert response == %{
               status: "RS_ERROR_INVALID_TOKEN",
               transaction_uuid: "txn127"
             }
    end

    test "returns an error for bet with empty user", %{server: server} do
      {:error, response} =
        Challenge.bet(server, %{
          user: "",
          transaction_uuid: "txn131",
          amount: 500,
          currency: "USD"
        })

      assert response == %{
               status: "RS_ERROR_INVALID_TOKEN",
               transaction_uuid: "txn131"
             }
    end

    test "returns an error for a bet of zero amount", %{server: server} do
      Challenge.create_users(server, ["user1"])

      {:error, response} =
        Challenge.bet(server, %{
          user: "user1",
          transaction_uuid: "txn128",
          amount: 0,
          currency: "USD"
        })

      assert response == %{
               status: "RS_ERROR_INVALID_AMOUNT",
               balance: 100_000,
               transaction_uuid: "txn128"
             }
    end

    test "returns an error for negative bet amount", %{server: server} do
      Challenge.create_users(server, ["user1"])

      {:error, response} =
        Challenge.bet(server, %{
          user: "user1",
          transaction_uuid: "txn133",
          amount: -500,
          currency: "USD"
        })

      assert response == %{
               status: "RS_ERROR_INVALID_AMOUNT",
               balance: 100_000,
               transaction_uuid: "txn133"
             }
    end
  end

  describe "bet/2 concurrency/performance" do
    test "handles concurrent bets correctly", %{server: server} do
      Challenge.create_users(server, ["user1"])

      Task.async(fn ->
        Challenge.bet(server, %{
          user: "user1",
          transaction_uuid: "txn129",
          amount: 1000,
          currency: "USD"
        })
      end)

      Task.async(fn ->
        Challenge.bet(server, %{
          user: "user1",
          transaction_uuid: "txn130",
          amount: 500,
          currency: "USD"
        })
      end)

      :timer.sleep(100)

      state = GenServer.call(server, :get_state)

      assert state["user1"].balance == 98_500
    end
  end
end
