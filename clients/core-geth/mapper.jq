# Removes all empty keys and values in input.
def remove_empty:
  . | walk(
    if type == "object" then
      with_entries(
        select(
          .value != null and
          .value != "" and
          .value != [] and
          .key != null and
          .key != ""
        )
      )
    else .
    end
  )
;

# Converts decimal string to number.
def to_int:
  if . == null then . else .|tonumber end
;

# Converts "1" / "0" to boolean.
def to_bool:
  if . == null then . else
    if . == "1" then true else false end
  end
;

# Output core-geth (CoreGethChainConfig) format.
# This ensures the genesis JSON is detected as core-geth format by the
# schema auto-detector in params/confp/generic/generic.go.
#
# Key differences from go-ethereum format:
#   - Uses "networkId" (triggers core-geth detection)
#   - Uses "eip2FBlock" instead of "homesteadBlock"
#   - Uses "eip161FBlock"/"eip170FBlock" instead of "eip158Block"
#   - No "daoForkSupport" (would trigger core-geth rejection)
#   - No "byzantiumBlock" (individual EIP fields instead)
#   - Supports block-based activation of Cancun EIPs (eip1153FBlock, etc.)

. + {
  "config": {
    "networkId": (env.HIVE_CHAIN_ID // "1337" | tonumber),
    "ethash": (if env.HIVE_CLIQUE_PERIOD then null else {} end),
    "clique": (if env.HIVE_CLIQUE_PERIOD == null then null else {
      "period": env.HIVE_CLIQUE_PERIOD|to_int,
    } end),
    "chainId": env.HIVE_CHAIN_ID|to_int,

    # Homestead (EIP-2 + EIP-7)
    "eip2FBlock": env.HIVE_FORK_HOMESTEAD|to_int,
    "eip7FBlock": env.HIVE_FORK_HOMESTEAD|to_int,

    # DAO fork
    "daoForkBlock": env.HIVE_FORK_DAO_BLOCK|to_int,

    # Tangerine Whistle
    "eip150Block": env.HIVE_FORK_TANGERINE|to_int,

    # Spurious Dragon (EIP-155, EIP-160, EIP-161, EIP-170)
    "eip155Block": env.HIVE_FORK_SPURIOUS|to_int,
    "eip160Block": env.HIVE_FORK_SPURIOUS|to_int,
    "eip161FBlock": env.HIVE_FORK_SPURIOUS|to_int,
    "eip170FBlock": env.HIVE_FORK_SPURIOUS|to_int,

    # Byzantium (individual EIPs)
    "eip100FBlock": env.HIVE_FORK_BYZANTIUM|to_int,
    "eip140FBlock": env.HIVE_FORK_BYZANTIUM|to_int,
    "eip198FBlock": env.HIVE_FORK_BYZANTIUM|to_int,
    "eip211FBlock": env.HIVE_FORK_BYZANTIUM|to_int,
    "eip212FBlock": env.HIVE_FORK_BYZANTIUM|to_int,
    "eip213FBlock": env.HIVE_FORK_BYZANTIUM|to_int,
    "eip214FBlock": env.HIVE_FORK_BYZANTIUM|to_int,
    "eip658FBlock": env.HIVE_FORK_BYZANTIUM|to_int,

    # Constantinople (individual EIPs)
    "eip145FBlock": env.HIVE_FORK_CONSTANTINOPLE|to_int,
    "eip1014FBlock": env.HIVE_FORK_CONSTANTINOPLE|to_int,
    "eip1052FBlock": env.HIVE_FORK_CONSTANTINOPLE|to_int,
    "eip1283FBlock": env.HIVE_FORK_CONSTANTINOPLE|to_int,

    # Petersburg
    "petersburgBlock": env.HIVE_FORK_PETERSBURG|to_int,

    # Istanbul (individual EIPs)
    "eip152FBlock": env.HIVE_FORK_ISTANBUL|to_int,
    "eip1108FBlock": env.HIVE_FORK_ISTANBUL|to_int,
    "eip1344FBlock": env.HIVE_FORK_ISTANBUL|to_int,
    "eip1884FBlock": env.HIVE_FORK_ISTANBUL|to_int,
    "eip2028FBlock": env.HIVE_FORK_ISTANBUL|to_int,
    "eip2200FBlock": env.HIVE_FORK_ISTANBUL|to_int,

    # Muir Glacier
    "eip2384FBlock": env.HIVE_FORK_MUIR_GLACIER|to_int,

    # Berlin (individual EIPs)
    "eip2565FBlock": env.HIVE_FORK_BERLIN|to_int,
    "eip2718FBlock": env.HIVE_FORK_BERLIN|to_int,
    "eip2929FBlock": env.HIVE_FORK_BERLIN|to_int,
    "eip2930FBlock": env.HIVE_FORK_BERLIN|to_int,

    # London (individual EIPs)
    "eip3529FBlock": env.HIVE_FORK_LONDON|to_int,
    "eip3541FBlock": env.HIVE_FORK_LONDON|to_int,
    "eip1559FBlock": env.HIVE_FORK_LONDON|to_int,
    "eip3198FBlock": env.HIVE_FORK_LONDON|to_int,
    "eip3554FBlock": env.HIVE_FORK_LONDON|to_int,

    # Merge
    "mergeNetsplitVBlock": env.HIVE_MERGE_BLOCK_ID|to_int,
    "terminalTotalDifficulty": env.HIVE_TERMINAL_TOTAL_DIFFICULTY|to_int,
    "terminalTotalDifficultyPassed": (if env.HIVE_TERMINAL_TOTAL_DIFFICULTY then true else null end),

    # Shanghai (timestamp-based for ETH, block-based fields also available)
    "eip3651FTime": env.HIVE_SHANGHAI_TIMESTAMP|to_int,
    "eip3855FTime": env.HIVE_SHANGHAI_TIMESTAMP|to_int,
    "eip3860FTime": env.HIVE_SHANGHAI_TIMESTAMP|to_int,
    "eip4895FTime": env.HIVE_SHANGHAI_TIMESTAMP|to_int,
    "eip6049FTime": env.HIVE_SHANGHAI_TIMESTAMP|to_int,

    # Cancun (timestamp-based for ETH)
    "eip1153FTime": env.HIVE_CANCUN_TIMESTAMP|to_int,
    "eip4844FTime": env.HIVE_CANCUN_TIMESTAMP|to_int,
    "eip4788FTime": env.HIVE_CANCUN_TIMESTAMP|to_int,
    "eip5656FTime": env.HIVE_CANCUN_TIMESTAMP|to_int,
    "eip6780FTime": env.HIVE_CANCUN_TIMESTAMP|to_int,
    "eip7516FTime": env.HIVE_CANCUN_TIMESTAMP|to_int,

    # ECIP-1121: Block-based activation of selected Cancun EIPs for ETC
    "eip1153FBlock": env.HIVE_FORK_ECIP1121_EIP1153|to_int,
    "eip5656FBlock": env.HIVE_FORK_ECIP1121_EIP5656|to_int,
    "eip6780FBlock": env.HIVE_FORK_ECIP1121_EIP6780|to_int
  }|remove_empty
}
