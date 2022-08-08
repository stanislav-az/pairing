module Main where

import Data.Curve.Weierstrass (Point (A), mul')
import Data.Group (pow)
import Data.Pairing.BN254
import Protolude hiding (GT)
import Data.Field.Galois
import Data.Curve.Weierstrass
import Control.DeepSeq (force)
import Unsafe

data VerificationKey = VerificationKey {
    vkAlfa1 :: G1 BN254
  , vkBeta2 :: G2 BN254
  , vkGamma2 :: G2 BN254
  , vkDelta2 :: G2 BN254
  , vkIC :: [G1 BN254]
  }
  deriving (Eq, Show)

data Proof = Proof {
    proofA :: G1 BN254
  , proofB :: G2 BN254
  , proofC :: G1 BN254
  }
  deriving (Eq, Show)


verificationKey :: VerificationKey
verificationKey = VerificationKey {
    vkAlfa1 = A
        3519983779875975884833669322644459063638450737909635765863865541872816858376
        7397099103576276514295477589558878626884885290877914840485004796772491333406
  , vkBeta2 = A

         [4055210887597267573862197659315373416864928047670163988706273513208955750759
         , 4233108826603850015763960594754484752349032325245460126061176201699088355723]


         [10734055131721991386361548026072880619041664090603612227306479935970068384429
         , 15529181653007204823676300510451171809392982039264354999549976792049587936261]

  , vkGamma2 = A

         [10857046999023057135944570762232829481370756359578518086990519993285655852781
         , 11559732032986387107991004021392285783925812861821192530917403151452391805634]


         [8495653923123431417604973247489272438418190587263600148770280649306958101930
         , 4082367875863433681332203403145435568316851327593401208105741076214120093531]

  , vkDelta2 = A

         [5795067521892209664508696230815993254066313192442331467455306988810762153656
         , 15150465902568040861568244142756230434811118386935944114889784614870630155655]


         [17887064173843031597393549322152319283014342519900457086032146517880793360891
         , 13471038907510548380069206393375488516383307496487161396960211476483925790387]

  , vkIC = [
        A
          12205800145834954087629756830011671649884585767932945027040922596370775575027
          12335909711281406674675777935087685643547480208328236512555693568331448637030
      , A
          11642085884811769906577990096315880343230600233455728567642797818737321267166
          1194068800058154376479103256936875836563891942409976760453620908437570741987
      , A
          15302762551311403468794223356053351955569213123927590593607892781770420932216
          17341761658547253261341398665768411153995274800232623766938021005739128393935
      , A
          11905519547163994483317077345000487664106200643027117393662431849423582259559
          17271392723818383815489974533793402703707209079397780140640476271182126349938
      , A
          11103214678582990427796680142068148646644353914344094476356909773699253567150
          20438733183586278340783911095605163119833027156590827692550246152785709634466
      , A
          1692776111806236653550976737571686296292047956215055404352758934926723275222
          3866854602724290522517283948294183629491075037104265397972296743285697658046
  ]
  }

proof :: Proof
proof = Proof {
    proofA = A
        20739405409438614042597371026051922137213700485910282599301378285294426636046
        9449570332458618936297290791620220393785839604194492193993750527721160548827
  , proofB = A

         [361476620837321102680770263983333243206041876597594168918161867213080787159
         , 17606736833174531683523029322800645792478796647938577745206864292045064223220]


         [14839742587991078825091053097482696001747240049034277675297099627546786399853
         , 18154295575728974618345045809000115348724447181000602002195519538602197066568]

  , proofC = A
        6410915015109806408011143640591143092944062431852100826225656289679047529663
        13551940261137955951732849972642375130512193711855635433686248681229928325179
  }


input :: [Fr]
input = [
    209056401552680342171500713693571551483705576731647616538780021193062270741
  , 241556073111170714216510186215943078975698974945161254652098530671580140386
  , 6557836041741118014001951194863174296773521821444037460394290925684
  , 7115327617372227038038094827163194829145401151534469365083940078405
  , 2000000
  ]

mkVkX :: [Fr] -> [G1 BN254] -> G1 BN254
mkVkX input ic = foldr (\x y -> force $ add x y) (unsafeHead ic) (zipWith mul (drop 1 ic) input)

mkVerifyProof :: VerificationKey -> [Fr] -> Proof -> Fq12
mkVerifyProof VerificationKey{..} input Proof{..} =
        (force . fromU) (pairing (inv proofA) proofB) *
        (force . fromU) (pairing vkAlfa1 vkBeta2) *
        (force . fromU) (pairing vkX vkGamma2) *
        (force . fromU) (pairing proofC vkDelta2)
  where
    vkX = force $ mkVkX input vkIC

main :: IO ()
main  = do
  putText "isOnCurve sanity check:"
  print (def $ proofA proof)
  print (def $ proofB proof)
  print (def $ proofC proof)
  print (def $ vkAlfa1 verificationKey)
  print (def $ vkBeta2 verificationKey)
  print (def $ vkGamma2 verificationKey)
  print (def $ vkDelta2 verificationKey)
  print (all def $ vkIC verificationKey)
  putText "pairing:"
  let p = mkVerifyProof verificationKey input proof
  print p
  print (p == mempty)
