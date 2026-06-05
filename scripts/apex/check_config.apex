BB_C360_Config__mdt cfg = BB_C360_Config__mdt.getInstance('Default');
System.debug('ConsumerKey present: ' + String.isNotBlank(cfg.ConsumerKey__c)
    + ' (len=' + (cfg.ConsumerKey__c == null ? 0 : cfg.ConsumerKey__c.length()) + ')');
System.debug('ConsumerSecret present: ' + String.isNotBlank(cfg.ConsumerSecret__c)
    + ' (len=' + (cfg.ConsumerSecret__c == null ? 0 : cfg.ConsumerSecret__c.length()) + ')');
