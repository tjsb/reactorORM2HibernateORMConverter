component extends="coldbox.system.testing.BaseTestCase"{
	
	/**            
    * @displayname setup        
    * @access public     
    * @returnType any    
    * @output false    
    * @hint I am a hint          
    */    
    function setup() {    
    	variables.Reactor2HibernateOrm = getModel("Reactor2HibernateOrm"); 
    }
    
    /**            
    * @displayname getObjectMetadataTest        
    * @access public     
    * @returnType any    
    * @output false    
    * @hint I am a hint          
    */    
    function getObjectMetadataTest() {    
    	  var result = variables.Reactor2HibernateOrm.getObjectMetadata("content");
    	  debug(result.getObjectMetadata());  
    }
    
    /**            
    * @displayname getFieldsTest        
    * @access public     
    * @returnType any    
    * @output false    
    * @hint I am a hint          
    */    
    function getFieldsTest() {    
    	 var result = variables.Reactor2HibernateOrm.getFields("customfielditemlanguagetemplate");
    	  debug(result);   
    }
    
    /**            
    * @displayname getRelationshipsTest        
    * @access public     
    * @returnType any    
    * @output false    
    * @hint I am a hint          
    */    
    function getRelationshipsTest() {    
    	 var result = variables.Reactor2HibernateOrm.getRelationships("ebaylisting");
    	  debug(result);   
    }
    
    /**            
    * @displayname generateFile        
    * @access public     
    * @returnType any    
    * @output false    
    * @hint I am a hint          
    */    
    function generateFileTest() {    
    	 var result = variables.Reactor2HibernateOrm.generateFile("category");
    	  debug(result);   
    }
    
    /**            
    * @displayname createEntityNameTest        
    * @access public     
    * @returnType any    
    * @output false    
    * @hint I am a hint          
    */    
    function createEntityNameTest() {    
    	 var result = variables.Reactor2HibernateOrm.createEntityName("custom_field_item_language_template");
    	 debug(result);   
    }
    
    /**            
    * @displayname removeFieldsWithRelationshipsTest        
    * @access public     
    * @returnType any    
    * @output false    
    * @hint I am a hint          
    */    
    function removeFieldsWithRelationshipsTest() { 
    	var objectname = "discount";
    	var arrFields = variables.Reactor2HibernateOrm.getFields(objectname); 
    	debug(arrFields);
    	var arrRelationships = variables.Reactor2HibernateOrm.getRelationships(objectname);   
    	debug(arrRelationships);
    	var result = variables.Reactor2HibernateOrm.removeFieldsWithRelationships(arrFields, arrRelationships);
    	debug(result);    
    }
    
    /**            
    * @displayname getReactorFactoryTest        
    * @access public     
    * @returnType any    
    * @output false    
    * @hint I am a hint          
    */    
    function getReactorFactoryTest() {    
    	var result = variables.Reactor2HibernateOrm.getReactorFactory();  
    	debug(result);  
    }
    
    /**            
    * @displayname getReactorObjectsTest        
    * @access public     
    * @returnType any    
    * @output false    
    * @hint I am a hint          
    */    
    function getReactorObjectsTest() {    
    	var result = variables.Reactor2HibernateOrm.getReactorObjects();  
    	debug(result);     
    }
    
    /**            
    * @displayname runAllTest        
    * @access public     
    * @returnType any    
    * @output false    
    * @hint I am a hint          
    */    
    function runAllTest() {    
    	 //var result = variables.Reactor2HibernateOrm.runAll() ; 
    	 debug(result); 
    }
    
     /**            
    * @displayname getPrimaryKeyFieldsTest        
    * @access public     
    * @returnType any    
    * @output false    
    * @hint I am a hint          
    */    
    function getPrimaryKeyFieldsTest() {    
    	var objectname = "contentsite";
    	var arrFields = variables.Reactor2HibernateOrm.getFields(objectname); 
    	debug(arrFields);
    	var arrPrimaryKeyFields = variables.Reactor2HibernateOrm.getPrimaryKeyFields(arrFields);   
    	debug(arrPrimaryKeyFields);
    	//var result = variables.Reactor2HibernateOrm.removeFieldsWithRelationships(arrFields, arrRelationships);
    	//debug(result);
    }
    
    /**            
    * @displayname pluralizeTest        
    * @access public     
    * @returnType any    
    * @output false    
    * @hint I am a hint          
    */    
    function pluralizeTest() {    
    	 var result = variables.Reactor2HibernateOrm.pluralize("class") ; 
    	 debug(result); 
    }
}