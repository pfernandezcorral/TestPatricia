var gitCommit = gitCommit || {};
var metadataGrid2;

//closure
(function(app){

//basic types to filter
app.filteredTypes = ['ApexClass'];

/**
 * Call heroku to request the commit action
 * @param  {[type]} commitId [description]
 * @return {[type]}          [description]
 */
app.callBackEnd = function(commitId){
    console.log('remote call for ', commitId, app.conf.data.userStoryId, app.conf.data.snapshotId, app.conf.data.repositoryId);

    // add both snapshot AND repo. snapshot for regular commits, repo for user story (unconfirmed?)
    statusManager.parentId = app.conf.data.snapshotId;
    statusManager.parentId2 = app.conf.data.repositoryId;
    document.addEventListener('copadoJobFinished1', function (e) {
        if(!e.detail)
            return;
        console.debug('copadoJobFinished1', e.detail.jobType, e.detail.jobType);
        if( e.detail.jobType.indexOf('apex')>-1 )
            return;
        if( e.detail.jobType.indexOf('retriever')>-1 )
            return;
        location.href='/'+ (app.conf.data.userStoryId || app.conf.data.snapshotId );
    }, false);

    // first tell the global job manager, THEN, call the status mgr.
    statusManager.lastAttachment = globalJobsManagerStart(app.conf.data.snapshotId, 'GitCommit', 'GIT-'+app.conf.data.repositoryId+'-'+app.conf.data.branch);
    statusManager.startProcess(function() {
        var msg = encodeURIComponent($copado('.js-message').val());
        dw.u.getRemote(app.conf.server.commitUrl.replace('__COMMITID__',commitId).replace('__MSG__',msg),function(res){
            console.info('commit callback >',res);
            statusManager.setStatusComplete();
        }, null, true);
    }, false, 'GitCommit');
};

/**
 * create a Git_Org_Commit__c record in salesforce
 * @return {[type]} [description]
 */
app.createCommitSObject = function(){

    var commit = new sforce.SObject(app.conf.ns + 'Git_Org_Commit__c');
    commit[app.conf.ns + 'Commit_Message__c'] = $copado('.js-message').val();
    commit[app.conf.ns + 'Org__c'] = app.conf.data.orgId;
    commit[app.conf.ns + 'Git_Backup__c'] = app.conf.data.snapshotId;
    commit[app.conf.ns + 'Status__c'] = 'Pending';

    var res = sforce.connection.create([commit]);

    if(res && res.length && res[0].success == 'true'){
        return res[0].id;
    }else{
        console.error(res);
        alert('Unexpected error whilst creating the commit record: '+res);
        unlockScreen();
        return false;
    }

};

/**
 * this method retrieve the selected items
 * then create a record in salesforce, attach the items to be commited
 * and finally call heroku to procede
 * @return {[type]} [description]
 */
app.doCommit = function(){

    lockScreen();

    //get selectd
    coGridHelper.datasource = app.datasource;

    //validate
    var sel = coGridHelper.getSelectedObj();
    if(!sel.length){
        alert(copadoPageLabels.SELECT_AT_LEAST_ONE_ITEM);
        unlockScreen();
        return;
    }
	if( !(elt_commitMessage.value||'').trim()) {
		alert(copadoPageLabels.ENTER_COMMIT_MESSAGE);
		unlockScreen();
		return;
	}
    //create record
    var commitId = app.createCommitSObject();

    //attach
    commitId && coGridHelper.saveSelected(commitId , 'MetaData', null, true, function(){
        console.debug('... callBackEnd');
        app.callBackEnd(commitId);
    });

    //back
    return false;

};

/**
 * Refresh cache
 * @return {[type]} [description]
 */
app.refreshCache = function(){
    metadataGrid2.refreshCache();
};

/**
 * update or hide refresh button
 * @param  {[type]} date [description]
 * @return {[type]}      [description]
 */
app.createCacheDeleteButton = function(date){
    if(!date){
        $copado('[id*=removeCacheContainer]').hide();
    }
    else{
        var $btn = $copado('[id$=removeCache]');
        $btn.length && $btn.html($btn.html().replace('__DATE__',date)).show();
    }
};

/**
 * Set the basic configuration,
 * Get supported types and create the grid.
 * @param  {[type]} conf  [description]
 * @param  {[type]} force [description]
 * @return {[type]}       [description]
 */
app.init = function(conf, force){
    console.log('init app using:', conf)
    app.conf = conf;

    //do normalize ns to empty string or value
    app.conf.ns = app.conf.ns || '';

    //start component
    lockScreen();

    dw.u.getRemote(app.conf.server.typesUrl,function(res){
        app.filteredTypes = res;
    });

};


var metadataGrid2 = null;

/**
* Previous hookups and initialization code:
**/
app.init = function(conf){
    console.log('init app using:', conf);
    app.conf = conf;

    //do normalize ns to empty string or value
    app.conf.ns = app.conf.ns || '';

    dw.u.getRemote(app.conf.server.typesUrl,function(res){
        app.filteredTypes = res;
    });

    conf.isScalable = conf.scalableGrid;
    conf.gridMode = 'gitCommit';
    conf.attachmentName = 'MetaData';
    if(!(metadataGrid2 && metadataGrid2.conf))
        metadataGrid2 = new MetadataGrid2(conf);

    var QueryString = function () {
      // This function is anonymous, is executed immediately and
      // the return value is assigned to QueryString!
      var query_string = {};
      var query = window.location.search.substring(1);
      var vars = query.split("&");
      for (var i=0;i<vars.length;i++) {
        var pair = vars[i].split("=");
            // If first entry with this name
        if (typeof query_string[pair[0]] === "undefined") {
          query_string[pair[0]] = decodeURIComponent(pair[1]);
            // If second entry with this name
        } else if (typeof query_string[pair[0]] === "string") {
          var arr = [ query_string[pair[0]],decodeURIComponent(pair[1]) ];
          query_string[pair[0]] = arr;
            // If third or later entry with this name
        } else {
          query_string[pair[0]].push(decodeURIComponent(pair[1]));
        }
      }
      return query_string;
    }();

    // note: can be null
    app.userStoryId = QueryString.userStoryId;
    console.info("initGrid", conf, QueryString.MetadataPreselectionId);

    // override loading selected metadata, since git commit has none (except the metadata preselection)
    metadataGrid2.loadSelectedMetaData = function(callbackFinished) {
            // if this comes
            if(QueryString.MetadataPreselectionId) {
            var savedItems = dw.u.getAttachById(QueryString.MetadataPreselectionId);
                console.debug("gitCommit: MetadataPreselectionId=", QueryString.MetadataPreselectionId, savedItems);
                if(savedItems) {
                    savedItems = Base64.decode(savedItems[0].Body);
                    savedItems = $copado.parseJSON(savedItems);
                }else{
                    alert("Could not load selections from other User Story commits.");
                }
            setWithoutRebinding(metadataGrid2.selectedMetadata, savedItems);
            }
        if(callbackFinished)
            callbackFinished();
};

    metadataGrid2.render(function() {
        console.info("MetadataGrid2:init grid rendered", conf);
        // leave the datasource available for save
        app.datasource = metadataGrid2.datasource;
            
            lockScreen();
        metadataGrid2.loadData(function() {
            console.info("MetadataGrid2:init grid data loaded");
            metadataGrid2.render();
                                unlockScreen();
                        });
                    });

    app.refreshMetadataTypes = function() { metadataGrid2.refreshMetadataTypes(); };
    };

}(gitCommit)); //end closure
