class Admin::OrdersController < AdminController
  before_action :set_orders, only: %i(index)
  before_action :find_order, only: %i(update_status show)

  def index
    @orders = @orders.sorted_by(params[:sort_by], params[:direction])
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

  def batch_update
    order_ids = params[:order_ids] || []

    return redirect_no_orders if order_ids.empty?

    orders = Order.where(id: order_ids)
    values = []

    orders.each do |order|
      process_order order, values
    end

    Order.import values, on_duplicate_key_update: [:status, :updated_at]
    redirect_to admin_orders_path, notice: t("orders.successfully_updated")
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

  def next_status_for order
    current_status_value = Order.statuses[order.status]
    next_status_value = current_status_value + 1
    Order.statuses.key(next_status_value)
  end

  def redirect_no_orders
    redirect_to(
      request.referer || admin_orders_path,
      alert: t("orders.no_orders_selected")
    )
  end

  def process_order order, values
    next_status = next_status_for order
    if next_status.nil?
      flash[:alert] = t("orders.cannot_transition", order_id: order.id)
      return
    end

    order.assign_attributes(status: next_status, updated_at: Time.current)
    values << order
  end
end
