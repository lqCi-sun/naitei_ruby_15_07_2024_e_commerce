class OrderItemSerializer < ActiveModel::Serializer
  attributes :id, :product_id, :quantity, :price, :total_price

  belongs_to :product

  def total_price
    object.quantity * object.price
  end
end
