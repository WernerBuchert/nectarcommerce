defmodule Nectar.Plugs.Cart do
  import Plug.Conn

  alias Nectar.Repo
  alias Nectar.UserForCheckout, as: User
  alias Nectar.Order

  def init(_opts) do
  end

  def call(conn, _) do
    # Hack: Guardian returns User but we need UserForCheckout
    current_user  =
      case Guardian.Plug.current_resource(conn) do
        nil  -> nil
        user -> %User{id: user.id}
      end
    current_order = fetch_current_order_from_session(conn)
    assign_cart_to_session_and_user(conn, current_user, current_order)
  end

  # conditional clauses for setting the current order

  # guest visiting for for first time
  defp assign_cart_to_session_and_user(conn, nil, nil) do
    current_order = create_guest_order
    conn
    |> assign(:current_order, current_order)
    |> put_session(:current_order, current_order.id)
  end

  # guest continuing on site, we already have an order from session
  defp assign_cart_to_session_and_user(conn, nil, order) do
    conn
    |> assign(:current_order, order)
  end

  # guest logged in, link the cart to the user
  defp assign_cart_to_session_and_user(conn, user, %Nectar.Order{user_id: nil} = order) do
    # load previous order only if cart in current session is empty
    previous_order = if Order.cart_empty? order do
      Order.current_order(user)
    else
      nil
    end
    # Use the previous order only assign the blank cart if it is nil.
    updated_order = previous_order || Nectar.Order.link_to_user_changeset(order, %{user_id: user.id}) |> Nectar.Repo.update!
    conn
    |> assign(:current_order, updated_order)
  end

  # logged in user visiting after some time or just completed an order
  defp assign_cart_to_session_and_user(conn, user, nil) do
    order = load_or_create_order_for_user(user)
    conn
    |> assign(:current_order, order)
    |> put_session(:current_order, order.id)
  end

  # logged in user continuing with session
  defp assign_cart_to_session_and_user(conn, _user, order) do
    conn
    |> assign(:current_order, order)
  end

  defp load_or_create_order_for_user(current_user) do
    Order.current_order(current_user) || (Order.user_cart_changeset(%Order{}, %{user_id: current_user.id}) |> Repo.insert!)
  end

  defp create_guest_order do
    Order.cart_changeset(%Order{}, %{}) |> Repo.insert!
  end

  # if the order in session has been confirmed, we need to create an empty cart for
  # checkout so return nil.
  defp fetch_current_order_from_session(conn) do
    case Repo.get(Order, get_session(conn, :current_order) || 0) do
      nil -> nil
      %Order{state: "confirmation"} -> nil
      order -> order
    end
  end

end
