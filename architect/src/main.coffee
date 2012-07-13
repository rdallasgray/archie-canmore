$ ->
  Canmore.archie = new Canmore.Architect("http://glowing-moon-5208.heroku.com/archie-canmore.html")
  AR.context.onLocationChanged = (lat, long, alt, acc) -> Canmore.archie.locationChanged(lat, long, alt, acc)
  Canmore.archie.setMode("placemark")
  