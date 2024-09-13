class ProductSerializer < ActiveModel::Serializer
  attributes %i(id category_id product_name description price stock
                sold rating image created_at updated_at deleted_at)

  belongs_to :category
  has_many :feedbacks

  def image
    return unless object.image.attached?

    Rails.application.routes.url_helpers.rails_blob_url(object.image,
                                                        only_path: true)
  end
end
