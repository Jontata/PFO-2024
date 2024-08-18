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
//loop(t$(ord(t)>=1 and ord(t)<= 263),
loop(t$(ord(t)>=4 and ord(t)<= 263),
Returns(i,t) = ReturnSubset(i,t);
);



// Bootstrapping algo

//Random three periods
SET
w /w1 * w4/
s /s1 * s1000/
period /m1 * m85/
ALIAS(period,k);

SCALARS
        Budget        'Nominal investment budget'
        rand
;

Parameter
         ScenRet(i,s)
         wScenRet(i,w,s)
         CompRet(i,s,k)
         CompoundScenario(*,*)
         ;

// Picking the 4 weeks period for each of the assset creatring 1000 scenarios
// From a pool of max number of weeks 262 (5 yrs)


DIsplay period;
$ontext

LOOP(k,
 LOOP(s,
  LOOP(w, rand = uniformint(1+((ord(k)-1)*4),262+((ord(k)-1)*4));
        wScenRet(i,w,s) = sum( t$(ord(t)=rand), Returnsubset(i,t)) );
        CompRet(i,s,k) = prod(w, (1 + wScenRet(i,w,s))) - 1);
);
Display Compret;
EXECUTE_UNLOAD 'Scenarios.gdx', CompRet;
$exit


$offtext




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
       actual_returns(i)
       returns_fourweek(k,i,w)
;

Variable
z 'Objective func'
;

POSITIVE VARIABLES
    x(i)             Holdings of assets in monetary units (not proportions)
    Regrets(l)       Measures of the negative deviations or regrets
    

;

Scalar
    PercentTarget    Percent Target
    old_ExpPortReturn   Exp Portfolio Return last month
    old_PortReturn   Actual Portfolio Return last month
    Portfolio_V     Value of Portfolio
    MU_TARGET_Initial
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
MU_TARGET_Initial = 0.005195;     // 4 week return of GP portfolio



$GDXIN Scenarios
$LOAD CompRet
$GDXIN



pr(l) = 1.0 / CARD(l);
P(i,l) = 1 + CompRet ( i, l,"m1");
EP(i) = SUM(l, pr(l) * P(i,l));

TargetIndex(l) = 1.02;


BudgetCon ..         SUM(i, x(i)) =E= Budget;
                                                                         // 2013-01-16 - 2018-01-18
ReturnCon ..         SUM(i, EP(i) * x(i)) =G= (1+MU_TARGET_Initial) * Budget;   // MU_TARGET = SUM(i, P_GP(i,l) * x_GP(i))

//ConstTest ..         TestVar =e= SUM(i, EP(i) * x(i));

RegretCon(l) ..      Regrets(l) =G=  TargetIndex(l) * Budget - SUM(i, P(i,l) * x(i)); // x is not optimized for GP portfolio, from historical data

ObjDefRegret ..      z =E= SUM(l, pr(l) * Regrets(l));


MODEL MinRegret 'PFO Model 5.4.1' /BudgetCon, ReturnCon, RegretCon, ObjDefRegret/;

P(i,l) = 1 + CompRet ( i, l, "m1" );
EP(i) = SUM(l, pr(l) * P(i,l));

SOLVE MinRegret MINIMIZING z USING LP;
display x.l;
//old_x.l = x.l;


old_expportreturn = sum(i,EP(i)*x.l(i));
PARAMETER
    MU_TARGET(k)
    old_x(i)         Holdings of assets in monetary units last month
    ChosenAllocation(k,i)
    PortfolioValue(k)
    ;

POSITIVE VARIABLES
    x(i)             Holdings of assets in monetary units (not proportions)
    x_buy(i)        Holdings Bought
    x_sell(i)       Holdings Sold

;



Equations
    ReturnCon_k        Equation defining the portfolio return constraint
    ExpRegretCon_k     Equation defining the expected regret allowed
    RegretCon_k(l)     Equations defining the regret constraints
    ObjDefRegret_k     Objective function definition for regret minimization
    BuySellCon_k(i)    Ensuring that x is updated properly
    CashBalanceCon_k   Building Link between buying and selling assets
    ContainingSell(i)
;

Scalar
    MU_TARGET_k;






$GDXIN MU_TARGET
$LOAD MU_TARGET
$GDXIN


CashBalanceCon_k ..     Sum(i, x_buy(i)) =E= SUM(i,x_sell(i)) - sum(i, (x_buy(i) + x_sell(i)))*0.001;

BuySellCon_k(i) ..    x(i) =E= x_buy(i) - x_sell(i) + old_x(i);

ContainingSell(i) .. x_sell(i) =L= old_x(i);
ReturnCon_k ..         SUM(i, EP(i) * x(i)) =G= (1+MU_TARGET_k) *  Portfolio_V;

RegretCon_k(l) ..      Regrets(l) =G=  1.02 * Portfolio_V - SUM(i, P(i,l) * x(i)); // x is not optimized for GP portfolio, from historical data

ObjDefRegret_k ..      z =E= SUM(l, pr(l) * Regrets(l));

MODEL MinRegret_k 'PFO Model 5.4.1' /ContainingSell,CashBalanceCon_k, ReturnCon_k, RegretCon_k, ObjDefRegret_k, BuySellCon_k/;//, BudgetCon_k/;


//Display x.l, Budget, MU_Target_Initial;



Scalar
    Upper
    Lower;
    
SET w w1 * w4;


LOOP(k,
    //Lower = 262+(ord(k)+1)*4;
    //Upper = 262+(ord(k)+2)*4;
    loop(w,
        Lower = 263+(ord(k)-1)*4 + ord(w);
        Loop(t$(ord(t)=Lower),
        
        Returns_fourweek(k,i,w) = ReturnSubset(i,t);
        );
    );
);


//Display Returns_fourweek;


//LOOP(k$(ord(k) >= 1 and ord(k) <= 40),
LOOP(k,
    P(i,l) = 1 + CompRet ( i, l,k);
    EP(i) = SUM(l, pr(l) * P(i,l)); // needs to be updated to have the expected 4 week return for every k
    MU_TARGET_k = MU_TARGET(k);
    actual_returns(i) = PROD(w,(1+returns_fourweek(k,i,w))) -1;
    old_x(i) = x.l(i) * (1+actual_returns(i)); // updating the chosen weights with the actual returns after portfolio creation to have the true weights and portfolio value when starting the new period
    Portfolio_V = sum(i,old_x(i));
    ChosenAllocation(k,i) = x.l(i);
    PortfolioValue(k) = Portfolio_V;

    SOLVE MinRegret_k MINIMIZING z USING NLP; //NOT LP??? or NLP???
   
);
$exit
// Used for Portfolio Performance comparison
EXECUTE_UNLOAD 'RegretPortfolioValue.gdx', PortfolioValue;
// Write SummaryReport into an Excel file
EXECUTE 'gdxxrw.exe RegretPortfolioValue.gdx O=PortfolioValue_RegretBalancing.xls par=PortfolioValue rng=sheet1!a1' ;

$exit

// Used for Allocation of the Portfolio per month
Display ChosenAllocation;

$exit
EXECUTE_UNLOAD 'ChosenAllocation.gdx', ChosenAllocation;
// Write SummaryReport into an Excel file
EXECUTE 'gdxxrw.exe ChosenAllocation.gdx O=ChosenAllocation_RegretBalancing.xls par=ChosenAllocation rng=sheet1!a1' ;


$exit

