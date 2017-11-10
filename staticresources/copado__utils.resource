var Base64 = {
    _keyStr: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=",
    _MINSIZEFORBTOA: 10485760, // minimum size to siwtch to BOTA/ATOB native functions ( 200x faster, but not unicode-friendly )
    encode: function(c) {
        console.debug('Base64.encode.length', c.length, c.length > Base64._MINSIZEFORBTOA ? 'using btoa' : 'using unicode-safe');

        // NR: there is  issue in btoa/atob: https://developer.mozilla.org/en/docs/Web/API/WindowBase64/Base64_encoding_and_decoding
        // the std solution is too slow, so the fallback is the original code.
        // NR: btoa/atob sometimes fails, but silently, so, we get mangled characters... so, alternative: over 10mb of attachment, switch to native, otherwise, local
        try {
            if (c.length > Base64._MINSIZEFORBTOA)
                return window.btoa(c);
        } catch (e) {
            console.debug('btoa did not work. Falling back to Base64.encode because', e);
        }

        var a = "",
            d, b, f, g, h, e, j = 0;
        for (c = Base64._utf8_encode(c); j < c.length;) d = c.charCodeAt(j++), b = c.charCodeAt(j++), f = c.charCodeAt(j++), g = d >> 2, d = (d & 3) << 4 | b >> 4, h = (b & 15) << 2 | f >> 6, e = f & 63, isNaN(b) ? h = e = 64 : isNaN(f) && (e = 64), a = a + this._keyStr.charAt(g) + this._keyStr.charAt(d) + this._keyStr.charAt(h) + this._keyStr.charAt(e);
        return a
    },
    decode: function(c) {
        console.debug('Base64.decode.length', c.length, c.length > Base64._MINSIZEFORBTOA ? 'using atob' : 'using unicode-safe');

        // NR: there is  issue in btoa/atob: https://developer.mozilla.org/en/docs/Web/API/WindowBase64/Base64_encoding_and_decoding
        // the std solution is too slow, so the fallback is the original code.
        // NR: btoa/atob sometimes fails, but silently, so, we get mangled characters... so, alternative: over 10mb of attachment, switch to native, otherwise, local
        try {
            if (c.length > Base64._MINSIZEFORBTOA)
                return window.atob(c);
        } catch (e) {
            console.debug('atob did not work. Falling back to Base64.encode because', e);
        }

        var a = "",
            d, b, f, g, h, e = 0;
        for (c = c.replace(/[^A-Za-z0-9\+\/\=]/g, ""); e < c.length;) d = this._keyStr.indexOf(c.charAt(e++)), b = this._keyStr.indexOf(c.charAt(e++)), g = this._keyStr.indexOf(c.charAt(e++)), h = this._keyStr.indexOf(c.charAt(e++)), d = d << 2 | b >> 4, b = (b & 15) << 4 | g >> 2, f = (g & 3) << 6 | h, a += String.fromCharCode(d), 64 != g && (a += String.fromCharCode(b)), 64 != h && (a += String.fromCharCode(f));
        a = Base64._utf8_decode(a);
        return a;
    },
    _utf8_encode: function(c) {
        c = c.replace(/\r\n/g, "\n");
        for (var a = "", d = 0; d < c.length; d++) {
            var b = c.charCodeAt(d);
            128 > b ? a += String.fromCharCode(b) : (127 < b && 2048 > b ? a += String.fromCharCode(b >> 6 | 192) : (a += String.fromCharCode(b >> 12 | 224), a += String.fromCharCode(b >> 6 & 63 | 128)), a += String.fromCharCode(b & 63 | 128))
        }
        return a
    },
    _utf8_decode: function(c) {
        for (var a = "", d = 0, b = c1 = c2 = 0; d < c.length;) b = c.charCodeAt(d), 128 > b ? (a += String.fromCharCode(b), d++) : 191 < b && 224 > b ? (c2 = c.charCodeAt(d + 1), a += String.fromCharCode((b & 31) << 6 | c2 & 63), d += 2) : (c2 = c.charCodeAt(d + 1), c3 = c.charCodeAt(d + 2), a += String.fromCharCode((b & 15) << 12 | (c2 & 63) << 6 | c3 & 63), d += 3);
        return a
    }
};

//IE helper
!window.console && (window.console = {
    log: function() {},
    error: function() {}
});

