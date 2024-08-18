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

// Bootstrapping algo
SET
w /w1 * w4/
s /s1 * s1000/
period /m1 * m85/

ALIAS(period,k);

SCALARS
        Lower
        Upper
        rand
        V             'Portfolio value'
;

Parameter
         ScenRet(i,s)
         wScenRet(i,w,s)
         CompRet(i,s,k)
         CompoundScenario(*,*)
         ;

// Picking the 4 weeks period for each of the assset creatring 1000 scenarios
// From a pool of max number of weeks 260 rolling 4 weeks for each k (5 yrs)

LOOP(k,
 LOOP(s,
  LOOP(w,
        Lower = 8   + (ord(k)-1)*4; //  Pick from next 5 year period  8 - 267
        Upper = 267 + (ord(k)-1)*4; //
        rand = uniformint(Lower, Upper);
        wScenRet(i,w,s) = sum( t$(ord(t)=rand), Returnsubset(i,t) )
       );
        CompRet(i,s,k) = prod(w, (1 + wScenRet(i,w,s) )) - 1;
  );
);


EXECUTE_UNLOAD 'Scenarios.gdx', CompRet;

