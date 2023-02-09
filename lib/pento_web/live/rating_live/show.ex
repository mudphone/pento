defmodule PentoWeb.RatingLive.Show do
  use Phoenix.Component
  use Phoenix.HTML

  def stars(assigns) do
    ~H"""
    <div>
      <h4>
        <%= @product.name %>;<br/>
        <%= raw formatted_stars(@rating.stars) %>
      </h4>
    </div>
    """
  end

  defp filled_stars(stars) do
    List.duplicate("&#x2605;", stars)
  end

  defp unfilled_stars(stars) do
    List.duplicate("&#x2606;", 5 - stars)
  end

  defp formatted_stars(stars) do
    stars
    |> filled_stars()
    |> Enum.concat(unfilled_stars(stars))
    |> Enum.join(" ")
  end
end
