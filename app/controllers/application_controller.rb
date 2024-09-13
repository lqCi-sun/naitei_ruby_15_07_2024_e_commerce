class ApplicationController < ActionController::Base
  before_action :configure_sign_up_params, if: :devise_controller?

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_path
    flash[:danger] = exception.message
  end

  include Pagy::Backend

  def default_url_options
    {locale: I18n.locale}
  end

  def after_sign_in_path_for resource
    if resource.role_admin?
      admin_orders_path
    else
      root_path
    end
  end

  before_action :set_search_query
  before_action :current_user

  def set_search_query
    @q = Product.ransack(params[:q])
  end

  around_action :switch_locale

  def switch_locale &action
    locale = params[:locale] || I18n.default_locale
    I18n.with_locale(locale, &action)
  end

  def set_order_items_ids
    @order_items_ids = if cookies[:cartitemids].present?
                         JSON.parse(cookies[:cartitemids]).map(&:to_i)
                       else
                         []
                       end
  end

  def encode_token payload
    JWT.encode(payload, ENV["JWT_SECRET_KEY"])
  end

  def decode_token
    auth_header = request.headers["Authorization"]
    return unless auth_header

    token = auth_header.split(" ")[1]
    begin
      JWT.decode(
        token, ENV["JWT_SECRET_KEY"],
        true,
        algorithm: Settings.algorithm
      )
    rescue JWT::DecodeError
      nil
    end
  end

  protected

  def configure_sign_up_params
    added_attrs = User::ACCOUNT_PARAMS
    devise_parameter_sanitizer.permit :sign_up, keys: added_attrs
  end
end
