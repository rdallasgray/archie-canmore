root = (exports ? this)

class Architect
  CANMORE_REQUEST_URL: '/'
  TEST_LOCATION: [55.8791, -4.2788, 59]
  LAT_METERS: 100000
  LONG_METERS: 70000
  RADIUS: 500
  DEFAULT_HEIGHT_SDU: 4.5
  DISTANCE_SCALE_FACTOR: 1.75
  MIN_SCALING_DISTANCE: 100
  OFFSET_Y_RANDOM_FACTOR: 3

  constructor: (canmoreRequestUrl) ->
    @canmoreRequestUrl = canmoreRequestUrl || @CANMORE_REQUEST_URL
    @lastLocation = new AR.GeoLocation(0, 0, 0)
    @currentLocation = new AR.GeoLocation(0, 0, 0)
    @geoObjects = {}
    @ARLoggerActivated = false
    
  log:(msg) ->
    html = $("#status").html()
    $("#status").html html + "<p>#{msg}</p>"

  setLocation: (loc, lat, long, alt) ->
    [loc.latitude, loc.longitude, loc.altitude] = [lat, long, alt]

  setLastLocation: (loc) ->
    @setLocation(@lastLocation, loc.latitude, loc.longitude, loc.altitude)

  locationChanged: (lat, long, alt, acc) ->
    @log "changing location to " + [lat, long].join ", "
    @setLocation(@currentLocation, lat, long, alt)
    if @currentLocation.distanceTo(@lastLocation) > @RADIUS / 5
      @setLastLocation @currentLocation
      @updateImages()

  updateImages: ->
    @cleanUpImages()
    @getImagesForLocation @currentLocation

  cleanUpImages: ->
    @log "Cleaning up images"
    for id, item of @geoObjects
      distance = @currentLocation.distanceTo(item.locations[0])
      @log "Object #{id} is #{distance}m away"
      if distance > @RADIUS / 2
        @log "Destroying object #{id}"
        @destroyGeoObject(id)
      else
        @log "Resetting opacity and scale on object #{id}"
        for drawable in item.drawables.cam
          @setOpacityAndScaleOnDrawable(drawable, distance)

  setOpacityAndScaleOnDrawable: (drawable, distance) ->
    scalingFactor = @MIN_SCALING_DISTANCE / (distance / @DISTANCE_SCALE_FACTOR)
    scale = Math.min 1, scalingFactor
    opacity = Math.min 1, scalingFactor
    drawable.scale = scale
    drawable.opacity = opacity 

  destroyGeoObject: (id) ->
    geo = @geoObjects[id]
    for drawable in geo.drawables.cam
      drawable.imageResource.destroy()
      drawable.destroy()
    for location in geo.locations
      location.destroy()
    geo.destroy()
    delete @geoObjects[id]

  createGeoObject: (siteId) ->
    if not @geoObjects[siteId]
      @serverRequest "details_for_site_id/", [siteId], (siteDetails) =>
        location = new AR.GeoLocation siteDetails.lat, siteDetails.long, @currentLocation.altitude
        distance = @currentLocation.distanceTo location
        drawableOptions = 
          offsetY: (Math.random() * @OFFSET_Y_RANDOM_FACTOR) - @OFFSET_Y_RANDOM_FACTOR / 2
          enabled: true
        @geoObjects[siteId] = new AR.GeoObject location, enabled: false
        imgRes = @createImageResource(siteDetails.thumbs[0], @geoObjects[siteId])
        drawable = @createImageDrawable imgRes, drawableOptions
        @setOpacityAndScaleOnDrawable drawable, distance
        @geoObjects[siteId].drawables.addCamDrawable drawable

  createImageResource: (uri, geoObject) ->
    imgRes = new AR.ImageResource uri,
      onError: =>
        @log "Error loading image #{uri}"
      onLoaded: =>
        @log "Loaded image #{uri}"
        unless imgRes.getHeight() is 109 and imgRes.getWidth() is 109
          geoObject.enabled = true
    return imgRes

  createImageDrawable: (imgRes, options) ->
    new AR.ImageDrawable imgRes, @DEFAULT_HEIGHT_SDU, options

  serverRequest: (url, params, callback) ->
    params ||= []
    requestUrl = @canmoreRequestUrl + url + params.join('/') + '?callback=?'
    $.getJSON requestUrl, (data) -> callback(data)
          
  getImagesForLocation: (loc, func) ->
    @serverRequest "site_ids_for_location/", [loc.latitude, loc.longitude, @RADIUS], (items) =>
      @log "Found #{items.length} images"
      for item in items
        @createGeoObject item


root.Canmore =
  Architect: Architect