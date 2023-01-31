defmodule PentoWeb.WrongLive do
  use PentoWeb, :live_view


  def mount(_params, _session, socket) do
    random_number = Enum.random(1..10)
    {:ok, assign(socket, score: 0, message: "Guess a number.", answer: random_number)}
  end


  def render(assigns) do
    ~H"""
    <h1>Your score: <%= @score %></h1>
    <h2>
      <p>
        It's <%= time() %>
        Answer: <%= @answer %>
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
    answer = socket.assigns.answer

    {message, points} = case String.to_integer(guess) do
      ^answer ->
        message = "Your guess: #{guess}. Correct!"
        points = 1
        {message, points}
      _ ->
        message = "Your guess: #{guess}. Wrong. Guess again."
        points = -1
        {message, points}
    end

    score = socket.assigns.score + points
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
