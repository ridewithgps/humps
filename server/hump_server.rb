class HumpServer < Sinatra::Base
  configure do
    db_settings = YAML.load(File.read('config/pg.yml'))
    dbs = db_settings[settings.environment.to_s]

    set :conn, DbConnector.new(dbs)
  end

  get '/' do
    "Actually, we need a JSON and you need to give me a POST.  None of this GET business!"
  end

  #TODO: change this to post, just testing for now
  post '/10m_grid' do
    min_lng = params[:min_lng].to_f
    min_lat = params[:min_lat].to_f
    max_lng = params[:max_lng].to_f
    max_lat = params[:max_lat].to_f
    num_x = params[:num_x].to_i
    num_y = params[:num_y].to_i

    grid = Humps.get_grid(min_lng, min_lat, max_lng, max_lat, num_x, num_y)
    grid.to_json
  end

  # JSONP endpoint for the new threedee viewer
  get '/10m_grid' do
    min_lng = params[:min_lng].to_f
    min_lat = params[:min_lat].to_f
    max_lng = params[:max_lng].to_f
    max_lat = params[:max_lat].to_f
    num_x = params[:num_x].to_i
    num_y = params[:num_y].to_i
    callback = params[:callback]

    grid = Humps.get_grid(min_lng, min_lat, max_lng, max_lat, num_x, num_y)

    content_type :js
    return "#{callback}(#{grid.to_json})"

  end

  post '/10m_points' do
    lats = params[:lats].split(',').collect { |n| n.to_f }
    lngs = params[:lngs].split(',').collect { |n| n.to_f }
    eles = []

    #this is a super shitty way to do it; i should make a new method
    #which doesn't pull a new header for each point
    (0..lngs.size-1).each do |i|
      eles << Humps.get_ele(lngs[i], lats[i])
    end

    eles.join("\n")
  end

  get '/get_eles' do
    callback = params.delete('callback')
    lats = params[:lats].split(',').collect { |n| n.to_f }
    lngs = params[:lngs].split(',').collect { |n| n.to_f }
    eles = []

    #this is a super shitty way to do it; i should make a new method
    #which doesn't pull a new header for each point
    (0..lngs.size-1).each do |i|
      eles << Humps.get_ele(lngs[i], lats[i])
    end

    if callback
      content_type :js
      return "#{callback}(#{eles.to_json})"
    else
      content_type :json
      return eles.to_json
    end
  end

  get '/timezone.?:format?' do
    #escape_string relies on connection to db, which if lost tosses an error
    begin
      lng = settings.conn.escape_string(params[:lng])
      lat = settings.conn.escape_string(params[:lat])
    rescue
      settings.conn.reset_connection
      lng = settings.conn.escape_string(params[:lng])
      lat = settings.conn.escape_string(params[:lat])
    end

    callback = params.delete('callback')
    dataset = params.delete('dataset') || 'tz_world'

    if dataset == 'tz_world'
      table = 'tz_world'
      col = 'tzid'
    else
      table = 'ne_10m_time_zones'
      col = 'tz_name1st'
    end

    sql = "SELECT #{col} FROM #{table} WHERE ST_Within(ST_Point(#{lng}, #{lat}), geom);"

    begin
      result = settings.conn.exec(sql).first
    rescue
      settings.conn.reset_connection
      result = settings.conn.exec(sql).first
    end
    response = if result
      {tzid: result[col]}
    else
      {error: 'Could not find a timezone with that latitude and longitude'}
    end

    if callback
      content_type :js
      return "#{callback}(#{response.to_json})"
    end

    if params[:format] == 'json'
      content_type :json
    else
      content_type :text
    end

    return response.to_json
  end
end
