class_name NetConfig
## Network/timing constants. Changing these requires bumping Protocol.VERSION.

const TICK_RATE: int = 60
const TICK_DT: float = 1.0 / 60.0
const SNAPSHOT_EVERY_TICKS: int = 3
const INPUT_REDUNDANCY: int = 3
const INTERP_DELAY_S: float = 0.1
const MAX_PENDING_INPUTS: int = 120
const PEER_TIMEOUT_MS: int = 10_000
const CHANNEL_RELIABLE: int = 0
const CHANNEL_INPUT: int = 1
const CHANNEL_SNAPSHOT: int = 2
const POS_QUANT: float = 2.0
