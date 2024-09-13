class OrderSerializer < ActiveModel::Serializer
  ORDER_PARAMS = %i(place payment_method user_name user_phone).freeze
  attributes :id, :total, :status, :created_at, :updated_at, :paid_at

  has_many :order_items
end
