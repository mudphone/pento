defmodule PentoWeb.ProductLive.FormComponent do
  use PentoWeb, :live_component

  alias Pento.Catalog

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage product records in your database.</:subtitle>
      </.header>

      <.simple_form
        :let={f}
        for={@changeset}
        id="product-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={{f, :name}} type="text" label="Name" />
        <.input field={{f, :description}} type="text" label="Description" />
        <.input field={{f, :unit_price}} type="number" label="Unit price" step="any" />
        <.input field={{f, :sku}} type="number" label="Sku" />

        <section phx-drop-target={ @uploads.image.ref }>
          <.live_file_input upload={@uploads.image}/>
        </section>

        <p>entries</p>
        <%= for entry <- @uploads.image.entries do %>
          <p><%= entry.client_name %></p>
          <p>
            <%= entry.client_name %> - <%= entry.progress %>%
            <span class="alert-danger"><%= upload_image_error(@uploads, entry) %></span>
            <button phx-target="{@myself}"
                    phx-click="cancel-upload"
                    phx-value-ref="{entry.ref}">cancel</button>
          </p>
          <.live_img_preview entry={entry} width="75" />
        <% end %>

        <p class="alert alert-info" role="alert"
           phx-click="lv:clear-flash"
           phx-value-key="info">
          <%= live_flash(@flash, :info) %>
        </p>

        <:actions>
          <.button phx-disable-with="Saving...">Save Product</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{product: product} = assigns, socket) do
    changeset = Catalog.change_product(product)
    Process.sleep(250)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)
     |> allow_upload(:image,
       accept: ~w(.jpg .jpeg .png),
       max_entries: 1,
       max_file_size: 9_000_000,
       auto_upload: true,
       progress: &handle_progress/3
      )}
  end

  defp upload_static_file(path, socket) do
    # Plug in your production image file persistence implementation here!
    dest = Path.join("priv/static/images", Path.basename(path))
    File.cp!(path, dest)
    {:ok, static_path(socket, "/images/#{Path.basename(dest)}")}
  end

  defp handle_progress(:image, entry, socket) do
    :timer.sleep(200)
    if entry.done? do
      path = consume_uploaded_entry(socket, entry, fn %{path: path_arg} ->
        {:ok, _path} = upload_static_file(path_arg, socket)
      end)
      {:noreply,
       socket
       |> put_flash(:info, "file #{entry.client_name} uploaded")
       |> assign(:image_upload, path)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("validate", %{"product" => product_params}, socket) do
    changeset =
      socket.assigns.product
      |> Catalog.change_product(product_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"product" => product_params}, socket) do
    save_product(socket, socket.assigns.action, product_params)
  end

  defp save_product(socket, :edit, params) do
    result = Catalog.update_product(socket.assigns.product, product_params(socket, params))
    case result do
      {:ok, _product} ->
        {:noreply,
         socket
         |> put_flash(:info, "Product updated successfully")
         |> push_navigate(to: socket.assigns.navigate)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_product(socket, :new, params) do
    case Catalog.create_product(product_params(socket, params)) do
      {:ok, _product} ->
        {:noreply,
         socket
         |> put_flash(:info, "Product created successfully")
         |> push_navigate(to: socket.assigns.navigate)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def product_params(socket, params) do
    Map.put(params, "image_upload", socket.assigns.image_upload)
  end

  def upload_image_error(%{image: %{errors: errors}}, entry) when length(errors) > 0 do
    {_, msg} =
      Enum.find(errors, fn {ref, _} ->
        ref == entry.ref || ref == entry.upload_ref
      end)

    upload_error_msg(msg)
  end

  def upload_image_error(_, _), do: ""

  defp upload_error_msg(:not_accepted) do
    "Invalid file type"
  end

  defp upload_error_msg(:too_many_files) do
    "Too many files"
  end

  defp upload_error_msg(:too_large) do
    "File exceeds max size"
  end
end
