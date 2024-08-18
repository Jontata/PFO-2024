$TITLE Mean-variance model.
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

* Risk attitude: 0 is risk-neutral, 1 is very risk-averse.;
SCALAR
    lambda 'Risk attitude';

POSITIVE VARIABLES
    X(i) 'Holdings of assets';

VARIABLES
    PortVariance 'Portfolio variance'
    PortReturn   'Portfolio return'
    z            'Objective function value';

EQUATIONS
    ReturnDef    'Equation defining the portfolio return'
    VarDef       'Equation defining the portfolio variance'
    NormalCon    'Equation defining the normalization constraint'
    ReturnCon    'Equation defining the min return constraint'
    ObjDef       'Objective function definition';

// Standard stuff

ReturnDef ..   PortReturn    =e= SUM(i, ExpectedAnnualReturns(i) * X(i));

VarDef    ..   PortVariance  =e= SUM((i,j), X(i) * VarCov(i,j) * X(j));

NormalCon ..   SUM(i, X(i))  =e= 1;

// Step 4, part 2:

SCALAR
    SydInvestStd    /0.0809/
    SydInvestReturn /0.064149/;

ReturnCon .. PortReturn =g=  SydInvestReturn;

ObjDef    ..   z =e= (1-lambda) * PortReturn - lambda * PortVariance;

MODEL MaxReturnModel 'model 4-1-1' /ReturnDef, VarDef, NormalCon, ReturnCon, ObjDef/;

lambda = 1;
// With lambda = 1, z=-PortVariance, i.e. we minimize variance 
SOLVE MaxReturnModel MAXIMIZE z USING nlp;
display X.l, PortVariance.l, PortReturn.l, SydInvestStd;

// Define output file
FILE results / 'results.txt' /;

// Write results to file
PUT results 'Maximizing return with STD constraint' /;
PUT results 'Portfolio return: ' PortReturn.L /;
PUT results 'Portfolio variance: ' PortVariance.L /;
PUT results 'Portfolio holdings:' /;
LOOP (i, 
    PUT results X.L(i);
);

DISPLAY PortReturn.L, PortVariance.L, X.L;


