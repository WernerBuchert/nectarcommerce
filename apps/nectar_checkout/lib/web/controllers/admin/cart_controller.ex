defmodule Nectar.Admin.CartController do
  use NectarCore.Web, :admin_controller

  plug Guardian.Plug.EnsureAuthenticated, handler: Nectar.Auth.HandleAdminUnauthenticated, key: :admin

  alias Nectar.LineItem
  alias Nectar.ProductForCheckout, as: Product
  alias Nectar.UserForCheckout, as: User

  def new(conn, _params) do
    users = Repo.all(User)
    cart_changeset = Nectar.Order.cart_changeset(%Nectar.Order{}, %{})
    render(conn, "new.html", users: users, cart_changeset: cart_changeset)
  end

  # use guest checkout unless user id provided.
  def create(conn, %{"order" => %{"user_id" => ""}}) do
    order = Nectar.Order.cart_changeset(%Nectar.Order{}, %{}) |> Repo.insert!
    conn
    |> redirect(to: NectarRoutes.admin_cart_path(conn, :edit, order))
  end

  def create(conn, %{"order" => %{"user_id" => user_id}}) do
    order = Nectar.Order.user_cart_changeset(%Nectar.Order{}, %{user_id: user_id}) |> Repo.insert!
    conn
    |> redirect(to: NectarRoutes.admin_cart_path(conn, :edit, order))
  end


  def edit(conn, %{"id" => id}) do
    {:ok, order} = Repo.get!(Nectar.Order, id) |> Nectar.CheckoutManager.back("cart")
    products  =
      Product
      |> Repo.all
      |> Repo.preload([variants: [option_values: :option_type]])

    line_items =
      LineItem
      |> LineItem.in_order(order)
      |> Repo.all
      |> Repo.preload([variant: [:product, [option_values: :option_type]]])

    render(conn, "edit.html", order: order, products: products, line_items: line_items)
  end

end
