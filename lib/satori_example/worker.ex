defmodule SatoriExample.Worker do
  use GenServer
  require Logger
  alias Satori.PDU

  @publish_channel "rosetta-home"
  @subscribe_channel "transportation"
  @publish_id "pubid"

  def start_link do
    GenServer.start_link(__MODULE__, :ok, [])
  end

  def init(:ok) do
    Satori.register(%PDU.Result{action: PDU.Data.action(), channel: @subscribe_channel})
    Satori.register(%PDU.Result{id: @publish_id, action: PDU.PublishOK.action(), channel: @publish_channel})

    url = "#{Application.get_env(:satori, :url)}?appkey=#{Application.get_env(:satori, :app_key)}"
    Logger.info "URL: #{url}"
    {:ok, pub} = Satori.Publisher.start_link(url, @publish_channel, Application.get_env(:satori, :role_secret))
    {:ok, sub} = Satori.Subscription.start_link(url, @subscribe_channel)
    Process.send_after(self(), :publish, 0)
    {:ok, %{pub: pub, sub: sub}}
  end

  def handle_info(%PDU{body: %PDU.Data{channel: @subscribe_channel}} = data, state) do
    Logger.info "Subscription Data: #{inspect data}"
    {:noreply, state}
  end

  def handle_info(%PDU{id: @publish_id, body: %PDU.PublishOK{}} = data, state) do
    Logger.info "Publish Data: #{inspect data}"
    {:noreply, state}
  end

  def handle_info(:publish, state) do
    Satori.Publisher.publish(state.pub, %{key: "ieq.co2", value: 501.22, tags: %{node: 2}}, @publish_id)
    Process.send_after(self(), :publish, 5_000)
    {:noreply, state}
  end

  def handle_info(other, state) do
    Logger.info "unknown: #{inspect other}"
    {:noreply, state}
  end

end
