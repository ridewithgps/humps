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
    lat = params[:lat]
    lng = params[:lng]
    unless lat && lat.size > 0 && lng && lng.size > 0
      return handle_error(422, "Missing 'lat' or 'lng' params")
    end

    if result = get_timezone(lat, lng, params[:dataset])
      response = { tzid: result }
    else
      return handle_error(404, "Could not find a timezone with that latitude and longitude")
    end

    if callback = params[:callback]
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

  error DbConnector::ConnectionFailedError do
    handle_error(502, "Sorry, we couldn't connect to the timezone database")
  end

  error do
    handle_error(500, "Sorry, something went wrong")
  end

  private

  def handle_error(code, message)
    status(code)
    body = { error: message }.to_json

    if callback = params[:callback]
      content_type(:js)
      body = "#{callback}(#{body.to_json})"
    else
      content_type(:json)
    end

    body
  end

  def get_timezone(lat, lng, dataset = "tz_world")
    if dataset == 'tz_world'
      table = 'tz_world'
      col = 'tzid'
    else
      table = 'ne_10m_time_zones'
      col = 'tz_name1st'
    end

    retried = false
    begin
      lat = settings.conn.conn.escape_string(lat)
      lng = settings.conn.conn.escape_string(lng)
      sql = "SELECT #{col} FROM #{table} WHERE ST_Within(ST_Point(#{lng}, #{lat}), geom);"
      result = settings.conn.conn.exec(sql).first&.[](col)
    rescue
      if retried
        raise
      else
        retried = true
        settings.conn.reset_connection
        retry
      end
    end
    result
  end

end
