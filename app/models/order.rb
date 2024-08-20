class Order < ApplicationRecord
  VALID_PHONE_REGEX = Regexp.new(Settings.value.phone_format)
  ORDER_PARAMS = %i(place payment_method user_name user_phone).freeze
  belongs_to :user
  has_many :order_items, dependent: :destroy

  enum status: {
    pending: 0,
    preparing: 1,
    in_transit: 2,
    delivered: 3,
    cancelled: 4
  }, _prefix: true
  validates :total, presence: true,
    numericality: {greater_than_or_equal_to: Settings.value.min_numeric}
  validates :place, presence: true
  validates :user_phone,
            length: {is: Settings.value.phone},
            format: {with: VALID_PHONE_REGEX}
  validates :status, presence: true
  validates :refuse_reason, presence: true, if: ->{status_cancelled?}
  validates :payment_method, presence: true
  scope :by_status, lambda {|status|
    if statuses.keys.include?(status.to_s)
      where(status: statuses[status])
    else
      all
    end
  }

  scope :sorted_by, lambda {|field, direction = :asc|
    order(field => direction)
  }

  scope :recently_updated, ->{order(updated_at: :desc)}

  def cancel_order role:, refuse_reason:
    formatted_reason = case role
                       when :admin
                         I18n.t(
                           "orders.refuse_reason_by_admin",
                           reason: refuse_reason
                         )
                       when :user
                         I18n.t(
                           "orders.refuse_reason_by_user",
                           reason: refuse_reason
                         )
                       else
                         refuse_reason
                       end

    Order.transaction do
      order_items.each do |order_item|
        product = order_item.product
        amount = order_item.quantity
        product.increment(stock_amount: amount, sold_amount: -amount)
      end

      update!(
        status: :cancelled,
        refuse_reason: formatted_reason
      )
    end
  rescue ActiveRecord::RecordInvalid
    error_message = I18n.t("admin.orders.orders_list.update_failed")
    errors.add(:base, error_message)
    false
  end
end
