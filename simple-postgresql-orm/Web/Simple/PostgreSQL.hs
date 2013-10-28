module Web.Simple.PostgreSQL where

import Control.Concurrent.MVar
import Control.Monad
import Control.Monad.IO.Class
import qualified Data.ByteString.Char8 as S8
import Database.PostgreSQL.Devel
import Database.PostgreSQL.Migrate
import Database.PostgreSQL.Simple
import System.Environment
import System.IO
import Web.Simple

type PostgreSQLConn = MVar Connection

class HasPostgreSQL hs where
  postgreSQLConn :: hs -> MVar Connection

createPostgreSQLConn :: IO (MVar Connection)
createPostgreSQLConn = do
  env <- getEnvironment
  let dev = maybe False (== "development") $ lookup "ENV" env
  when dev $ void $ do
    putStrLn "Starting dev database..."
    initLocalDB "db/development"
    startLocalDB "db/development"
    setLocalDB "db/development"
    initializeDb
    runMigrationsForDir stdout defaultMigrationsDir
  let envConnect = maybe S8.empty S8.pack $ lookup "DATABASE_URL" env
  connectPostgreSQL envConnect >>= newMVar

withConnection :: HasPostgreSQL hs
               => (Connection -> Controller hs b) -> Controller hs b
withConnection func = do
  dbvar <- postgreSQLConn `fmap` controllerState
  bracket (liftIO $ takeMVar dbvar) (liftIO . (putMVar dbvar)) $ \conn -> do
    res <- func conn
    return res
