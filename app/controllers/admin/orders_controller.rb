class Admin::OrdersController < AdminController
  before_action :set_orders, only: %i(index)
  before_action :find_order, only: %i(update_status show)

  def index
    sort_by = params[:sort_by].present? ? params[:sort_by].to_sym : nil
    @orders = case sort_by
              when :status
                @orders.sorted_by(:status, :asc)
              when :created_at
                @orders.sorted_by(:created_at, :asc)
              else
                @orders.sorted_by(:updated_at, :desc)
              end
    @pagy, @orders = pagy @orders, limit: Settings.page_10
  end

  def show
    return unless find_order

    @pagy, @order_items = pagy(@order.order_items, items: Settings.page_10)
  end

  def update_status
    return unless find_order

    begin
      ActiveRecord::Base.transaction do
        handle_status_transition
      end
    rescue ActiveRecord::Rollback
      flash[:error] = t("admin.orders.orders_list.update_failed")
    ensure
      redirect_to request.referer || admin_orders_path
    end
  end

  def set_orders
    @current_status = determine_current_status
    @orders = Order.by_status(@current_status)
    @orders_count = Order.all
  end

  private

  def status_valid?
    params[:status].present? && Order.statuses.key?(params[:status].to_sym)
  end

  def determine_current_status
    if status_valid?
      params[:status].to_sym
    else
      :all
    end
  end

  def handle_status_transition
    new_status = params[:status].to_sym
    case @order.status.to_sym
    when :pending
      handle_pending_status(new_status)
    when :preparing
      handle_preparing_status(new_status)
    when :in_transit
      handle_in_transit_status(new_status)
    else
      flash[:error] = t("admin.orders.orders_list.update_failed")
      raise ActiveRecord::Rollback
    end
  end

  def handle_pending_status new_status
    case new_status
    when :preparing
      prepare_order
    when :cancelled
      cancel_order
    else
      flash[:error] = t("admin.orders.orders_list.update_failed")
      raise ActiveRecord::Rollback
    end
  end

  def handle_preparing_status new_status
    if new_status == :in_transit
      update_order_status(:in_transit)
    else
      flash[:error] = t("admin.orders.orders_list.update_failed")
      raise ActiveRecord::Rollback
    end
  end

  def handle_in_transit_status new_status
    if new_status == :delivered
      update_order_status(:delivered)
    else
      flash[:error] = t("admin.orders.orders_list.update_failed")
      raise ActiveRecord::Rollback
    end
  end

  def prepare_order
    @order.order_items.each do |order_item|
      product = order_item.product
      amount = order_item.quantity
      product.increment(stock_amount: amount, sold_amount: amount)
    end
    @order.update(status: :preparing)
    flash[:success] = t "admin.orders.orders_list.update_to_preparing"
  end

  def cancel_order
    if @order.cancel_order(role: :admin, refuse_reason: params[:refuse_reason])
      flash[:success] = t "admin.orders.orders_list.update_to_cancelled"
    else
      flash[:error] = t "admin.orders.orders_list.update_failed"
      raise ActiveRecord::Rollback
    end
  end

  def update_order_status new_status
    @order.update!(status: new_status)
    flash[:success] = t("admin.orders.orders_list.update_to_#{new_status}")
  end

  def find_order
    @order = Order.find_by(id: params[:id])
    unless @order
      flash[:error] = t("admin.orders.not_found")
      redirect_to admin_orders_path
      return false
    end
    true
  end

  def valid_status_transition current_status, new_status
    case current_status
    when :pending
      %i(preparing cancelled).include?(new_status)
    when :preparing
      new_status == :in_transit
    when :in_transit
      new_status == :delivered
    else
      false
    end
  end
end
