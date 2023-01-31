defmodule PentoWeb.WrongLive do
  use PentoWeb, :live_view


  def mount(_params, _session, socket) do
    {:ok, assign(socket, score: 0, message: "Guess a number.")}
  end


  def render(assigns) do
    ~H"""
    <h1>Your score: <%= @score %></h1>
    <h2>
      <p>
        It's <%= time() %>
      </p>
      <%= @message %>
    </h2>
    <h2>
      <%= for n <- 1..10 do %>
        <a href="#" phx-click="guess" phx-value-number={n} ><%= n %></a>
      <% end %>
    </h2>
    """
  end


  defp time() do
    DateTime.utc_now |> to_string
  end


  def handle_event("guess", %{"number" => guess}=_data, socket) do
    message = "Your guess: #{guess}. Wrong. Guess again. "
    score = socket.assigns.score - 1
    {
      :noreply,
      assign(
        socket,
        message: message,
        score: score
      )
    }
  end
end
