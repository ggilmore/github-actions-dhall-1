let map =
      https://raw.githubusercontent.com/dhall-lang/dhall-lang/9f259cd68870b912fbf2f2a08cd63dc3ccba9dc3/Prelude/List/map

let mapOptional =
      https://raw.githubusercontent.com/dhall-lang/dhall-lang/9f259cd68870b912fbf2f2a08cd63dc3ccba9dc3/Prelude/Optional/map

let GHC = < GHC802 | GHC822 | GHC844 | GHC865 | GHC881 >

let Cabal = < Cabal30 | Cabal24 | Cabal22 | Cabal20 >

let VersionInfo = { ghc-version : Text, cabal-version : Text }

let BuildStep =
      < Uses : { uses : Text, with : Optional VersionInfo }
      | Name : { name : Text, run : Text }
      >

let DhallVersion = { ghc-version : GHC, cabal-version : Cabal }

let Matrix = { matrix : { ghc : List Text, cabal : List Text } }

let DhallMatrix = { ghc : List GHC, cabal : List Cabal }

let CI =
      { name : Text
      , on : List Text
      , jobs :
          { build :
              { runs-on : Text
              , steps : List BuildStep
              , strategy : Optional Matrix
              }
          }
      }

let printGhc =
        λ(ghc : GHC)
      → merge
          { GHC802 = "8.0.2"
          , GHC822 = "8.2.2"
          , GHC844 = "8.4.4"
          , GHC865 = "8.6.5"
          , GHC881 = "8.8.1"
          }
          ghc

let printCabal =
        λ(cabal : Cabal)
      → merge
          { Cabal30 = "3.0", Cabal24 = "2.4", Cabal22 = "2.2", Cabal20 = "2.0" }
          cabal

let printEnv =
        λ(v : DhallVersion)
      → { ghc-version = printGhc v.ghc-version
        , cabal-version = printCabal v.cabal-version
        }

let printMatrix =
        λ(v : DhallMatrix)
      → { ghc = map GHC Text printGhc v.ghc
        , cabal = map Cabal Text printCabal v.cabal
        }

let checkout =
      BuildStep.Uses { uses = "actions/checkout@v1", with = None VersionInfo }

let haskellEnv =
        λ(v : VersionInfo)
      → BuildStep.Uses { uses = "actions/setup-haskell@v1", with = Some v }

let defaultEnv = { ghc-version = "8.6.5", cabal-version = "3.0" }

let latestEnv = { ghc-version = "8.8.1", cabal-version = "3.0" }

let matrixEnv =
      { ghc-version = "\${{ matrix.ghc }}"
      , cabal-version = "\${{ matrix.cabal }}"
      }

let mkMatrix = λ(st : DhallMatrix) → { matrix = printMatrix st }

let cabalDeps =
      BuildStep.Name
        { name = "Install dependencies"
        , run =
            ''
            cabal update
            cabal build --enable-tests --enable-benchmarks --only-dependencies
            ''
        }

let cabalBuild =
      BuildStep.Name
        { name = "Build"
        , run = "cabal build --enable-tests --enable-benchmarks"
        }

let cabalTest = BuildStep.Name { name = "Tests", run = "cabal test" }

let cabalDoc = BuildStep.Name { name = "Documentation", run = "cabal haddock" }

let defaultCi =
        { name = "Haskell CI"
        , on = [ "push" ]
        , jobs =
            { build =
                { runs-on = "ubuntu-latest"
                , steps =
                    [ checkout
                    , haskellEnv defaultEnv
                    , cabalDeps
                    , cabalBuild
                    , cabalTest
                    , cabalDoc
                    ]
                , strategy = None Matrix
                }
            }
        }
      : CI

let defaultWith =
        λ(sts : List BuildStep)
      → λ(mat : Optional DhallMatrix)
      →     defaultCi
          ⫽ { jobs =
                { build =
                    { runs-on = defaultCi.jobs.build.runs-on
                    , steps = sts
                    , strategy = mapOptional DhallMatrix Matrix mkMatrix mat
                    }
                }
            }
        : CI

in  { VersionInfo = VersionInfo
    , BuildStep = BuildStep
    , Matrix = Matrix
    , CI = CI
    , GHC = GHC
    , Cabal = Cabal
    , DhallVersion = DhallVersion
    , cabalDoc = cabalDoc
    , cabalTest = cabalTest
    , cabalDeps = cabalDeps
    , cabalBuild = cabalBuild
    , checkout = checkout
    , haskellEnv = haskellEnv
    , defaultEnv = defaultEnv
    , latestEnv = latestEnv
    , matrixEnv = matrixEnv
    , defaultCi = defaultCi
    , defaultWith = defaultWith
    , mkMatrix = mkMatrix
    , printMatrix = printMatrix
    , printEnv = printEnv
    , printGhc = printGhc
    , printCabal = printCabal
    }