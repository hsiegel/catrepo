import System.Directory (doesFileExist)
import System.Exit (exitFailure)
import System.FilePath (takeBaseName)
import System.Process (readProcess)

-- import System.IO (appendFile)

skip :: [String]
skip = [".gitignore", "ChangeLog.md", "CHANGELOG.md", "LICENSE", "README.md", "Setup.hs", "stack.yaml", "stack.yaml.lock"]

main :: IO ()
main = do
  reponame <- getRepoName
  let filename = reponame <> "-all.txt"
  putStrLn ("Erstelle Datei: " ++ filename)
  result <- runGitLsFiles
  case result of
    Right files -> do
      writeFile filename ""
      mapM_ (appendToFile filename) files
    Left err -> putStrLn ("Fehler: " ++ err) >> exitFailure

getRepoName :: IO String
getRepoName = do
  output <- readProcess "git" ["rev-parse", "--show-toplevel"] ""
  return $ takeBaseName (init output)

runGitLsFiles :: IO (Either String [String])
runGitLsFiles = do
  output <- readProcess "git" ["ls-files"] ""
  return $ Right (lines output)

appendToFile :: String -> FilePath -> IO ()
appendToFile filename file = do
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
          appendFile filename (header ++ content ++ footer)
    else putStrLn ("Datei nicht gefunden: " ++ file)
