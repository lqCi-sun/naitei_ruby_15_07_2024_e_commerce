class Admin::ProductsController < AdminController
  before_action :find_product, only: %i(edit update destroy)
  before_action :default_categories, only: %i(new create edit update index)
  def index
    @q = Product.ransack(params[:q] || {})
    @query = params.dig(:q, :product_name_cont) || nil
    session[:search_query] = @query
    @pagy, @products_search = pagy(
      @q.result,
      limit: Settings.page_10
    )
    render :index
  end

  def new
    @product = Product.new
  end

  def create
    @product = Product.new product_params
    @product.rating = 0
    if @product.save
      flash[:success] = t "admin.products.create.messages.success"
      redirect_to admin_products_path q: {product_name_cont:
                                          @product.product_name}
    else
      flash[:error] = t "admin.products.create.messages.error"
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @product.update product_params
      flash[:success] = t "admin.products.update.messages.success"
      redirect_to admin_products_path q: {product_name_cont:
                                          session[:search_query]}
      session.delete(:search_query)
    else
      flash[:error] = t "admin.products.update.messages.error"
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @product.destroy
      flash[:success] = t "admin.products.destroy.messages.success"
      redirect_to admin_products_path q: {product_name_cont:
                                          session[:search_query]}
    else
      flash[:error] = t "admin.products.destroy.messages.error"
    end
    session.delete(:search_query)
  end

  private

  def product_params
    params.require(:product).permit Product::PRODUCT_PARAMS
  end

  def find_product
    @product = Product.find_by id: params[:id]

    return if @product

    flash[:warning] = t "flash.not_found_product"
    redirect_to admin_products_path q: {product_name_cont:
                                        session[:search_query]}
  end

  def default_categories
    @categories = Category.all
  end
end
