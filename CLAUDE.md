# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

AI Document Review is an enterprise solution for automated document review using AI agents. It analyzes PDF documents to identify issues like grammar errors and definitive language problems, presenting results in a web UI with PDF annotation capabilities.

## Architecture

The solution consists of three main components:

1. **React Frontend** (`app/ui/`) - Document upload, PDF viewer with annotations, real-time streaming of review results
2. **FastAPI Backend** (`app/api/`) - REST API serving the UI and handling document processing via LangChain/OpenAI
3. **PromptFlow Agents** (`flows/`) - AI workflows for document analysis, deployable to Azure AI Foundry

### Data Flow
- User uploads PDF → stored locally or in Azure Blob Storage
- Review initiated → API calls LangChain pipeline (or PromptFlow endpoint in Azure)
- AI agents analyze document chunks in parallel, streaming issues back
- Issues stored in SQLite (local) or Cosmos DB (Azure)
- Users accept/dismiss issues with optional feedback

### Key Directories
- `common/` - Shared Pydantic models (`Issue`, `IssueType`, `Location`, `ReviewRule`) used by both API and flows
- `flows/ai_doc_review/` - Main PromptFlow flow with streaming document processing
- `flows/ai_doc_review/agent_template/` - Template for creating new AI agents
- `flows/ai_doc_review/prompts/` - Agent-specific prompts (grammar, definitive_language)
- `infra/` - Terraform modules for Azure deployment

## Common Commands

### Infrastructure (via Taskfile)
```bash
task -a                    # List all available tasks
task infra-init            # Initialize Terraform
task infra-deploy          # Deploy Azure resources
task infra-destroy         # Tear down Azure resources
```

### Application Build & Deploy
```bash
task app-build             # Build both UI and API
task app-build-ui          # Build UI only (outputs to app/api/www/)
task app-build-api         # Build API only
task app-deploy            # Deploy to Azure App Service
```

### PromptFlow
```bash
task flow-deploy           # Deploy main flow to Azure AI Foundry
task flow-deploy-endpoint  # Create hosted endpoint for the flow
```

### Local Development

**API Setup:**
```bash
cd app/api
python -m venv .venv
source .venv/bin/activate  # Windows: .venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

**UI Setup:**
```bash
cd app/ui
npm install
npm run dev                # Starts Vite dev server on localhost:5173
```

**Run API locally:**
```bash
cd app/api
uvicorn main:app --reload --port 8000
```

The Vite dev server proxies `/api` and `/ws` requests to `localhost:8000`.

**VS Code Debug:** Use the compound profile `App (UI & API)` to debug both simultaneously.

### PromptFlow Local Development
```bash
cd flows
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
pip install -r ai_doc_review/requirements.txt
pf --version  # Verify installation
```

Create connection named `aisconns_aoai` for Azure OpenAI via the VS Code PromptFlow extension.

## Adding a New AI Agent

1. Add new value to `IssueType` enum in `common/models.py`
2. Create prompts in `flows/ai_doc_review/prompts/<agent_name>/`:
   - `agent.jinja2` - Main agent logic
   - `consolidator.jinja2` - Result ranking/verification
   - `guidelines.jinja2` - Issue taxonomy
3. Register agent in `AGENT_PROMPTS` dict in `flows/ai_doc_review/flows.py`

## API Structure

The API follows a layered architecture:
- `routers/` - FastAPI route handlers (issues, files, rules)
- `services/` - Business logic (IssuesService, RulesService, LangChainPipeline)
- `database/` - SQLite repositories (IssuesRepository, RulesRepository)
- `security/auth.py` - Authentication (Entra ID in Azure, placeholder locally)

Key endpoints:
- `GET /api/v1/review/{doc_id}/issues` - Stream issues for a document (SSE)
- `PATCH /api/v1/review/{doc_id}/issues/{issue_id}/accept` - Accept an issue
- `PATCH /api/v1/review/{doc_id}/issues/{issue_id}/dismiss` - Dismiss an issue
- `POST/PATCH .../hitl/start|resume` - Human-in-the-loop workflow

## Configuration

Environment variables loaded from `.env` files (auto-generated after `infra-deploy`):
- `app/api/.env` - API config (OpenAI API key, MinerU settings, local paths)
- `app/ui/.env` - UI config (MSAL client ID, storage URLs)
- `flows/.env` - PromptFlow config (Azure AI project, subscription info)

Key settings in `app/api/config/config.py`:
- `mineru_*` - PDF processing via MinerU service
- `openai_*` - LLM configuration
- `pagination` - Chunk size for streaming (default: 32 paragraphs)

## Tech Stack

- **Frontend:** React 18, Fluent UI, react-pdf, Vite, TypeScript
- **Backend:** FastAPI, LangChain, Pydantic, SQLite (local) / Cosmos DB (Azure)
- **AI/ML:** OpenAI (GPT), PromptFlow
- **Infrastructure:** Terraform, Azure App Service, Azure AI Foundry
- **Auth:** Microsoft Entra ID (Azure AD)
