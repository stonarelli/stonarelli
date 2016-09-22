@isTest
private class TestXIRR {
    
    @isTest static void TestXIRR1() {
    
        XIRR c = new XIRR();
        
        Double test1 = c.calculate( new List<Date>{ Date.newInstance(2008, 1, 1), Date.newInstance(2008, 3, 1), Date.newInstance(2008, 10, 30), Date.newInstance(2009, 2, 15), Date.newInstance(2009, 4, 1) },  new List<Double>{ -10000.0, 2750.0, 4250.0, 3250.0, 2750.0 } );
        
        System.assertEquals( test1, 37.34 );
        
        Double test2 = c.calculate(  new List<Date>{ Date.newInstance(2013, 12, 30), Date.newInstance(2014, 5, 2), Date.newInstance(2015, 4, 17), Date.newInstance(2015, 7, 30) }, new List<Double>{ -15000000.0, 142371.0, 238467.0, 955477.0 } );
        
        System.assertEquals( test2, -80.59 );      
          
        Double test3 = c.calculate(  new List<Date>{ Date.newInstance(2013, 12, 30), Date.newInstance(2014, 5, 2), Date.newInstance(2015, 4, 17), Date.newInstance(2015, 7, 30), Date.newInstance(2015, 10, 31) }, new List<Double>{ -15000000.0, 142371.0, 238467.0, 955477.0, 14997088.0 } );
        
        System.assertEquals( test3, 4.85 );
    }
    
    @isTest static void TestXIRRTrigger() {
    
        Account a = new Account( 
            Name = 'Pepe', 
            Estimated_FMV__c = 14997088.0,
            Estimated_FMV_Date__c = Date.newInstance(2015, 10, 31)
        );
        insert a;
        
        Fund__c f = new Fund__c( 
	        Name = 'Test Fund', 
	        Non_Anthos_Investments__c = FALSE 
        );
        
        insert f;
    
        Position__c p = new Position__c(
            Account__c = a.Id,
            Fund__c = f.Id,
            Non_Anthos_Investments__c = FALSE,
            Anthos_Ownership__c = 1
        );
        
        insert p;
        
        insert new Deal_History__c(
            Date__c = Date.newInstance(2013, 12, 30), 
            Amount__c = 15000000.0, 
            Type__c = 'Investment', 
            Position__c = p.Id
        );
        
        insert new Deal_History__c(
            Date__c = Date.newInstance(2014, 5, 2), 
            Amount__c = 142371.0, 
            Type__c = 'Exit', 
            Position__c = p.Id
        );
        
        insert new Deal_History__c(
            Date__c = Date.newInstance(2015, 4, 17), 
            Amount__c = 238467.0, 
            Type__c = 'Exit', 
            Position__c = p.Id
        );
        
        insert new Deal_History__c(
            Date__c = Date.newInstance(2015, 7, 30), 
            Amount__c = 955477.0, 
            Type__c = 'Exit', 
            Position__c = p.Id
        ); 
        
        // Update Account
        a.Estimated_FMV__c = 14997088.1;
        update a;
        
        List<Position__c> pList = [SELECT Unrealized_IRR__c, Realized_IRR__c FROM Position__c WHERE Id = :p.Id];

        System.assertEquals( pList.get(0).Realized_IRR__c, -80.59 );

        System.assertEquals( pList.get(0).Unrealized_IRR__c, 4.85 );

    }  
}