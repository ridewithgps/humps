require 'rexml/document'
require 'open-uri'

class Humps
  #SRTM_PATH = "#{Rails.root}/gisdata/srtm/"
  #NED_PATH = "#{Rails.root}/gisdata/ned/"
  #ASTER_PATH = "#{Rails.root}/gisdata/aster/"
  SRTM_PATH = "/var/gisdata/srtm/"
  NED_PATH = "/var/gisdata/ned/ned_13_arc_second_1_degree_tiles/"
  ASTER_PATH = "/var/gisdata/aster/"

  def self.srtm_path
    @srtm_path || SRTM_PATH
  end
  def self.srtm_path= path
    @srtm_path = path
  end
  def self.ned_path
    @ned_path || NED_PATH
  end
  def self.ned_path= path
    @ned_path = path
  end
  def self.aster_path
    @aster_path || ASTER_PATH
  end
  def self.aster_path= path
    @aster_path = path
  end


  #fall through various sources in order of importance
  def self.get_ele(x,y)
    return -9999 unless x && y
    if y >= 60
      ele = self.bilinear_aster(x, y)# if ele.nil? or ele < -420
    else
      ele = self.bilinear_ned(x,y)
      ele = self.bilinear_srtm(x, y) if ele.nil? or ele < -420
      ele = self.bilinear_aster(x, y) if ele.nil? or ele < -420
    end
    return ele
  end

  def self.get_hdr(source, x, y)
    hdr_fn, dem_fn = get_file_names(source, x, y)
    return nil unless hdr_fn && File.exists?(hdr_fn)

    hdr = {}
    File.read(hdr_fn).split("\n").collect { |a| a.split }.each { |d| hdr[d.first] = d.last }
    return {
      :min_x => hdr['xllcorner'].to_f,
      :min_y => hdr['yllcorner'].to_f,
      :cellsize => hdr['cellsize'].to_f,
      :ncols => hdr['ncols'].to_i,
      :nrows => hdr['nrows'].to_i,
      :data_file => dem_fn
    }
  end




  ############ ASTER related calls #################
  def self.nn_aster(x,y)
    hdr = self.get_hdr(:aster, x, y)
    return -9999 if hdr.nil?
    return nn(hdr, x, y, 2, 's')
  end

  def self.bilinear_aster(x, y)
    hdr = self.get_hdr(:aster, x, y)
    return -9999 if hdr.nil?
    return bilinear(hdr, x, y, 2, 'ss')
  end

  def self.cubic_aster(x, y)
    hdr = get_hdr(:aster, x,y)
    return -9999 if hdr.nil?
    return cubic(hdr, x, y, 2, 'ssss')
  end


  ############# SRTM related calls ##############
  def self.nn_srtm(x, y)
    hdr = self.get_hdr(:srtm, x, y)
    return -9999 if hdr.nil?
    return nn(hdr, x, y, 2, 's')
  end

  def self.bilinear_srtm(x, y)
    hdr = self.get_hdr(:srtm, x, y)
    return -9999 if hdr.nil?
    return bilinear(hdr, x, y, 2, 'ss')
  end

  def self.cubic_srtm(x,y)
    hdr = get_hdr(:srtm, x,y)
    return -9999 if hdr.nil?
    return cubic(hdr, x, y, 2, 'ssss')
  end


  ######## NED related calls ################
  def self.nn_ned(x,y)
    hdr = get_hdr(:ned, x,y)
    return -9999 if hdr.nil?
    return nn(hdr, x, y, 4, 'f')
  end

  def self.bilinear_ned(x, y)
    hdr = get_hdr(:ned, x, y)
    return -9999 if hdr.nil?
    return bilinear(hdr, x, y, 4, 'ff')
  end

  def self.cubic_ned(x,y)
    hdr = get_hdr(:ned, x,y)
    return -9999 if hdr.nil?
    return cubic(hdr, x, y, 4, 'ffff')
  end


  ########## base methods ############33333
  def self.nn(hdr, x, y, bytes, pack)
    begin
      #puts hdr
      x_offset = ((x-hdr[:min_x]) / hdr[:cellsize]).round
      y_offset = (((hdr[:min_y] + hdr[:cellsize]*(hdr[:ncols]-1)) - y) / hdr[:cellsize]).round
      byte_offset = bytes*(x_offset + hdr[:ncols]*y_offset)
      #puts "#{x_offset},#{y_offset}"# - ele: #{ele}"
      ele = IO.read(hdr[:data_file], bytes, byte_offset).unpack(pack)[0]
      return ele.round(1)
    rescue
      return -9999
    end
  end

  def self.bilinear(hdr, x, y, bytes, pack)
    x_offset_abs = (x - hdr[:min_x]) / hdr[:cellsize]
    y_offset_abs = ((hdr[:min_y] + hdr[:cellsize]*(hdr[:ncols]-1)) - y) / hdr[:cellsize]
    x_offset = x_offset_abs.floor
    y_offset = y_offset_abs.floor
    x_index = x_offset_abs - x_offset
    y_index = y_offset_abs - y_offset
    num_bytes_to_read = bytes*2

    byte_offset1 = bytes*(x_offset + hdr[:ncols] * y_offset)
    byte_offset2 = bytes*(x_offset + hdr[:ncols] * (y_offset+1))

    #puts "(#{x_offset_abs}, #{y_offset_abs}), (#{x_offset}, #{y_offset}), (#{x_index}, #{y_index})"

    begin
      a1, a2 = IO.read(hdr[:data_file], num_bytes_to_read, byte_offset1).unpack(pack)
      a3, a4 = IO.read(hdr[:data_file], num_bytes_to_read, byte_offset2).unpack(pack)
    rescue
      #we wrapped around our DEM edges, let's just get nearest neighbor for simplicity in this rare case
      return self.nn_srtm(x, y)
    end

    #if all values are nodata, then it's not a local fluke/void, let's return nodata value
    #otherwise, not all cells are nodata, which is a local void and probably sea level (passing over bridge)
    return -9999 if(a1 < -420 && a1 == a2 && a1 == a3 && a1 == a4)
    a1 = 0 if a1 < -420
    a2 = 0 if a2 < -420
    a3 = 0 if a3 < -420
    a4 = 0 if a4 < -420

    res = a1 + (a2 - a1)*x_index + (a3 - a1)*y_index + (a1 - a2 - a3 + a4)*x_index*y_index
    res.round(1)
  end

  def self.cubic(hdr, x, y, bytes, pack)
    ty = hdr[:min_y] + hdr[:cellsize] * (hdr[:ncols]-1)
    x_offset_abs = (x - hdr[:min_x]) / hdr[:cellsize]
    y_offset_abs = (ty - y) / hdr[:cellsize]
    x_offset = x_offset_abs.floor
    y_offset = y_offset_abs.floor
    x = x_offset_abs - x_offset
    y = y_offset_abs - y_offset
    num_bytes_to_read = bytes*4

    byte_offset0 = bytes * (x_offset - 1 + (y_offset-1) * hdr[:ncols])
    byte_offset1 = bytes * (x_offset - 1 + (y_offset  ) * hdr[:ncols])
    byte_offset2 = bytes * (x_offset - 1 + (y_offset+1) * hdr[:ncols])
    byte_offset3 = bytes * (x_offset - 1 + (y_offset+2) * hdr[:ncols])

    #we are performing 4 interpolations in the x direction, to get the four elevation points
    #that will makeup a column of interpolated elevations.  This column is then used to
    #do one more interpolation to get the elevation point in center of grid.
    begin
      row0 = IO.read(hdr[:data_file], num_bytes_to_read, byte_offset0).unpack(pack).map { |p| p < -420 ? 0 : p }
      row1 = IO.read(hdr[:data_file], num_bytes_to_read, byte_offset1).unpack(pack).map { |p| p < -420 ? 0 : p }
      row2 = IO.read(hdr[:data_file], num_bytes_to_read, byte_offset2).unpack(pack).map { |p| p < -420 ? 0 : p }
      row3 = IO.read(hdr[:data_file], num_bytes_to_read, byte_offset3).unpack(pack).map { |p| p < -420 ? 0 : p }
    rescue
      #probably wrapped off edge of file
      return self.nn_srtm(x, y)
    end

    i0 = cubic_interpolate(row0, x)
    i1 = cubic_interpolate(row1, x)
    i2 = cubic_interpolate(row2, x)
    i3 = cubic_interpolate(row3, x)

    #now we have a column of interpolated elevations, we can do one more cubic interpolation
    #and get a final elevation value.
    #puts row3.inspect
    #puts row2.inspect
    #puts row1.inspect
    #puts row0.inspect
    self.cubic_interpolate([i0, i1, i2, i3], y).round(1)
  end















  def self.test_functions(klass, id)
    asset = klass.find(id)
    points = asset.track_points
    bi_eles, cubic_eles, nn_eles, saved_eles = [], [], [], [], []
    last = points[0]
    dist = 0
    sets = []
    nn_res, saved_res, bi_res, cubic_res = [], [], [], []

    points.each do |point|
      saved_eles << ele = point['ele']
      nn_eles << nn = self.nn_ned(point['lng'], point['lat'])
      bi_eles << bi = self.bilinear_ned(point['lng'], point['lat'])
      cubic_eles << cubic = self.cubic_ned(point['lng'], point['lat'])

      dist += Trip.haversine_distance(last['lat'], last['lng'], point['lat'], point['lng'])
      saved_res << "#{dist}, #{ele}"
      nn_res << "#{dist}, #{nn}"
      bi_res << "#{dist}, #{bi}"
      cubic_res << "#{dist}, #{cubic}"

      last = point
    end

    s, e = 0, points.length-1
    plotter = ModelPlotter.new([{:data => saved_res[s..e].join("\n"), :title => 'Saved'}, {:data => nn_res[s..e].join("\n"), :title => 'Nearest'}, {:data => bi_res[s..e].join("\n"), :title => 'Bilinear'}, {:data => cubic_res[s..e].join("\n"), :title => 'Cubic'}], 'plotfile.plot', 'Elevations Oh Mai!', 'Distance', 'Elevation', 5000, 4000)
    plotter.plot

    bi_gain, bi_loss = GainLoss.calculate(bi_eles)
    cubic_gain, cubic_loss = GainLoss.calculate(cubic_eles)
    nn_gain, nn_loss = GainLoss.calculate(nn_eles)
    saved_gain, saved_loss = GainLoss.calculate(saved_eles)

    puts "nearest neighbor gain/loss: #{nn_gain}, #{nn_loss}"
    puts "bilinear gain/loss: #{bi_gain}, #{bi_loss}"
    puts "cubic gain/loss: #{cubic_gain}, #{cubic_loss}"
    puts "saved gain/loss: #{saved_gain}, #{saved_loss}"
    puts "saved smoothed gain/loss: #{asset.elevation_gain}, #{asset.elevation_loss}"
  end

  def self.get_grid(ll_x, ll_y, ur_x, ur_y, num_x, num_y)
    x_spacing = (ur_x - ll_x) / num_x
    y_spacing = (ur_y - ll_y) / num_y
    grid = {:vertices => []}
    max_ele = -50000;
    min_ele = 50000;

    (num_x + 1).times do |x|
      lng = ll_x + x_spacing*x
      column = []
      (num_y + 1).times do |y|
        lat = ll_y + y_spacing*y
        ele = get_ele(lng, lat)

        max_ele = ele if ele > max_ele
        min_ele = ele if ele < min_ele

        column << {:lng => lng, :lat => lat, :ele => ele}
      end
      grid[:vertices] << column
    end

    return grid.merge!({:min_ele => min_ele, :max_ele => max_ele})
  end


  private

  def self.cubic_interpolate(row, x)
    a0 = row[3] - row[2] - row[0] + row[1]
    a1 = row[0] - row[1] - a0
    a2 = row[2] - row[0]

    (a0*x*x*x) + (a1*x*x) + a2*x + row[1]
  end

  def self.get_file_names(source, x, y)
    case source.to_sym
    when :aster
      #each file is a 1x1 degree chunk, named ASTGTM_[N|S][lat.floor][E|W][lng.floor].flt
      n = y >= 0 ? "N" : "S"
      e = x >= 0 ? "E" : "W"
      #ok, so it took me a while to figure this out, but these aren't too magic
      #of numbers...each tile doesn't start on a clean number.  The min-y of
      #a tile may be 46.999861.  So we have to offset our number by the remainder.
      x_offset = x.floor.abs
      y_offset = y.floor.abs
      fn_base = "#{aster_path}/ASTGTM_#{n}%02d#{e}%03d_dem" % [y_offset, x_offset]
    when :srtm
      #these aren't that magical, we have a 5 degree tile system so we have to
      #do a little math to make sure we chunk by degrees of five.  The magic looking
      #offset numbers are because each tile does not start/end on a clean decimal
      #boundary, so we have to offset by the amount of overlap between degrees.
      #filex = ((x + 179.999584) / 5.0).ceil
      #filey = 24 - ((y + 60.0004168) / 5.0).floor
      filex = ((x + 180 + (5/6000.0)) / 5.0).ceil
      filey = (24 - ((y + 60 + (5/6000.0)) / 5.0)).ceil
      fn_base = "#{srtm_path}/srtm_%.2d_%.2d" % [filex, filey]
    when :ned
      return nil if x > 0 || y < 0 #we only have a certain range in the NED
      x_offset = x.abs.ceil
      y_offset = y.abs.ceil
      fn_base = "#{ned_path}/dem#{x_offset}#{y_offset}"
    else
      return nil
    end
    return fn_base + '.hdr', fn_base
  end
end
