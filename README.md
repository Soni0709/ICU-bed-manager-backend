# ICU Bed Manager - Backend API

A high-concurrency bed tracking system for ICU management with strict state machine enforcement and pessimistic locking.

## Table of Contents

- [Overview](#overview)
- [Tech Stack](#tech-stack)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Database Setup](#database-setup)
- [Running the Server](#running-the-server)
- [API Documentation](#api-documentation)
- [State Logic](#state-logic)
- [Testing](#testing)
- [Project Structure](#project-structure)

---

## Overview

The ICU Bed Manager backend is a Rails API-only application designed to manage hospital ICU bed assignments with:
- **Strict state machine** enforcement to prevent invalid bed transitions
- **Pessimistic locking** to handle concurrent user requests safely
- **CSV streaming** for efficient data export
- **Real-time bed status tracking** across available, occupied, and maintenance states

---

## 🛠️ Tech Stack

- **Framework**: Ruby on Rails 8.1.2 (API mode)
- **Language**: Ruby 3.4.7
- **Database**: PostgreSQL
- **Key Gems**:
  - `rack-cors` - CORS support for frontend integration
  - PostgreSQL adapter for database connectivity

---

## Features

### 1. **State Machine (The Guardrail)**
Enforces strict bed lifecycle transitions:
```
Available → Occupied → Maintenance → Available
```
**The Guardrail Rule**: Beds CANNOT transition from `Occupied` directly to `Available`. They MUST go through `Maintenance` first.

Any attempt to bypass this logic returns `422 Unprocessable Entity`.

### 2. **Pessimistic Locking (Concurrency Control)**
Uses `SELECT FOR UPDATE` to ensure:
- Only ONE user can modify a bed at a time
- If two users click "Assign" simultaneously, only one succeeds
- Prevents race conditions and double-booking

### 3. **CSV Streaming Export**
Streams bed data as CSV without buffering entire file in memory:
- Immediate download start
- Memory-efficient for large datasets
- Real-time data generation

### 4. **RESTful API**
Clean JSON API with proper error handling and HTTP status codes.

---

## Prerequisites

- **Ruby**: 3.4.7 or higher
- **Rails**: 8.1.2 or higher
- **PostgreSQL**: 14 or higher
- **Bundler**: Latest version

### Install Prerequisites

**macOS (using Homebrew):**
```bash
brew install postgresql@14
brew install ruby
gem install rails
```

---

## Installation

### 1. Clone the Repository
```bash
git clone <your-repo-url>
cd icu_bed_manager
```

### 2. Install Dependencies
```bash
bundle install
```

### 3. Configure Database

Edit `config/database.yml` if needed (default configuration shown):
```yaml
default: &default
  adapter: postgresql
  encoding: unicode
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  username: postgres
  password: <%= ENV.fetch("DATABASE_PASSWORD") { "password" } %>
  host: localhost

development:
  <<: *default
  database: icu_bed_manager_development

test:
  <<: *default
  database: icu_bed_manager_test
```

**Set database password (optional):**
```bash
export DATABASE_PASSWORD=your_password
```

---

## Database Setup

### 1. Create Database
```bash
rails db:create
```

### 2. Run Migrations
```bash
rails db:migrate
```

### 3. Seed Initial Data (20 ICU Beds)
```bash
rails db:seed
```

This creates 20 beds named `ICU-01` through `ICU-20`, all in `available` state.

### 4. Verify Setup
```bash
rails console
```
```ruby
Bed.count
# => 20

Bed.first
# => #<Bed id: 1, bed_number: "ICU-01", state: "available", ...>
```

---

## Running the Server

### Development Mode
```bash
rails server
```

Server starts at: **http://localhost:3000**

### Check Server Status
```bash
curl http://localhost:3000/health
# => OK
```

### Test API Endpoint
```bash
curl http://localhost:3000/beds | jq '.'
```

---

## API Documentation

Base URL: `http://localhost:3000`

### Endpoints

#### 1. Get All Beds

**GET** `/beds`

**Response:**
```json
[
  {
    "id": 1,
    "bed_number": "ICU-01",
    "state": "available",
    "patient_name": null,
    "urgency_level": null,
    "assigned_at": null,
    "discharged_at": null,
    "created_at": "2026-02-05T18:23:03.067Z",
    "updated_at": "2026-02-05T18:23:03.067Z"
  }
  // ... 19 more beds
]
```

---

#### 2. Assign Patient to Bed

**POST** `/beds/:id/assign`

**Request Body:**
```json
{
  "patient_name": "John Doe",
  "urgency_level": "high"
}
```

**Urgency Levels:** `"low"`, `"medium"`, `"high"`, `"critical"`

**Success Response (200):**
```json
{
  "id": 1,
  "bed_number": "ICU-01",
  "state": "occupied",
  "patient_name": "John Doe",
  "urgency_level": "high",
  "assigned_at": "2026-02-05T20:30:00.000Z",
  "discharged_at": null,
  "created_at": "2026-02-05T18:23:03.067Z",
  "updated_at": "2026-02-05T20:30:00.000Z"
}
```

**Error Response (422):**
```json
{
  "error": "Bed not available"
}
```

**Example:**
```bash
curl -X POST http://localhost:3000/beds/1/assign \
  -H "Content-Type: application/json" \
  -d '{"patient_name": "John Doe", "urgency_level": "high"}'
```

---

#### 3. Discharge Patient

**POST** `/beds/:id/discharge`

Transitions bed from `occupied` to `maintenance` state.

**Success Response (200):**
```json
{
  "id": 1,
  "bed_number": "ICU-01",
  "state": "maintenance",
  "patient_name": "John Doe",
  "urgency_level": "high",
  "assigned_at": "2026-02-05T20:30:00.000Z",
  "discharged_at": "2026-02-05T22:15:00.000Z",
  "created_at": "2026-02-05T18:23:03.067Z",
  "updated_at": "2026-02-05T22:15:00.000Z"
}
```

**Error Response (422):**
```json
{
  "error": "No patient to discharge"
}
```

**Example:**
```bash
curl -X POST http://localhost:3000/beds/1/discharge
```

---

#### 4. Mark Bed as Cleaned

**POST** `/beds/:id/clean`

Transitions bed from `maintenance` to `available` state.

**Success Response (200):**
```json
{
  "id": 1,
  "bed_number": "ICU-01",
  "state": "available",
  "patient_name": null,
  "urgency_level": null,
  "assigned_at": null,
  "discharged_at": null,
  "created_at": "2026-02-05T18:23:03.067Z",
  "updated_at": "2026-02-05T23:00:00.000Z"
}
```

**Error Response (422):**
```json
{
  "error": "Bed not in maintenance"
}
```

**Example:**
```bash
curl -X POST http://localhost:3000/beds/1/clean
```

---

#### 5. Export Beds as CSV

**GET** `/beds/export`

Downloads a CSV file with all bed data.

**Response:** CSV file stream

**Example:**
```bash
curl http://localhost:3000/beds/export --output beds.csv
```

**CSV Format:**
```csv
Bed Number,State,Patient Name,Urgency Level,Assigned At,Discharged At
ICU-01,available,N/A,N/A,N/A,N/A
ICU-02,occupied,John Doe,high,2026-02-05 20:30:00 UTC,N/A
ICU-03,maintenance,Jane Smith,critical,2026-02-05 19:00:00 UTC,2026-02-05 22:00:00 UTC
```

---

## State Logic

### Valid Transitions
```
┌─────────────┐
│  AVAILABLE  │ ◄──────────────┐
│   (Green)   │                │
└──────┬──────┘                │
       │                       │
       │ assign                │ clean
       │                       │
       ▼                       │
┌─────────────┐         ┌─────┴──────┐
│  OCCUPIED   │────────►│ MAINTENANCE│
│    (Red)    │         │  (Yellow)  │
└─────────────┘         └────────────┘
    discharge
```

### State Rules

| Current State | Action | Next State | HTTP Code |
|--------------|--------|------------|-----------|
| `available` | `assign` | `occupied` | 200 ✅ |
| `occupied` | `discharge` | `maintenance` | 200 ✅ |
| `maintenance` | `clean` | `available` | 200 ✅ |
| `available` | `discharge` | - | 422 ❌ |
| `available` | `clean` | - | 422 ❌ |
| `occupied` | `assign` | - | 422 ❌ |
| `occupied` | `clean` | - | 422 ❌ (THE GUARDRAIL) |
| `maintenance` | `assign` | - | 422 ❌ |
| `maintenance` | `discharge` | - | 422 ❌ |

---

## Testing

### Manual API Testing

#### Test Valid Flow
```bash
# 1. Assign patient (Available → Occupied)
curl -X POST http://localhost:3000/beds/1/assign \
  -H "Content-Type: application/json" \
  -d '{"patient_name": "Test Patient", "urgency_level": "high"}'
# Expected: 200 OK

# 2. Discharge patient (Occupied → Maintenance)
curl -X POST http://localhost:3000/beds/1/discharge
# Expected: 200 OK

# 3. Clean bed (Maintenance → Available)
curl -X POST http://localhost:3000/beds/1/clean
# Expected: 200 OK
```

#### Test THE GUARDRAIL (Invalid Transition)
```bash
# Setup: Assign patient to bed 2
curl -X POST http://localhost:3000/beds/2/assign \
  -H "Content-Type: application/json" \
  -d '{"patient_name": "Guardrail Test", "urgency_level": "critical"}'

# Try to clean without discharging (Occupied → Available)
curl -X POST http://localhost:3000/beds/2/clean
# Expected: 422 Unprocessable Entity
# Response: {"error":"Bed not in maintenance"}
```

---

## Project Structure
```
icu_bed_manager/
├── app/
│   ├── controllers/
│   │   └── beds_controller.rb       # API endpoints
│   └── models/
│       └── bed.rb                    # State machine logic
├── config/
│   ├── database.yml                  # Database configuration
│   ├── routes.rb                     # API routes
│   └── initializers/
│       └── cors.rb                   # CORS configuration
├── db/
│   ├── migrate/
│   │   └── XXXXX_create_beds.rb     # Database migration
│   ├── schema.rb                     # Database schema
│   └── seeds.rb                      # Seed data (20 beds)
├── Gemfile                           # Ruby dependencies
└── README.md                         # This file
```

---

## Database Schema

### Beds Table

| Column | Type | Null | Default | Description |
|--------|------|------|---------|-------------|
| `id` | `bigint` | NO | AUTO | Primary key |
| `bed_number` | `varchar` | NO | - | Unique identifier (ICU-01, etc.) |
| `state` | `varchar` | NO | `'available'` | Current state (available/occupied/maintenance) |
| `patient_name` | `varchar` | YES | `NULL` | Patient name when occupied |
| `urgency_level` | `varchar` | YES | `NULL` | Urgency (low/medium/high/critical) |
| `assigned_at` | `timestamp` | YES | `NULL` | When patient was assigned |
| `discharged_at` | `timestamp` | YES | `NULL` | When patient was discharged |
| `created_at` | `timestamp` | NO | NOW | Record creation time |
| `updated_at` | `timestamp` | NO | NOW | Last update time |

**Indexes:**
- Primary key on `id`
- Unique index on `bed_number`
- Index on `state` (for filtering)

---

## API Response Codes

| Code | Meaning | When It Occurs |
|------|---------|----------------|
| 200 | Success | Valid operation completed |
| 422 | Unprocessable Entity | Invalid state transition attempted |
| 404 | Not Found | Bed ID doesn't exist |
| 500 | Internal Server Error | Unexpected server error |

