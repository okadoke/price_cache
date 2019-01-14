defmodule PriceCache do

  @name __MODULE__
  @crypto_compare_apikey "e654d641178cfe2d09782fa5278adef8ec9192fc30330d4c906ef54af5d49a39"

  def start_link() do
    # First, we should start `inets` application.
    # `httpc` is part of it:
    Application.ensure_all_started(:inets)
    Application.ensure_all_started(:ssl)
    Agent.start_link(fn -> %{} end, name: @name)
  end

  def get_price(pair, max_age) do
    [currency, denomination] = pair |> String.upcase() |> String.split("/")
    get_price(currency, denomination, max_age)
  end

  def get_price(currency, denomination, max_age) do
    Agent.get_and_update(@name, fn prices -> get_and_update(prices, currency, denomination, max_age) end)
  end

  defp get_and_update(prices, currency, denomination, max_age) do
    price_data = Map.get(prices, {currency, denomination})
    if price_data == nil or (max_age != nil and (System.system_time(:second) - price_data.timestamp) < max_age) do
      price = fetch_current_price(currency, denomination)
      prices = Map.put(prices, {currency, denomination}, %{price: price, timestamp: System.system_time(:second)})
      {price, prices}
    else
      {price_data.price, prices}
    end
  end

  # Fetches price of ticker from a third party server
  defp fetch_current_price(currency, denomination) do
    url = 'https://min-api.cryptocompare.com/data/price?fsym=#{currency}&tsyms=#{denomination}&api_key=#{@crypto_compare_apikey}'
    %{^denomination => price} = read_crypto_compare_response(:httpc.request(:get, {url, []}, [], []))
    price
  end

  defp read_crypto_compare_response({:ok, {{'HTTP/1.1', 200, 'OK'}, _headers, body}}) do
    {:ok, map} = Jason.decode(body)
    map
  end

  defp read_crypto_compare_response({:error, resp}) do
    IO.puts(inspect(resp))
    nil
  end
end
