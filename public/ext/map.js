var map = null;
var geocoder = null;

window.onload = function() {
    if (GBrowserIsCompatible()) {
        map = new GMap2(document.getElementById('map'));
        map.setUIToDefault();
        geocoder = new GClientGeocoder();
        showAddress(t('location') + ', ' + t('address'));
    }
};

function t(i) { return document.getElementById(i).innerHTML; }

function showAddress(address) {
    if (geocoder) {
        geocoder.getLatLng(
                           address,
                           function(point) {
                               if (point) {
                                   map.setCenter(point, 11);
                                   var marker = new GMarker(point);
                                   map.addOverlay(marker);
                               }
                           }
                           );
    }
}
