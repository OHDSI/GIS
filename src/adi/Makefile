generate:
	runhaskell --ghc-arg=-i../common/haskell generateSourceFiles.hs > source-files.json.new
calcHash:
	runhaskell --ghc-arg=-i../common/haskell CalculateHashes ./source-files.json > source-files.json.new
