Options  decimals = 8;
$eolcom //

SET Date  'Dates'
    Asset 'Assets' /DK0060647444, DK0015323406, DK0016098825, DK0015916225, DK0060036994, DK0010270776/
    //Asset 'Assets' /DK0060647444, DK0015323406/
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

loop(ani(an,i),
ReturnSubset(i, t) = AssetReturn(t,i,an);
);

SET
w /w1 * w4/
s /s1 * s1000/
period /m1 * m85/

ALIAS(period,k);
Alias(s,l);

SCALARS
        V_new
        V_old
        lower
        upper
;

Parameter
         Actual_Port_return(k)
         Actual_returns(i,k)
         Returns_fourweek(i,w)
;

LOOP(k,
    loop(w,
        Lower = 263+(ord(k)-1)*4 + ord(w);  //263 because 263 + ord(w)=1 = 264
        Loop(t$(ord(t)= Lower),
            Returns_fourweek(i,w) = ReturnSubset(i,t);
        );
    );
         Actual_returns(i,k) = PROD(w, (1 + returns_fourweek(i,w))) - 1;
);

Display Actual_returns

// We want the actual port returns for the GP portfolio for the testing period, week 264 to week 603
// We loop over the first 4 weeks and compound the returns.

Parameter
         Weights_new(i)
         Weights_old(i)
;


Weights_old('DK0060647444') = 5.3732;
Weights_old('DK0015323406') = 24.2239;
Weights_old('DK0016098825') = 16.8069;
Weights_old('DK0015916225') = 24.4297;
Weights_old('DK0060036994') = 10.5427;
Weights_old('DK0010270776') = 18.6237;

$ontext
Weights('DK0060647444') = 0.053732;
Weights('DK0015323406') = 0.242239;
Weights('DK0016098825') = 0.168069;
Weights('DK0015916225') = 0.244297;
Weights('DK0060036994') = 0.105427;
Weights('DK0010270776') = 0.186237;
$offtext

Display Actual_returns;

LOOP(k, // 1 to 85

      //Display actual_returns;

      V_old = Sum(i,  Weights_old(i));

      Weights_new(i) = Weights_old(i)*(1+actual_returns(i,k));

      V_new = Sum(i, Weights_new(i));

      Weights_old(i) = Weights_new(i);

      // Update weights

      Actual_Port_return(k) = (V_new-V_old)/V_old;

      Display V_new, V_old, Actual_Port_return;
      //Display Actual_Port_return
);

$exit

//Display Actual_Port_return;

EXECUTE_UNLOAD 'GP_RETURN.gdx', k, Actual_Port_return;

