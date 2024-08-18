Options  decimals = 8;
$eolcom //

SET Date  'Dates'
    //Asset 'Assets' /DK0060647444, DK0015323406, DK0016098825, DK0015916225, DK0060036994, DK0010270776/
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


// Select the weeks from the ReturnSubset data (5 years)
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
        rand
;

Parameter
         ScenRet(i,s)
         wScenRet(i,w,s)
         CompRet(i,s)
         CompoundScenario(*,*)
         ;

// Picking the 4 weeks period for each of the assset creatring 1000 scenarios
// From a pool of max number of weeks 262 (5 yrs)

LOOP(s,
  LOOP(w, rand = uniformint(1,262);
        wScenRet(i,w,s) = sum( t$(ord(t)=rand), Returns(i,t)) );
        CompRet(i,s) = prod(w, (1 + wScenRet(i,w,s))) - 1);

//CompoundScenario(i,s) = compret(i,s);

// Display CompRet

// Downside Regret model
Alias(s,l);


PARAMETERS
       TargetIndex(l)   Target index returns
       pr(l)      'Scenario probability'
       P(i,l)      'Final values'
       EP(i)       'Expected final values'
       EP_GP(i)    'Expected final values for grandparents'
       Avg_Downside_Regret

;

Variable
z 'Objective func'
;

POSITIVE VARIABLES
    x(i)             Holdings of assets in monetary units (not proportions)
    Regrets(l)       Measures of the negative deviations or regrets
;

Scalar
    MU_TARGET        Target portfolio return
    PercentTarget    Percent Target
;

Equations
    BudgetCon        Equation defining the budget contraint
    ReturnCon        Equation defining the portfolio return constraint
    ExpRegretCon     Equation defining the expected regret allowed
    RegretCon(l)     Equations defining the regret constraints
    ObjDefRegret     Objective function definition for regret minimization
    ConstTest
  ;

Budget = 100.0;
//PercentTarget = 0.0947;
//MU_TARGET = 1 + PercentTarget; //Wrong Expected Return for this period 2013-2018


//MU_TARGET = 0.72;      // 5 year return of GP portfolio
//MU_TARGET = 0.1138;    // 1 year return of GP portfolio
MU_TARGET = 0.005195;     // 4 week return of GP portfolio
//MU_TARGET = 0.02;     // 4 week return of GP portfolio


pr(l) = 1.0 / CARD(l);

P(i,l) = 1 + CompRet ( i, l );
TargetIndex(l) = 1.02;

EP(i) = SUM(l, pr(l) * P(i,l));

BudgetCon ..         SUM(i, x(i)) =E= Budget;
                                                                         // 2013-01-16 - 2018-01-18
ReturnCon ..         SUM(i, EP(i) * x(i)) =G= (1+MU_TARGET) * Budget;   // MU_TARGET = SUM(i, P_GP(i,l) * x_GP(i))

//ConstTest ..         TestVar =e= SUM(i, EP(i) * x(i));

RegretCon(l) ..      Regrets(l) =G=  TargetIndex(l) * Budget - SUM(i, P(i,l) * x(i)); // x is not optimized for GP portfolio, from historical data

ObjDefRegret ..      z =E= SUM(l, pr(l) * Regrets(l));

MODEL MinRegret 'PFO Model 5.4.1' /BudgetCon, ReturnCon, RegretCon, ObjDefRegret/;

SOLVE MinRegret MINIMIZING z USING LP;

Avg_Downside_Regret = SUM(l, pr(l) * Regrets.l(l));

Display x.l, Regrets.l, z.l, MU_TARGET, Avg_Downside_Regret;


//----    171 VARIABLE x.L  Holdings of assets in monetary units (not proportions)

//DK0016272602 19.69283054,    LU0376447149 11.05463934
//DK0060158160 35.48561775,    GB00B05BHT55 33.76691237

//----    171 REGRET VARIABLE z.L                   =   0.98878056  Objective func
