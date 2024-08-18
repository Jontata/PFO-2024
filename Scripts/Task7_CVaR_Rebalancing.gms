$title Conditional Value at Risk models

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
         ReturnSubset(i,t)                  'Subset of selected return'
         AssetReturn(Date,Asset,AssetName)  'Comment'
;

* Read from Estimate.gdx the data needed to run the mean-variance model

$GDXIN pfo_data_2024
$LOAD Date, AssetName, AssetReturn
$GDXIN

Display AssetName

//Random three periods
SET
w /w1 * w4/
s /s1 * s1000/
period /m1 * m85/
ALIAS(period,k);


set ani(an,i); //matching i and an together

loop(t$(ord(t)=1),
ani(an,i)$AssetReturn(t,i,an) = YES;
);


loop(ani(an,i),
ReturnSubset(i, t) = AssetReturn(t,i,an);
);


SCALARS
        Budget        Nominal investment budget
        alpha         Confidence level
        MU_TARGET     Target portfolio return
        MU_STEP       Target return step
        MIN_MU        Minimum return in universe
        MAX_MU        Maximum return in universe
;


Budget = 100.0;
alpha  = 0.95;

Alias(s,l);

PARAMETERS
        pr(l)       Scenario probability
        P(i,l)      Final values
        EP(i)       Expected final values
       TargetIndex(l)
;

Parameter
         CompRet(i,s,k)
;


$GDXIN Scenarios
$LOAD CompRet
$GDXIN

Display CompRet;

pr(l) = 1.0 / CARD(l);

P(i,l) = 1 + CompRet ( i, l, "m2"); ;

EP(i) = SUM(l, pr(l) * P(i,l));

MIN_MU = SMIN(i, EP(i));
MAX_MU = SMAX(i, EP(i));
MAX_MU = 1.01195;
//MU_TARGET = 0.99729920-1;

* Assume we want 20 portfolios in the frontier

MU_STEP = (MAX_MU - MIN_MU) / 20;

MU_TARGET =  1 + 0.005195;

Display MIN_MU, MAX_MU,MU_STEP;

Display P;

Display EP;


POSITIVE VARIABLES
        x(i)            Holdings of assets in monetary units (not proportions)
        VaRDev(l)       Measures of the deviations from the VaR;


VARIABLES
       VaR             Value-at-Risk
        z               Objective function value
      Losses(l)       Measures of the losses;

EQUATIONS
        BudgetCon        Equation defining the budget contraint
        ReturnCon        Equation defining the portfolio return constraint

        ObjDefCVaR       Objective function definition for CVaR minimization
        ObjDefReturn     Objective function definition for return mazimization
        LossDef(l)       Equations defining the losses
        VaRDevCon(l)     Equations defining the VaR deviation constraints
;

BudgetCon ..         SUM(i, x(i)) =E= Budget;

ReturnCon ..         SUM(i, EP(i) * x(i)) =G= MU_TARGET * Budget;

VaRDevCon(l) ..      VaRDev(l) =G= Losses(l) - VaR;

LossDef(l)..         Losses(l) =E= (Budget - SUM(i, P(i,l) * x(i)));

ObjDefCVaR ..        z =E= VaR + SUM(l, pr(l) * VaRDev(l)) / (1 - alpha);

ObjDefReturn ..      z =E= SUM(i, EP(i) * x(i));

MODEL MinCVaR  'PFO Model 5.5.1' /BudgetCon, ReturnCon, LossDef, VaRDevCon, ObjDefCVaR/;

DISPLAY MU_TARGET;
SOLVE MinCVaR MINIMIZING z USING LP;
DISPLAY x.l, z.l;





PARAMETER
    old_x(i)         Holdings of assets in monetary units last month
    PortfolioValue(k) Vector holding all PortfolioValues over months
    ChosenAllocationCVaR(k,i) Allocation of all the assets every month
    ;

POSITIVE VARIABLES
    x_buy(i)        Holdings Bought
    x_sell(i)       Holdings Sold

;

Scalar
    ExpectedReturn_k
    MU_TARGET_k
    Portfolio_V   
;

Parameter
         actual_Port_return(k)
         Returns_fourweek(i,w)
         Actual_returns(i,k)
        Act_port_return(k)
        Exp_port_return(k)
        Min_port_return(k)
        Max_port_return(k)
        SummaryReport(*,*)      'Summary report';
;


$GDXIN GP_RETURN
$LOAD Actual_Port_return
$GDXIN

