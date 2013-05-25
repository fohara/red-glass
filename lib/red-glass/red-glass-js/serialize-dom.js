var domgun = {}; domgun.query = jQuery.noConflict();
var uniqueIds = [];

function toInt(n){ return Math.round(Number(n)); };

function isUniqueId(id, idArray){
    return domgun.query.inArray(id, idArray) == -1 ? true : false;
}

function getPath($thing)
{
    elt = $thing[0];
    var path = '';
    for (; elt && elt.nodeType == 1; elt = elt.parentNode)
    {
        var idx = domgun.query(elt.parentNode).children(elt.tagName).index(elt) + 1;
        if(elt.tagName.substring(0,1) != "/"){//Internet explorer oddity- some tagnames can begin with backslash.
            if(elt.id != 'undefined' && elt.id !='' && isUniqueId(elt.id, uniqueIds)){
                uniqueIds.push(elt.id);
                idPath="[@id=" + "'" + elt.id + "'" + "]";
                path = '/' + elt.tagName.toLowerCase() + idPath + path;
            }
            else{
                idx='[' + idx + ']';
                path = '/' + elt.tagName.toLowerCase() + idx + path;
            }
        }
    }
    return path;
}

function hasText($thing){
    var isTxt = true;
    if($thing.text() == ""){
        isTxt = false;
    }
    return isTxt;
}

function isVisible($thing) {
    return $thing.is(':visible');
}

function RecurseDomJSON($item, domJSON) {
    $item.each(function() {
        try{
            domJSON += '{"tagName":' + '"' + domgun.query(this).get(0).tagName + '"' + ',' + '"id":' + '"' +
                domgun.query(this).attr("id") + '"' + ',' + '"top":' + '"' + toInt(domgun.query(this).offset().top) + '"' +
                ',' + '"left":' + '"' + toInt(domgun.query(this).offset().left) + '"' +
                ',' + '"xpath":' + '"' + getPath(domgun.query(this)) + '"' +
                ',' + '"width":' + '"' + toInt(domgun.query(this).width()) + '"' +
                ',' + '"height":' + '"' + toInt(domgun.query(this).height()) + '"' +
                ',' + '"isVisible":' + '"' + isVisible(domgun.query(this)) + '"' +
                ',' + '"hasText":' + '"' + hasText(domgun.query(this)) +'"},\n\t' ;
        }
        catch(err){

        }
    });
    uniqueIds = [];
    return domJSON;
}