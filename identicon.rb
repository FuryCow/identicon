# frozen_string_literal: true

require "chunky_png"
require "base64"

DEFAULT_OPTIONS = {
  border_size: 15,
  square_size: 44,
  grid_size: 5,
  background_color: ChunkyPNG::Color::WHITE,
  key: "\x00\x11\x22\x33\x44\x55\x66\x77\x88\x99\xAA\xBB\xCC\xDD\xEE\xFF"
}

class Identicon

  def initialize(username, path = __dir__)
    @username = username
    @path = path
  end

  def generate
    ImageProcessor.create_and_save username_representation, image_path
  end

  private

  def image_path
    @path + '/' + @username + '.png'
  end

  def username_representation
    p = 31
    m = 1e9 + 5
    power_of_p = 2
    hash = 0
    for i in 0..@username.length-1 do
      hash = (hash + (@username[i].ord - 'a'.ord + 1) * power_of_p) % m
      power_of_p = (power_of_p * p) % m
    end
    hash.to_i
  end
end

class ImageProcessor
  def self.create_and_save(hash, filename)
    raise "filename cannot be nil" if filename.nil?
    
    blob = create(hash)
    return false if blob.nil?
    
    File.open(filename, "wb") { |f| f.write(blob) }
  end

  def self.create(hash)
    options = DEFAULT_OPTIONS
    
    png = ChunkyPNG::Image.new((options[:border_size] * 2) + (options[:square_size] * options[:grid_size]),
      (options[:border_size] * 2) + (options[:square_size] * options[:grid_size]), options[:background_color])

    color = ChunkyPNG::Color.rgba((hash & 0xff), ((hash >> 8) & 0xff), ((hash >> 16) & 0xff), 0xff)
    
    sqx = sqy = 0
    (options[:grid_size] * ((options[:grid_size] + 1) / 2)).times do
      if hash & 1 == 1
        x = options[:border_size] + (sqx * options[:square_size])
        y = options[:border_size] + (sqy * options[:square_size])

        png.rect(x, y, x + options[:square_size] - 1, y + options[:square_size] - 1, color, color)

        x = options[:border_size] + ((options[:grid_size] - 1 - sqx) * options[:square_size])
        png.rect(x, y, x + options[:square_size] - 1, y + options[:square_size] - 1, color, color)
      end
    
      hash >>= 1
      sqy += 1
      if sqy == options[:grid_size]
        sqy = 0
        sqx += 1
      end
    end
    
    png.to_blob color_mode: ChunkyPNG::COLOR_INDEXED
  end
end