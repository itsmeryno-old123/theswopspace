class UploadProcessor  
  def save_image(input)
    @i = Image.new
    @i.filename = input.original_filename
    @i.content_type = input.content_type.chomp
    @i.binary_data = input.read
    @i.imageguid = SecureRandom.hex(32)
    @i.save
    @i
  end
end