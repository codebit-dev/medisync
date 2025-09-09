# MEDISYNC - EHR Integration Microservice

A Flask-based microservice for integrating NAMASTE traditional medicine codes with WHO ICD-11 TM2 & Biomedicine terminology, compliant with India's 2016 EHR Standards.

## Features

- **NAMASTE CSV Ingestion**: Upload and process NAMASTE traditional medicine codes
- **ICD-11 Integration**: Sync WHO ICD-11 TM2 and Biomedicine codes via API
- **FHIR R4 Compliance**: All endpoints return FHIR-compliant resources
- **Code Translation**: Bidirectional translation between NAMASTE and ICD-11 codes
- **Auto-complete Search**: Fast lookup for both NAMASTE and ICD-11 codes
- **Bundle Processing**: Accept FHIR Bundles with dual-coded problem lists
- **OAuth 2.0 Security**: ABHA token-based authentication
- **Audit Logging**: ISO 22600 compliant audit trail with versioning
- **Consent Management**: Built-in consent validation system

## API Endpoints

### Core Endpoints

- `POST /ingest/csv` - Ingest NAMASTE CSV file
- `GET /valueset/search?q=<term>` - Auto-complete code search
- `POST /translate` - Translate between NAMASTE and ICD-11 codes
- `POST /bundle/upload` - Upload FHIR Bundle with dual-coded entries
- `POST /sync/icd11` - Sync ICD-11 codes from WHO API
- `GET /health` - Health check endpoint
- `GET /docs` - Swagger API documentation

## Installation

### Prerequisites

- Python 3.8+
- SQLite (or PostgreSQL for production)
- WHO ICD-11 API credentials
- ABHA/ABDM credentials (for production)

### Setup Instructions

1. **Clone the repository**
```bash
cd D:\coding\Project\MEDISYNC
```

2. **Create virtual environment**
```bash
python -m venv venv
venv\Scripts\activate  # On Windows
# source venv/bin/activate  # On Linux/Mac
```

3. **Install dependencies**
```bash
pip install -r requirements.txt
```

4. **Configure environment variables**
```bash
copy .env.template .env
# Edit .env with your credentials
```

5. **Initialize database**
```bash
flask db init
flask db migrate -m "Initial migration"
flask db upgrade
```

6. **Run the application**
```bash
python app.py
```

The API will be available at `http://localhost:5000`

## Usage Examples

### 1. Ingest NAMASTE CSV

```bash
curl -X POST http://localhost:5000/ingest/csv \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "file=@namaste_codes.csv"
```

CSV Format:
```csv
code,display,definition,category,parent_code
NAM001,Vata Dosha,Primary dosha in Ayurveda,Ayurveda,
NAM002,Pitta Dosha,Fire element dosha,Ayurveda,
```

### 2. Search Codes

```bash
curl -X GET "http://localhost:5000/valueset/search?q=diabetes&limit=10"
```

### 3. Translate Codes

```bash
curl -X POST http://localhost:5000/translate \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "source_code": "NAM001",
    "source_system": "http://terminology.india.gov.in/namaste",
    "target_system": "http://id.who.int/icd11/mms"
  }'
```

### 4. Upload FHIR Bundle

```bash
curl -X POST http://localhost:5000/bundle/upload \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "resourceType": "Bundle",
    "type": "collection",
    "entry": [{
      "resource": {
        "resourceType": "Condition",
        "code": {
          "coding": [
            {
              "system": "http://terminology.india.gov.in/namaste",
              "code": "NAM001",
              "display": "Vata Imbalance"
            },
            {
              "system": "http://id.who.int/icd11/mms",
              "code": "TM2.A01",
              "display": "Constitutional disorder"
            }
          ]
        }
      }
    }]
  }'
```

## Authentication

The API uses OAuth 2.0 with ABHA tokens. Include the token in the Authorization header:

```
Authorization: Bearer YOUR_ABHA_TOKEN
```

### Obtaining ABHA Tokens

For development/testing:
- Use the ABDM sandbox environment
- Register at https://sandbox.abdm.gov.in

For production:
- Use production ABDM credentials
- Follow ABHA integration guidelines

## Database Schema

The application uses SQLAlchemy with the following main models:

- **NAMASTECode**: Traditional medicine codes
- **ICD11Code**: WHO ICD-11 codes
- **ConceptMapping**: Mappings between NAMASTE and ICD-11
- **AuditLog**: Audit trail for all operations
- **FHIRResource**: Stored FHIR resources with versioning
- **ConsentRecord**: Patient consent management

## FHIR Resources

All endpoints return FHIR R4 compliant resources:

- **CodeSystem**: NAMASTE and ICD-11 code systems
- **ValueSet**: Search results and code collections
- **ConceptMap**: Mappings between code systems
- **Bundle**: Collections of resources
- **OperationOutcome**: Error and success responses
- **Parameters**: Operation inputs/outputs

## Security Features

- **OAuth 2.0**: ABHA token-based authentication
- **Audit Logging**: Complete audit trail for all operations
- **Consent Management**: ISO 22600 compliant consent validation
- **Rate Limiting**: Configurable API rate limits
- **CORS**: Configurable cross-origin resource sharing

## Development

### Project Structure

```
MEDISYNC/
├── app.py                 # Flask application entry point
├── config.py             # Configuration settings
├── models.py             # Database models
├── requirements.txt      # Python dependencies
├── .env.template        # Environment variables template
├── src/
│   ├── api/
│   │   └── __init__.py  # API endpoints
│   ├── middleware/
│   │   └── auth.py      # Authentication middleware
│   ├── services/
│   │   └── icd11_service.py  # WHO ICD-11 integration
│   └── utils/
│       └── fhir_resources.py  # FHIR resource generators
```

### Running Tests

```bash
pytest tests/
```

### API Documentation

Swagger documentation is available at `http://localhost:5000/docs`

## Deployment

### Production Considerations

1. **Database**: Use PostgreSQL instead of SQLite
2. **Security**: Use proper SSL/TLS certificates
3. **Secrets**: Store credentials in secure vault
4. **Scaling**: Consider using Elasticsearch for search
5. **Monitoring**: Implement logging and monitoring

### Docker Deployment

```dockerfile
FROM python:3.9-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
CMD ["gunicorn", "-w", "4", "-b", "0.0.0.0:5000", "app:create_app()"]
```

## Compliance

- **India EHR Standards 2016**: Fully compliant
- **FHIR R4**: All resources follow FHIR R4 specification
- **ISO 22600**: Consent and audit logging compliance
- **ABDM/ABHA**: Integration ready

## Support

For issues or questions, contact support@medisync.in

## License

This project is developed for healthcare integration in India following government EHR standards.
