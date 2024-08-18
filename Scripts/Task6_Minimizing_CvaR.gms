Options  decimals = 8;
$eolcom //

SET Date  'Dates'
    Asset 'Assets' /DK0016272602
, DK0060012466, DK0061542719, DK0060761492, LU0376447149, DK0060786218,
                         DK0060244325, DK0010264456, DK0061543600, DK0016306798, IE00BM67HS53, DK0060786994,
                         DK0060497378, DK0060787026, DK0016205255, DK0016262728, DK0060300929, DK0060446896,
                         DK0060498509, LU0249702647, DK0016044654, DK0060034007, DK0060009405, LU0123484106,
                         DK0060037455, DK0060158160, GB00B05BHT55, GB00B0XNFF59, DK0061553245,
                         DK0061150984, DK0060227239, DK0000581109, DK0060051282, DK0015942650, DK0060158590/
    AssetName
;

Alias(Date,t);
Alias(Asset,i);
Alias(AssetName,an);

PARAMETERS
         Returns(i,t)
         ReturnSubset(i,t)                  'Subset of selected return'
         AssetReturn(Date,Asset,AssetName)  'Comment'
;

* Read from Estimate.gdx the data needed to run the mean-variance model

$GDXIN pfo_data_2024
$LOAD Date, AssetName, AssetReturn
$GDXIN

Display AssetName


set ani(an,i); //matching i and an together

loop(t$(ord(t)=1),
ani(an,i)$AssetReturn(t,i,an) = YES;
);

Display ani

loop(ani(an,i),
ReturnSubset(i, t) = AssetReturn(t,i,an);
);


// Select the weeks from the ReturnSubset data
loop(t$(ord(t)>=1 and ord(t)<= 263),
Returns(i,t) = ReturnSubset(i,t);
);

Display Returns;


Parameter
         ExpectedTotalReturns(i)
         ExpectedAnnualReturns(i)
         ExpectedWeeklyReturns(i)
         ;

ExpectedTotalReturns(i) = (PROD(t, (1+Returns(i,t))));
ExpectedAnnualReturns(i) = ExpectedTotalReturns(i) ** (1 / (262 / 52)) - 1;
ExpectedWeeklyReturns(i) = ExpectedTotalReturns(i) ** (1 / 262) - 1;


Display ExpectedTotalReturns, ExpectedAnnualReturns;

// Bootstrapping algo

//Random three periods
SET
w /w1 * w4/
s /s1 * s1000/

SCALARS
        Budget        'Nominal investment budget'
        alpha         'Confidence level'
        MU_Target     'Target portfolio return'
        MIN_MU        'Minimum return in universe'
        MAX_MU        'Maximum return in universe'
        rand
        MAX_Return
        MIN_Return
        AVG_return
        probs
        GrandparentFourWeek
        GrandparentCVaR
;

Budget = 100.0;
alpha  = 0.95;
GrandparentFourWeek = 0.519;
GrandparentCVaR = 102.75;

//PARAMETERS
        //pr(l)       'Scenario probability'
        // P(i,l)      'Final values'
       // EP(i)       'Expected final values'
//;

Variable
    CVaR
    Losses(s)
    z
    VaR
    PortReturnReturn
    z_Return
    ;

Positive Variable
    VarDev(s)
    x(i);

Binary Variable
    y(s);


Parameter
         ScenRet(i,s)
         wScenRet(i,w,s)
         //AssetReturns(i,l)
         CompRet(i,s)
         CompoundScenario(*,*)
         //OneoveNReturns(s)
         //Ps(i,s)
         //Epss(i)
         ;

// Picking the 4 weeks period for each of the assset creatring 1000 scenarios
// From a pool of max number of weeks 262 (5 yrs)

LOOP(s,
  LOOP(w, rand = uniformint(1,262);
        wScenRet(i,w,s) = sum( t$(ord(t)=rand), Returns(i,t)) );
        CompRet(i,s) = prod(w, (1 + wScenRet(i,w,s))) - 1);

//CompoundScenario(i,s) = compret(i,s);

Display CompRet



PARAMETERS
        pr(s)       'Scenario probability'
        P(i,s)      'Final values'
        EP(i)       'µ(i)'
      
;

Variable
    VAR
    x(i)
    Losses(s)
    z
    ;
    
Positive Variable
    VarDev(s);

Binary Variable
    y(s);
    
    
pr(s) = 1.0 / CARD(s);


P(i,s) = 1 + CompRet ( i, s);
EP(i) = SUM(s, pr(s) * P(i,s));

display EP, CompRet;




MIN_MU = SMIN(i, EP(i));
MAX_MU = SMAX(i, EP(i));
display MIN_MU, MAX_MU, pr;

MU_TARGET = MIN_MU;
MU_TARGET = MAX_MU;
MU_Target = (Max_mu + Min_mu)/2;

scalar HighestLoss;
HighestLoss = Budget*(smax((i,s), CompRet(i,s) )- smin((i,s), CompRet(i,s)));
display HighestLoss, MU_Target;



//Complete the code from here

Equations
    Budgetcon
    ReturnDefReturn        
    ObjDef       
    VardevCon    
    HighestLossCon
    Alphacon
    BudgetconCVaR
    TargetconCVaR
    LossesConCVaR(s)
    VardevconCVaR(s)
    CvarConCVaR
    ObjDefCVaR
    ReturnConstraint
    ObjDefMaxReturn
    CVaRCon
    ReturnCon
;



GrandparentFourWeek = 0.005195;


BudgetCon ..         SUM(i, x(i)) =E= Budget;

//ReturnCon ..         SUM(i, EP(i) * x(i)) =G= (1 + GrandparentFourWeek) * Budget;  

ReturnDefReturn ..   PortReturnReturn    =e= SUM(i, EP(i) * x(i));

TargetconCVaR     ..   sum(i,EP(i)*x(i))  =g= MU_Target * Budget ;

LossesConCVaR(s) .. Losses(s) =e= Budget - sum(i,P(i,s) * x(i));

VardevconCVaR(s) ..  VarDev(s) =g= Losses(s)-VAR;

//ObjDefCVaR  ..   z =e= VaR + (sum(s,pr(s)*Vardev(s))/(1-alpha));

ObjDefMaxReturn    ..   z_Return =e= PortReturnReturn;

CVaRCon .. CVaR =l= GrandparentCVaR;  

//MODEL CVaRModel 'PFO Model CVaR' /BudgetCon,ReturnCon,LossesConCVaR,VardevconCVaR,ObjDefCVaR/;


//SOLVE CVaRModel MINIMIZING z USING lp;

//Display z.l, x.l, P;


MODEL CVaRModelMax 'PFO Model CVaR' /Budgetcon,ReturnDefReturn,TargetconCVaR,LossesConCVaR,VardevconCVaR,ObjDefMaxReturn, CVaRCon/;


SOLVE CVaRModelMax MAXIMIZING z_Return USING lp;

Display CVaR.l, x.l, PortReturnReturn.l;







