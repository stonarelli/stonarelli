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
    
}