Equations
    CashBalanceCon_k
    BuySellCon_k(i)
    ReturnCon_k
    LossesConCVaR_k(l)
    VardevconCVaR_k(l)
    ObjDefCVaR_k
;

Display Actual_Port_return;

CashBalanceCon_k ..     Sum(i, x_buy(i)) =E= SUM( i,x_sell(i) ) - sum(i, ( x_buy(i) + x_sell(i) ) ) * 0.001;

BuySellCon_k(i) ..    x(i) =E= x_buy(i) - x_sell(i) + old_x(i);

ReturnCon_k ..         SUM(i, EP(i) * x(i)) =G= MU_TARGET_k *  Portfolio_V;

LossesConCVaR_k(l) .. Losses(l) =e= Portfolio_V - sum(i,P(i,l) * x(i));

VardevconCVaR_k(l) ..  VarDev(l) =g= Losses(l)-VAR;

ObjDefCVaR_k  ..   z =e= VaR + (sum(s,pr(s)*Vardev(s))/(1-alpha));

MODEL CVaRModel_k 'PFO Model CVaR' /CashBalanceCon_k,BuySellCon_k,ReturnCon_k,LossesConCVaR_k,VardevconCVaR_k,ObjDefCVaR_k/;

Scalar
    Upper
    Lower;

LOOP(k,
    loop(w,
        Lower = 263+(ord(k)-1)*4 + ord(w);
        Loop(t$(ord(t)=Lower),
        Returns_fourweek(i,w) = ReturnSubset(i,t);
        );
    );
    Actual_returns(i,k) = PROD(w, (1 + returns_fourweek(i,w))) - 1;
);

// Display Actual_returns;


LOOP(k,

    P(i,l) = 1 + CompRet ( i, l, k);
    EP(i) = SUM(l, pr(l) * P(i,l)); // needs to be updated to have the expected 4 week return for every k
    MU_TARGET_k = (1 + Actual_Port_return(k));

    Display P;
    Display EP;

    old_x(i) = x.l(i) * (1 + actual_returns(i,k)); // updating the chosen weights with the actual returns after portfolio creation to have the true weights and portfolio value when starting the new period
    Portfolio_V = sum(i, old_x(i));
    PortfolioValue(k) = Portfolio_V;
    ChosenAllocationCVaR(k,i) = old_x(i);
    
    Act_port_return(k) = Portfolio_V;
    Exp_port_return(k) = sum(i,old_x(i)*EP(i));
    Min_port_return(k) = sum(i, smin(l,P(i,l))*old_x(i));
    Max_port_return(k) = sum(i, smax(l,P(i,l))*old_x(i));
SOLVE CVaRModel_k MINIMIZING z USING NLP; //NOT LP??? or NLP???


);

//Display ChosenAllocationCVaR;

// Used for the Ex-Post / Ante Analysis
SummaryReport('ActualReturn',k) = Act_port_return(k);
SummaryReport('ExpectedReturn',k) = Exp_port_return(k);
SummaryReport('WorstCaseReturn',k) = Min_port_return(k);
SummaryReport('BestCaseReturn', k) = Max_port_return(k);

Display ChosenAllocationCVaR;

$exit

// Write SummaryReport into a GDX file
EXECUTE_UNLOAD 'SummaryCVaREx-PostAnte.gdx', SummaryReport;
// Write SummaryReport into an Excel file
EXECUTE 'gdxxrw.exe SummaryCVaREx-PostAnte.gdx O=CVaR_Ex_Post_Ante.xls par=SummaryReport rng=sheet1!a1' ;


// Used for the Performance comparison of the Portfolios
$exit
EXECUTE_UNLOAD 'CVaRPortfolioValue.gdx', PortfolioValue;
// Write SummaryReport into an Excel file
EXECUTE 'gdxxrw.exe CVaRPortfolioValue.gdx O=PortfolioValue_CVaRBalancing.xls par=PortfolioValue rng=sheet1!a1' ;

$exit
// Used for the Allocation of the CVaR Portfolio
EXECUTE_UNLOAD 'ChosenAllocation_CVaR.gdx', ChosenAllocationCVaR;
// Write SummaryReport into an Excel file
EXECUTE 'gdxxrw.exe ChosenAllocation_CVaR.gdx O=ChosenAllocation_CVaR_rebalancing.xls par=ChosenAllocationCVaR rng=sheet1!a1' ;




