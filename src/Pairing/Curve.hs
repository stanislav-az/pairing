module Pairing.Curve
  (
  -- * Galois fields
    Fq
  , Fq2
  , Fq6
  , Fq12
  , Fr
  -- * Elliptic curves
  , G1
  , G2
  , G2'
  , GT
  , gG1
  , gG2
  , gGT
  , rG1
  , rG2
  , rGT
  -- * Parameters
  , _a
  , _a'
  , _b
  , _b'
  , _k
  , _nqr
  , _q
  , _r
  , _t
  , _xi
  -- * Miscellaneous functions
  , conj
  , getYfromX
  , scale
  , mulXi
  , fq12Frobenius
  , isRootOfUnity
  , isPrimitiveRootOfUnity
  , primitiveRootOfUnity
  , precompRootOfUnity
  -- , fromByteStringG1
  -- , fromByteStringG2
  -- , fromByteStringGT
  ) where

import Protolude

import Curve (Curve(..))
import qualified Curve.Weierstrass.BN254 as BN254
import qualified Curve.Weierstrass.BN254T as BN254T
import ExtensionField (ExtensionField, IrreducibleMonic, fromField, toField)
import GaloisField (GaloisField(..))
import qualified Group.Field.BN254TF as BN254TF

-- import Pairing.Serialize.Types

-------------------------------------------------------------------------------
-- Galois fields
-------------------------------------------------------------------------------

-- | Prime field @Fq@.
type Fq = BN254.Fq

-- | Quadratic extension field of @Fq@ defined as @Fq2 = Fq[u]/<u^2 + 1>@.
type Fq2 = BN254T.Fq2

-- | Cubic extension field of @Fq2@ defined as @Fq6 = Fq2[v]/<v^3 - (9 + u)>@.
type Fq6 = BN254TF.Fq6

-- | Quadratic extension field of @Fq6@ defined as @Fq12 = Fq6[w]/<w^2 - v>@.
type Fq12 = BN254TF.Fq12

-- | Prime field @Fr@.
type Fr = BN254.Fr

-------------------------------------------------------------------------------
-- Elliptic curves
-------------------------------------------------------------------------------

-- | G1 is @E(Fq)@ defined by @y^2 = x^3 + b@.
type G1 = BN254.PA

-- | G2 is @E'(Fq2)@ defined by @y^2 = x^3 + b / xi@.
type G2 = BN254T.PA

-- | G2' is G2 in Jacobian coordinates.
type G2' = BN254T.PJ

-- | GT is subgroup of @r@-th roots of unity of the multiplicative group of @Fq12@.
type GT = BN254TF.P

-- | Generator of G1.
gG1 :: G1
gG1 = BN254.gA

-- | Generator of G2.
gG2 :: G2
gG2 = BN254T.gA

-- | Generator of GT.
gGT :: GT
gGT = BN254TF.g_

-- | Order of G1.
rG1 :: Integer
rG1 = BN254._r

-- | Order of G2.
rG2 :: Integer
rG2 = BN254T._r

-- | Order of GT.
rGT :: Integer
rGT = BN254TF._r

-------------------------------------------------------------------------------
-- Parameters
-------------------------------------------------------------------------------

-- | Elliptic curve @E(Fq)@ coefficient @A@, with @y = x^3 + Ax + B@.
_a :: Fq
_a = BN254._a

-- | Elliptic curve @E(Fq2)@ coefficient @A'@, with @y = x^3 + A'x + B'@.
_a' :: Fq2
_a' = BN254T._a

-- | Elliptic curve @E(Fq)@ coefficient @B@, with @y = x^3 + Ax + B@.
_b :: Fq
_b = BN254._b

-- | Elliptic curve @E(Fq2)@ coefficient @B'@, with @y = x^3 + A'x + B'@.
_b' :: Fq2
_b' = BN254T._b

-- | Embedding degree.
_k  :: Integer
_k = 12

-- | Quadratic nonresidue in @Fq@.
_nqr :: Integer
_nqr = 21888242871839275222246405745257275088696311157297823662689037894645226208582

