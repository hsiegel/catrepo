import System.Directory (doesFileExist)
import System.Exit (exitFailure)
import System.Process (readProcess)

-- import System.IO (appendFile)

skip :: [String]
skip = [".gitignore", "CHANGELOG.md", "LICENSE", "README.md", "Setup.hs", "stack.yaml", "stack.yaml.lock"]

main :: IO ()
main = do
  result <- runGitLsFiles
  case result of
    Right files -> mapM_ appendToFile files
    Left err -> putStrLn ("Fehler: " ++ err) >> exitFailure

runGitLsFiles :: IO (Either String [String])
runGitLsFiles = do
  output <- readProcess "git" ["ls-files"] ""
  return $ Right (lines output)

appendToFile :: FilePath -> IO ()
appendToFile file = do
  exists <- doesFileExist file
  if exists
    then
      if file `elem` skip
        then putStrLn ("Ignoriere: " ++ file)
        else do
          content <- readFile file
          let header = "--- Datei: " ++ file ++ " ---\n"
          let footer = "\n--- Ende von " ++ file ++ " ---\n\n"
          putStrLn ("Füge an: " ++ file)
          appendFile "allfiles.txt" (header ++ content ++ footer)
    else putStrLn ("Datei nicht gefunden: " ++ file)
