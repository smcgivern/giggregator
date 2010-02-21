var map = null;
var geocoder = null;

window.onload = attachMap;

function e(i) { return document.getElementById(i); }
function t(e) { return e.innerHTML; }

function attachMap() {
    if (google.maps.BrowserIsCompatible()) {
        map = new google.maps.Map2(e('map'));
        map.setUIToDefault();
        geocoder = new google.maps.ClientGeocoder();
        if (e('address')) {
            addMarker(t(e('location')) + ', ' + t(e('address')));
        } else {

        }
    }
};

function addMarker(address) {
    if (geocoder) {
		var callback = function(point) {
            if (point) {
                map.setCenter(point, 11);
                var marker = new google.maps.Marker(point);
                map.addOverlay(marker);
            }
        };

        geocoder.getLatLng(address, callback);
    }
}