-- | Characteristic of finite fields.
_q :: Integer
_q = BN254._q

-- | Order of G1 and characteristic of prime field of exponents.
_r :: Integer
_r = BN254._r

-- | BN parameter that determines the prime @_q@.
_t :: Integer
_t = 4965661367192848881

-- | Parameter of twisted curve over @Fq@.
_xi :: Fq2
_xi = toField [9, 1]

-------------------------------------------------------------------------------
-- Miscellaneous functions
-------------------------------------------------------------------------------

-- | Conjugation.
conj :: forall k im . IrreducibleMonic k im
  => ExtensionField k im -> ExtensionField k im
conj x
  | deg x /= 2 * deg (witness :: k) = panic "conj: extension degree is not two."
  | otherwise                       = case fromField x of
    [y, z] -> toField [y, negate z]
    [y]    -> toField [y]
    []     -> 0
    _      -> panic "conj: unreachable."
{-# INLINABLE conj #-}

-- | Get Y coordinate from X coordinate given a curve and a choice function.
getYfromX :: Curve f c e q r => Point f c e q r -> (q -> q -> q) -> q -> Maybe q
getYfromX curve choose x = choose <*> negate <$> yX curve x
{-# INLINABLE getYfromX #-}

-- | Scalar multiplication.
scale :: IrreducibleMonic k im => k -> ExtensionField k im -> ExtensionField k im
scale = (*) . toField . return
{-# INLINABLE scale #-}

-------------------------------------------------------------------------------
-- Miscellaneous functions (temporary)
-------------------------------------------------------------------------------

-- | Multiply by @_xi@ (cubic nonresidue in @Fq2@) and reorder coefficients.
mulXi :: Fq6 -> Fq6
mulXi w = case fromField w of
  [x, y, z] -> toField [z * _xi, x, y]
  [x, y]    -> toField [0, x, y]
  [x]       -> toField [0, x]
  []        -> toField []
  _         -> panic "mulXi: not exhaustive."
{-# INLINE mulXi #-}

-- | Iterated Frobenius automorphism in @Fq12@.
fq12Frobenius :: Int -> Fq12 -> Fq12
fq12Frobenius i a
  | i == 0    = a
  | i == 1    = fastFrobenius a
  | i > 1     = let prev = fq12Frobenius (i - 1) a in fastFrobenius prev
  | otherwise = panic "fq12Frobenius: not defined for negative values of i."
{-# INLINABLE fq12Frobenius #-}

-- | Fast Frobenius automorphism in @Fq12@.
fastFrobenius :: Fq12 -> Fq12
fastFrobenius = coll . conv [[0,2,4],[1,3,5]] . cong
  where
    cong :: Fq12 -> [[Fq2]]
    cong = map (map conj . fromField) . fromField
    conv :: [[Integer]] -> [[Fq2]] -> [[Fq2]]
    conv = zipWith (zipWith (\x y -> pow _xi ((x * (_q - 1)) `div` 6) * y))
    coll :: [[Fq2]] -> Fq12
    coll = toField . map toField
{-# INLINABLE fastFrobenius #-}

-- | Check if an element is a root of unity.
isRootOfUnity :: Integer -> Fr -> Bool
isRootOfUnity n x
  | n > 0     = pow x n == 1
  | otherwise = panic "isRootOfUnity: negative powers not supported."
{-# INLINABLE isRootOfUnity #-}

-- | Check if an element is a primitive root of unity.
isPrimitiveRootOfUnity :: Integer -> Fr -> Bool
isPrimitiveRootOfUnity n x
  | n > 0     = isRootOfUnity n x && all (\m -> not $ isRootOfUnity m x) [1 .. n - 1]
  | otherwise = panic "isPrimitiveRootOfUnity: negative powers not supported."
{-# INLINABLE isPrimitiveRootOfUnity #-}

-- | Compute primitive roots of unity for 2^0, 2^1, ..., 2^28. (2^28
-- is the largest power of two that divides _r - 1, therefore there
-- are no primitive roots of unity for higher powers of 2 in Fr.)
primitiveRootOfUnity :: Int -> Fr
primitiveRootOfUnity k
  | 0 <= k && k <= 28 = 5^((_r - 1) `div` (2^k))
  | otherwise         = panic "primitiveRootOfUnity: no primitive root for given power of 2."
{-# INLINABLE primitiveRootOfUnity #-}

-- | Precompute roots of unity.
precompRootOfUnity :: Int -> Fr
precompRootOfUnity 0  = 1
precompRootOfUnity 1  = 21888242871839275222246405745257275088548364400416034343698204186575808495616
precompRootOfUnity 2  = 21888242871839275217838484774961031246007050428528088939761107053157389710902
precompRootOfUnity 3  = 19540430494807482326159819597004422086093766032135589407132600596362845576832
precompRootOfUnity 4  = 14940766826517323942636479241147756311199852622225275649687664389641784935947
precompRootOfUnity 5  = 4419234939496763621076330863786513495701855246241724391626358375488475697872
precompRootOfUnity 6  = 9088801421649573101014283686030284801466796108869023335878462724291607593530
precompRootOfUnity 7  = 10359452186428527605436343203440067497552205259388878191021578220384701716497
precompRootOfUnity 8  = 3478517300119284901893091970156912948790432420133812234316178878452092729974
precompRootOfUnity 9  = 6837567842312086091520287814181175430087169027974246751610506942214842701774
precompRootOfUnity 10 = 3161067157621608152362653341354432744960400845131437947728257924963983317266
precompRootOfUnity 11 = 1120550406532664055539694724667294622065367841900378087843176726913374367458
precompRootOfUnity 12 = 4158865282786404163413953114870269622875596290766033564087307867933865333818
precompRootOfUnity 13 = 197302210312744933010843010704445784068657690384188106020011018676818793232
precompRootOfUnity 14 = 20619701001583904760601357484951574588621083236087856586626117568842480512645
precompRootOfUnity 15 = 20402931748843538985151001264530049874871572933694634836567070693966133783803
precompRootOfUnity 16 = 421743594562400382753388642386256516545992082196004333756405989743524594615
precompRootOfUnity 17 = 12650941915662020058015862023665998998969191525479888727406889100124684769509
precompRootOfUnity 18 = 11699596668367776675346610687704220591435078791727316319397053191800576917728
precompRootOfUnity 19 = 15549849457946371566896172786938980432421851627449396898353380550861104573629
precompRootOfUnity 20 = 17220337697351015657950521176323262483320249231368149235373741788599650842711
precompRootOfUnity 21 = 13536764371732269273912573961853310557438878140379554347802702086337840854307
precompRootOfUnity 22 = 12143866164239048021030917283424216263377309185099704096317235600302831912062
precompRootOfUnity 23 = 934650972362265999028062457054462628285482693704334323590406443310927365533
precompRootOfUnity 24 = 5709868443893258075976348696661355716898495876243883251619397131511003808859
precompRootOfUnity 25 = 19200870435978225707111062059747084165650991997241425080699860725083300967194
precompRootOfUnity 26 = 7419588552507395652481651088034484897579724952953562618697845598160172257810
precompRootOfUnity 27 = 2082940218526944230311718225077035922214683169814847712455127909555749686340
precompRootOfUnity 28 = 19103219067921713944291392827692070036145651957329286315305642004821462161904
precompRootOfUnity _  = panic "precompRootOfUnity: exponent too big for Fr / negative"
{-# INLINABLE precompRootOfUnity #-}

-- fromByteStringG1 :: FromSerialisedForm u => u -> LByteString -> Either Text G1
-- fromByteStringG1 unser = unserializePoint unser generatorG1 . toSL

-- fromByteStringG2 :: FromSerialisedForm u => u -> LByteString -> Either Text G2
-- fromByteStringG2 unser = unserializePoint unser generatorG2 . toSL

-- fromByteStringGT :: FromUncompressedForm u => u -> LByteString -> Either Text GT
-- fromByteStringGT unser = unserialize unser 1 . toSL
