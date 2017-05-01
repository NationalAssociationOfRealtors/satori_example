defmodule SatoriExample.Worker do
  use GenServer
  require Logger
  alias Satori.PDU

  @publish_channel "rosetta-home"
  @subscribe_channel "transportation"

  def start_link do
    GenServer.start_link(__MODULE__, :ok, [])
  end

  def init(:ok) do
    Satori.register(%PDU.Data{channel: @subscribe_channel})
    Satori.register(%PDU.Publish{channel: @publish_channel})

    url = "#{Application.get_env(:satori, :url)}?appkey=#{Application.get_env(:satori, :app_key)}"
    Logger.info "URL: #{url}"
    {:ok, pub} = Satori.Publisher.start_link(url, @publish_channel, Application.get_env(:satori, :role_secret))
    {:ok, sub} = Satori.Subscription.start_link(url, "transportation")
    Process.send_after(self(), :publish, 0)
    {:ok, %{pub: pub, sub: sub}}
  end

  def handle_info(%PDU.Data{channel: @subscribe_channel} = data, state) do
    Logger.info "Subscription Data: #{inspect data}"
    {:noreply, state}
  end

  def handle_info(%PDU.Publish{channel: @publish_channel} = data, state) do
    Logger.info "Publish Data: #{inspect data}"
    {:noreply, state}
  end

  def handle_info(:publish, state) do
    Satori.Publisher.publish(state.pub, %{key: "ieq.co2", value: 501.22, tags: %{node: 2}})
    Process.send_after(self(), :publish, 5_000)
    {:noreply, state}
  end

  def handle_info(other, state) do
    Logger.info "unknown: #{inspect other}"
    {:noreply, state}
  end

end
