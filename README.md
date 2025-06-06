
#  FarmChain – Supply Chain Transparency for Farmers

**FarmChain** is a decentralized application (DApp) that enhances **transparency** and **fair pricing** in agricultural supply chains. Built using the **Clarinet programming language** (for Clarity smart contracts on Stacks), it enables consumers to trace the journey of their food from **farm to market**, verify its authenticity, and **tip the farmer** directly.

##  Problem Statement

* **Fake produce origins** erode trust in food labels and agricultural claims.
* **Middlemen manipulation** leads to **unfair pricing** for local farmers.
* **Lack of traceability** reduces accountability in the supply chain.

---

##  Features

### 1.  Track Food from Farm to Market

* Every product is logged on-chain with:

  * Timestamp
  * Geolocation tags
  * Farmer ID and transaction details

### 2.  Direct Tips to Farmers

* Consumers can send **tokens as tips** to a farmer’s wallet address
* Improves income transparency and incentivizes quality

### 3.  Product Journey Tracker (UI)

* A clean and interactive **UI page** where users input a product ID
* View **step-by-step journey**: farm → transport → market
* Shows real-time data like timestamp logs and location updates

---

## 🛠 Tech Stack

| Layer              | Tech                                      |
| ------------------ | ----------------------------------------- |
| Smart Contracts    | Clarity (via Clarinet)                    |
| Blockchain         | Stacks Blockchain                         |
| Dev Tooling        | Clarinet CLI, Jest for testing            |
| Frontend           | React.js / Next.js (optional)             |
| Wallet Integration | Hiro Wallet                               |
| Geo-tagging        | IPFS/Oracles or mocked GPS metadata (MVP) |

---

##  Smart Contract Modules

1. **`farmchain-core.clar`**

   * Register product batches
   * Log timestamps and geolocation
   * Emit journey events

2. **`wallet-tips.clar`**

   * Allow consumers to send STX/SIP-010 tokens to farmers
   * Track tip history and balances

3. **`product-tracker.clar`**

   * Retrieve full product journey
   * View lifecycle events

---

##  Testing

* Run unit tests:

  ```bash
  clarinet test
  ```
* Test coverage includes:

  * Product registration
  * Location log validation
  * Tip transaction success
  * Event tracking integrity

---

##  Frontend (UI – Product Journey Tracker)

* Users enter a **Product ID**
* The DApp pulls **on-chain product logs** and renders a timeline:

  *  Farmer → 🚛 Transit → 🛒 Market
* Includes:

  * Tip button with STX/USDA token integration
  * Verified Origin Badge ✅

---

##  Security & Integrity

* All logs are immutable on-chain.
* Product IDs are hashed to prevent tampering.
* Geo-data is either pulled from a trusted oracle or submitted by verified actors only.

---

##  Future Improvements

* Integration with IoT devices for real-time tracking
* Verifiable farmer reputation scores
* Cross-border traceability for export markets

---

##  Contributing

Pull requests are welcome. For major changes, open an issue first to discuss what you would like to change.

---

##  License

MIT License. See `LICENSE.md` for more details.
