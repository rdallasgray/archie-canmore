root = (exports ? this)

class Architect
  CANMORE_REQUEST_URL: '/'
  TEST_LOCATION: [55.8791, -4.2788, 59]
  LAT_METERS: 100000
  LONG_METERS: 70000
  RADIUS: 500
  DEFAULT_HEIGHT_SDU: 4.5
  DISTANCE_SCALE_FACTOR: 1.75
  MIN_SCALING_DISTANCE: 50
  OFFSET_Y_RANDOM_FACTOR: 3

  constructor: (canmoreRequestUrl) ->
    @canmoreRequestUrl = canmoreRequestUrl || @CANMORE_REQUEST_URL
    @lastLocation = new AR.GeoLocation(0, 0, 0)
    @currentLocation = new AR.GeoLocation(0, 0, 0)
    @photoGeoObjects = {}
    @placemarkGeoObjects = {}
    @imgResources = {}
    @locationChangedFunc = null
    @mode = null
    @reportBuffer = []
    @reportInterval = 10
    @reportCount = 0
    @timeSinceLastReport = @reportInterval
    setInterval (=> @clearReportBuffer()), @reportInterval
    
  log:(msg) ->
    if $("#status p").length > 20
      $("#status p").first().remove()
    html = $("#status").html()
    $("#status").html html+"<p>#{msg}</p>"

  showLog: ->
    $("#status").show()

  report:(msg) ->
    @reportBuffer.push { 'report': msg }

  request:(msg) ->
    @reportBuffer.unshift { 'request': msg }

  clearReportBuffer: ->
    report = @reportBuffer.shift()
    if report == undefined
      return
    @sendReport(report)    

  sendReport:(report) ->
    for type, msg of report
#      console.log("#{type}: #{msg} ")
      document.location = "architectsdk://#{type}?msg="+encodeURIComponent(msg)
        
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
    @report "setting mode #{mode}"
    return if mode == @mode
    if mode == "photo"
      @setupPhotoMode()
    else
      @setupPlacemarkMode()

  setupPhotoMode: ->
    @report "setting up photo mode"
    @locationChangedFunc = null
    @mode = 'photo'
    @disablePlacemarks()
    @cleanUpPhotos()
    @enablePhotos()
    if @locationChangeSufficient()
      @updatePhotos
    @locationChangedFunc = @maybeUpdatePhotos

  locationChangeSufficient: ->
    @currentLocation.distanceTo(@lastLocation) > @RADIUS / 5

  maybeUpdatePhotos: ->
    @log "conditionally updating photos"
    if @locationChangeSufficient()
      @setLastLocation @currentLocation
      @cleanUpPhotos()
      @updatePhotos()

  enablePhotos: ->
    @log "enabling photos"
    for id, photo of @photoGeoObjects
      photo.enabled = true

  updatePhotos: ->
    @report "updating photos"
    @getPhotosForLocation @currentLocation

  cleanUpPhotos: ->
    @report "cleaning up photos"
    for id, item of @photoGeoObjects
      distance = @currentLocation.distanceTo(item.locations[0])
      @report "Object #{id} is #{distance}m away"
      if distance > @RADIUS
        @report "Destroying object #{id}"
        @destroyGeoObject('photo', id)
      else
        @report "Resetting opacity and scale on object #{id}"
        for drawable in item.drawables.cam
          @setOpacityAndScaleOnDrawable(drawable, distance)

  createPhotoGeoObject: (siteId) ->
    @report "creating photoGeoObject for id #{siteId}"
    if @photoGeoObjects[siteId] == undefined
      @serverRequest "details_for_site_id/", [siteId], (siteDetails) =>
        @log "creating geoObject with loc #{siteDetails.lat}, #{siteDetails.long}: #{siteDetails.thumbs[0]}"
        location = { lat: siteDetails.lat, long: siteDetails.long, alt: @currentLocation.altitude }
        @createGeoObject location, siteDetails.thumbs[0], siteId, 'photoGeoObjects'
          
  getPhotosForLocation: (loc) ->
    @report "getting photos for location #{loc.latitude}, #{loc.longitude}"
    @serverRequest "site_ids_for_location/", [loc.latitude, loc.longitude, @RADIUS], (siteIds) =>
      @report "Found #{siteIds.length} images"
      for id in siteIds
        @createPhotoGeoObject id

  setupPlacemarkMode: ->
    @report "setting up placemark mode"
    @locationChangedFunc = null
    @mode = "placemark"
    if @empty(@placemarkGeoObjects)
      @requestPlacemarkData()
    @report "enabling placemarks"
    @enablePlacemarks()
    if @locationChangeSufficient()
      @updatePlacemarks
    @locationChangedFunc = @maybeUpdatePlacemarks

  requestPlacemarkData: ->
    @log "requesting placemark data"
    @request "requestplacemarkdata"
    
  setPlacemarkData: (data) ->
    @log "setting placemark data"
    @destroyPlacemarks()
    for id, details of data
      @createGeoObject details.location, details.imgUri, id, "placemarkGeoObjects"

  destroyPlacemarks: ->
    for id, placemark of @placemarkGeoObjects
      @destroyGeoObject "placemark", id

  enablePlacemarks: ->
    for id, placemark of @placemarkGeoObjects
      placemark.enabled = true

  disablePlacemarks: ->
    @report "disabling placemarks"
    for id, placemark of @placemarkGeoObjects
      @report "disabling placemark #{id}"
      placemark.enabled = false

  maybeUpdatePlacemarks: ->
    @log "conditionally updating placemarks"
    if @currentLocation.distanceTo(@lastLocation) > @RADIUS / 5
      @setLastLocation @currentLocation
      @updatePlacemarks()

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

  destroyGeoObject: (type = "photo", id) ->
    @report "destroying #{type} geoObjects"
    collection = @["#{type}GeoObjects"]
    geo = collection[id]
    for drawable in geo.drawables.cam
      delete @imgResources[drawable.imageResource.uri]
      drawable.imageResource.destroy()
      drawable.destroy()
    for location in geo.locations
      location.destroy()
    geo.destroy()
    delete collection[id]

  createGeoObject: (location, imgUri, id, collectionName) ->
    @report "creating geoObject #{id} in collection #{collectionName}::#{@reportCount++}"
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
    if @imgResources[uri] != undefined
      geoObject.enabled = true
      return @imgResources[uri]
    @report "creating imageResource for #{uri}"
    imgRes = new AR.ImageResource uri,
      onError: =>
        @log "error loading image #{uri}"
      onLoaded: =>
        unless imgRes.getHeight() is 109 and imgRes.getWidth() is 109
          @log "loaded image #{uri}"
          geoObject.enabled = true
    @imgResources[uri] = imgRes
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