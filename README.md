# Precious Place Admin 🍰

A centralized business management and financial accounting suite designed for independent retail and food businesses. This project integrates a Point of Sale (POS) system, a multi-currency double-entry ledger, and custom order management into a single infrastructure, automating the pipeline from ingredient costing (COGS) to final financial reporting. It demonstrates a distributed architecture that prioritizes data integrity and low-code operational agility.

## Architecture

```text
                                     +-------------------+
                                     |   Telegram API    |
                                     +---------^---------+
                                               |
                                               |
         +-------------------+       +---------v---------+       +-------------------+
         |  Vue.js Frontends |       |        n8n        |       |    PostgreSQL     |
         |  (POS, Ledger,    <------->  (Orchestrator &  <-------> (Multiple Schemas: |
         |   Orders)         |       |   API Logic)      |       |  POS, Accounting, |
         +---------^---------+       +---------^---------+       |  COGS, Admin)     |
                   |                           |                 +-------------------+
                   |                           |
         +---------v---------------------------v---------+
         |                Traefik Proxy                  |
         |          (SSL & Routing via Cloudflare)       |
         +----------------------^------------------------+
                                |
                                |
                          +-----v-----+
                          |   User    |
                          +-----------+
```

## Tech Stack

| Component | Technology | Purpose |
| :--- | :--- | :--- |
| **Frontend** | Vue.js 3 / Pinia | Interactive UI for POS, accounting, and order management. |
| **Orchestration** | n8n | Backend logic, webhook handling, and external API integration. |
| **Database** | PostgreSQL 15 | Relational storage with strict PL/pgSQL triggers for data integrity. |
| **Reverse Proxy** | Traefik | Dynamic routing, SSL termination (Let's Encrypt), and ForwardAuth. |
| **Static Assets** | Nginx | High-performance serving of product and UI images. |
| **Messaging** | Telegram Bot API | Real-time notifications and natural language administrative commands. |
| **Infrastructure** | Docker Compose | Containerized deployment and environment consistency. |

## Project Structure

- `.github/workflows/`: CI/CD pipelines for staging and production deployment.
- `ledger-frontend/`: Vue.js application for double-entry bookkeeping and financial reports.
- `n8n/n8n-workflows/`: JSON exports of all backend automation and API logic.
- `orders-frontend/`: Vue.js interface for managing custom customer orders.
- `pos-frontend/`: Retail Point of Sale interface optimized for fast checkout.
- `postgres/postgres-init/`: SQL initialization scripts defining multi-tenant database schemas.
- `public/images/`: Centralized storage for product images served via Nginx.
- `docker-compose.yml`: Main orchestration file for the entire service stack.
- `GEMINI.md`: Internal developer guide and technical standards.
- `dev_init.ps1`: Environment initialization and production file synchronization script.

## Quick Start

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-repo/precious-place-admin.git
   cd precious-place-admin
   ```

2. **Configure environment:**
   Create a `.env` file based on the keys required in `docker-compose.yml` (e.g., `DB_PASSWORD`, `DOMAIN_OR_IP`, `TELEGRAM_BOT_TOKEN`).

3. **Initialize the stack:**
   ```bash
   docker compose up -d --build
   ```

4. **Access the services:**
   - **POS:** `https://<DOMAIN>/pos`
   - **Ledger:** `https://<DOMAIN>/accounting`
   - **n8n:** `https://n8n.<DOMAIN>`

## How It Works

1.  **Frontend Interaction:** Users interact with the `pos-frontend` or `ledger-frontend`. Actions like "Checkout" or "New Journal Entry" trigger asynchronous Axios calls to n8n webhooks defined in `VITE_API_BASE_URL`.
2.  **Orchestration (The Brain):** n8n receives the request via a Webhook Node. It executes business logic (e.g., calculating totals, verifying stock levels) by branching into specialized workflows like `admin_orchestrate_message.json`.
3.  **Data Integrity:** n8n interacts with the PostgreSQL service. For financial transactions, it writes to the `accounting` schema. A PL/pgSQL trigger (`enforce_balanced_journal` in `03_create_accounting_db.sql`) ensures that no journal entry can be saved unless debits equal credits.
4.  **Secondary Interfaces:** The Telegram Bot API serves as a mobile-first interface. Messages like "Update price of Red Velvet to $45" are parsed by n8n, which updates the `pos` database and triggers a notification to other admin users.
5.  **Secure Routing:** Traefik handles incoming traffic, automatically provisioned SSL certificates via Cloudflare DNS-01 challenges, and uses a `ForwardAuth` middleware directed to n8n to ensure only authorized users access the frontends.

## Design Decisions

1.  **n8n as a Low-Code Backend**: Chosen to replace a traditional REST API (Node/Python). This allows for visual debugging of complex business flows and rapid integration with external services (Telegram, Email) without writing boilerplate boilerplate code.
2.  **Database-Level Constraint Enforcement**: Business-critical rules (like balanced ledger entries) are implemented via PL/pgSQL triggers. This guarantees data integrity regardless of which client (Vue, n8n, or direct SQL) modifies the data.
3.  **Partitioned Multi-Database Schema**: The system uses distinct databases (`cogs`, `pos`, `accounting`) instead of one large schema. This provides strong isolation between modules, preventing a bug in the POS from affecting the core financial ledger.
4.  **Thin Client Architecture**: Frontends are strictly UI-driven. All state-change logic and calculations are offloaded to the backend (n8n/SQL), ensuring consistency across the Web UI and the Telegram interface.

## What This Demonstrates

-   **Full-Stack Orchestration**: Proficiency in integrating disparate systems (Vue, n8n, PG, Traefik) into a unified, containerized ecosystem.
-   **Advanced Data Engineering**: Implementation of complex relational schemas with automated data integrity via triggers and views.
-   **DevOps & Security**: Practical experience with SSL automation, reverse proxying, and environment-aware CI/CD pipelines.
-   **Automation Architecture**: Ability to map real-world business requirements into scalable, observable automated workflows.