Date.fromISOString = (function() {
    var tzoffset = (new Date).getTimezoneOffset();

    function fastDateParse(y, m, d, h, i, s, ms) { // this -> tz
        return new Date(y, m - 1, d, h || 0, +(i || 0) - this, s || 0, ms || 0);
    }

    // result function
    return function(isoDateString) {
        var tz = isoDateString.substr(10).match(/([\-\+])(\d{1,2}):?(\d{1,2})?/) || 0;
        if (tz)
            tz = tzoffset + (tz[1] == '-' ? -1 : 1) * (tz[3] != null ? +tz[2] * 60 + (+tz[3]) : +tz[2]);
        return fastDateParse.apply(tz || 0, isoDateString.split(/\D/));
    }
})();

//namespace
var dw = dw || {};
dw.u = {
    conf: {
        retryLimit: 300,
        retryUISelector: '#retry-label'
    }
};

dw.u.retry = function(url, cb, postData, avoidRetry, onError) {
    if (dw.u.getRemote.attempts < dw.u.conf.retryLimit) {
        dw.u.getRemote(url, cb, postData, avoidRetry, onError);
        //ﬁdw.u.conf.retryUISelector).append('...');
    } else {
        console.log('retry fail', dw.u.getRemote.attempts, dw.u.conf.retryLimit)
        alert(copadoLabels.OOPS_SOMETHING_WENT_WRONG_GETTING_ORG_REMOTE_DATA);
        return false;
    }
};

dw.u.getRemote = function(url, cb, postData, avoidRetry, onError, requestType) {
    if(Copado_Licenses.hasMultiLicense && !(Copado_Licenses.hasCopado ||Copado_Licenses.hasCCM ||Copado_Licenses.hasCST) ) {
        var errorMsgs = 'Your current license does not allow performing this action.';
        alert(errorMsgs);
        return;
    }

    dw.u.getRemote.attempts++;
    sforce.connection.remoteFunction({
        url: url,
        requestHeaders: {
            "Content-Type": "text/json",
            "userId": _temp_conf.userId,
            "orgId": _temp_conf.orgId,
            "sessionId": _temp_conf.sessionId,
            "token": _temp_conf.token
        },
        method: postData ? 'POST' : "GET",
        requestData: postData ? postData : {},
        onSuccess: function(res) {
            //check response
            try {
                !res && console.log('No response');


                var obj = $copado.parseJSON(res.replace(/(\r\n|\n|\r)/gm, ' '));


                //FIXME: understand why parse is giving an string
                if (typeof obj === 'string') {

                    obj = $copado.parseJSON(obj.replace(/(\r\n|\n|\r)/gm, ' '));
                }


                if (obj.ok) {

                    setTimeout(function() {
                        dw.u.retry(url, cb, postData, avoidRetry, onError);
                    }, 2000);
                    return;
                }

                if (obj.error) {
                    console.error('Remote Error: ', obj.error);
                    avoidRetry = true;
                    alert(obj.error);
                    throw obj.error;
                }

                if (obj.messages && obj.messages.length > 0) {
                    var errorMsgs = obj.messages.join('\n');
                    alert(errorMsgs);
                    console.error('Error Messages: ', errorMsgs);
                    throw errorMsgs;
                }

                cb && cb(obj);

            } catch (e) {

                console.log('remote error', e);
                if (avoidRetry) {
                    try {
                        $copado('#loading').hide();
                    } catch (e) {}
                    try {
                        $copado('#jqxgrid').html(e);
                    } catch (e) {}
                }
                onError && onError(e);
                !avoidRetry && setTimeout(function() {
                    dw.u.retry(url, cb, postData, avoidRetry, onError);
                }, 2000);

            }
        },
        onFailure: function(response) {
            console.log('onFailure', onError, response)
            if (onError) {
                onError(response);
                return;
            }!avoidRetry && setTimeout(function() {
                dw.u.retry(url, cb, postData, avoidRetry, onError);
            }, 2000);
        },
        timeout: 250000
    });
};
dw.u.getRemote.attempts = 0;

