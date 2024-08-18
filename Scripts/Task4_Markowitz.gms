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
loop(t$(ord(t)>1 and ord(t)<= 263),
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

ALIAS (i,j);
Table VarCov(i,j);
loop((i,j), VarCov(i,j) = 52*sum(t,(Returns(i,t)-ExpectedWeeklyReturns(i))*(Returns(j,t)-ExpectedWeeklyReturns(j))/(262)));

Display VarCov;

;
display i, ExpectedWeeklyReturns, VarCov;
* Risk attitude: 0 is risk-neutral, 1 is very risk-averse.;
SCALAR
    lambda 'Risk attitude'
    SydInvestStd 'Std of current portfolio'
    SydInvestReturn 'Return of current portfolio';
SydInvestStd = 0.0809;
SydInvestReturn = 0.064149;


POSITIVE VARIABLES
    X_return(i) 'Holdings of assets'
    X_var(i) 'Holdings of assets';  ;

VARIABLES
    PortVarianceReturn 'Portfolio variance'
    PortVarianceVar 'Portfolio variance'
    PortReturnReturn   'Portfolio return'
    PortReturnVar 'Portfolio return'
    z_Return            'Objective function value'
    z_Var            'Objective function value'
    PortStd 'Portfolio std';


EQUATIONS
    ReturnDefReturn    'Equation defining the portfolio return'
    ReturnDefVar    'Equation defining the portfolio return'
    VarDefReturn       'Equation defining the portfolio variance'
    VarDefVar       'Equation defining the portfolio variance'
    NormalConReturn    'Equation defining the normalization contraint'
    NormalConVar   'Equation defining the normalization contraint'
    ObjDefMaxReturn       'Objective function definition'
    ObjDefMinVar       'Objective function definition'
    MaxStd       'Maximal allowed Portfolio Std'
    MinReturn 'Minimal achievable Return';



ReturnDefReturn ..   PortReturnReturn    =e= SUM(i, ExpectedAnnualReturns(i) * X_return(i));

ReturnDefVar ..   PortReturnVar    =e= SUM(i, ExpectedAnnualReturns(i) * X_var(i));

VarDefReturn    ..   PortVarianceReturn  =e= SUM((i,j), X_return(i) * VarCov(i,j) * X_return(j));

VarDefVar   ..   PortVarianceVar  =e= SUM((i,j), X_var(i) * VarCov(i,j) * X_var(j));

MaxStd ..      sqrt(PortVarianceReturn)  =l= SydInvestStd;

MinReturn .. PortReturnVar =g=  SydInvestReturn;

NormalConReturn ..   SUM(i, X_return(i))  =e= 1;

NormalConVar .. SUM(i,X_var(i)) =e= 1;

ObjDefMinVar .. z_Var =e= PortVarianceVar;

ObjDefMaxReturn    ..   z_Return =e= (1-lambda)*PortReturnReturn;
// Markowitz model for maximizing return
MODEL MeanVarMaxReturn 'PFO Model 3.2.3' /ReturnDefReturn, VarDefReturn, NormalConReturn, ObjDefMaxReturn, MaxStd/;
// Markowitz model for minimizing volatility
MODEL MeanVarMinVar 'PFO Model 3.2.3' /ReturnDefVar, VarDefVar, MinReturn, NormalConVar, ObjDefMinVar/;

lambda = 0;
SOLVE MeanVarMaxReturn MAXIMIZING z_Return USING nlp;
display x_return.l, PortVarianceReturn.l, PortReturnReturn.l, SydInvestStd;

//MODEL MeanVarMinStd 'PFO Model;

SOLVE MeanVarMinVar MINIMIZING z_Var USING nlp;
display x_var.l, PortVarianceVar.l, PortReturnVar.l, SydInvestReturn;
*Comments are made using (*)

