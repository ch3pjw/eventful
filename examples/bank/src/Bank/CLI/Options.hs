module Bank.CLI.Options
  ( runOptionsParser
  , Options (..)
  , CLICommand (..)
  , parseDatabaseFileOption
  ) where

import Data.Monoid ((<>))
import qualified Data.Text as T
import Options.Applicative

import Eventful

import Bank.Aggregates.Account
import Bank.Aggregates.Customer

runOptionsParser :: IO Options
runOptionsParser = execParser $ info (helper <*> parseOptions) (fullDesc <> progDesc "eventful bank CLI")

data Options
  = Options
  { optionsDatabaseFile :: FilePath
  , optionsCommand :: CLICommand
  } deriving (Show)

data CLICommand
  = CreateCustomerCLI CreateCustomerData
  | ViewAccountCLI UUID
  | OpenAccountCLI OpenAccountData
  deriving (Show, Eq)

parseOptions :: Parser Options
parseOptions =
  Options <$>
  parseDatabaseFileOption <*>
  subparser (
    command "create-customer" (info (helper <*> parseCreateCustomer) (progDesc "Create a customer")) <>
    command "view-account" (info (helper <*> parseViewAccount) (progDesc "View an account")) <>
    command "open-account" (info (helper <*> parseOpenAccount) (progDesc "Open a new account"))
  )

parseDatabaseFileOption :: Parser FilePath
parseDatabaseFileOption =
  strOption
    ( metavar "DATABASE_PATH" <>
      long "database-path" <>
      short 'p' <>
      value "database.db" <>
      help "File path for SQLite database. Default is ./database.db"
    )

parseCreateCustomer :: Parser CLICommand
parseCreateCustomer =
  CreateCustomerCLI . CreateCustomerData <$>
  strOption (
    long "name" <>
    metavar "name" <>
    help "Customer's name"
  )

parseViewAccount :: Parser CLICommand
parseViewAccount =
  ViewAccountCLI <$>
  option parseUUID (
    long "account-id" <>
    metavar "uuid" <>
    help "UUID for account aggregate"
  )

parseOpenAccount :: Parser CLICommand
parseOpenAccount =
  fmap OpenAccountCLI . OpenAccountData <$>
  option parseUUID (
    long "owner-id" <>
    metavar "uuid" <>
    help "UUID for the account owner"
  ) <*>
  option auto (
    long "initial-funds" <>
    metavar "amount" <>
    value 0 <>
    help "Initial funds for account."
  )

parseUUID :: ReadM UUID
parseUUID = maybe (readerError "Could not parse UUID") return . uuidFromText =<< (T.pack <$> str)