dw.u.deleteAttach = function(parentId, name) {
    console.info('deleting attachments from '+parentId+'...');
    var result = sforce.connection.query("Select Id From Attachment where Name='" + name + "' and parentId = '" + parentId + "'");
    var rv = {};
    if(result.size > 0){
        try{
            var records = result.getArray("records");            
            var idsForDeletion = [];
            for(var i=0; i<records.length; i++){
                idsForDeletion.push(records[i].Id);                
            }
            var delRes = sforce.connection.deleteIds(idsForDeletion);

            for(var i = 0; i<delRes.length; i++){
                
                if(delRes[i].success == "false"){                    
                    throw delRes[i].errors.message;
                    break;
                }
            }
            rv.success = true;
            rv.id = parentId;
            return rv;
        }catch(e){
            rv.success = false;
            rv.id = parentId;
            rv.message = 'Exception while deleting metadata attachment : '+e;
            console.warn('Exception while deleting metadata attachment : '+e);
            return rv;
        }
    }else{
        rv.success = false;
        rv.id = parentId;
        rv.message = 'No attachment found to delete';
        console.warn('no attachment found');
        return rv;
    }
    
}

dw.u.getAttach = function(parentId, name) {

    var q = "Select Id, Body, LastModifiedDate, Name, ParentId From Attachment where Name='" + name + "' and parentId = '" + parentId + "' order by LastModifiedDate DESC limit 1",
        result = sforce.connection.query(q),
        records = result.getArray("records");
    return records;
};

dw.u.getAttachById = function(attachmentId) {
    var q = "Select Id, Body, LastModifiedDate, Name, ParentId From Attachment where Id='" + attachmentId + "'",
        result = sforce.connection.query(q),
        records = result.getArray("records");
    return records;
};

dw.u.getDecodedAttach = function(parentId, name) {
    var a = dw.u.getAttach(parentId, name);
    if (!a.length) return null;
    a.Body = Base64.decode(a[0].Body);
    return a;
};


//upsert
dw.u.upsertAttach = function(parentId, name, body, alreadyCheck) {


    var Id = false;
    if (!alreadyCheck) {

        var attach = dw.u.getAttach(parentId, name);
        if (attach.length) {
            Id = attach[0].Id;
        }

    }
    var att = new sforce.SObject("Attachment");
    att.parentId = parentId;
    att.name = name;
    att.body = Base64.encode(body);

    if (Id) {
        att.Id = Id;
    }

    var result = sforce.connection.upsert("Id", [att]);


};

//this function try to recover the data from cached attach
//if is not cached it get from remote source and save it in attach
dw.u.getCachedRemote = function(opt) {
    /*
    opt sample
    { 
        url: remoteUrl,
        parentId: ':)',
        name: 'Metadata' ,
        postData:data
        success:function(){},
        error:function(){},
        
    };*/

    var attach = dw.u.getAttach(opt.parentId, opt.name);
    if (opt.force || attach.length != 1) {

        //get remote and save
        dw.u.getRemote.attempts = 0;

        dw.u.getRemote(opt.url, function(res) {
                console.log('getRemote ok', res);

                //save as attach
                dw.u.upsertAttach(opt.parentId, opt.name, JSON.stringify(res), !opt.force);
                opt.success(res, 0);
            },
            opt.postData ? opt.postData : null
        );

    } else {
        // try{
        //decode the attach body
        var res = Base64.decode(attach[0].Body);


        //format date
        var date = Date.fromISOString(attach[0].LastModifiedDate);

        //parse json
        opt.success($copado.parseJSON(res), date.toLocaleString());

        /*}catch(e){
            //console.log(Base64.decode(attach[0].Body));
            console.error('Exception on saved data:',e);
            opt.error();
            throw e;
        }*/
    }

};

dw.u.getSavedStepData = function(type, isNotJSON) {
    if (!rock.stepId) return false;
    return dw.u.getSavedData(rock.stepId, type, isNotJSON);
};


dw.u.getSavedData = function(id, type, isNotJSON) {
    var attach = dw.u.getAttach(id, type);
    if (attach.length > 0) {
        try {
            //decode the attach body
            var res = Base64.decode(attach[0].Body);
            //parse json
            return isNotJSON ? res : $copado.parseJSON(res);

        } catch (e) {
            console.log('Exception on saved data:', e);
        }
    }
    return false;
};

function reformatMilliseconds(milliseconds) {

    var d = parseInt(milliseconds) / 1000;
    x = d
    seconds = x % 60
    x /= 60
    minutes = x % 60
    x /= 60
    hours = x % 24
    x /= 24
    days = x

    var output = (Math.floor(hours) > 0) ? Math.floor(hours) + ' ' + copadoLabels.HOURS + ' ' : '';
    output += (Math.floor(minutes) > 0) ? Math.floor(minutes) + ' ' + copadoLabels.MINUTES + ' ' : '';
    output += (Math.floor(seconds) > 0) ? Math.floor(seconds) + ' ' + copadoLabels.SECONDS + ' ' : '';
    output += (milliseconds > 0 && milliseconds < 1000) ? milliseconds + ' ' + copadoLabels.MILLISECONDS : '';
    return output;
}

