# Precious Place Admin

A comprehensive, modular business management system for independent retail bakeries and food businesses. 

---

## 🌟 Overview

**Precious Place Admin** is a centralized operational hub designed to digitize and automate the day-to-day management of a retail bakery. It replaces fragmented, manual processes (paper accounting, text-based orders, manual inventory) with a cohesive digital infrastructure.

The system is built on a **local-first, low-cost philosophy**, leveraging open-source tools and containerization to provide enterprise-grade capabilities without expensive SaaS subscriptions.

---

## 🏗️ System Architecture

The project is organized into distinct but interconnected modules orchestrated by **n8n**.

### 1. Point of Sale (POS)
*   **Frontend:** Vue.js 3 / Vite application.
*   **Capabilities:** Fast retail interface, cart management, transaction recording.
*   **Integration:** Communicates with the POS database and triggers accounting events via n8n.

### 2. Double-Entry Accounting (General Ledger)
*   **Frontend:** Vue.js 3 / Vite application.
*   **Backend:** PostgreSQL `accounting` database with balanced journal entry enforcement (PL/pgSQL triggers).
*   **Reports:** Real-time Balance Sheet, Profit & Loss, Trial Balance, and General Ledger views.
*   **Automation:** Daily sales from the POS are automatically aggregated and posted to the ledger.

### 3. COGS & Inventory Management
*   **Database:** PostgreSQL `cogs` database.
*   **Capabilities:** Ingredient tracking, unit conversion (e.g., grams to kilograms), and recipe management.
*   **Costing:** Dynamically calculates product costs based on recipe components and current ingredient prices.

### 4. AI-Powered Telegram Admin Bot
*   **Orchestration:** n8n workflows using the **Gemini API**.
*   **Natural Language Management:** Add products, update prices, or check inventory by simply messaging the bot (e.g., *"Add Double Chocolate Cake $100"*).
*   **Order Intake:** Structured flow for custom cake orders, replacing unstructured text conversations.

### 5. Orchestration & Integration (The "Brain")
*   **Engine:** **n8n** manages all data flows between frontends, databases, and external APIs.
*   **Security:** Acts as a custom authentication layer for frontends using Traefik's `forwardauth`.

---

## 🛠️ Tech Stack

| Layer | Technology |
| :--- | :--- |
| **Frontend** | Vue.js 3, Vite, Tailwind CSS (Vanilla CSS variants) |
| **Orchestration** | n8n |
| **Database** | PostgreSQL 15 (5 separate databases) |
| **Proxy / Edge** | Traefik (HTTPS via Let's Encrypt + Cloudflare DNS Challenge) |
| **Image Hosting** | Nginx |
| **AI** | Google Gemini API |
| **Infrastructure** | Docker & Docker Compose |

---

## 🚀 Getting Started

### Prerequisites
*   Docker & Docker Compose
*   Cloudflare Account (for DNS-01 SSL challenges)
*   Telegram Bot Token
*   Google Gemini API Key

### Environment Setup
1.  Copy `.env.example` (if available) or create a `.env` file with the following keys:
    ```env
    DOMAIN_OR_IP=yourdomain.com
    BASE_DOMAIN=yourdomain.com
    N8N_DOMAIN=n8n.yourdomain.com
    ADMIN_EMAIL=admin@yourdomain.com
    DNS_TOKEN=your_cloudflare_token
    TELEGRAM_BOT_TOKEN=your_bot_token
    GEMINI_API_KEY=your_gemini_key
    POSTGRES_USER=...
    POSTGRES_PASSWORD=...
    DB_PASSWORD=...
    ```

2.  **Initialize the Databases:**
    The databases are automatically initialized on the first run using the scripts in `./postgres/postgres-init/`.

3.  **Deploy:**
    ```bash
    docker-compose up -d
    ```

4.  **Sync Local Environment (Optional):**
    Use `dev_init.ps1` to sync production data/configurations to your local machine for development.

---

## 📂 Project Structure

```text
├── ledger-frontend/      # Accounting Vue.js app
├── pos-frontend/         # POS Vue.js app
├── n8n/                  # n8n workflows and initialization
│   ├── n8n-workflows/    # Exported workflow JSONs
│   └── flows2/           # n8n persistent data
├── postgres/
│   └── postgres-init/    # SQL scripts for 5 database schemas
├── public/               # Static assets & image storage
└── docker-compose.yml    # Main orchestration
```

---

## 💡 Design Philosophy

*   **Solve Real Problems:** Prioritize stable, functional workflows over feature bloat.
*   **Data Ownership:** All data remains on your server in standard PostgreSQL databases.
*   **Modularity:** Each component (Accounting, POS, COGS) can operate independently or together.
*   **AI for Accessibility:** Use AI (Gemini) to make complex database management as simple as sending a text.

---

## ⚖️ License

[MIT](LICENSE) - See LICENSE file for details.
