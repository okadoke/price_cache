defmodule PriceCache.Application do
  use Application

  def start(_type, _args) do

    import Supervisor.Spec

    children = [
      worker(PriceCache, [])
    ]
    options = [
      name: PriceCache.Supervisor,
      strategy: :one_for_one,
    ]
    Supervisor.start_link(children, options)
  end
end
