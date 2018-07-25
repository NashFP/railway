import Control.Monad
import System.Environment

-- The Railway monad lets you either return a value or an error string
data Railway a = RWValue a | RWError String

-- This declares the Railway Monad. If you invoke a function on an
-- RWError value, it just returns the RWError. Otherwise, if you invoke
-- it on an RWValue it extracts the value and calls f. The function is
-- expected to return a Railway value.
instance Monad Railway  where
    (RWError s) >>= f = RWError s
    (RWValue a) >>= f = f a
    return = RWValue

-- In GHC now you have to declare Functor and Applicative instances
-- for any Monad.
instance Functor Railway where
    fmap f (RWError s) = RWError s
    fmap f (RWValue x) = RWValue (f x)

-- These are the default functions for applicative, I'm not sure if
-- they are correct.
instance Applicative Railway where
    pure = return
    (<*>) = ap

-- Define functions to test for value/error and extract each
getRWError (RWError s) = s
getRWError (RWValue _) = error "Tried to retrieve error from RWValue"

getRWValue (RWError _) = error "Tried to reteieve value from RWError"
getRWValue (RWValue n) = n

isError (RWError s) = True
isError (RWValue _) = False

isValue (RWError s) = False
isValue (RWValue _) = True

-- safeDivide refuses to divide by 0 and returns an error
safeDivide :: Integer -> Integer -> Railway Integer
safeDivide _ 0 = RWError "Divide by zero"
safeDivide n d = RWValue (n `div` d)


-- Compute ((n/d1)/d2)/d3 safely
-- The flip function changes the order of arguments, and since we really
-- want the output of the first safeDivide to be the first argument to
-- the next call instead of the second, we use flip to reverse the
-- arguments.
--
doSomeMath n d1 d2 d3 = 
    safeDivide n d1 >>=
    (flip safeDivide) d2 >>=
    (flip safeDivide) d3
    
readInt :: String -> Integer
readInt = read

-- Run as:
-- railway n d1 d2 d3
main = do
    args <- getArgs
    let [n, d1, d2, d3] = map readInt args

    let result = doSomeMath n d1 d2 d3

    if isValue result then
        putStrLn $ show (getRWValue result)
    else
        putStrLn $ getRWError result
