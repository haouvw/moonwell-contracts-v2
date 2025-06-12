# MIP-B43 cbXRP Asset Listing Proposal

## cbXRP: Short Summary

We are pleased to present a proposal for adding **Coinbase Wrapped XRP (cbXRP)**
to **Moonwell’s Base Core Markets**. cbXRP is a fully‑collateralised, ERC‑20
representation of XRP that is minted and redeemed 1‑for‑1 through Coinbase. The
listing would bring a blue‑chip, payments‑oriented asset to the protocol, deepen
liquidity on Moonwell, and attract new retail and institutional users familiar
with XRP.

cbXRP is new, and as a result has a few liquidity concerns, but it shows
substantial benefits to the Moonwell community.

---

## Benefits to the Moonwell Community

1. **Enhanced Liquidity & Volume**  
   Issuance by Coinbase immediately bootstraps liquidity on Aerodrome and
   Uniswap v4.
2. **Stable Collateral Type**  
   Tight 1‑for‑1 peg to XRP backed by a regulated custodian.
3. **New User Acquisition**  
   XRP has one of the largest retail followings (3 M+ on X), offering growth
   potential for Moonwell.
4. **Diversification**  
   Adds a non‑USD‑pegged, large‑cap asset that is uncorrelated with ETH/Layer‑2
   governance tokens.

---

## Resources and Socials

- Website: <https://xrpl.org/>
- Twitter: <https://x.com/Ripple>
- Coinbase Assets Announcement:
  <https://x.com/CoinbaseAssets/status/1930360878886535373>

---

## Market Risk Assessment

![cbXRP-Market](https://europe1.discourse-cdn.com/flex017/uploads/moonwell/original/2X/8/86813fb7b496f43cdd6f992c4cf8656b23dbaf70.png)

### Market Metrics (Source)

- **Market Cap:** \$5 M
- **Minimum/Maximum Market Cap (Last 6 months):** \$0 (December 5 2024) / \$5 M
  (June 5 2025)
- **Circulating Supply:** 2.3 M cbXRP
- **Maximum Supply:** 2.3 M cbXRP
- **24‑Hour Trading Volume:** \$341000 (first day of trading on Aerodrome)

### Liquidity on Centralized Exchanges

_Not applicable_ — cbXRP is an on‑chain deployment of XRP.

### Holder Concentration

- **Herfindahl Index:** 0.88 (on Base) – indicates significant concentration
  among wallets for cbXRP.

> Note: Ripple and Coinbase are reputable companies, and cbXRP borrows from
> Coinbase’s reserve supply, so this may not fully reflect governance risk.

Source: <https://coinmarketcap.com/currencies/coinbase-wrapped-xrp/>

---

## Decentralization

- **Top 10 Holders:** Majority in a Coinbase wallet followed by an Aerodrome LP.
- **Token Contract:** `0xcb585250f852c6c6bf90434ab21a00f02833a4af`
- cbXRP operates as an on‑chain Ethereum‑native deployment of XRP, backed by
  Coinbase reserves.
- All administrative roles and access are through Coinbase or Ripple.

### Governance Structure

- Coinbase‑wrapped assets are held in custody by Coinbase and are subject to
  Coinbase Custody rules (jurisdiction‑dependent).

### Blacklist Functionality

- The cbXRP contract includes `blacklist` and `unBlacklist` functions and a
  public getter to check blacklist status.

---

## Smart Contract Risks

### Codebase and On‑Chain Activity

- Smart contract:
  <https://basescan.org/token/0xcb585250f852c6c6bf90434ab21a00f02833a4af#code>
- Holders: 264 (as of the first day).

### Security Posture

- Deployed under the same wrapped‑asset framework audited by OpenZeppelin. Audit
  details: <https://blog.openzeppelin.com/coinbase-liquid-staking-token-audit>

### Upgradeability

- Upgradeable under an `Admin` role (likely a Coinbase multisig).

---

## Oracle Assessment

- **Chainlink price feed:** `0x9f0C1dD78C4CBdF5b9cf923a549A201EdC676D34`
- cbXRP price tracks native XRP through Coinbase reserves. Supply on Base is
  capped by Coinbase Custody.
  - Coinbase Proof‑of‑Reserves page:
    <https://www.coinbase.com/cbxrp/proof-of-reserves>

---

## Swap Size Requirement

cbXRP currently does **not** meet the MALF swap‑size requirements; however, it
has only been live for a few days.

---

## Liquidity Threshold

![Liquidity-Threshold](https://europe1.discourse-cdn.com/flex017/uploads/moonwell/original/2X/a/ac3f732dc38307efa3922ce3cc9f16d0529c93bc.png)
Currently, the liquidity does not meet the \$2M threshold Moonwell has under
MALF; however, seeing as though liquidity on Aerodrome has already hit 8% of
that goal in a day, it is not far fetched to see it hitting this threshold
sooner rather than later.

---

## Commercial Viability

Even if cbXRP never rises above cbETH’s historical utilisation peak (~33%), a
\$2 M liquidity seed, with one‑third borrowed at ~10% APY, would generate
roughly \$90000 annual interest. After Moonwell’s 10-15% reserve cut, protocol
revenue would be just over \$1100 per month—above the MALF threshold, with
headroom for growth.

---

## Proposal Author Information

- **Names:** Coolhorsegirl & 0xMims
- **Twitter:** <https://x.com/Coolhorsegirl>, <https://x.com/0xMims>
- **Relationship with Token:** 0xMims is a Moonwell governance lead;
  Coolhorsegirl is a delegate with the Tally team.

---

## Conclusion

Listing **cbXRP** as a core asset on Moonwell unlocks significant potential for
protocol growth, liquidity expansion, and user adoption. While some risks
remain—particularly liquidity depth and holder concentration—cbXRP’s stable,
compliance‑ready design aligns with Moonwell’s mission of simple, secure, and
accessible DeFi. We invite the community to engage in discussion and help shape
this proposal to best serve Moonwell’s long‑term vision.

---

## Table of Contents

1. [cbXRP: Short Summary](#cbxrp-short-summary)
2. [Benefits to the Moonwell Community](#benefits-to-the-moonwell-community)
3. [Resources and Socials](#resources-and-socials)
4. [Market Risk Assessment](#market-risk-assessment)
5. [Decentralization](#decentralization)
6. [Smart Contract Risks](#smart-contract-risks)
7. [Oracle Assessment](#oracle-assessment)
8. [Swap Size Requirement](#swap-size-requirement)
9. [Liquidity Threshold](#liquidity-threshold)
10. [Commercial Viability](#commercial-viability)
11. [Proposal Author Information](#proposal-author-information)
12. [Conclusion](#conclusion)
