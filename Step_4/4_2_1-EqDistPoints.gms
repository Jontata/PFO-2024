$TITLE Mean-variance model.
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

$GDXIN pfo_data_2024
$LOAD Date, AssetName, AssetReturn
$GDXIN

Display AssetName

// Matching Assets and Dates
set ani(an,i); //matching i and an together

loop(t$(ord(t)=1),
ani(an,i)$AssetReturn(t,i,an) = YES;
);

// Subsetting and Populating Returns Data
loop(ani(an,i),
ReturnSubset(i, t) = AssetReturn(t,i,an);
);


// Select the weeks from the ReturnSubset data
loop(t$(ord(t)>1 and ord(t)<= 263),
Returns(i,t) = ReturnSubset(i,t);
);

// Calculating Expected Returns
Parameter
         ExpectedTotalReturns(i)
         ExpectedAnnualReturns(i)
         ExpectedWeeklyReturns(i)
         ;

ExpectedTotalReturns(i) = (PROD(t, (1+Returns(i,t))));
ExpectedAnnualReturns(i) = ExpectedTotalReturns(i) ** (1 / (262 / 52)) - 1;
ExpectedWeeklyReturns(i) = ExpectedTotalReturns(i) ** (1 / 262) - 1;

Display ExpectedTotalReturns, ExpectedAnnualReturns;

// Variance-Covariance Matrix Calculation
ALIAS (i,j);
Table VarCov(i,j);
loop((i,j), VarCov(i,j) = 52*sum(t,(Returns(i,t)-ExpectedWeeklyReturns(i))*(Returns(j,t)-ExpectedWeeklyReturns(j))/(262)));

// Defining Scalars for Portfolio Characteristics
SCALAR
    lambda 'Risk attitude'
    SydInvestStd 'Std of current portfolio'
    SydInvestReturn 'Return of current portfolio';
SydInvestStd = 0.0809;
SydInvestReturn = 0.064149;

// overwrite value of std
SydInvestStd = SMax((i,j), VarCov(i,j));  //I initialize VarLevel to its biggest possible level
DISPLAY SydInvestStd


POSITIVE VARIABLES
    x(i) Holdings of assets;

VARIABLES
    PortVariance Portfolio variance
    PortReturn   Portfolio return
    z            Objective function value;

EQUATIONS

    ReturnDef    'Equation defining the portfolio return'
    VarDef       'Equation defining the portfolio variance'
    NormalCon    'Equation defining the normalization contraint'
    VarCon       'Constraint on portfolio variance to be used in formulation two'
    ObjDef       'Objective function definition';

ReturnDef ..   PortReturn    =e= SUM(i, ExpectedAnnualReturns(i)*x(i));

VarDef    ..   PortVariance  =e= SUM((i,j), x(i)*VarCov(i,j)*x(j));

NormalCon ..   SUM(i, x(i))  =e= 1;

VarCon   ..    PortVariance  =l= SydInvestStd;

ObjDef    ..   z             =e= (1-lambda) * PortReturn - lambda * PortVariance;

MODEL MeanVar 'PFO Model 4.2' /ReturnDef,VarDef,NormalCon, VarCon, ObjDef/;

* Output directly to an Excel file through the GDX utility
SET FrontierPoints / PP_0 * PP_9 /
ALIAS (FrontierPoints,p);

PARAMETERS
         RiskWeight(p)           'Investor risk attitude parameter'
         PortfolioVariance(p)    'Optimal level of portfolio variance'
         PortfolioReturn(p)      'Portfolio return'
         OptimalAllocation(p,i)  'Optimal asset allocation'
         SolverStatus(p,*)       'Status of the solver'
         SummaryReport(*,*)      'Summary report';


Scalar MaxVar, MinVar, Stepsize; //These are helping scalars for calculating the step size in my equidistant efficient frontier


//First I need to find the risk neutral portfolio
lambda = 0;
SOLVE MeanVar MAXIMIZING z USING NLP;
PortfolioVariance(p)$(ord(p)=1) = PortVariance.l;
PortfolioReturn(p)$(ord(p)=1) = PortReturn.l;
OptimalAllocation(p,i)$(ord(p)=1) = x.l(i);

MaxVar = PortVariance.l; //Saving the value of the maximum variance for step size calculation


//Then I need to find the risk averse portfolio
lambda = 1;
SOLVE MeanVar MAXIMIZING z USING NLP;
PortfolioVariance(p)$(ord(p)=card(p)) = PortVariance.l;
PortfolioReturn(p)$(ord(p)=card(p)) = PortReturn.l;
OptimalAllocation(p,i)$(ord(p)=card(p)) = x.l(i);

MinVar = PortVariance.l; //Saving the value of the minimum variance for step size calculation


display PortfolioVariance, PortfolioReturn, OptimalAllocation, MaxVar, MinVar;

//Now I calculate the stepsize
Stepsize = (MaxVar-MinVar) / (Card(p)-1) ;

display Stepsize;

//Now we are ready to generate the remaining points of the efficient frontier in equidistant steps of portfolio variance

SydInvestStd = MaxVar; //We start from the right most value of the portfolio variance
lambda = 0; // I remove the risk term so we change the model to the second formulation

// Generate remaining points of the efficient frontier in equidistant steps of portfolio variance
LOOP(p$(ord(p)>1),
   SydInvestStd = SydInvestStd - Stepsize;
   SOLVE MeanVar MAXIMIZING z USING NLP;
   PortfolioVariance(p)= PortVariance.l;
   PortfolioReturn(p)  = PortReturn.l;
   OptimalAllocation(p,i)     = x.l(i);
);

SummaryReport(i,p) = OptimalAllocation(p,i);
SummaryReport('Variance',p) = PortfolioVariance(p);
SummaryReport('Return',p) = PortfolioReturn(p);

display SummaryReport;

// Write SummaryReport into a GDX file
EXECUTE_UNLOAD '42SummaryEqDist.gdx', SummaryReport;
// Write SummaryReport into an Excel file
EXECUTE 'gdxxrw.exe 42SummaryEqDist.gdx O=42MeanVarianceFrontier_EqDist.xls par=SummaryReport rng=sheet1!a1' ;
















