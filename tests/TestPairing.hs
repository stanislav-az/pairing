module TestPairing where

import Protolude

import Curve
import Curve.Weierstrass
import ExtensionField
import Group.Field
import Pairing.Curve
import Pairing.Pairing
import Pairing.Params
import Test.QuickCheck
import Test.Tasty.HUnit

-- Random points in G1, G2 as generated by libff.
inpG1 :: G1
inpG1 = A
        1368015179489954701390400359078579693043519447331113978918064868415326638035
        9918110051302171585080402603319702774565515993150576347155970296011118125764

inpG2 :: G2
inpG2 = A
  ( toField
    [ 2725019753478801796453339367788033689375851816420509565303521482350756874229
    , 7273165102799931111715871471550377909735733521218303035754523677688038059653
    ]
  )
  ( toField
    [ 2512659008974376214222774206987427162027254181373325676825515531566330959255
    , 957874124722006818841961785324909313781880061366718538693995380805373202866
    ]
  )

beforeExponentiation :: GT
beforeExponentiation = F $ construct
  [ 10244919957345566208036224388367387294947954375520342002142038721148536068658
  , 20520725903107462730350108147804326707908059028221039276493719519842949720531
  , 6086095302240468555411758663466251351417777262748587710512082696159022563215
  , 3498483043828007000664704983384438380014626741459095899124517210966193962189
  , 9839947403899670326057934148290729066991318244952536153418081752510541932805
  , 9202072764973620760720243946210007480782851719144203914690329192926361472509
  , 10396963991176748371570893144856868074352236348257264320828640725417622807401
  , 16918234646064442383576265933863121396979541666923405352165222603555475148795
  , 1146287855099517708899800840204495527878843746533321795244252048321172986641
  , 15272723827732170058231690870045992172379497733734277515700990114389642596090
  , 6026541190208646112995382377707652888403252171847993766999540977939986078453
  , 4033750506662808934164561353819561401109395743946249795674228367029912558059
  ]

afterExponentiation :: GT
afterExponentiation = F $ construct
  [ 7297928317524675251652102644847406639091474940444702627333408876432772026640
  , 18010865284024443253481973710158529446817119443459787454101328040744995455319
  , 14179125828660221708486990054318233868908974550229474018509093903907472063156
  , 19672547343219696395323430329000470270122259521813831378125910505067755316037
  , 10811020225621941034352015694422164943041584464746963243431262955968538467312
  , 18591344525433923700278298641693487837785792806011751060570085671866249379154
  , 18214296718386486500838507024306049626571830525675768493345345883297201451077
  , 19227311731387426597265504864999881769743583647552324796732605660514141916117
  , 15463354980731838106439887363063618463783317416732018231077874458188347926701
  , 3765441250413579779915094051038487360437654739171671492016287185303087270469
  , 21029416079740174485345021549306749850075185576152640151652655104272393297142
  , 19736982780723093346009254617143639137054958583796054069884522103959451721163
  ]

-- Sanity check test inputs
unit_inpG1_valid :: Assertion
unit_inpG1_valid
  = assertBool "inpG1 does not satisfy curve equation" $ def inpG1

unit_inpG2_valid :: Assertion
unit_inpG2_valid
  = assertBool "inpG2 does not satisfy curve equation" $ def inpG2

-- Test our pairing ouput against that of libff.
unit_pairingLibff_0 :: Assertion
unit_pairingLibff_0 = beforeExponentiation @=? atePairing inpG1 inpG2

unit_pairingLibff_1 :: Assertion
unit_pairingLibff_1 = afterExponentiation @=? reducedPairing inpG1 inpG2

pairingTestCount :: Int
pairingTestCount = 10

prop_pairingBilinear :: Property
prop_pairingBilinear = withMaxSuccess pairingTestCount prop
  where
    prop :: G1 -> G2 -> Integer -> Integer -> Bool
    prop e1 e2 preExp1 preExp2
      = reducedPairing (mul' e1 exp1) (mul' e2 exp2)
        == mul' (reducedPairing e1 e2) (exp1 * exp2)
      where
        -- Quickcheck might give us negative integers or 0, so we
        -- take the absolute values instead and add one.
        exp1 = abs preExp1 + 1
        exp2 = abs preExp2 + 1

prop_pairingNonDegenerate :: Property
prop_pairingNonDegenerate = withMaxSuccess pairingTestCount prop
  where
    prop :: G1 -> G2 -> Bool
    prop e1 e2 = or [ e1 == mempty
                    , e2 == mempty
                    , reducedPairing e1 e2 /= mempty
                    ]

-- Output of the pairing to the power _r should be the unit of GT.
prop_pairingPowerTest :: Property
prop_pairingPowerTest = withMaxSuccess pairingTestCount prop
  where
    prop :: G1 -> G2 -> Bool
    prop e1 e2 = def (reducedPairing e1 e2)

prop_frobeniusFq12Correct :: Fq12 -> Bool
prop_frobeniusFq12Correct f = frobeniusNaive 1 f == fq12Frobenius 1 f

prop_finalExponentiationCorrect :: Property
prop_finalExponentiationCorrect = withMaxSuccess 10 prop
  where
    prop :: Fq12 -> Bool
    prop f = finalExponentiation f == finalExponentiationNaive f
