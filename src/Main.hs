import Control.Exception (IOException, evaluate, try)
import Control.Monad (forM_)
import Data.List (dropWhileEnd)
import System.Directory (doesFileExist)
import System.Exit (exitFailure)
import System.FilePath (takeBaseName)
import System.Process (readProcess)

skipFiles :: [FilePath]
skipFiles = [".gitignore", "stack.yaml.lock"]

main :: IO ()
main = do
  outputFileResult <- getOutputFileName
  trackedFilesResult <- runGitLsFiles
  case (outputFileResult, trackedFilesResult) of
    (Left err, _) -> reportFailure err
    (_, Left err) -> reportFailure err
    (Right outputFile, Right files) -> writeCombinedRepoFile outputFile files

reportFailure :: String -> IO a
reportFailure err = putStrLn ("Error: " ++ err) >> exitFailure

getOutputFileName :: IO (Either String FilePath)
getOutputFileName = do
  repoRootResult <- runGitCommand ["rev-parse", "--show-toplevel"]
  return $ fmap (buildOutputFileName . takeBaseName . trimTrailingLineBreaks) repoRootResult

buildOutputFileName :: String -> FilePath
buildOutputFileName repoName = repoName <> "-all.txt"

writeCombinedRepoFile :: FilePath -> [FilePath] -> IO ()
writeCombinedRepoFile outputFile files = do
  putStrLn ("Creating file: " ++ outputFile)
  writeFile outputFile ""
  forM_ files (appendTrackedFile outputFile)

runGitLsFiles :: IO (Either String [FilePath])
runGitLsFiles = do
  outputResult <- runGitCommand ["ls-files", "--eol"]
  case outputResult of
    Left err -> return (Left err)
    Right output -> do
      let (textFiles, binaryFiles) = classifyByTextOrBinary (lines output)
      forM_ binaryFiles (\file -> putStrLn ("Skipping binary file (git): " ++ file))
      return (Right textFiles)

runGitCommand :: [String] -> IO (Either String String)
runGitCommand args = do
  outputOrErr <- try (readProcess "git" args "") :: IO (Either IOException String)
  return $
    case outputOrErr of
      Right output -> Right output
      Left err -> Left ("git " ++ unwords args ++ " failed: " ++ show err)

appendTrackedFile :: FilePath -> FilePath -> IO ()
appendTrackedFile outputFile file = do
  exists <- doesFileExist file
  if not exists
    then putStrLn ("File not found: " ++ file)
    else
      if file `elem` skipFiles
        then putStrLn ("Ignoring: " ++ file)
        else do
          contentResult <- tryReadTextFile file
          case contentResult of
            Right content -> do
              putStrLn ("Appending: " ++ file)
              appendFile outputFile (renderFileSection file content)
            Left _ ->
              putStrLn ("Skipping (not readable as text): " ++ file)

renderFileSection :: FilePath -> String -> String
renderFileSection file content =
  "--- File: " ++ file ++ " ---\n"
    ++ content
    ++ "\n--- End of " ++ file ++ " ---\n\n"

tryReadTextFile :: FilePath -> IO (Either IOException String)
tryReadTextFile file = do
  contentOrErr <- try (readFile file) :: IO (Either IOException String)
  case contentOrErr of
    Left err -> return (Left err)
    Right content -> do
      decodedOrErr <- try (evaluate (length content)) :: IO (Either IOException Int)
      case decodedOrErr of
        Left err -> return (Left err)
        Right _ -> return (Right content)

classifyByTextOrBinary :: [String] -> ([FilePath], [FilePath])
classifyByTextOrBinary linesToParse =
  let (textFilesRev, binaryFilesRev) = foldl' step ([], []) linesToParse
   in (reverse textFilesRev, reverse binaryFilesRev)
  where
    step :: ([FilePath], [FilePath]) -> String -> ([FilePath], [FilePath])
    step (textFiles, binaryFiles) line =
      case parseEolLine line of
        Just (file, True) -> (textFiles, file : binaryFiles)
        Just (file, False) -> (file : textFiles, binaryFiles)
        Nothing -> (textFiles, binaryFiles)

parseEolLine :: String -> Maybe (FilePath, Bool)
parseEolLine line =
  case break (== '\t') line of
    (meta, '\t' : file) ->
      case words meta of
        (indexInfo : _) -> Just (file, indexInfo == "i/-text")
        _ -> Nothing
    _ -> Nothing

trimTrailingLineBreaks :: String -> String
trimTrailingLineBreaks = dropWhileEnd (`elem` "\r\n")
