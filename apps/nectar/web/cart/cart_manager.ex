defmodule Nectar.CartManager do
  alias Nectar.Order
  alias Nectar.Variant
  alias Nectar.LineItem
  alias Nectar.Repo

  def count_items_in_cart(%Order{} = order) do
    Enum.reduce(order.line_items, 0, &(&1.quantity + &2))
  end

  def add_to_cart(_, %{"variant_id" => nil}) do
    {:error, %Ecto.Changeset{errors: [variant: "can't be blank"]}}
  end

  def add_to_cart(%Nectar.Order{} = order, %{"variant_id" => variant_id, "quantity" => quantity}) do
    variant = Repo.get!(Variant, variant_id) |> Repo.preload([:product])
    do_add_to_cart(order, variant, quantity)
  end

  def add_to_cart(order_id, %{"variant_id" => variant_id, "quantity" => quantity}) do
    order = Repo.get!(Order, order_id)
    variant = Repo.get!(Variant, variant_id) |> Repo.preload([:product])
    do_add_to_cart(order, variant, quantity)
  end

  defp do_add_to_cart(%Order{} = order, %Variant{} = variant, quantity) do
    find_or_build_line_item(order, variant)
    |> LineItem.quantity_changeset(%{add_quantity: quantity})
    |> Repo.insert_or_update
  end


  defp find_or_build_line_item(order, variant) do
    find_line_item(order, variant) || build_line_item(order, variant)
  end

  defp find_line_item(order, variant) do
    LineItem
    |> LineItem.in_order(order)
    |> LineItem.with_variant(variant)
    |> Repo.one()
  end

  defp build_line_item(%Order{id: order_id} = _order, %Variant{} = variant) do
    variant
    |> Ecto.build_assoc(:line_items)
    |> LineItem.create_changeset(%{order_id: order_id})
  end
end
