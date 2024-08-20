module OrdersHelper
  def calculate_item_total cart
    product = Product.find_by id: cart.product_id
    cart.quantity * product.price
  end

  def calculate_total_amount order_items_ids
    order_items_ids.reduce(0) do |total_amount, id|
      cart = Cart.find_by(id:)
      total_amount + calculate_item_total(cart)
    end
  end

  def status_name status
    t "orders.statuses.#{status}"
  end

  def format_price price
    number_with_delimiter price, unit: "đ"
  end

  def orders_path_for_current_role sort_by
    if current_user.role_admin?
      admin_orders_path sort_by:
    else
      orders_path sort_by:
    end
  end

  def orders_sort_path sort_by, status
    if current_user.role_admin?
      admin_orders_path(sort_by:, status:)
    else
      orders_path(sort_by:, status:)
    end
  end

  def display_action_column? orders, current_user
    current_user.role_admin? && orders.any? do |order|
      %w(preparing in_transit).include? order.status.to_sym
    end ||
      orders.any?{|order| order.status.to_sym == :pending}
  end
end
