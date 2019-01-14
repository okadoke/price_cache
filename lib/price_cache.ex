defmodule PriceCache do

  @name __MODULE__
  @crypto_compare_apikey "e654d641178cfe2d09782fa5278adef8ec9192fc30330d4c906ef54af5d49a39"
  @max_age 0

  def start_link() do
    # First, we should start `inets` application.
    # `httpc` is part of it:
    Application.ensure_all_started(:inets)
    Application.ensure_all_started(:ssl)
    Agent.start_link(fn -> %{} end, name: @name)
  end

  def get_price(ticker, max_age \\ @max_age)

  def get_price(ticker, max_age) when is_binary(ticker) do
    [currency, denomination] = ticker |> String.upcase() |> String.split("/")
    get_price({currency, denomination}, max_age)
  end

  def get_price(ticker, max_age) when is_tuple(ticker) do
    Agent.get_and_update(@name, fn prices -> get_and_update(prices, ticker, max_age) end)
  end

  defp get_and_update(prices, ticker, max_age) do
    price_data = Map.get(prices, ticker)
    get_and_update(prices, ticker, price_data, is_too_old?(price_data, max_age))
  end

  defp get_and_update(prices, ticker, _price_data,  _is_too_old = true) do
    price = fetch_current_price(ticker)
    prices = Map.put(prices, ticker, %{price: price, timestamp: System.system_time(:second)})
    {price, prices}
  end

  defp get_and_update(prices, _ticker, price_data, _is_too_old) do
    IO.puts("retrieving price from cache")
    {price_data.price, prices}
  end

  defp is_too_old?(price_data, max_age) do
    price_data == nil or (System.system_time(:second) - price_data.timestamp) > max_age
  end

  # Fetches price of ticker from a third party server
  defp fetch_current_price({currency, denomination}) do
    IO.puts("fetching price for #{currency}/#{denomination}")
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
