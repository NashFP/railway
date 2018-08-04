import Data.Either
import System.Environment

-- The Haskell Either monad already does the Railway.
-- The Left track is the error track. Once the computation stream
-- is on the Left track, its return value is the first Left value
-- that was generated.
-- The Right track contains an error-free value.


-- safeDivide refuses to divide by 0 and returns an error
-- Safe divide includes the current n so you can see at what
-- point the error occurred.
safeDivide :: Integer -> Integer -> Either String Integer
safeDivide n 0 = Left ("Divide by zero at n = " ++ (show n))
safeDivide n d = Right (n `div` d)


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
-- railway_either n d1 d2 d3
--
-- Example:
-- railway_either 100 2 5 2  prints 5
-- railway_either 100 0 2 10 prints Divide by zero at n = 100
-- railway_either 100 2 0 10 prints Divide by zero at n = 50
-- railway_either 100 2 10 0 prints Divide by zero at n = 5
-- railway_either 100 0 10 0 prints Divide by zero at n = 100
--
main = do
    args <- getArgs
    let [n, d1, d2, d3] = map readInt args

    let result = doSomeMath n d1 d2 d3

-- The either function takes 2 functions and an Either. If the Either is
-- the left, it applies the first function to the Either's left value. If
-- it is right, it applies the second function to the right value.
-- In this case, since the left is already a string, we just use the identity
-- function for the left, and for the right we use show, which converts the
-- integer to a string.
-- The $ operator is just a way to do function application. It's the same
-- as putStrLn (either id show result)
--
   putStrLn $ either id show result
