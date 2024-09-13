class Api::V1::Admin::ProductsController < AdminController
  skip_before_action :verify_authenticity_token
  before_action :find_product, only: %i(edit update destroy)
  before_action :default_categories, only: %i(new create edit update index)

  def index
    @q = Product.ransack(params[:q] || {})
    @query = params.dig(:q, :product_name_cont) || nil
    @products_search = @q.result
    render json: @products_search, each_serializer: ProductSerializer
  end

  def new
    @product = Product.new
    render json: @product
  end

  def create
    @product = Product.new product_params
    @product.rating = 0
    if @product.save
      render json: {
        message: t("admin.products.create.messages.success"),
        product: ProductSerializer.new(@product)
      }, status: :created
    else
      render json: {errors: t("admin.products.create.messages.error")},
             status: :unprocessable_entity
    end
  end

  def edit
    render json: @product, serializer: ProductSerializer
  end

  def update
    if @product.update product_params
      render json: {
        message: t("admin.products.update.messages.success"),
        product: ProductSerializer.new(@product)
      }, status: :ok
    else
      render json: {errors: t("admin.products.update.messages.error")},
             status: :unprocessable_entity
    end
  end

  def destroy
    if @product.destroy
      render json: {message: t("admin.products.destroy.messages.success")},
             status: :ok
    else
      render json: {errors: t("admin.products.destroy.messages.error")},
             status: :unprocessable_entity
    end
  end

  private

  def product_params
    params.require(:product).permit Product::PRODUCT_PARAMS
  end

  def find_product
    @product = Product.find_by id: params[:id]
    return if @product

    render json: {errors: t("flash.not_found_product")}, status: :not_found
  end

  def default_categories
    @categories = Category.all
  end
end
