Canmore.archie = new Canmore.Architect
$ ->
  AR.context.onLocationChanged = (lat, long, alt, acc) -> Canmore.archie.locationChanged(lat, long, alt, acc)
  Canmore.archie.setMode 'placemark'

lat = 55.8891
long = -4.2887
timesToChange = 2
changeLocation = ->
  unless timesToChange < 1
    timesToChange--
    lat = lat - 0.001
    long = long - 0.001
    Canmore.archie.locationChanged lat, long, 0, 3
changeLocation()
setInterval changeLocation, 5000