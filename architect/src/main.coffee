Canmore.archie = new Canmore.Architect
$ -> AR.context.onLocationChanged = (lat, long, alt, acc) -> Canmore.archie.locationChanged(lat, long, alt, acc)
