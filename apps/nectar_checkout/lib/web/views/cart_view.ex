defmodule Nectar.CartView do
  use NectarCore.Web, :view

  def cart_empty?(%Nectar.Order{line_items: []}), do: true
  def cart_empty?(%Nectar.Order{} = _order), do: false

  def render("cart.json",  %{order: order}) do
    %{id: order.id}
  end
end
