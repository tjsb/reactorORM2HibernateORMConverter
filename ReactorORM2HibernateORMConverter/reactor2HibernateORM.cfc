/* 
Copyright 2015 Tom Bishop - you may use and change this file to suit your own requirements as you see fit. 
I do not in any way indemnify or guarantee the results.
The results are not perfect but if you've got a lot of database tables then it should save you a significant amount of time.
I built and tested this component within a ColdBox framework context - hence the wirebox injection. 
If not using Wirebox, you will need to inject the reactor ormService into the component (or instantiate a new instance without an IOC container) 
or modify it so that it is available in the variables scope.
I have also included the unit test.
*/

component {
	
	property name="ormService" inject="ocm:reactor";
	
	/**            
    * @displayname init        
    * @access public     
    * @returnType any    
    * @output false    
    * @hint I am a hint          
    */    
    function init() {    
    	variables.genPath = "C:\path\to\the\generated\folder";
    	variables.reactorConfigFilePath = "C:\path\to\your\Reactor.xml";
    	variables.lb = Chr(13) & Chr(10);
    	variables.lb2 = lb & lb;
    	variables.tab = chr(9);
    	variables.lbAndDblTab = lb & tab & tab;
    }
    
	/**            
    * @displayname getReactorFactory        
    * @access public     
    * @returnType any    
    * @output false    
    * @hint I am a hint          
    */    
    function getReactorFactory() {    
    	return ormService;    
    }
    
    /**            
    * @displayname runAll        
    * @access public     
    * @returnType any    
    * @output false    
    * @hint I am a hint          
    */    
    function runAll(string objectlist="") {  
    	var arrErrors = [];
    	//getReactorFactory().compile();  
    	var arrObjects = getReactorObjects();
    	for (var oObject in arrObjects) {
    		if (listLen(objectlist)){
    			if (listFindNoCase(objectlist, oObject)){
    				try{
    					generateFile(oObject);
    				} catch (any e){
    					arrayAppend(arrErrors, e.message);
    					continue;
    				}
    			}
    		} else {
    			try{
					generateFile(oObject);
				} catch (any e){
					arrayAppend(arrErrors, e.message);
					continue;
				}
    		}
    		
    	}
    	return arrErrors;
    }
    
    /**            
    * @displayname readFile        
    * @access public     
    * @returnType any    
    * @output false    
    * @hint I am a hint          
    */    
    function getReactorObjects() { 
    	var arrNodesOut = [];   
    	var oFile = fileRead(variables.reactorConfigFilePath);
    	//var xml = xmlParse(variables.reactorConfigFilePath);
    	var arrNodes = xmlSearch(oFile, "/reactor/objects/object/");
    	for (var node in arrNodes){
    		if (structKeyExists(node.xmlAttributes, "alias")){
    			arrayAppend(arrNodesOut, node.xmlAttributes.alias);
    		} else {
    			arrayAppend(arrNodesOut, node.xmlAttributes.name);
    		}
    		
    	}
    	return arrNodesOut;
    }
    
    /**            
    * @displayname get|ObjectMetadata        
    * @access public     
    * @returnType any    
    * @output false    
    * @hint I am a hint          
    */    
    function getObjectMetadata(string objectName) {    
    	return ormService.createRecord(objectName)._getObjectMetadata();
    }
    
    /**            
    * @displayname getFields        
    * @access public     
    * @returnType any    
    * @output false    
    * @hint I am a hint          
    */    
    function getFields(string objectName) {    
    	 return getObjectMetadata(objectName).getFields();   
    }
    
    /**            
    * @displayname getRelationships        
    * @access public     
    * @returnType any    
    * @output false    
    * @hint I am a hint          
    */    
    function getRelationships(string objectName) {    
    	 return getObjectMetadata(objectName).getRelationships();   
    }
    
    /**            
    * @displayname generateFile        
    * @access public     
    * @returnType any    
    * @output false    
    * @hint I am a hint          
    */    
    function generateFile(string objectName) {    
    	 var oMetadata = getObjectMetadata(objectName);
    	 var arrFields = getFields(objectName);
    	 var arrPrimaryKeyFields = getPrimaryKeyFields(arrFields);
    	 var arrRelationships = getRelationships(objectName);
    	 var arrFields = removeFieldsWithRelationships(arrFields, arrRelationships);
    	 var usesCompositePks = usesCompositePks(arrFields);
    	 var entityName = createEntityName(oMetadata.getName());
    	 var tableName = oMetadata.getName();
    	 var filename = entityName & ".cfc";
    	 var filepath = variables.genPath & "\" & filename;
    	 var initVariableDefaults = "";
    	 var arrConvenienceMethods = [];
    	 var count = 0;
    	 var content = "";
    	 savecontent variable="content" {
    	 	writeOutput('component persistent="true" table="#tableName#" accessors="true" {');
    	 	writeOutput(lb2);
    	 	writeOutput(tab & '//created: #dateFormat(now(), "dd/mm/yyyy")# at #timeFormat(now(), "HH:mm:ss")#' & lb);
    	 	writeOutput(tab & '//checked: No');
    	 	writeOutput(lb2);
    	 	for (var oField in arrFields) {     
    	 		if (oField.primaryKey == true){
    	 			//arrayAppend(arrPrimaryKeyFields, oField);
    	 			if (usesCompositePks){
    	 				var generator = "assigned";
    	 			} else {
    	 				var generator = "identity";
    	 			}
    	 			writeOutput(tab & 'property name="#oField.alias#" type="#oField.cfDataType#" ormtype="#oField.dbDataType#" fieldtype="id" persistent="true" generator="#generator#";' & lb);
    	 		} else {
    	 			if (findNoCase("boolean", oField.alias)){
    	 				var cfdatatype = "boolean";
    	 			} else {
    	 				var cfdatatype = oField.cfDataType;
    	 			}
    	 			writeOutput(tab & 'property name="#oField.alias#" type="#cfdatatype#" ormtype="#oField.dbDataType#" fieldtype="column" persistent="true" default="#oField.default#";' & lb);
    	 			initVariableDefaults &= tab & 'variables.#oField.alias# = "#oField.default#";' & lb & tab;
    	 		}     
            }
            writeOutput(lb2);
            //relationships
            for (var oRelationship in arrRelationships) {  
            	count++;
            	strContent = generateRelationshipProperty(oRelationship, arrPrimaryKeyFields, entityName, count);          
            	writeOutput(strContent.content);
            	if (structKeyExists(strContent, "convenienceMethod")){
            		arrayAppend(arrConvenienceMethods, strContent.convenienceMethod); 
            	}
            	if (structKeyExists(strContent, "initVariableDefaults")){
            		initVariableDefaults &= strContent.initVariableDefaults;
            	}
            }
    	 	writeOutput(lb2);
    	 	writeOutput(tab & '/**' & lb);
    	 	writeOutput(tab & '* @displayname init ' & lb);
    	 	writeOutput(tab & '* @access public ' & lb);
    	 	writeOutput(tab & '* @output false ' & lb);
    	 	writeOutput(tab & '* @hint I am the #entityName# constructor ' & lb);
    	 	writeOutput(tab & '**/' & lb);
    	 	writeOutput(tab & 'function init() {' & lb);
    	 	writeOutput(tab & initVariableDefaults);
    	 	writeOutput(tab & 'return this;' & lb);
    	 	writeOutput(tab & '}' & lb);
    	 	for (var oConvenienceMethod in arrConvenienceMethods) {             
            	writeOutput(lb2 & tab & oConvenienceMethod);           
            }
    	 	writeOutput('}');
    	 }
    	 fileWrite(filepath, content);
    	 return "#objectName# successfully created";
    }
    
    /**            
    * @displayname getPrimaryKeyFields        
    * @access public     
    * @returnType array    
    * @output false    
    * @hint I am a hint          
    */    
    function getPrimaryKeyFields(array arrFields) {    
    	var arrPrimaryKeyFields = [];
    	for (var oField in arrFields) {        
        	if (oField.primarykey){
        		arrayAppend(arrPrimaryKeyFields, oField);
        	}      
        } 
        return arrPrimaryKeyFields;
    }
    
    /**            
    * @displayname createEntityName        
    * @access public     
    * @returnType string    
    * @output false    
    * @hint I am a hint          
    */    
    function createEntityName(string name) {    
    	var entityName = "";
    	var bIsMulti = false;
    	if (listLen(name, "_")){
    	 	bIsMulti = true;
    	}
    	if (bIsMulti){
    		for (var i=1;i <= listLen(name, "_"); i++) {            
            	var namepart = listGetAt(name, i, "_");
            	namepart = reReplace(namepart,"(^[a-z])","\U\1","ALL");
            	entityName &= namepart;
            }
    	}
    	entityName = replaceNoCase(entityName, "LanguageTemplate", "Lang");
    	return entityName;
    }
    
    /**            
    * @displayname removeFieldsWithRelationships        
    * @access public     
    * @returnType any    
    * @output false    
    * @hint I am a hint          
    */    
    function removeFieldsWithRelationships(array arrFields, array arrRelationships) {    
    	var arrOut = []; 
    	var currpos = 0;
    	var arrPosToDelete = [];
    	for (var oField in arrFields) {  
    		currpos++;      
        	var name = oField.name;
        	for (var oRelationship in arrRelationships) {
        		if (structKeyExists(oRelationship, "relate")) {        
	            	var arrRelates =  oRelationship.relate;
	            	for (var oRelate in arrRelates){
	            		var relfrom = oRelate.from;
	            		if (relfrom == name && oField.primaryKey == false && not arrayFind(arrPosToDelete, currpos)){
	            			arrayAppend(arrPosToDelete, currpos);
	            		}
	            	} 
            	}        
            }    
        }
        //return arrPosToDelete;
        var count = 0;
        for (var pos in arrPosToDelete) {        
        	  arrayDeleteAt(arrFields, pos - count);  
        	  count++;
        	     
        }
        return arrFields;
    }
    
    /**            
    * @displayname usesCompositePks        
    * @access public     
    * @returnType boolean    
    * @output false    
    * @hint I am a hint          
    */    
    function usesCompositePks(array arrFields) {    
    	var countPKs = 0;
    	for (var oField in arrFields) {        
        	if (oField.primaryKey == true){
        		countPKs++;
        	}     
        }  
        if (countPKs > 1){
        	return true;
        } else {
        	return false;
        }
    }
    
    /**            
    * @displayname pluralize        
    * @access public     
    * @returnType any    
    * @output false    
    * @hint I am a hint          
    */    
    function pluralize(string name) { 
    	//var pos = len(name);
    	var lastLetter = right(name, 1); 
    	var last3Letters = right(name, 3); 
    	var cond1 = false;
    	var cond2 = false;
    	if (listfindnocase("x,s", lastLetter)){
    		cond1 = true;
    		name = name & "es";
    	}
    	if (lastLetter == "y"){
    		cond2 = true;
    		name = Left(name, len(name)-1);
    		name = name & "ies";
    	}
    	if (!cond1 && !cond2){
    		name = name & "s";
    	}
    	return name;    
    }
    
    /**            
    * @displayname generateRelationshipProperty        
    * @access public     
    * @returnType any    
    * @output false    
    * @hint I am a hint          
    */    
    function generateRelationshipProperty(struct oRelationship, array arrPrimaryKeyFields, string entityName, numeric id) {    
    	switch (oRelationship.type){
    		case "hasOne":
    			return generateMany2OneProperty(id, oRelationship, arrPrimaryKeyFields);
    		break;
    		case "hasMany":
    			if (structKeyExists(oRelationship, "relate")){
    				return generateOne2ManyProperty(id, oRelationship, entityName);
    			} else {
    				return generateMany2ManyProperty(id, oRelationship, arrPrimaryKeyFields, entityName);
    			}
    		break;
    	}
    }
    
    /**            
    * @displayname generateMany2OneProperty        
    * @access public     
    * @returnType any    
    * @output false    
    * @hint I am a hint          
    */    
    function generateMany2OneProperty(id, oRelationship, arrPrimaryKeyFields) {   
    	var strOut = {};
    	var pklist = "";
    	var strCannotCreate = "";
    	try {
    		for (var oField in arrPrimaryKeyFields) {                
            	 pklist = listAppend(pklist, oField.name);              
            }
	    	var oMetadata = getObjectMetadata(oRelationship.name);
	    	var entityName = createEntityName(oMetadata.getName()); 
	    	var fkList = "";
	    	var fieldtype = "";
	    	var lazy = 'lazy="true"';
	    	for (var i=1;i <= arrayLen(oRelationship.relate); i++) {            
            	fkList = listAppend(fkList, oRelationship.relate[i].from);
            }
            for (var j=1;j <= listLen(fklist);j++){
            	var key = listGetAt(fklist, j);
            	if (listFindNoCase(pklist, key)){
            		fieldtype = "id,";
            		lazy = "";
            		break;
            	}
            }
	    	var content = "";
	    	savecontent variable="content" { 
	    		writeOutput(tab & '//hasOne #oRelationship.alias# [#id#]' & lb);
	    		writeOutput(tab & 'property name="#oRelationship.alias#"' & lbAndDblTab & 'fieldtype="#fieldtype#many-to-one" ' & lbAndDblTab & 'cfc="#entityName#" ' & lbAndDblTab & 'fkcolumn="#fkList#" ' & lbAndDblTab & '#lazy#;' & lb2);
	    	}
	    	strOut.content = content;
    	} catch (any e){
    		savecontent variable="strCannotCreate" { 
	    		writeOutput(tab & "/*** could not create Many2One property for #oRelationship.alias# [#e.message#] ***/");
	    	}
    		strOut.content = replace(strCannotCreate,"\r\n","","all") & lb2;
    	}
    	return strOut;
    }
    
    /**            
    * @displayname generateOne2ManyProperty        
    * @access public     
    * @returnType any    
    * @output false    
    * @hint I am a hint          
    */    
    function generateMany2ManyProperty(id, oRelationship, arrPrimaryKeyFields, creatingEntityName) { 
    	var strOut = {};
    	var strCannotCreate = "";
    	try {   
	    	var oMetadata = getObjectMetadata(oRelationship.alias);
	    	var entityName = createEntityName(oMetadata.getName());
	    	var entityNamePlural = lcase(pluralize(entityName));
	    	var oMetaDataLink = getObjectMetadata(oRelationship.link[1]);
	    	var content = "";
	    	savecontent variable="content" { 
	    		writeOutput(tab & '//TODO: remove convenience methods on one side of this relationship. Keep inverse="true" on the side that keeps the convenience methods.' & lb);
	    		writeOutput(tab & '//Many #pluralize(creatingEntityName)# to many #entityNamePlural# [#id#]' & lb);
	    		writeOutput(tab & 'property name="#entityNamePlural#"' & lbAndDblTab & 'singularName="#lcase(entityName)#" ' & lbAndDblTab & 'linktable="#oMetaDataLink.getName()#" ' & lbAndDblTab & 'fieldtype="many-to-many" ' & lbAndDblTab & 'cfc="#entityName#" ' & lbAndDblTab & 'fkcolumn="#arrPrimaryKeyFields[1].name#" ' & lbAndDblTab & 'inversejoincolumn="#oMetadata.getPrimaryKey()#" ' & lbAndDblTab & 'inverse="true" ' & lbAndDblTab & 'lazy="true" ' & lbAndDblTab & 'cascade="all-delete-orphan";' & lb2);
	    	}
	    	strOut.content = content;
	    	var convenienceMethod = "";
	    	savecontent variable="convenienceMethod" {
	    		writeOutput('/**' & lb);
	    		writeOutput(tab & '* @displayname add#entityName# ' & lb);
	    		writeOutput(tab & '* @access public' & lb);
	    		writeOutput(tab & '* @output false ' & lb);
	    		writeOutput(tab & '* @hint [#id#] I add an #entityName# and call the set#creatingEntityName# on the other side of the relationship' & lb);
	    		writeOutput(tab & '**/' & lb);
	    		writeOutput(tab & 'void function add#entityName#( required #entityName# ) {' & lb);
	    		writeOutput(tab & tab & 'param name="variables.#entityNamePlural#" default="##arrayNew(1)##";' & lb);
	    		writeOutput(tab & tab & 'if (!has#entityName#( arguments.#entityName# )){' & lb);
	    		writeOutput(tab & tab & tab & 'variables.#entityNamePlural# = [];' & lb);
	    		writeOutput(tab & tab & '}' & lb);
	    		writeOutput(tab & tab & 'ArrayAppend(variables.#entityNamePlural#, arguments.#entityName#);' & lb);
	    		writeOutput(tab & tab & 'arguments.#entityName#.set#creatingEntityName#(this);' & lb);
	    		writeOutput(tab & '}' & lb);
	    		writeOutput(lb);
	    		//remove
	    		writeOutput('/**' & lb);
	    		writeOutput(tab & '* @displayname remove#entityName# ' & lb);
	    		writeOutput(tab & '* @access public' & lb);
	    		writeOutput(tab & '* @output false ' & lb);
	    		writeOutput(tab & '* @hint [#id#] I remove a(n) #entityName# and also remove the #creatingEntityName# from the other side of the relationship' & lb);
	    		writeOutput(tab & '**/' & lb);
	    		writeOutput(tab & 'void function remove#entityName#( required #entityName# ) {' & lb);
	    		writeOutput(tab & tab & 'if (has#entityName#( arguments.#entityName# )){' & lb);
	    		writeOutput(tab & tab & tab & 'ArrayDelete( variables.#entityNamePlural#, arguments.#entityName#);' & lb);
	    		writeOutput(tab & tab & tab & 'arguments.#entityName#.remove#creatingEntityName#(this);' & lb);
	    		writeOutput(tab & tab & '}' & lb);
	    		writeOutput(tab & '}' & lb);
	    		writeOutput(lb);
	    		//set from both sides
	    		writeOutput('/**' & lb); 
	    		writeOutput(tab & '* @displayname set#entityNamePlural# ' & lb);
	    		writeOutput(tab & '* @access public' & lb);
	    		writeOutput(tab & '* @output false ' & lb);
	    		writeOutput(tab & '* @hint [#id#] I set from both sides of the relationship' & lb);
	    		writeOutput(tab & '**/' & lb);
	    		writeOutput(tab & 'void function set#entityNamePlural#( required array #entityNamePlural# ) {' & lb);
	    		writeOutput(tab & tab & 'var #entityName# = "";' & lb);
	    		writeOutput(tab & tab & '//loop thru existing #entityNamePlural#' & lb);
	    		writeOutput(tab & tab & 'for (#entityName# in variables.#entityNamePlural#){' & lb);
	    		writeOutput(tab & tab & tab & 'if ( !ArrayContains(arguments.#entityNamePlural#, #entityName#)){' & lb);
	    		writeOutput(tab & tab & tab & tab & '#entityName#.remove#creatingEntityName#(this);' & lb);
	    		writeOutput(tab & tab & tab & '}' & lb);
	    		writeOutput(tab & tab & '}' & lb);
	    		writeOutput(tab & tab & '//loop thru passed #entityNamePlural#' & lb);
	    		writeOutput(tab & tab & 'for (#entityName# in arguments.#entityNamePlural#){' & lb);
	    		writeOutput(tab & tab & tab & 'if (!#entityName#.has#creatingEntityName#()){' & lb);
	    		writeOutput(tab & tab & tab & tab & '#entityName#.add#creatingEntityName#(this);' & lb);
	    		writeOutput(tab & tab & tab & '}' & lb);
	    		writeOutput(tab & tab & '}' & lb);
	    		writeOutput(tab & tab & 'variables.#entityNamePlural# = arguments.#entityNamePlural#;' & lb);
	    		writeOutput(tab & '}' & lb);
	    		writeOutput(lb);
	    		
	    	}
	    	strOut.convenienceMethod = convenienceMethod;
		} catch (any e){
			content = "";
			convenienceMethod = "";
			savecontent variable="strCannotCreate" { 
	    		writeOutput(tab & "/*** could not create Many2Many property for #oRelationship.alias# [#e.message#]***/");
	    	}
    		strOut.content = replace(strCannotCreate,"\r\n","","all");
    	}
    	return strOut;
    }
    
    /**            
    * @displayname generateOne2ManyProperty        
    * @access public     
    * @returnType any    
    * @output false    
    * @hint I am a hint          
    */    
    function generateOne2ManyProperty(id, oRelationship, creatingEntityName) { 
    	var strOut = {};
    	var strCannotCreate = "";
    	try {    
	    	var oMetadata = getObjectMetadata(oRelationship.alias);
	    	var entityName = createEntityName(oMetadata.getName());
	    	var entityNamePlural = lcase(pluralize(entityName));
	    	var fkList = "";
	    	for (var i=1;i <= arrayLen(oRelationship.relate); i++) {            
            	fkList = listAppend(fkList, oRelationship.relate[i].from);
            }
	    	var content = "";
	    	savecontent variable="content" { 
	    		writeOutput(tab & '//hasMany #entityNamePlural# [#id#]' & lb);
	    		writeOutput(tab & 'property name="#entityNamePlural#"' & lbAndDblTab & 'singularName="#lcase(entityName)#" ' & lbAndDblTab & 'fieldtype="one-to-many" ' & lbAndDblTab & 'type="array" ' & lbAndDblTab & 'cascade="delete-orphan" ' & lbAndDblTab & 'cfc="#entityName#" ' & lbAndDblTab & 'fkcolumn="#fkList#" ' & lbAndDblTab & 'inverse="true" ' & lbAndDblTab & 'lazy="true";' & lb2);
	    	}
	    	strOut.content = content;
	    	strOut.initVariableDefaults = tab & 'variables.#entityNamePlural# = [];' & lb & tab;
	    	var convenienceMethod = "";
	    	savecontent variable="convenienceMethod" {
	    		writeOutput('/**' & lb);
	    		writeOutput(tab & '* @displayname add#entityName# ' & lb);
	    		writeOutput(tab & '* @access public' & lb);
	    		writeOutput(tab & '* @output false ' & lb);
	    		writeOutput(tab & '* @hint [#id#] I add a(n) #entityName#' & lb);
	    		writeOutput(tab & '**/' & lb);
	    		writeOutput(tab & 'void function add#entityName#( required #entityName# ) {' & lb);
	    		writeOutput(tab & tab & 'param name="variables.#entityNamePlural#" default="##arrayNew(1)##";' & lb);
	    		writeOutput(tab & tab & 'if (!has#entityName#( arguments.#entityName# )){' & lb);
	    		writeOutput(tab & tab & tab & 'variables.#entityNamePlural# = [];' & lb);
	    		writeOutput(tab & tab & '}' & lb);
	    		writeOutput(tab & tab & 'ArrayAppend(variables.#entityNamePlural#, arguments.#entityName#);' & lb);
	    		writeOutput(tab & tab & 'arguments.#entityName#.set#creatingEntityName#(this);' & lb);
	    		writeOutput(tab & '}' & lb);
	    	}
	    	strOut.convenienceMethod = convenienceMethod;
    	} catch (any e){
    		savecontent variable="strCannotCreate" { 
	    		writeOutput(tab & "/*** could not create One2Many property for #oRelationship.alias# [#e.message#]***/");
	    	}
    		strOut.content = strCannotCreate;
    	}
    	return strOut;
    }
}