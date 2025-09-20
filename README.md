# 🚀 Frappe Custom Apps Development Environment

<p align="center">
  <a href="" rel="noopener">
 <img src="LOGO.png" alt="Project logo"></a>
</p>

<div align="center">

[![Status](https://img.shields.io/badge/status-active-success.svg)]()
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](/LICENSE)

</div>

---

<p align="center">
Development environment for building **custom Frappe applications**, designed to run inside a **Docker container** with full integration into **VSCode Dev Containers**.  
This setup allows developers to code directly from VSCode while the Frappe bench and ERPNext ecosystem run inside the container.
</p>

---

## 📝 Table of Contents

- [About](#about)
- [Architecture](#architecture)
- [Getting Started](#getting_started)
- [Scripts](#scripts)
- [Usage](#usage)
- [Deployment](#deployment)
- [Built Using](#built_using)
- [Authors](#authors)
- [Acknowledgments](#acknowledgements)

---

## 🧐 About <a name = "about"></a>

This project provides a **ready-to-use development environment** for building, testing, and running **custom Frappe apps**.  
It uses **Docker Compose** to set up the full stack (Frappe bench, MariaDB, Redis, Node.js build tools), while **VSCode Dev Containers** enables developers to seamlessly edit and debug their code inside the container.  

The goal is to allow **developers to focus only on coding apps**, without worrying about local dependencies or complex setup.

---

## 🏗 Architecture <a name = "architecture"></a>

- **Docker Compose** spins up containers for:
  - Frappe Bench
  - MariaDB
  - Redis (cache, queue, socketio)
- **VSCode Dev Container (`devcontainer.json`)** provides:
  - Preinstalled extensions for Python, Node, and SQL tools
  - Port forwarding for web (8000), socketio (9000), and file watcher (6787)
- **Shell Scripts (`.sh` files)** automate common tasks:
  - Building and initializing bench
  - Creating new apps
  - Installing/uninstalling apps
  - Running the setup wizard
  - Starting the environment

---

## 🏁 Getting Started <a name = "getting_started"></a>

### Prerequisites
- [Docker](https://www.docker.com/get-started)
- [VSCode](https://code.visualstudio.com/)
- [Dev Containers Extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)

### Installing
1. Clone this repository.
2. Open it in **VSCode**.
3. When prompted, reopen in **Dev Container**.  
   VSCode will use `devcontainer.json` and `docker-compose.yml` to build the environment.
4. Once inside, run:

```bash
bash build.sh
```

This will initialize bench, create a default site (`dev.localhost`), and optionally install apps like ERPNext, Payments, LMS, or Frappe Comment AGT.

> To initialize the bench, please refer to the [Usage Section](#usage) for more details.

---

## 📜 Scripts <a name="scripts"></a>

> All scripts are located in the project root and can be executed from within the Dev Container terminal. They will not work on the host machine directly, you must be inside the container.

### 🔨 `build.sh`
- Initializes `frappe-bench` (optionally on branch v15).
- Creates a default site (`dev.localhost`) with predefined DB and admin credentials.
- Configures Redis and MariaDB connections.
- Optionally installs ERPNext, Payments, LMS, and Frappe Comment AGT.
- Runs the setup wizard automatically.
- **Usage**:
  ```bash
  bash build.sh
  ```

---

### 🏗 `create-app.sh`
- Creates a **new custom Frappe app**.
- Installs it directly into the given site.
- Clears cache after installation.
- **Usage**:
  ```bash
  bash create-app.sh <app_name> <site_name>
  ```

---

### 📦 `install-app.sh`
- Fetches an app from a repository (with optional branch).
- Installs it into the site.
- Runs migrations and clears cache.
- **Usage**:
  ```bash
  bash install-app.sh <site_name> <app_name> <repo_url> <branch>
  ```

---

### 🧹 `uninstall-app.sh`
- Removes an app from a site.
- Cleans `apps.txt` and updates installed apps.
- Runs migrations and clears cache.
- **Usage**:
  ```bash
  bash uninstall-app.sh <site_name> <app_name>
  ```

---

### ⚙️ `setup-wizard.sh`
- Automates the ERPNext/Frappe **Setup Wizard**.
- Configures currency, timezone, chart of accounts, and company name.
- Uses predefined values for Brazil (BRL, São Paulo timezone, Brazilian CoA).
- **Usage**:
  ```bash
  bash setup-wizard.sh <site_name> <user_email> <user_password>
  ```

---

### ▶️ `start.sh`
- Starts Frappe services via `honcho`.
- Runs all background processes: socketio, watch, schedule, worker, and web.
- Displays the login URL and recommended credentials.
- **Usage**:
  ```bash
  bash start.sh <site_name> <user_email> <user_password>
  ```

---

## 🎈 Usage <a name="usage"></a>
- Access the Dev Container terminal by 'Open Current Folder in Container' option in the Dev Containers tool.
- Build the environment (if not done yet):
  ```bash
  bash build.sh
  ```
- Start the environment:
  ```bash
  bash start.sh dev.localhost
  ```
- Access your site at:  
  [http://dev.localhost:8000](http://dev.localhost:8000)  
- Default login (if not overridden):  
  ```
  Email: administrator
  Password: admin
  ```

---

## 🚀 Deployment <a name="deployment"></a>
This setup is primarily for **development**. Therefore, it is highly **NOT RECOMMENDED** for production.

---

## ⛏️ Built Using <a name = "built_using"></a>
- [Frappe](https://frappeframework.com/) – App framework
- [ERPNext](https://erpnext.com/) – Business management platform
- [Docker](https://www.docker.com/) – Containerized environment
- [VSCode Dev Containers](https://code.visualstudio.com/docs/remote/containers) – IDE integration
- [Honcho](https://github.com/nickstenning/honcho) – Process manager

---

## ✍️ Authors <a name = "authors"></a>
- **AnyGrid Tech** – Environment design & automation

---

## 🎉 Acknowledgements <a name = "acknowledgements"></a>
- [Frappe](https://frappeframework.com/)
- [ERPNext](https://erpnext.com/)
- [Docker](https://www.docker.com/)