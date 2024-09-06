defmodule HandleState do
  def handle_bet(state, user, amount, currency, transaction_uuid) do
    case Map.get(state, user) do
      nil ->
        response = %{
          :status => "RS_ERROR_INVALID_TOKEN",
          :transaction_uuid => transaction_uuid
        }

        {:reply, {:error, response}, state}

      user_data ->
        cond do
          amount <= 0 ->
            response = %{
              :status => "RS_ERROR_INVALID_AMOUNT",
              :balance => user_data.balance,
              :transaction_uuid => transaction_uuid
            }

            {:reply, {:error, response}, state}

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

  def handle_win(state, user, amount, transaction_uuid) do
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
end
