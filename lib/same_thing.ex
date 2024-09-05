defmodule SameThing do
  use GenServer
  @moduledoc """
  Challenge module to implement the Wallet API functionalities.
  """

 @doc """
  Start a linked and isolated supervision tree and return the root server that
  will handle the requests.
  """
  @spec start :: GenServer.server()
  def start do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @doc """
  Create non-existing users with currency as "USD" and amount as 100_000.

  It must ignore empty binary `""` or if the user already exists.
  """
  @spec create_users(server :: GenServer.server(), users :: [String.t()]) :: :ok
  def create_users(server, users) do
    GenServer.cast(server, {:create_users, users})
  end

  @doc """
  The same behavior is from `POST /transaction/bet` docs.

  The `body` parameter is the "body" from the docs as a map with keys as atoms.
  The result is the "response" from the docs as a map with keys as atoms.
  """
  @spec bet(server :: GenServer.server(), body :: map) :: map
  def bet(server, body) do
    GenServer.call(server, {:bet, body})
  end

  @doc """
  The same behavior is from `POST /transaction/win` docs.

  The `body` parameter is the "body" from the docs as a map with keys as atoms.
  The result is the "response" from the docs as a map with keys as atoms.
  """
  @spec win(server :: GenServer.server(), body :: map) :: map
  def win(server, body) do
    GenServer.call(server, {:win, body})
  end

  @impl true
  def init(_) do
    {:ok, %{}}
  end

  @impl true
  def handle_cast({:create_users, users}, state) do
    new_state = Enum.reduce(users, state, fn user, acc ->
      if user != "" and not Map.has_key?(acc, user) do
        Map.put(acc, user, %{currency: "USD", balance: 100_000})
      else
        acc
      end
    end)

    {:noreply, new_state}
  end

  @impl true
def handle_call({:bet, %{transaction_uuid: transaction_uuid, user: user, amount: amount, currency: currency} = _body}, _from, state) do
  case Map.get(state, user) do
    nil ->
      response = %{
        :status => "RS_ERROR_INVALID_TOKEN",
        :transaction_uuid => transaction_uuid
      }
      {:reply, {:error, response}, state}

    user_data ->
      cond do
        user_data.currency != currency ->
          response = %{
            :status => "RS_ERROR_WRONG_CURRENCY",
            :balance => user_data.balance,
            :transaction_uuid => transaction_uuid
          }
          {:reply, {:error, response}, state}

        user_data.balance < amount ->
          response = %{
            :status => "RS_ERROR_NOT_ENOUGH_MONEY",
            :balance => user_data.balance,
            :transaction_uuid => transaction_uuid
          }
          {:reply, {:error, response}, state}

        true ->
          new_balance = user_data.balance - amount
          new_state = Map.put(state, user, %{user_data | balance: new_balance})

          response = %{
            :status => "RS_OK",
            :balance => new_balance,
            :transaction_uuid => transaction_uuid
          }
          {:reply, {:ok, response}, new_state}
      end
  end
end

@impl true
def handle_call({:win, %{transaction_uuid: transaction_uuid, user: user, amount: amount}}, _from, state) do
  case Map.get(state, user) do
    nil ->
      response = %{
        status: "RS_ERROR_INVALID_TOKEN",
        transaction_uuid: transaction_uuid
      }
      {:reply, response, state}

    user_data ->
      new_balance = user_data.balance + amount
      new_state = Map.put(state, user, %{user_data | balance: new_balance})

      response = %{
        status: "RS_OK",
        balance: new_balance,
        transaction_uuid: transaction_uuid
      }

      {:reply, response, new_state}
  end
end


@impl true
def handle_call(:get_state, _from, state) do
  {:reply, state, state}
end
end
