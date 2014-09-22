var eventDB = [];
var eventIDs = ['empty'];

$(document).ready(function(){

    $('table tbody tr').hide();

    //Establish socket connection
    var socket = new WebSocket('wss://localhost:4568');
    socket.onopen = function(){
        socket.send('all');
    }
    socket.onmessage = function(msg){
        console.log(msg.data);
        var json = $.parseJSON(msg.data);
        updateEventDB(json);
    }
    socket.onclose = function(){
        $('#waiting').html('<h1>Event socket closed.</h1>');
    }

    //Register kill server event handler
    $(document).on('click', '#kill', function(event){
        event.preventDefault();
        $.ajax({
            url: "/kill",
            complete: function(){
                $('#kill').parent().html("<span id='killed'>Killed.</span>");
            }
        })
        return false;
    })

    //Register target detail event handler
    $(document).on('click', 'a.node-delta-detail', function(event){
        var domEventID = $(event.target).attr('id');
        var domEvent = getDomEvent(domEventID);
        event.preventDefault();
        var dialogContainer =  $(document.createElement('div'));
        $(dialogContainer).append("<pre class='prettyprint'></pre>");
        $(dialogContainer).dialog({
            position: 'top',
            modal: true,
            width: 800,
			title: "DOM &Delta; Detail",
			show: 'fade',
			hide: 'fade',
            open: function(){
                $('pre.prettyprint').text($.trim(domEvent.target));
                prettyPrint();
            },
			close: function(){$(this).dialog('destroy').remove();}
		});
        return false;
    })

    //Register xhr response detail event handler
    $(document).on('click', 'a.xhr-response-detail', function(event){
        var domEventID = $(event.target).attr('id');
        var domEvent = getDomEvent(domEventID);
        event.preventDefault();
        var dialogContainer =  $(document.createElement('div'));
        $(dialogContainer).append("<pre class='prettyprint'></pre>");
        $(dialogContainer).dialog({
            position: 'top',
            modal: true,
            width: 800,
			title: "XHR Response Detail",
			show: 'fade',
			hide: 'fade',
            open: function(){
                $('pre.prettyprint').text($.trim(domEvent.response));
                prettyPrint();
            },
			close: function(){$(this).dialog('destroy').remove();}
		});
        return false;
    })

    //Register js error detail event handler
    $(document).on('click', 'a.js-error-detail', function(event){
        var domEventID = $(event.target).attr('id');
        var domEvent = getDomEvent(domEventID);
        event.preventDefault();
        var dialogContainer =  $(document.createElement('div'));
        $(dialogContainer).append("<pre class='prettyprint'></pre>");
        $(dialogContainer).dialog({
            position: 'top',
            modal: true,
            width: 800,
			title: "XHR Response Detail",
			show: 'fade',
			hide: 'fade',
            open: function(){
                var errorDetail = "Script: " + domEvent.target + "\n";
                errorDetail += "Line Number: " + domEvent.errorLineNumber + "\n";
                errorDetail += "Error Message: " + domEvent.errorMessage;
                $('pre.prettyprint').text(errorDetail);
                prettyPrint();
            },
			close: function(){$(this).dialog('destroy').remove();}
		});
        return false;
    })

});

function updateEventDB(json) {
    if(eventDB == []){
        eventDB = json;
        updateEventIDs(eventDB);
        $.each(eventDB, function(index, event){
            addEventTableRow(event);
        });
    }
    else {
        for(i=0; i < json.length; i++){
            if($.inArray(json[i], eventDB) == -1){
                eventDB.push(json[i]);
                eventIDs.push(json[i].test_id);
                addEventTableRow(json[i]);
            }
        }
    }
}

function updateEventIDs(json) {
    for(i=0; i < json.length; i++){
        eventIDs.push(json[i].test_id);
    }
}

function addEventTableRow(event){
    var eventTable = $('table tr:last');
    var target = "..pending";
    var domDelta = getNodeCount(event.target);
    var eventType = event.type.substr(0,3) == 'xhr' ? 'xhr' : event.type;
    switch(eventType){
        case "click":
            target = event.target;
            domDelta = 0;
            break;
        case "js-error":
            target = "<a href='#' class='js-error-detail' id='" + event.id + "'>Show JavaScript Error</a>";
            domDelta = 0;
            break;
        case "keydown":
            target = event.target;
            domDelta = 0;
            break;
        case "keyup":
            target = event.target;
            domDelta = 0;
            break;
        case "xhr":
            target = "<span class='xhr-method'>" + event.method + "</span>: " + event.target;
            target = typeof(event.response) == 'undefined' ? target : target + "<br/>" +"<a href='#' class='xhr-response-detail' id='" + event.id + "'>Show Response</a>";
            domDelta = 0;
            break;
        case "DOMNodeInserted":
            target = "<a href='#' class='node-delta-detail' id='" + event.id + "'>Show Added Nodes</a>";
            domDelta = "+" + domDelta;
            break;
        case "DOMNodeRemoved":
            target = "<a href='#' class='node-delta-detail' id='" + event.id + "'>Show Removed Nodes</a>";
            domDelta = "-" + domDelta;
            break;
        default:
            target = "Target type not found.";
    }

    var newRow = "<tr><td class=\"timestamp\">" + event.time +
        "</td><td><div class=\"cell event " + eventType +  "\">" + event.type +
        "</div></td><td><div class=\"cell target\">" + target +
        "</div></td><td><div class=\"cell dom\">"+ domDelta + "</div></td></tr>";
    eventTable.after($(newRow).hide().fadeIn('slow').css('display', 'table-row'));
}

function getDomEvent(eventID){
    var desiredEvent = null;
    for(var i=0; i < eventDB.length; i++){
        if(eventDB[i].id == eventID){
            desiredEvent = eventDB[i];
            break;
        }
    }
    return desiredEvent;
}

function getNodeCount(xmlString){
    var nodeCount = 1;
    try{
        var $xml = $(xmlString);
        nodeCount += $xml.find('*').filter(function(){return $(this).children().length === 0;}).length;
    }
    catch(e){
        console.log("Node counting error.\n");
        console.log(e);
    }
    return nodeCount;
}