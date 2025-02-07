import System.Process (readProcess)
import System.Exit (exitFailure)
import System.Directory (doesFileExist)
import System.IO (appendFile)

main :: IO ()
main = do
    result <- runGitLsFiles
    case result of
        Right files -> mapM_ appendToFile files
        Left err    -> putStrLn ("Fehler: " ++ err) >> exitFailure

runGitLsFiles :: IO (Either String [String])
runGitLsFiles = do
    output <- readProcess "git" ["ls-files"] ""
    return $ Right (lines output)

appendToFile :: FilePath -> IO ()
appendToFile file = do
    exists <- doesFileExist file
    if exists
        then do
            content <- readFile file
            let header = "--- Datei: " ++ file ++ " ---\n"
            let footer = "\n--- Ende von " ++ file ++ " ---\n\n"
            appendFile "total.txt" (header ++ content ++ footer)
        else putStrLn ("Datei nicht gefunden: " ++ file)
