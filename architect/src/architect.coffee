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
    @photoGeoObjects = {}
    @placemarkGeoObjects = {}
    @locationChangedFunc = null
    @mode = null
    
  log:(msg) ->
    $("#status").html "<p>#{msg}</p>"

  setLocation: (loc, lat, long, alt) ->
    [loc.latitude, loc.longitude, loc.altitude] = [lat, long, alt]

  setLastLocation: (loc) ->
    @setLocation(@lastLocation, loc.latitude, loc.longitude, loc.altitude)

  locationChanged: (lat, long, alt, acc) ->
    @log "changing location to " + [lat, long].join ", "
    @setLocation(@currentLocation, lat, long, alt)
    if @locationChangedFunc != null
      @locationChangedFunc()

  setMode:(mode, data = null) ->
    @log "setting mode #{mode}"
    return if mode == @mode
    if mode == 'photo'
      @setupPhotoMode()
    else
      @setupPlacemarkMode(data)

  setupPhotoMode: ->
    @locationChangedFunc = null
    @mode = 'photo'
    @disablePlacemarks
    @cleanUpPhotos
    @enablePhotos
    @locationChangedFunc = @maybeUpdatePhotos

  maybeUpdatePhotos: ->
    @log "conditionally updating photos"
    if @currentLocation.distanceTo(@lastLocation) > @RADIUS / 5
      @setLastLocation @currentLocation
      @cleanUpPhotos
      @updatePhotos()

  enablePhotos: ->
    @log "enabling photos"
    for id, photo of @photoGeoObjects
      photo.enabled = true

  updatePhotos: ->
    @log "updating photos"
    @getPhotosForLocation @currentLocation

  cleanUpPhotos: ->
    @log "cleaning up photos"
    for id, item of @photoGeoObjects
      distance = @currentLocation.distanceTo(item.locations[0])
      @log "Object #{id} is #{distance}m away"
      if distance > @RADIUS
        @log "Destroying object #{id}"
        @destroyGeoObject('photo', id)
      else
        @log "Resetting opacity and scale on object #{id}"
        for drawable in item.drawables.cam
          @setOpacityAndScaleOnDrawable(drawable, distance)

  createPhotoGeoObject: (siteId) ->
    @log "creating photoGeoObject for id #{siteId}"
    if not @photoGeoObjects[siteId]
      @serverRequest "details_for_site_id/", [siteId], (siteDetails) =>
        @log "creating geoObject with loc #{siteDetails.lat}, #{siteDetails.long}: #{siteDetails.thumbs[0]}"
        location = { lat: siteDetails.lat, long: siteDetails.long, alt: @currentLocation.altitude }
        @createGeoObject location, siteDetails.thumbs[0], siteId, 'photoGeoObjects'
          
  getPhotosForLocation: (loc) ->
    @log "getting photos for location #{loc.latitude}, #{loc.longitude}"
    @serverRequest "site_ids_for_location/", [loc.latitude, loc.longitude, @RADIUS], (siteIds) =>
      @log "Found #{siteIds.length} images"
      for id in siteIds
        @createPhotoGeoObject id

  setupPlacemarkMode:() ->
    @locationChangedFunc = null
    @mode = 'placemark'
    if @empty(@placemarkGeoObjects)
      @requestPlacemarkData()
    @enablePlacemarks()
    @locationChangedFunc = @maybeUpdatePlacemarks

  requestPlacemarkData: ->
    @log "requesting placemark data"
    document.location = "architectsdk://requestplacemarkdata"
    
  setPlacemarkData: (data) ->
    @log "setting placemark data"
    count = 0
    @destroyPlacemarks
    for id, details of data
      count++
      @log count
      @createGeoObject details.location, details.imgUri, id, 'placemarkGeoObjects'

  destroyPlacemarks: ->
    for id, placemark of @placemarkGeoObjects
      destroyGeoObject 'placemark', id

  enablePlacemarks: ->
    for id, placemark of @placemarkGeoObjects
      placemark.enabled = true

  disablePlacemarks: ->
    for id, placemark of @placemarkGeoObjects
      placemark.enabled = false

  maybeUpdatePlacemarks: ->
    @log "conditionally updating placemarks"
    if @currentLocation.distanceTo(@lastLocation) > @RADIUS / 5
      @setLastLocation @currentLocation
      @updatePlacemarks

  updatePlacemarks: ->
    @log "updating placemarks"
    for id, placemark of @placemarkGeoObjects
      distance = @currentLocation.distanceTo(placemark.locations[0])
      @log "object #{id} is #{distance}m away"
      @log "resetting opacity and scale on object #{id}"
      for drawable in placemark.drawables.cam
        @setOpacityAndScaleOnDrawable(drawable, distance)

  setOpacityAndScaleOnDrawable: (drawable, distance) ->
    scalingFactor = @MIN_SCALING_DISTANCE / (distance / @DISTANCE_SCALE_FACTOR)
    scale = Math.min 1, scalingFactor
    opacity = Math.min 1, scalingFactor
    drawable.scale = scale
    drawable.opacity = opacity 

  destroyGeoObject: (type = 'photo', id) ->
    collection = @["#{type}GeoObjects"]
    geo = collection[id]
    for drawable in geo.drawables.cam
      drawable.imageResource.destroy()
      drawable.destroy()
    for location in geo.locations
      location.destroy()
    geo.destroy()
    delete collection[id]

  createGeoObject: (location, imgUri, id, collectionName) ->
    @log "creating geoObject #{id} in collection #{collectionName}"
    collection = @[collectionName]
    location = new AR.GeoLocation location.lat, location.long, location.alt
    distance = @currentLocation.distanceTo location
    drawableOptions = 
      offsetY: (Math.random() * @OFFSET_Y_RANDOM_FACTOR) - @OFFSET_Y_RANDOM_FACTOR / 2
      enabled: true
    geoObject = new AR.GeoObject location, enabled: false
    imgRes = @createImageResource(imgUri, geoObject)
    drawable = @createImageDrawable imgRes, drawableOptions
    drawable.triggers.onClick = => @objectWasClicked id, collectionName
    @setOpacityAndScaleOnDrawable drawable, distance
    geoObject.drawables.addCamDrawable(drawable)
    collection[id] = geoObject

  objectWasClicked: (id, collection) ->
    @log "clicked #{id}, #{collection}"
    document.location = "architectsdk://clickedobject?id=#{id}&collection=#{collection}"
  
  createImageResource: (uri, geoObject) ->
    @log "creating imageResource for #{uri}"
    imgRes = new AR.ImageResource uri,
      onError: =>
        @log "error loading image #{uri}"
      onLoaded: =>
        unless imgRes.getHeight() is 109 and imgRes.getWidth() is 109
          @log "loaded image #{uri}"
          geoObject.enabled = true
    return imgRes

  createImageDrawable: (imgRes, options) ->
    new AR.ImageDrawable imgRes, @DEFAULT_HEIGHT_SDU, options

  serverRequest: (url, params, callback) ->
    params ||= []
    requestUrl = @canmoreRequestUrl + url + params.join('/') + '?callback=?'
    $.getJSON requestUrl, (data) -> callback(data)

  empty: (object) ->
    for key, val of object
      return false
    true


root.Canmore =
  Architect: Architect