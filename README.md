# Aegis AI Platform

## Enterprise RAG, Multi-Agent, MLOps, GenAIOps, and AKS-based AI Platform on Azure

Aegis AI Platform is an enterprise-grade AI platform designed to demonstrate how modern AI systems are built, deployed, evaluated, monitored, and governed on Microsoft Azure.

The platform starts as a FastAPI-based RAG API and gradually evolves into a full AI Platform Engineering proof of concept covering:

- Document upload and ingestion
- Text extraction and chunking
- Embedding generation
- Cosmos DB and Azure AI Search-based retrieval
- Azure OpenAI integration
- Multi-agent orchestration
- Azure AI Foundry integration
- Containerized deployment
- AKS deployment
- MLOps pipeline
- GenAIOps pipeline
- Evaluation framework
- Monitoring and tracing
- Security and governance

---

## Project Vision

The goal of this project is to build a production-style AI platform, not just a chatbot.

```text
User
 ↓
Streamlit UI / Web UI
 ↓
FastAPI Backend
 ↓
RAG Service
 ↓
Azure OpenAI + Azure AI Search / Cosmos DB
 ↓
Multi-Agent Layer
 ↓
Azure AI Foundry
 ↓
Evaluation + Monitoring + GenAIOps
 ↓
Azure Container Apps / AKS

```

<details>
<summary><b>Phase 1: FastAPI RAG API</b></summary>

### Goal
Build the core backend API for document upload, document reading, embedding generation, storage, retrieval, and answering questions.

### What Will Be Built
FastAPI API with:
- Upload documents
- Read PDF/DOCX/TXT
- Chunk text
- Generate embeddings
- Save text chunks and embeddings
- Ask questions
- Retrieve relevant chunks
- Send context to Azure OpenAI or another model
- Return answer with sources

### Azure Services to Create
**Required**
- Azure OpenAI Service
- Azure Cosmos DB
- Azure Container Registry

**Optional**
- Azure Storage Account
- Azure Key Vault
- Azure App Configuration
- Application Insights
- Azure AI Search
- Azure Document Intelligence

### Open-Source / Framework Stack
**Backend:**
- FastAPI
- Uvicorn
- Pydantic

**Document Processing:**
- pypdf
- python-docx

**AI:**
- Azure OpenAI SDK
- OpenAI SDK

**Database:**
- Azure Cosmos DB SDK

**Testing:**
- pytest

**Configuration:**
- python-dotenv

### API Endpoints
- `GET    /health`
- `POST   /documents/upload`
- `GET    /documents`
- `GET    /documents/{document_id}`
- `DELETE /documents/{document_id}`
- `POST   /chat/ask`

### Expected Output
1. Upload a PDF/DOCX/TXT document
2. Extract text from the document
3. Split text into chunks
4. Generate embeddings
5. Save chunks and embeddings to Cosmos DB
6. Ask a question
7. Retrieve relevant chunks
8. Generate grounded answer
9. Return answer with source references

</details>
