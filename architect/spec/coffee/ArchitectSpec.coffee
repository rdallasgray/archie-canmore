mockRels = [123456, 789101, 121314]

mockDetails =
  lat: 55.8791,
  long: -4.2787,
  thumb_link: "test.jpg"

window.$ = ->
  html:(msg) -> console.log msg

window.$.getJSON = (url, func) ->
  if /details_for_site_id/.test url then data = mockDetails
  else data = mockRels
  func(data)

window.AR =
  GeoLocation: (lat, long, alt) ->
    latitude: lat
    longitude: long
    altitude: alt
    distanceTo: (loc) -> 1000
    destroy: -> @destroyed = true
  GeoObject: (loc, options) ->
    locations: [loc]
    destroy: -> @destroyed = true
    drawables:
      cam: []
      addCamDrawable: (d) ->
        @cam.push d
  ImageResource: (uri, callbacks) ->
    uri: uri
    callbacks: callbacks
    getHeight: -> 10
    getWidth: -> 10
    destroy: -> @destroyed = true
  ImageDrawable: (imgRes, height, options) ->
    imageResource: imgRes
    height: height
    options: options
    destroy: -> @destroyed = true
    

a = null
        
describe "Canmore.Architect", ->
  beforeEach ->
    a = new Canmore.Architect

  it "sets up current and last location", ->
    expect(a.currentLocation.latitude).toEqual 0
    expect(a.lastLocation.longitude).toEqual 0

  it "sets the default canmore url", ->
    expect(a.canmoreRequestUrl).toBe "/"
    
  it "sets up a GeoLocation", ->
    l = new AR.GeoLocation(10, 20, 30, 5)
    a.setLocation(l, 90, 80, 70, 3)
    expect(l.latitude).toBe(90)
    
  it "sets the last location", ->
    l = new AR.GeoLocation(10, 20, 30, 5)
    a.setLastLocation l
    expect(a.lastLocation.latitude).toBe(l.latitude)

  it "creates imageResources", ->
    geoObject = new AR.GeoObject(new AR.GeoLocation(1, 2, 3, 4), { test: "test" })
    res = a.createImageResource(mockDetails.thumb_link, geoObject)
    expect(res.uri).toBe(mockDetails.thumb_link)
    res.callbacks.onLoaded()
    expect(geoObject.enabled).toBe(true)

  it "creates ImageDrawables", ->
    geoObject = new AR.GeoObject(new AR.GeoLocation(1, 2, 3, 4), { test: "test" })    
    res = a.createImageResource(mockDetails.thumb_link, geoObject)
    d = a.createImageDrawable(res, { test: "test"})
    expect(d.height).toBe(4.5)
  
  it "creates GeoObjects", ->
    spyOn(a, 'serverRequest').andCallThrough()
    spyOn(a, 'createImageDrawable').andCallThrough()
    spyOn(a, 'createImageResource').andCallThrough()
    a.createGeoObject(mockRels[0])
    expect(a.serverRequest).toHaveBeenCalled()
    expect(a.createImageResource).toHaveBeenCalled()
    expect(a.createImageDrawable).toHaveBeenCalled()
    expect(a.geoObjects[mockRels[0]].drawables.cam[0].imageResource.uri).toBe(mockDetails.thumb_link)

  it "destroys GeoObjects", ->
    a.createGeoObject(mockRels[0])
    o = a.geoObjects[mockRels[0]]
    spyOn(o, 'destroy')
    spyOn(o.locations[0], 'destroy')
    spyOn(o.drawables.cam[0], 'destroy')
    spyOn(o.drawables.cam[0].imageResource, 'destroy')
    a.destroyGeoObject mockRels[0]
    expect(o.destroy).toHaveBeenCalled()
    expect(o.locations[0].destroy).toHaveBeenCalled()
    expect(o.drawables.cam[0].destroy).toHaveBeenCalled()
    expect(o.drawables.cam[0].imageResource.destroy).toHaveBeenCalled()
    expect(a.geoObjects[mockRels[0]]).toBe undefined

  it "sets scale and opacity on drawables", ->
    geoObject = new AR.GeoObject(new AR.GeoLocation(1, 2, 3, 4), { test: "test" })    
    res = a.createImageResource(mockDetails.thumb_link, geoObject)
    d = a.createImageDrawable(res, { test: "test"})
    a.setOpacityAndScaleOnDrawable(d, 1000)
    expect(d.scale).toEqual(a.MIN_SCALING_DISTANCE / (1000 / a.DISTANCE_SCALE_FACTOR))
    expect(d.opacity).toEqual(a.MIN_SCALING_DISTANCE / (1000 / a.DISTANCE_SCALE_FACTOR))    

  it "cleans up images", ->
    spyOn(a, 'destroyGeoObject').andCallThrough()
    a.createGeoObject(mockRels[0])
    a.cleanUpImages()
    expect(a.destroyGeoObject).toHaveBeenCalled()
    expect(a.geoObjects).toEqual({})

  it "sets the last location on a location change", ->
    a.locationChanged(55, -4, 0, 3)
    expect(a.lastLocation.latitude).toEqual(55)

  it "updates images on a valid location change", ->
    spyOn(a, 'updateImages').andCallThrough()
    a.locationChanged(55, -4, 0, 3)
    expect(a.updateImages).toHaveBeenCalled()
    expect(a.geoObjects[mockRels[0]].locations[0].latitude).toEqual(mockDetails.lat)