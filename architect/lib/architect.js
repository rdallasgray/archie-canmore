// Generated by CoffeeScript 1.3.3
(function() {
  var Architect, root;

  root = typeof exports !== "undefined" && exports !== null ? exports : this;

  Architect = (function() {

    Architect.prototype.CANMORE_REQUEST_URL = '/';

    Architect.prototype.TEST_LOCATION = [55.8791, -4.2788, 59];

    Architect.prototype.LAT_METERS = 100000;

    Architect.prototype.LONG_METERS = 70000;

    Architect.prototype.RADIUS = 500;

    Architect.prototype.DEFAULT_HEIGHT_SDU = 4.5;

    Architect.prototype.DISTANCE_SCALE_FACTOR = 1.75;

    Architect.prototype.MIN_SCALING_DISTANCE = 100;

    Architect.prototype.OFFSET_Y_RANDOM_FACTOR = 3;

    function Architect(canmoreRequestUrl) {
      this.canmoreRequestUrl = canmoreRequestUrl || this.CANMORE_REQUEST_URL;
      this.lastLocation = new AR.GeoLocation(0, 0, 0);
      this.currentLocation = new AR.GeoLocation(0, 0, 0);
      this.geoObjects = {};
      this.ARLoggerActivated = false;
    }

    Architect.prototype.log = function(msg) {
      var html;
      html = $("#status").html();
      return $("#status").html(html + ("<p>" + msg + "</p>"));
    };

    Architect.prototype.setLocation = function(loc, lat, long, alt) {
      var _ref;
      return _ref = [lat, long, alt], loc.latitude = _ref[0], loc.longitude = _ref[1], loc.altitude = _ref[2], _ref;
    };

    Architect.prototype.setLastLocation = function(loc) {
      return this.setLocation(this.lastLocation, loc.latitude, loc.longitude, loc.altitude);
    };

    Architect.prototype.locationChanged = function(lat, long, alt, acc) {
      this.log("changing location to " + [lat, long].join(", "));
      this.setLocation(this.currentLocation, lat, long, alt);
      if (this.currentLocation.distanceTo(this.lastLocation) > this.RADIUS / 5) {
        this.setLastLocation(this.currentLocation);
        return this.updateImages();
      }
    };

    Architect.prototype.updateImages = function() {
      this.cleanUpImages();
      return this.getImagesForLocation(this.currentLocation);
    };

    Architect.prototype.cleanUpImages = function() {
      var distance, drawable, id, item, _ref, _results;
      this.log("Cleaning up images");
      _ref = this.geoObjects;
      _results = [];
      for (id in _ref) {
        item = _ref[id];
        distance = this.currentLocation.distanceTo(item.locations[0]);
        this.log("Object " + id + " is " + distance + "m away");
        if (distance > this.RADIUS / 2) {
          this.log("Destroying object " + id);
          _results.push(this.destroyGeoObject(id));
        } else {
          this.log("Resetting opacity and scale on object " + id);
          _results.push((function() {
            var _i, _len, _ref1, _results1;
            _ref1 = item.drawables.cam;
            _results1 = [];
            for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
              drawable = _ref1[_i];
              _results1.push(this.setOpacityAndScaleOnDrawable(drawable, distance));
            }
            return _results1;
          }).call(this));
        }
      }
      return _results;
    };

    Architect.prototype.setOpacityAndScaleOnDrawable = function(drawable, distance) {
      var opacity, scale, scalingFactor;
      scalingFactor = this.MIN_SCALING_DISTANCE / (distance / this.DISTANCE_SCALE_FACTOR);
      scale = Math.min(1, scalingFactor);
      opacity = Math.min(1, scalingFactor);
      drawable.scale = scale;
      return drawable.opacity = opacity;
    };

    Architect.prototype.destroyGeoObject = function(id) {
      var drawable, geo, location, _i, _j, _len, _len1, _ref, _ref1;
      geo = this.geoObjects[id];
      _ref = geo.drawables.cam;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        drawable = _ref[_i];
        drawable.imageResource.destroy();
        drawable.destroy();
      }
      _ref1 = geo.locations;
      for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
        location = _ref1[_j];
        location.destroy();
      }
      geo.destroy();
      return delete this.geoObjects[id];
    };

    Architect.prototype.createGeoObject = function(siteId) {
      var _this = this;
      if (!this.geoObjects[siteId]) {
        return this.serverRequest("details_for_site_id/", [siteId], function(siteDetails) {
          var distance, drawable, drawableOptions, imgRes, location;
          location = new AR.GeoLocation(siteDetails.lat, siteDetails.long, _this.currentLocation.altitude);
          distance = _this.currentLocation.distanceTo(location);
          drawableOptions = {
            offsetY: (Math.random() * _this.OFFSET_Y_RANDOM_FACTOR) - _this.OFFSET_Y_RANDOM_FACTOR / 2,
            enabled: true
          };
          _this.geoObjects[siteId] = new AR.GeoObject(location, {
            enabled: false
          });
          imgRes = _this.createImageResource(siteDetails.thumbs[0], _this.geoObjects[siteId]);
          drawable = _this.createImageDrawable(imgRes, drawableOptions);
          _this.setOpacityAndScaleOnDrawable(drawable, distance);
          return _this.geoObjects[siteId].drawables.addCamDrawable(drawable);
        });
      }
    };

    Architect.prototype.createImageResource = function(uri, geoObject) {
      var imgRes,
        _this = this;
      imgRes = new AR.ImageResource(uri, {
        onError: function() {
          return _this.log("Error loading image " + uri);
        },
        onLoaded: function() {
          _this.log("Loaded image " + uri);
          if (!(imgRes.getHeight() === 109 && imgRes.getWidth() === 109)) {
            return geoObject.enabled = true;
          }
        }
      });
      return imgRes;
    };

    Architect.prototype.createImageDrawable = function(imgRes, options) {
      return new AR.ImageDrawable(imgRes, this.DEFAULT_HEIGHT_SDU, options);
    };

    Architect.prototype.serverRequest = function(url, params, callback) {
      var requestUrl;
      params || (params = []);
      requestUrl = this.canmoreRequestUrl + url + params.join('/') + '?callback=?';
      return $.getJSON(requestUrl, function(data) {
        return callback(data);
      });
    };

    Architect.prototype.getImagesForLocation = function(loc, func) {
      var _this = this;
      return this.serverRequest("site_ids_for_location/", [loc.latitude, loc.longitude, this.RADIUS], function(items) {
        var item, _i, _len, _results;
        _this.log("Found " + items.length + " images");
        _results = [];
        for (_i = 0, _len = items.length; _i < _len; _i++) {
          item = items[_i];
          _results.push(_this.createGeoObject(item));
        }
        return _results;
      });
    };

    return Architect;

  })();

  root.Canmore = {
    Architect: Architect
  };

}).call(this);
