defmodule PriceCacheTest do
  use ExUnit.Case
  doctest PriceCache

  test "greets the world" do
    assert PriceCache.get_price("BTC/USD")
  end
end