/*************************************************
Generic Grid Helper
*************************************************/
var coGridHelper = {
    /**
     * Merge selected items from 2 sources. using the "s" attribute
     * @param  {[type]} metaOrgData [description]
     * @param  {[type]} dataStep    [description]
     * @return {[type]}             [description]
     */
    mergeSavedData: function(metaOrgData, dataStep) {

        var len = dataStep.length;

        while (len--) {
            if (typeof dataStep[len] !== 'object') {
                delete dataStep[len];
            } else {
                dataStep[len].s = true;
            }
        }

        var len2 = dataStep.length;
        for (var i = 0; i < len2; i++) {
            var el = dataStep[i];

            var index = coGridHelper.getIndexByNT(metaOrgData, el.n, (el.t || el.ns));
            if (index > -1) {
                metaOrgData[index].s = true;
            } else {
                if (typeof(window._errNotFoundShown) == 'undefined') {
                    window._errNotFoundShown = true;
                    alert(copadoLabels.missing_element_msg + (el.t || el.ns) + ' - ' + el.n);
                }
            }
        }

        return metaOrgData;
    },

    /**
     * get selected items from the datasource
     * @return {[type]} [description]
     */
    getSelectedObj: function() {
        // NR: when there is no coGridHelper (because it is not a partial selection), we return empty array
        if (!coGridHelper.datasource)
            return [];
        var data = coGridHelper.datasource.localdata,
            len = data.length;

        coGridHelper._selectedNames = [];

        while (len--) {
            var o = {
                n: data[len].n,
                s: true,
                d: data[len].d,
                b: data[len].b,
                cd: data[len].cd,
                cb: data[len].cb
            };

            if (typeof data[len].r != 'undefined') {
                o.r = data[len].r;
            }
            if (typeof data[len].ns != 'undefined') {
                o.ns = data[len].ns;
            } else {
                o.t = data[len].t;
            }

            data[len].s && coGridHelper._selectedNames.push(o);
        }
        return coGridHelper._selectedNames;
    },

    //selected "Names"
    _selectedNames: [],

    /**
     * helper to find index items by name, namespace and type
     * @param  {[type]} arr [description]
     * @param  {[type]} n   [description]
     * @param  {[type]} t   [description]
     * @return {[type]}     [description]
     */
    getIndexByNT: function(arr, n, t) {

        var initialIndex = 0; // todo improve index change >> this.initialIndex || 0,
        len = arr.length;

        for (initialIndex; initialIndex < len; initialIndex++) {
            var el = arr[initialIndex];
            try {
                if (el.n === n && (el.t === t || el.ns === t)) {
                    this.initialIndex = initialIndex;
                    return initialIndex;
                }
            } catch (e) {
                console.error(e);
                return -1;
            }
        }
        return -1;
    },

    /**
     * Save in attachment the selected items of the grid
     * @param  {[type]} id                   parentId
     * @param  {[type]} type                 Attachment Name
     * @param  {[type]} additionalValidation function for additional validations
     * @param  {[type]} allowEmpty           skip length validation
     * @param  {[type]} callcack             
     * @return {[type]}                      false
     */
    saveSelected: function(id, type, additionalValidation, allowEmpty, callback) {

        var me = coGridHelper;
        //validations
        //check global selected items
        me.getSelectedObj();
        if (!allowEmpty && !me._selectedNames.length) {
            //check if copadoApp showmessage is active
            if (copadoApp.showMessage) {
                copadoApp.showMessage('ERROR', copadoLabels.SPECIFY_AT_LEAST_ONE_ITEM_TO_DEPLOY, 0);
            } else {
                alert(copadoLabels.SPECIFY_AT_LEAST_ONE_ITEM_TO_DEPLOY);
            }
            return false;
        }

        var valid = !additionalValidation ? true : additionalValidation(me._selectedNames);

        valid && me.remoteSaveMeta(id, me._selectedNames, type, callback);

        return false;
    },

    /**
     * save an attachment
     * @param  {[type]} id       parentId
     * @param  {[type]} items    data for stringify
     * @param  {[type]} type     attachment name
     * @param  {[type]} callcack function on callback
     * @return {[type]}          void
     */
    remoteSaveMeta: function(id, items, type, callback) {
        dw.u.upsertAttach(id, type, JSON.stringify(items));
        callback && callback();
    }
};