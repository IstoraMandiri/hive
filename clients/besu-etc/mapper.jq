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

# Replace 'config' section in input JSON for Ethereum Classic.
. + {
  "config": {
    "ethash": (if env.HIVE_CLIQUE_PERIOD then null else {} end),
    "clique": (if env.HIVE_CLIQUE_PERIOD == null then null else {
      "blockperiodseconds": env.HIVE_CLIQUE_PERIOD|to_int,
      "epochlength": 30000,
    } end),
    "chainID": env.HIVE_CHAIN_ID|to_int,

    # Early forks (shared with ETH)
    "homesteadBlock": env.HIVE_FORK_HOMESTEAD|to_int,
    "eip150Block": env.HIVE_FORK_TANGERINE|to_int,
    "eip150Hash": env.HIVE_FORK_TANGERINE_HASH,
    "eip155Block": env.HIVE_FORK_SPURIOUS|to_int,
    "eip158Block": env.HIVE_FORK_SPURIOUS|to_int,

    # ETC-specific forks
    "classicForkBlock": env.HIVE_FORK_CLASSIC|to_int,
    "ecip1015Block": env.HIVE_FORK_ECIP1015|to_int,
    "dieHardBlock": env.HIVE_FORK_DIE_HARD|to_int,
    "gothamBlock": env.HIVE_FORK_GOTHAM|to_int,
    "defuseDifficultyBombBlock": env.HIVE_FORK_ECIP1041|to_int,

    # ETC equivalents of ETH forks
    "atlantisBlock": env.HIVE_FORK_ATLANTIS|to_int,
    "aghartaBlock": env.HIVE_FORK_AGHARTA|to_int,
    "phoenixBlock": env.HIVE_FORK_PHOENIX|to_int,
    "thanosBlock": env.HIVE_FORK_THANOS|to_int,
    "magnetoBlock": env.HIVE_FORK_MAGNETO|to_int,
    "mystiqueBlock": env.HIVE_FORK_MYSTIQUE|to_int,
    "spiralBlock": env.HIVE_FORK_SPIRAL|to_int,

    # Support ETH-style fork names for compatibility with shared tests
    # These map to ETC equivalents
    "byzantiumBlock": env.HIVE_FORK_BYZANTIUM|to_int,
    "constantinopleBlock": env.HIVE_FORK_CONSTANTINOPLE|to_int,
    "constantinopleFixBlock": env.HIVE_FORK_PETERSBURG|to_int,
    "istanbulBlock": env.HIVE_FORK_ISTANBUL|to_int,
    "berlinBlock": env.HIVE_FORK_BERLIN|to_int,

    # ECIP-1017 monetary policy (5M blocks per era)
    "ecip1017EraRounds": (if env.HIVE_FORK_ECIP1017 then 5000000 else null end),

  }|remove_empty
}
