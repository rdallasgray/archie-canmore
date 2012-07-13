// Generated by CoffeeScript 1.3.3
(function(){var e,t;t=typeof exports!="undefined"&&exports!==null?exports:this,e=function(){function e(e){this.canmoreRequestUrl=e||this.CANMORE_REQUEST_URL,this.lastLocation=new AR.GeoLocation(0,0,0),this.currentLocation=new AR.GeoLocation(0,0,0),this.photoGeoObjects={},this.placemarkGeoObjects={},this.locationChangedFunc=null,this.mode=null}return e.prototype.CANMORE_REQUEST_URL="/",e.prototype.TEST_LOCATION=[55.8791,-4.2788,59],e.prototype.LAT_METERS=1e5,e.prototype.LONG_METERS=7e4,e.prototype.RADIUS=500,e.prototype.DEFAULT_HEIGHT_SDU=4.5,e.prototype.DISTANCE_SCALE_FACTOR=1.75,e.prototype.MIN_SCALING_DISTANCE=50,e.prototype.OFFSET_Y_RANDOM_FACTOR=3,e.prototype.log=function(e){return $("#status").html("<p>"+e+"</p>")},e.prototype.setLocation=function(e,t,n,r){var i;return i=[t,n,r],e.latitude=i[0],e.longitude=i[1],e.altitude=i[2],i},e.prototype.setLastLocation=function(e){return this.setLocation(this.lastLocation,e.latitude,e.longitude,e.altitude)},e.prototype.locationChanged=function(e,t,n,r){this.log("changing location to "+[e,t].join(", ")),this.setLocation(this.currentLocation,e,t,n);if(this.locationChangedFunc!==null)return this.locationChangedFunc()},e.prototype.setMode=function(e,t){t==null&&(t=null),this.log("setting mode "+e);if(e===this.mode)return;return e==="photo"?this.setupPhotoMode():this.setupPlacemarkMode(t)},e.prototype.setupPhotoMode=function(){return this.locationChangedFunc=null,this.mode="photo",this.disablePlacemarks,this.cleanUpPhotos,this.enablePhotos,this.locationChangedFunc=this.maybeUpdatePhotos},e.prototype.maybeUpdatePhotos=function(){this.log("conditionally updating photos");if(this.currentLocation.distanceTo(this.lastLocation)>this.RADIUS/5)return this.setLastLocation(this.currentLocation),this.cleanUpPhotos,this.updatePhotos()},e.prototype.enablePhotos=function(){var e,t,n,r;this.log("enabling photos"),n=this.photoGeoObjects,r=[];for(e in n)t=n[e],r.push(t.enabled=!0);return r},e.prototype.updatePhotos=function(){return this.log("updating photos"),this.getPhotosForLocation(this.currentLocation)},e.prototype.cleanUpPhotos=function(){var e,t,n,r,i,s;this.log("cleaning up photos"),i=this.photoGeoObjects,s=[];for(n in i)r=i[n],e=this.currentLocation.distanceTo(r.locations[0]),this.log("Object "+n+" is "+e+"m away"),e>this.RADIUS?(this.log("Destroying object "+n),s.push(this.destroyGeoObject("photo",n))):(this.log("Resetting opacity and scale on object "+n),s.push(function(){var n,i,s,o;s=r.drawables.cam,o=[];for(n=0,i=s.length;n<i;n++)t=s[n],o.push(this.setOpacityAndScaleOnDrawable(t,e));return o}.call(this)));return s},e.prototype.createPhotoGeoObject=function(e){var t=this;this.log("creating photoGeoObject for id "+e);if(!this.photoGeoObjects[e])return this.serverRequest("details_for_site_id/",[e],function(n){var r;return t.log("creating geoObject with loc "+n.lat+", "+n.long+": "+n.thumbs[0]),r={lat:n.lat,"long":n.long,alt:t.currentLocation.altitude},t.createGeoObject(r,n.thumbs[0],e,"photoGeoObjects")})},e.prototype.getPhotosForLocation=function(e){var t=this;return this.log("getting photos for location "+e.latitude+", "+e.longitude),this.serverRequest("site_ids_for_location/",[e.latitude,e.longitude,this.RADIUS],function(e){var n,r,i,s;t.log("Found "+e.length+" images"),s=[];for(r=0,i=e.length;r<i;r++)n=e[r],s.push(t.createPhotoGeoObject(n));return s})},e.prototype.setupPlacemarkMode=function(){return this.locationChangedFunc=null,this.mode="placemark",this.empty(this.placemarkGeoObjects)&&this.requestPlacemarkData(),this.enablePlacemarks(),this.locationChangedFunc=this.maybeUpdatePlacemarks},e.prototype.requestPlacemarkData=function(){return this.log("requesting placemark data"),document.location="architectsdk://requestplacemarkdata"},e.prototype.setPlacemarkData=function(e){var t,n,r,i;this.log("setting placemark data"),t=0,this.destroyPlacemarks,i=[];for(r in e)n=e[r],t++,this.log(t),i.push(this.createGeoObject(n.location,n.imgUri,r,"placemarkGeoObjects"));return i},e.prototype.destroyPlacemarks=function(){var e,t,n,r;n=this.placemarkGeoObjects,r=[];for(e in n)t=n[e],r.push(destroyGeoObject("placemark",e));return r},e.prototype.enablePlacemarks=function(){var e,t,n,r;n=this.placemarkGeoObjects,r=[];for(e in n)t=n[e],r.push(t.enabled=!0);return r},e.prototype.disablePlacemarks=function(){var e,t,n,r;n=this.placemarkGeoObjects,r=[];for(e in n)t=n[e],r.push(t.enabled=!1);return r},e.prototype.maybeUpdatePlacemarks=function(){this.log("conditionally updating placemarks");if(this.currentLocation.distanceTo(this.lastLocation)>this.RADIUS/5)return this.setLastLocation(this.currentLocation),this.updatePlacemarks},e.prototype.updatePlacemarks=function(){var e,t,n,r,i,s;this.log("updating placemarks"),i=this.placemarkGeoObjects,s=[];for(n in i)r=i[n],e=this.currentLocation.distanceTo(r.locations[0]),this.log("object "+n+" is "+e+"m away"),this.log("resetting opacity and scale on object "+n),s.push(function(){var n,i,s,o;s=r.drawables.cam,o=[];for(n=0,i=s.length;n<i;n++)t=s[n],o.push(this.setOpacityAndScaleOnDrawable(t,e));return o}.call(this));return s},e.prototype.setOpacityAndScaleOnDrawable=function(e,t){var n,r,i;return i=this.MIN_SCALING_DISTANCE/(t/this.DISTANCE_SCALE_FACTOR),r=Math.min(1,i),n=Math.min(1,i),e.scale=r,e.opacity=n},e.prototype.destroyGeoObject=function(e,t){var n,r,i,s,o,u,a,f,l,c;e==null&&(e="photo"),n=this[""+e+"GeoObjects"],i=n[t],l=i.drawables.cam;for(o=0,a=l.length;o<a;o++)r=l[o],r.imageResource.destroy(),r.destroy();c=i.locations;for(u=0,f=c.length;u<f;u++)s=c[u],s.destroy();return i.destroy(),delete n[t]},e.prototype.createGeoObject=function(e,t,n,r){var i,s,o,u,a,f,l=this;return this.log("creating geoObject "+n+" in collection "+r),i=this[r],e=new AR.GeoLocation(e.lat,e.long,e.alt),s=this.currentLocation.distanceTo(e),u={offsetY:Math.random()*this.OFFSET_Y_RANDOM_FACTOR-this.OFFSET_Y_RANDOM_FACTOR/2,enabled:!0},a=new AR.GeoObject(e,{enabled:!1}),f=this.createImageResource(t,a),o=this.createImageDrawable(f,u),o.triggers.onClick=function(){return l.objectWasClicked(n,r)},this.setOpacityAndScaleOnDrawable(o,s),a.drawables.addCamDrawable(o),i[n]=a},e.prototype.objectWasClicked=function(e,t){return this.log("clicked "+e+", "+t),document.location="architectsdk://clickedobject?id="+e+"&collection="+t},e.prototype.createImageResource=function(e,t){var n,r=this;return this.log("creating imageResource for "+e),n=new AR.ImageResource(e,{onError:function(){return r.log("error loading image "+e)},onLoaded:function(){if(n.getHeight()!==109||n.getWidth()!==109)return r.log("loaded image "+e),t.enabled=!0}}),n},e.prototype.createImageDrawable=function(e,t){return new AR.ImageDrawable(e,this.DEFAULT_HEIGHT_SDU,t)},e.prototype.serverRequest=function(e,t,n){var r;return t||(t=[]),r=this.canmoreRequestUrl+e+t.join("/")+"?callback=?",$.getJSON(r,function(e){return n(e)})},e.prototype.empty=function(e){var t,n;for(t in e)return n=e[t],!1;return!0},e}(),t.Canmore={Architect:e},$(function(){return Canmore.archie=new Canmore.Architect("http://glowing-moon-5208.heroku.com/archie-canmore.html"),AR.context.onLocationChanged=function(e,t,n,r){return Canmore.archie.locationChanged(e,t,n,r)},Canmore.archie.setMode("placemark")})}).call(this)