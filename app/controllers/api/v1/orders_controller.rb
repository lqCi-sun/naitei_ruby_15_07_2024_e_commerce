class Api::V1::OrdersController < ApplicationController
  skip_before_action :verify_authenticity_token,
                     only: %i(create update destroy)
  before_action :set_order, only: %i(show update destroy)

  def index
    @orders = fetch_orders
    @orders = @orders.sorted_by(params[:sort_by], params[:direction])

    render json: @orders, each_serializer: OrderSerializer
  end

  def show
    render json: @order, serializer: OrderSerializer
  end

  def create
    @order = last_user.orders.new(order_params)
    @order_items_ids = params[:order_items_ids] || []
    if params[:order_items_ids]
      @order.total = calculate_total_amount(params[:order_items_ids])
    end

    if @order.save
      add_order_items
      handle_successful_order
      render json: @order, serializer: OrderSerializer, status: :created
    else
      render json: {
        errors: @order.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def update
    if @order.status_pending? && params[:status].to_sym == :cancelled
      if cancel_order
        render json: @order, status: :ok
      else
        render json: {error: t("admin.orders.orders_list.update_failed")},
               status: :unprocessable_entity
      end
    else
      render json: {error: t("admin.orders.orders_list.update_failed")},
             status: :unprocessable_entity
    end
  end

  def destroy
    @order.destroy
    head :no_content
  end

  private

  def set_order
    @order = Order.find_by(id: params[:id])
    return if @order

    render json: {error: t("orders.not_found")}, status: :not_found
  end

  def order_params
    params.require(:order).permit Order::ORDER_PARAMS
  end

  def calculate_total_amount order_items_ids
    OrderItem.where(id: order_items_ids).sum do |item|
      item.quantity * item.price
    end
  end

  def add_order_items
    @order_items_ids.each do |id|
      cart = Cart.find_by(id:)
      product = Product.find_by(id: cart&.product_id)

      if cart.blank? || product.blank?
        render json: {error: t("flash.not_found_product")}, status: :not_found
        next
      end

      @order.order_items.build(
        product_id: product.id,
        quantity: cart.quantity,
        price: product.price
      )
    end
  end

  def handle_successful_order
    UpdateProductStockJob.perform_later(@order.order_items.as_json(
                                          only: %i(product_id quantity)
                                        ))
    @order.update(paid_at: Time.current)
    ClearCartJob.perform_later(@order_items_ids)
    cookies.delete(:cartitemids)
    cookies.delete(:total)
  end

  def update_status new_status
    if @order.status_pending? && new_status.to_sym == :cancelled
      @order.update(status: :cancelled)
    else
      false
    end
  end

  def fetch_orders
    user = last_user
    if status_valid?
      user.orders.by_status(params[:status].to_sym)
    else
      user.orders
    end
  end

  def last_user
    User.order(created_at: :desc).first
  end

  def status_valid?
    params[:status].present? && Order.statuses.key?(params[:status].to_sym)
  end

  def cancel_order
    @order.cancel_order(role: :user, refuse_reason: params[:refuse_reason])
  end

  def determine_current_status
    status_valid? ? params[:status].to_sym : :all
  end
end
