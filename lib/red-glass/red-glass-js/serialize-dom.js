var rgUtils = {};
var uniqueIds = [];
rgUtils.query = jQuery.noConflict();
rgUtils.toInt = function(n){ return Math.round(Number(n)); };
rgUtils.hasText = function($thing){
    var isTxt = true;
    if($thing.text() == ""){
        isTxt = false;
    }
    return isTxt;
};
rgUtils.isVisible = function($thing) { return $thing.is(':visible'); };

function RecurseDomJSON($item, domJSON) {
    $item.each(function() {
        try{
            domJSON += '{"tagName":' + '"' + rgUtils.query(this).get(0).tagName + '"' + ',' + '"id":' + '"' +
                rgUtils.query(this).attr("id") + '"' + ',' + '"top":' + '"' + rgUtils.toInt(rgUtils.query(this).offset().top) + '"' +
                ',' + '"left":' + '"' + rgUtils.toInt(rgUtils.query(this).offset().left) + '"' +
                ',' + '"xpath":' + '"' + rgUtils.query(this).ellocate(uniqueIds).xpath + '"' +
                ',' + '"width":' + '"' + rgUtils.toInt(rgUtils.query(this).width()) + '"' +
                ',' + '"height":' + '"' + rgUtils.toInt(rgUtils.query(this).height()) + '"' +
                ',' + '"isVisible":' + '"' + rgUtils.isVisible(rgUtils.query(this)) + '"' +
                ',' + '"hasText":' + '"' + rgUtils.hasText(rgUtils.query(this)) +'"},\n\t' ;
        }
        catch(err){  } // Perhaps errors could be thrown in a configurable "strict" mode.
    });
    uniqueIds = [];
    return domJSON;
}