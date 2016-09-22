/*
 * - https://github.com/ept/jxirr/blob/master/src/main/java/in/satpathy/financial/XIRR.java
 * - Gnumeric
 */

public with sharing class XIRR {

    public GoalxirrData xirrData {get; set;}
    
    private static final boolean DEBUG_GOAL_SEEK = false ;
    private static final Integer GOAL_SEEK_OK     = 0 ;
    private static final Integer GOAL_SEEK_ERROR  = 1 ;

    public XIRR(){
        xirrData = new GoalxirrData();
        xirrData.guess  = 0.1 ;
        
		xirrData.dates = new List<Date>();
		xirrData.values = new List<Double>();
    }
    
    public void addCashFlow( Date d, Double v ){
    	if( d != NULL && v != NULL ){
    		xirrData.dates.add( d );
    		xirrData.values.add( v );
    	}
    }
        
    public Decimal calculate( List<Date> dates, List<Double> values ){

        xirrData.values = values;
        xirrData.dates  = dates;
        
        return xirr(); 
    }  

    public Decimal xirr(){

        GoalSeekData data = new GoalSeekData() ;
        GoalSeekStatus status;
        
        Double result;
        Double rate0;
        Integer n;
        Integer d_n;
        
        if( xirrData.values.size() < 1 || xirrData.dates.size() != xirrData.values.size() ) return null;
        
        Boolean hasPositive = false;
        Boolean hasNegative = false;
        
        for( Double v : xirrData.values ){
            if( v > 0.0 ) hasPositive = true;
            else if( v < 0.0 ) hasNegative = true;
        }
        
        if( !( hasPositive && hasNegative ) ) return null;
        
        xirrData.n      = xirrData.values.size();
        
        goal_seek_initialize( data ) ;
        data.xmin   = -1;
        data.xmax   = Math.min( 1000, data.xmax ) ;
        rate0       = xirrData.guess ; //argv[2] ? value_get_as_float (argv[2]) : 0.1;        
        
        status = goalSeekNewton( new XIRRNPV(), null, data, xirrData, rate0 ) ;
        
        if (status.seekStatus == GOAL_SEEK_OK)  {
            
            result = Double.valueOf( status.returnData );
        }else{
            result = null;
        }
        
        result = ( Decimal.valueOf( ( result != null ) ? (result - 1) : 0 ) * 100 ).setScale(2);
            
        System.debug( 'XIRR Result = ' + result ) ;
        
        return result;
    }
    
    /**
     *  Seek a goal (root) using Newton's iterative method.
     *
     *  The supplied function must (should) be continously differentiable in
     *  the supplied interval.  If NULL is used for `df', this function will
     *  estimate the derivative.
     *
     *  This method will find a root rapidly provided the initial guess, x0,
     *  is sufficiently close to the root.  (The number of significant digits
     *  (asympotically) goes like i^2 unless the root is a multiple root in
     *  which case it is only like c*i.)
     */
     
    public GoalSeekStatus goalSeekNewton(
                                        XIRRNPV f,
                                        XIRRNPV df,
                                        GoalSeekData data,
                                        GoalxirrData userData, 
                                        double x0 ) {

        Integer iterations;
        double precision = data.precision / 2;
        
        if ( data.have_root )   {
            return new GoalSeekStatus( GOAL_SEEK_OK, Double.valueOf(data.root) );
        }
        
        if ( DEBUG_GOAL_SEEK ) system.debug( '\n\n goalSeekNewton \n\n' ) ;

        
        for (iterations = 0; iterations < 100; iterations++) {
            Double x1 ;
            Double y0 ;
            Double df0 ;
            Double stepsize ;
            GoalSeekStatus status;
            
            if ( DEBUG_GOAL_SEEK ) system.debug( 'goalSeekNewton - x0 = ' + x0 + ', (i = ' + iterations + ' )' ) ;
            
            if ( x0 < data.xmin || x0 > data.xmax ) {
                return new GoalSeekStatus( GOAL_SEEK_ERROR, null );
            }

            status = f.f(x0, userData ) ; //y0, userData) ;

            if ( status.seekStatus != GOAL_SEEK_OK )   {
                return status ;
            }

            y0 = Double.valueOf( status.returnData );
            if ( DEBUG_GOAL_SEEK ) system.debug( '   y0 = ' + y0 );
            
            if ( update_data(x0, y0, data) ){
                return new GoalSeekStatus( GOAL_SEEK_OK, Double.valueOf(data.root) );
            }
            
            if ( df != null ) {
            
                status = df.f( x0, userData ) ;
                
            }else{
                
                Double xstep;
                
                if ( Math.abs(x0) < data.precision ) {
                
                    if (data.havexneg && data.havexpos)
                        xstep = Math.abs(data.xpos - data.xneg) / 1000000;
                    else
                        xstep = (data.xmax - data.xmin) / 1000000;
                        
                }else{
                    xstep = Math.abs(x0) / 1000000;
                }
                
                status = fake_df(f, x0, xstep, data, userData) ;
            }
            
            if( status.seekStatus != GOAL_SEEK_OK ){
                return status;
            }
            
            df0 = Double.valueOf( status.returnData );
            //  If we hit a flat spot, we are in trouble.
            if ( df0 == 0 ) {
                return new GoalSeekStatus( GOAL_SEEK_ERROR, null );
            }       
            
            /*
             * Overshoot slightly to prevent us from staying on
             * just one side of the root.
             */
             
            x1 = x0 - 1.000001 * y0 / df0;
            
            stepsize = Math.abs(x1 - x0) / (Math.abs(x0) + Math.abs(x1)) ;
            
            if ( DEBUG_GOAL_SEEK ) {
                system.debug( '    df0 = ' + df0 ) ;
                system.debug( '   ss = ' + stepsize ) ;
            }
            
            x0 = x1;
            
            if ( stepsize < precision ) {
                data.root = x0;
                data.have_root = true;
                return new GoalSeekStatus( GOAL_SEEK_OK, Double.valueOf(data.root) );
            }
             
        }
        
        return new GoalSeekStatus( GOAL_SEEK_ERROR, null ) ; //GOAL_SEEK_ERROR
    }
    
    /**
     *  Initialize a GoalSeekData object.
     */
    public static void goal_seek_initialize( GoalSeekData data )    {
        data.havexpos = data.havexneg = data.have_root = false;
        data.xpos = data.xneg = data.root = null ; //gnm_nan;
        data.ypos = data.yneg = null ; //gnm_nan ;
        data.xmin = -10000000000.0; //-1e10;
        data.xmax = 10000000000.0; //+1e10;
        data.precision = 0.0000000001; // 1e-10;
    }
    /**
     *
     *  @param x
     *  @param y
     *  @param data
     *  @return
     */
    public static boolean update_data( double x, double y, GoalSeekData data ){
        if (y > 0) {
            if (data.havexpos) {
                if (data.havexneg) {
                    /*
                     *  When we have pos and neg, prefer the new point only
                     *  if it makes the pos-neg x-internal smaller.
                     */
                    if (Math.abs(x - data.xneg) < Math.abs(data.xpos - data.xneg)) {
                        data.xpos = x;
                        data.ypos = y;
                    }
                }
                else if (y < data.ypos) {
                    /* We have pos only and our neg y is closer to zero.  */
                    data.xpos = x;
                    data.ypos = y;
                }
            }
            else {
                data.xpos = x;
                data.ypos = y;
                data.havexpos = true  ;
            }
            return false  ;
        }
        else if (y < 0) {
            if (data.havexneg) {
                if (data.havexpos) {
                    /*
                     * When we have pos and neg, prefer the new point only
                     * if it makes the pos-neg x-internal smaller.
                     */
                    if (Math.abs(x - data.xpos) < Math.abs(data.xpos - data.xneg)) {
                        data.xneg = x;
                        data.yneg = y;
                    }
                }
                else if (-y < -data.yneg) {
                    /* We have neg only and our neg y is closer to zero.  */
                    data.xneg = x;
                    data.yneg = y;
                }

            }
            else {
                data.xneg = x;
                data.yneg = y;
                data.havexneg = true;
            }
            return false  ;
        }
        else {
            /* Lucky guess...  */
            data.have_root = true  ;
            data.root = x  ;
            return true  ;
        }
    }
    
    /*
     *  Calculate a reasonable approximation to the derivative of a function
     *  in a single point.
     */
    public static GoalSeekStatus fake_df( XIRRNPV f, double x,
                                          double xstep, GoalSeekData data,
                                          GoalxirrData userData) {
                                          
        double          xl ;
        double          xr ;
        double          yl ;
        double          yr ;
        double          dfx ;
        GoalSeekStatus  status;
        
        if ( DEBUG_GOAL_SEEK ) system.debug( 'fake_df (x = ' + x +', xstep = ' + xstep + ')' ) ;
        
        xl = x - xstep;
        if (xl < data.xmin)
            xl = x;

        xr = x + xstep;
        if (xr > data.xmax)
            xr = x;

        if (xl == xr) { 
            if ( DEBUG_GOAL_SEEK ) system.debug( '==> xl == xr' ) ;
            return new GoalSeekStatus( GOAL_SEEK_ERROR, null ) ;
        }
        
        status = f.f( xl, userData ) ;
        
        if ( status.seekStatus != GOAL_SEEK_OK ) {
            if ( DEBUG_GOAL_SEEK ) system.debug( '==> failure at xl\n' ) ;
            return status;
        }
        
        yl = Double.valueOf( status.returnData ) ;
        if ( DEBUG_GOAL_SEEK ) system.debug( '==> xl = ' + xl + ' ; yl =' + yl ) ;
        status = f.f( xr, userData ) ;  //yr, userData ) ;
        
        if (status.seekStatus != GOAL_SEEK_OK) {
            if ( DEBUG_GOAL_SEEK ) system.debug( '==> failure at xr' ) ;
            return status;
        }
        
        yr = Double.valueOf( status.returnData ) ;
        if ( DEBUG_GOAL_SEEK ) system.debug( '==> xr = ' + xr + ' ; yr =' + yr ) ;    
        
        dfx = (yr - yl) / (xr - xl) ;
        if ( DEBUG_GOAL_SEEK ) system.debug( '==> ' + dfx ) ;    
                                          
        //return Double.isInfinite(dfx) ?
        //       new GoalSeekStatus( GOAL_SEEK_ERROR, null) :
        //       new GoalSeekStatus( GOAL_SEEK_OK, Double.valueOf(dfx) ) ;
               
               
        return new GoalSeekStatus( GOAL_SEEK_OK, Double.valueOf(dfx) ) ;
    }

    
    public class GoalxirrData {
    
        public Integer          n ;
        public Double       guess ;
        public Double[]     values ;
        public Date[]     dates ;
 
        public GoalxirrData(){}
    }
    
    public class XIRRNPV{
        
        public XIRRNPV() {}
        
        /**
         *
         *  @param rate
         *  @param y
         *  @param userData
         *  @return
         */
        public GoalSeekStatus f( Double rate, GoalxirrData userData ) {
                
            GoalxirrData p;
            Double[]    values ;
            Date[]    dates ;
            Double      sum ;
            Integer         n ;
            
            p       = userData ;
            values  = p.values ;
            dates   = p.dates ;
            n       = p.n ;
            sum     = 0 ;
            
            for ( Integer i = 0; i < n; i++ ) {
            
                double d = dates.get(0).daysBetween( dates.get(i) ); // dates[i] - dates[0];
                
                if ( d < 0 )  {
                    return new GoalSeekStatus( GOAL_SEEK_ERROR, null) ;
                }
                
                sum += values.get(i) / Math.pow(rate, Double.valueOf( d / 365.0 ) ) ; //pow1p( rate, d / 365.0 ) ;
            }
        
            return new GoalSeekStatus( GOAL_SEEK_OK, Double.valueOf( sum ) ) ;
        }
    }
    
    public class GoalSeekData {
    
        public Double   xmin;             /* Minimum allowed values for x.  */
        public Double   xmax;             /* Maximum allowed values for x.  */
        public Double   precision;        /* Desired relative precision.  */
    
        public Boolean  havexpos;        /* Do we have a valid xpos?  */
        public Double   xpos;             /* Value for which f(xpos) > 0.  */
        public Double   ypos;             /* f(xpos).  */
    
        public Boolean  havexneg;        /* Do we have a valid xneg?  */
        public Double   xneg;             /* Value for which f(xneg) < 0.  */
        public Double   yneg;             /* f(xneg).  */
    
        public Boolean  have_root;       /* Do we have a valid root?  */
        public Double   root;             /* Value for which f(root) == 0.  */
        
        public GoalSeekData(){}
    } 

    public class GoalSeekStatus {

        public Integer      seekStatus ;
        public Double   returnData ;
    
        public GoalSeekStatus( Integer pStatus, Double retData ) {
            this.seekStatus = pStatus ;
            this.returnData = retData ;
        }
    
        public Integer getSeekStatus() {
            return seekStatus;
        }
    
        public void setSeekStatus( Integer seekStatus ) {
            this.seekStatus = seekStatus;
        }
    
        public Double getReturnData() {
            return returnData;
        }
    
        public void setReturnData( Double returnData ) {
            this.returnData = returnData;
        }
    
        public String tooString() {
            return 'Status - ' + seekStatus + ', Return Data - ' + returnData ;
        }
    }
}