(function($) {
    $.fn.redGlass = function(testID, port) {
        port = typeof port == 'undefined' ? '4567' : port;
        var rg = {
            handleInteractionEvent: function(e){
                var eventData = {};
                eventData.id = '';
                eventData.url = window.location.pathname;
                eventData.testID = testID;
                eventData.time = new Date().getTime();
                var desiredProperties = ['type', 'pageX', 'pageY'];
                $.each(desiredProperties, function(index, property){
                    eventData[property] = e[property];
                })
                eventData.target = $(e.target).getPath();
                rg.sendEvent(JSON.stringify(eventData));
            },
            handleMutationEvent: function(e){
                var eventData = {};
                eventData.id = '';
                eventData.url = window.location.pathname;
                eventData.testID = testID;
                eventData.time = new Date().getTime();
                eventData.type = e.type;
                eventData.target = e.target.innerHTML;
                //rg.sendEvent(JSON.stringify(eventData), e.target.innerHTML);
                rg.sendEvent(JSON.stringify(eventData));
            },
            handleXHREvent: function(event){
                var eventData = {};
                eventData.id = '';
                eventData.url = window.location.pathname;
                eventData.testID = testID;
                eventData.time = new Date().getTime();
                eventData.type = event.type;
                eventData.target = event.url;
                eventData.method = event.method;
                switch(event.type){
                    case "xhr: Response returned":
                    eventData.response = event.response;
                    break;
                }
                rg.sendEvent(JSON.stringify(eventData));
            },
            handleErrorEvent: function(event){
                var eventData = {};
                eventData.id = '';
                eventData.url = window.location.pathname;
                eventData.testID = testID;
                eventData.time = new Date().getTime();
                eventData.type = event.type;
                eventData.target = event.errorUrl;
                eventData.errorMessage = event.errorMessage;
                eventData.errorLineNumber = event.errorLineNumber;
                rg.sendEvent(JSON.stringify(eventData));
            },
            sendEvent: function(eventData){
                var formData = new FormData();
                formData.append("event_json", eventData);
                var request = new XMLHttpRequest();
                request.open('POST', "http://localhost:" + port, true);
                request.send(formData);

                /*
                Old versions of jQuery would return a 404 from the request below,
                so we must use the plain xhr above.
                $.ajax({
                    url: "http://localhost:" + port,
                    type: "POST",
                    data: {event_json: eventData}
                })
                */
            }
        }

        //Interaction events
        this.bind("click keydown keyup", rg.handleInteractionEvent);

        //DOM mutation events
        this.bind('DOMNodeInserted DOMNodeRemoved', rg.handleMutationEvent);

        //XHR events
        (function() {
            //Create proxy to the native method
            var nativeOpen = XMLHttpRequest.prototype.open;

            //Overwrite native open method
            XMLHttpRequest.prototype.open = function(method, url, async, user, pass) {
                //Handle readyState changes
                this.addEventListener("readystatechange", function() {
                    if(url != "http://localhost:" + port){
                        var eventData = {};
                        eventData.method = method;
                        var readyStateDesc = '';
                        switch(parseInt(this.readyState)){
                            case 0:
                                readyStateDesc = 'Initializing';
                                break;
                            case 1:
                                readyStateDesc = 'Connected';
                                break;
                            case 2:
                                readyStateDesc = 'Request received';
                                break;
                            case 3:
                                readyStateDesc = 'Processing request';
                                break;
                            case 4:
                                readyStateDesc = 'Response returned';
                                eventData.response = this.responseText;
                                break;
                        }
                        eventData.type = 'xhr: ' + readyStateDesc;
                        eventData.url = url;
                        rg.handleXHREvent(eventData);
                    }
                }, false);

                //Call native open method
                nativeOpen.call(this, method, url, async, user, pass);
            };
        })();

        //Error events
        window.onerror = function(message, url, lineNumber) {
            var eventData = {};
            eventData.type = "js-error";
            eventData.errorMessage = message;
            eventData.errorUrl = url;
            eventData.errorLineNumber = lineNumber;
            rg.handleErrorEvent(eventData);
            return false;
        };

        return this;
    };
})(jQuery);