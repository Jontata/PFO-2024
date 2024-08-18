Options  decimals = 8;
$eolcom //
SET Date  'Dates'
    Asset 'Assets' /DK0060647444, DK0015323406, DK0016098825, DK0015916225, DK0060036994, DK0010270776/
    AssetName
;

Alias(Date,t);
Alias(Asset,i);
Alias(AssetName,an);

PARAMETERS
         Returns(i,t)
         ReturnSubset(i,t)                  'Subset of selected return'
         AssetReturn(Date, Asset, AssetName)  'Comment'
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
        Lower
        Upper
        rand
;

Parameter
         ScenRet(i,s)
         wScenRet(i,w,s)
         CompRet(i,s,k)
         CompoundScenario(*,*)
         pr(s)
         P(i,s,k)
         EP(i,k)
         ;

// Compute Scenarios for each k
LOOP(k,
     LOOP(s,
         LOOP(w,
              Lower = 8   + (ord(k)-1)*4; //  Pick from next 5 year period  8 - 267
              Upper = 267 + (ord(k)-1)*4; //
              rand = uniformint(Lower, Upper);
              //Display rand, Lower, Upper;
              wScenRet(i,w,s) = sum(t$(ord(t)=rand), Returnsubset(i,t));
         );
              CompRet(i,s,k) = prod(w, (1 + wScenRet(i,w,s))) - 1;
     );
);

SCALARS
        lower
        upper
        Budget        'Nominal investment budget'
        rand
        V             'Portfolio value'
;

Parameter
         Weights(i)
         MU_TARGET(k)
         ExpectedReturn(k)
;

// Weights in 2018 -- And update them using actual returns

//W = 158 + 1339 + 633 + 1009 + 315 + 3046;

Weights('DK0060647444') = 0.053732;
Weights('DK0015323406') = 0.242239;
Weights('DK0016098825') = 0.168069;
Weights('DK0015916225') = 0.244297;
Weights('DK0060036994') = 0.105427;
Weights('DK0010270776') = 0.186237;

pr(s) = 1.0 / CARD(s);
P(i,s,k) = 1 + CompRet (i,s,k);
EP(i,k) = SUM(s, pr(s) * P(i,s,k));

// Combinding everything together

Parameter
         ExpectedReturn(k)
         Actual_returns(i)
         Returns_fourweek(k,i,w)
;

LOOP(k,
    loop(w,
        Lower = 263+(ord(k)-1)*4 + ord(w); //263 because 263 + ord(w)=1 = 264
        Loop(t$(ord(t)= Lower),
        Returns_fourweek(k,i,w) = ReturnSubset(i,t);
        );
    );
);

LOOP(k,
      actual_returns(i) = PROD(w,(1+returns_fourweek(k,i,w))) -1;
      V = Sum(i, Weights(i)*actual_returns(i));
      Weights(i) = (Weights(i)*actual_returns(i)) / V;
      MU_TARGET(k) = sum(i, EP(i,k)*Weights(i)) - 1;
);

Display MU_TARGET;

//Unload the MU_TARGET data

EXECUTE_UNLOAD 'MU_TARGET.gdx', k, MU_TARGET;




