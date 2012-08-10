# encoding: utf-8

class CampusImageUploader < CarrierWave::Uploader::Base
  # Include RMagick or ImageScience support:
  include CarrierWave::RMagick
  # include CarrierWave::ImageScience

  # Choose what kind of storage to use for this uploader:
  storage :file
  # storage :fog

  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    "images/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  # Provide a default URL as a default if there hasn't been a file uploaded:
  def default_url
    "/assets/#{model.class.to_s.underscore}/fallback/" + [version_name, "default.jpg"].compact.join('_')
  end

  # Process files as they are uploaded:
  process :resize_to_fill => [400, 400]
  #
  # def scale(width, height)
  #   # do something
  # end

  # Create different versions of your uploaded files:
  version :medium do
    process :resize_to_fill => [100, 100]
  end

  version :small do
    process :resize_to_fill => [48, 48]
  end

  # Add a white list of extensions which are allowed to be uploaded.
  # For assets you might use something like this:
  # def extension_white_list
  #   %w(jpg jpeg gif png)
  # end

  # Override the filename of the uploaded files:
  # Avoid using model.id or version_name here, see uploader/store.rb for details.
  # def filename
  #   "something.jpg" if original_filename
  # end

end
