# Security Implementation Guide

This guide provides step-by-step instructions for implementing the most critical security controls in Unison.

## Part 1: JWT Authentication Service

### Create unison-auth Service

#### 1.1 Directory Structure
```bash
mkdir -p unison-auth/src
cd unison-auth
```

#### 1.2 requirements.txt
```txt
fastapi==0.104.1
uvicorn[standard]==0.24.0
python-jose[cryptography]==3.3.0
passlib[bcrypt]==1.7.4
python-multipart==0.0.6
redis==5.0.1
```

#### 1.3 src/auth_service.py
```python
from fastapi import FastAPI, HTTPException, Depends, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from jose import JWTError, jwt
from passlib.context import CryptContext
from datetime import datetime, timedelta
import redis
import os
from typing import Optional, Dict, Any

app = FastAPI(title="unison-auth")

# Configuration
SECRET_KEY = os.getenv("UNISON_JWT_SECRET", "your-secret-key-change-in-production")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30
REFRESH_TOKEN_EXPIRE_MINUTES = 1440  # 24 hours

# Redis for token blacklist
redis_client = redis.Redis(
    host=os.getenv("REDIS_HOST", "localhost"),
    port=int(os.getenv("REDIS_PORT", "6379")),
    decode_responses=True
)

# Password hashing
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
security = HTTPBearer()

# Mock user database (replace with real database)
USERS_DB = {
    "admin": {
        "username": "admin",
        "hashed_password": pwd_context.hash("admin123"),
        "roles": ["admin"],
        "active": True
    },
    "operator": {
        "username": "operator",
        "hashed_password": pwd_context.hash("operator123"),
        "roles": ["operator"],
        "active": True
    },
    "developer": {
        "username": "developer",
        "hashed_password": pwd_context.hash("dev123"),
        "roles": ["developer"],
        "active": True
    }
}

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password: str) -> str:
    return pwd_context.hash(password)

def get_user(username: str) -> Optional[Dict[str, Any]]:
    return USERS_DB.get(username)

def authenticate_user(username: str, password: str) -> Optional[Dict[str, Any]]:
    user = get_user(username)
    if not user:
        return None
    if not verify_password(password, user["hashed_password"]):
        return None
    return user

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=15)
    to_encode.update({"exp": expire, "type": "access"})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

def create_refresh_token(data: dict) -> str:
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(minutes=REFRESH_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire, "type": "refresh"})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

def is_token_blacklisted(jti: str) -> bool:
    return redis_client.exists(f"blacklist:{jti}")

def blacklist_token(jti: str, exp: int):
    ttl = exp - int(datetime.utcnow().timestamp())
    if ttl > 0:
        redis_client.setex(f"blacklist:{jti}", ttl, "1")

async def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)) -> Dict[str, Any]:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    
    try:
        payload = jwt.decode(credentials.credentials, SECRET_KEY, algorithms=[ALGORITHM])
        username: str = payload.get("sub")
        jti: str = payload.get("jti")
        token_type: str = payload.get("type")
        
        if username is None or token_type != "access":
            raise credentials_exception
        
        if is_token_blacklisted(jti):
            raise credentials_exception
            
    except JWTError:
        raise credentials_exception
    
    user = get_user(username=username)
    if user is None:
        raise credentials_exception
    
    return user

@app.post("/token")
async def login(username: str, password: str):
    user = authenticate_user(username, password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user["username"], "roles": user["roles"]}, 
        expires_delta=access_token_expires
    )
    refresh_token = create_refresh_token(
        data={"sub": user["username"], "roles": user["roles"]}
    )
    
    return {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "token_type": "bearer",
        "expires_in": ACCESS_TOKEN_EXPIRE_MINUTES * 60
    }

@app.post("/refresh")
async def refresh_token(refresh_token: str):
    try:
        payload = jwt.decode(refresh_token, SECRET_KEY, algorithms=[ALGORITHM])
        username: str = payload.get("sub")
        token_type: str = payload.get("type")
        
        if username is None or token_type != "refresh":
            raise HTTPException(status_code=401, detail="Invalid refresh token")
            
    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid refresh token")
    
    user = get_user(username=username)
    if not user:
        raise HTTPException(status_code=401, detail="User not found")
    
    # Create new access token
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user["username"], "roles": user["roles"]}, 
        expires_delta=access_token_expires
    )
    
    return {"access_token": access_token, "token_type": "bearer"}

@app.post("/logout")
async def logout(credentials: HTTPAuthorizationCredentials = Depends(security)):
    try:
        payload = jwt.decode(credentials.credentials, SECRET_KEY, algorithms=[ALGORITHM])
        jti: str = payload.get("jti")
        exp: int = payload.get("exp")
        
        if jti and exp:
            blacklist_token(jti, exp)
            
    except JWTError:
        pass
    
    return {"message": "Successfully logged out"}

@app.get("/me")
async def read_users_me(current_user: Dict[str, Any] = Depends(get_current_user)):
    return {
        "username": current_user["username"],
        "roles": current_user["roles"],
        "active": current_user["active"]
    }

@app.get("/health")
async def health():
    return {"status": "ok", "service": "unison-auth"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8088)
```

#### 1.4 Dockerfile
```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY src/ ./src/

EXPOSE 8088

CMD ["python", "src/auth_service.py"]
```

## Part 2: Authentication Middleware for Existing Services

### 2.1 Update unison-common with auth utilities

#### src/unison_common/auth.py
```python
from fastapi import HTTPException, Depends, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from jose import JWTError, jwt
import os
import httpx
from typing import Dict, Any, List

# Configuration
SECRET_KEY = os.getenv("UNISON_JWT_SECRET", "your-secret-key")
ALGORITHM = "HS256"
AUTH_SERVICE_URL = os.getenv("UNISON_AUTH_SERVICE_URL", "http://auth:8088")

security = HTTPBearer()

class AuthError(Exception):
    def __init__(self, message: str, status_code: int = status.HTTP_401_UNAUTHORIZED):
        self.message = message
        self.status_code = status_code

async def verify_token(credentials: HTTPAuthorizationCredentials = Depends(security)) -> Dict[str, Any]:
    """Verify JWT token with auth service"""
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            response = await client.post(
                f"{AUTH_SERVICE_URL}/verify",
                json={"token": credentials.credentials}
            )
            
        if response.status_code != 200:
            raise AuthError("Invalid token")
            
        return response.json()
        
    except httpx.RequestError:
        raise AuthError("Auth service unavailable")

def require_roles(required_roles: List[str]):
    """Decorator to require specific roles"""
    def decorator(func):
        async def wrapper(*args, **kwargs):
            current_user = kwargs.get('current_user')
            if not current_user:
                raise AuthError("Authentication required")
                
            user_roles = current_user.get('roles', [])
            if not any(role in user_roles for role in required_roles):
                raise AuthError("Insufficient permissions", status.HTTP_403_FORBIDDEN)
                
            return await func(*args, **kwargs)
        return wrapper
    return decorator

# Service-to-service authentication
def create_service_token(service_name: str) -> str:
    """Create token for service-to-service communication"""
    # This should use a different secret or method
    import time
    payload = {
        "sub": service_name,
        "type": "service",
        "iat": int(time.time()),
        "exp": int(time.time()) + 3600  # 1 hour
    }
    return jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)

def verify_service_token(token: str) -> bool:
    """Verify service token"""
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        return payload.get("type") == "service"
    except JWTError:
        return False
```

### 2.2 Update Orchestrator with Authentication

#### Add to unison-orchestrator/src/server.py
```python
# Add imports
from unison_common.auth import verify_token, require_roles, AuthError

# Add authentication dependency
@app.post("/event")
async def handle_event(
    envelope: dict = Body(...),
    current_user: Dict[str, Any] = Depends(verify_token)
):
    """Handle events with authentication"""
    _metrics["/event"] += 1
    
    try:
        envelope = validate_event_envelope(envelope)
    except EnvelopeValidationError as e:
        raise HTTPException(status_code=400, detail=str(e))
    
    # Add user context to envelope
    envelope["user"] = {
        "username": current_user.get("sub"),
        "roles": current_user.get("roles", [])
    }
    
    # Rest of the existing logic...
```

## Part 3: Network Security with Docker Compose

### 3.1 docker-compose.security.yml
```yaml
version: '3.8'

networks:
  public:
    driver: bridge
    # Only API gateway and load balancer
  
  internal:
    driver: bridge
    internal: true
    # Internal services
  
  data:
    driver: bridge
    internal: true
    # Storage and databases
  
  auth:
    driver: bridge
    internal: true
    # Auth and Redis

services:
  # API Gateway (public facing)
  api-gateway:
    image: kong:3.4
    networks:
      - public
      - internal
      - auth
    ports:
      - "80:8000"
      - "443:8443"
    environment:
      KONG_DATABASE: "off"
      KONG_DECLARATIVE_CONFIG: /kong/declarative/kong.yml
      KONG_PROXY_ACCESS_LOG: /dev/stdout
      KONG_ADMIN_ACCESS_LOG: /dev/stdout
      KONG_PROXY_ERROR_LOG: /dev/stderr
      KONG_ADMIN_ERROR_LOG: /dev/stderr
      KONG_ADMIN_LISTEN: 0.0.0.0:8001
    volumes:
      - ./kong.yml:/kong/declarative/kong.yml:ro
    depends_on:
      - auth

  # Auth Service
  auth:
    build:
      context: ../unison-auth
    image: ghcr.io/project-unisonos/unison-auth:latest
    networks:
      - auth
    environment:
      REDIS_HOST: redis
      REDIS_PORT: 6379
    depends_on:
      - redis
    restart: unless-stopped

  # Redis for auth
  redis:
    image: redis:7-alpine
    networks:
      - auth
    volumes:
      - redis_data:/data
    restart: unless-stopped

  # Orchestrator (internal only)
  orchestrator:
    image: ghcr.io/project-unisonos/unison-orchestrator:latest
    networks:
      - internal
      - data
      - auth
    environment:
      UNISON_AUTH_SERVICE_URL: "http://auth:8088"
    depends_on:
      - auth
      - context
      - storage
      - policy
      - inference
    restart: unless-stopped
    # Remove public port mapping
    # ports:
    #   - "8080:8080"

  # Other services with network restrictions
  context:
    image: ghcr.io/project-unisonos/unison-context:latest
    networks:
      - internal
      - data
    restart: unless-stopped

  storage:
    image: ghcr.io/project-unisonos/unison-storage:latest
    networks:
      - data
    volumes:
      - unison_data:/data
    restart: unless-stopped

  policy:
    image: ghcr.io/project-unisonos/unison-policy:latest
    networks:
      - internal
      - data
    restart: unless-stopped

  inference:
    image: ghcr.io/project-unisonos/unison-inference:latest
    networks:
      - internal
    restart: unless-stopped

volumes:
  unison_data:
  redis_data:
```

### 3.2 Kong Configuration (kong.yml)
```yaml
_format_version: "3.0"

services:
- name: orchestrator-service
  url: http://orchestrator:8080
  plugins:
  - name: jwt
  - name: rate-limiting
    config:
      minute: 100
      hour: 1000

- name: auth-service
  url: http://auth:8088
  routes:
  - name: auth-route
    paths:
    - /auth
    - /token
    - /refresh
    - /logout

routes:
- name: orchestrator-route
  service: orchestrator-service
  paths:
  - /api
  - /event

consumers:
- username: service-user
  jwt_secrets:
  - key: service-key
    secret: your-service-secret

plugins:
- name: cors
  config:
    origins: ["http://localhost:3000"]
    methods: ["GET", "POST", "PUT", "DELETE"]
    headers: ["Accept", "Content-Type", "Authorization"]
```

## Part 4: Security Headers and Middleware

### 4.1 Add security middleware to all services
```python
# Add to each FastAPI service
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.trustedhost import TrustedHostMiddleware

# Security headers middleware
@app.middleware("http")
async def add_security_headers(request: Request, call_next):
    response = await call_next(request)
    
    # Security headers
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
    response.headers["X-XSS-Protection"] = "1; mode=block"
    response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"
    response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
    
    # Content Security Policy
    csp = (
        "default-src 'self'; "
        "script-src 'self' 'unsafe-inline'; "
        "style-src 'self' 'unsafe-inline'; "
        "img-src 'self' data:; "
        "font-src 'self'; "
        "connect-src 'self'"
    )
    response.headers["Content-Security-Policy"] = csp
    
    return response

# CORS middleware (configure as needed)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000"],  # Your frontend URL
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE"],
    allow_headers=["*"],
)

# Trusted hosts (prevents host header attacks)
app.add_middleware(
    TrustedHostMiddleware,
    allowed_hosts=["localhost", "127.0.0.1", "*.yourdomain.com"]
)
```

## Part 5: Rate Limiting

### 5.1 Add rate limiting to services
```python
# Add to requirements.txt
slowapi==0.1.9
redis==5.0.1

# Add to service code
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded

limiter = Limiter(key_func=get_remote_address)
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

@app.post("/event")
@limiter.limit("100/minute")
async def handle_event(request: Request, envelope: dict = Body(...)):
    # Your existing code
    pass

@app.get("/health")
@limiter.limit("1000/minute")  # Higher limit for health checks
async def health(request: Request):
    return {"status": "ok"}
```

## Part 6: Enhanced Input Validation

### 6.1 Update envelope validation
```python
# Update unison-common/src/unison_common/envelope.py
import re
import bleach
from typing import Any, Dict

class EnvelopeValidationError(ValueError):
    """Raised when an event envelope fails structural validation."""
    pass

REQUIRED_FIELDS = ["timestamp", "source", "intent", "payload"]

# Sanitization patterns
INTENT_PATTERN = re.compile(r'^[a-z0-9\.]+$')
SOURCE_PATTERN = re.compile(r'^[a-zA-Z0-9\-\.]+$')
MAX_PAYLOAD_SIZE = 1024 * 1024  # 1MB
MAX_STRING_LENGTH = 10000

def sanitize_string(value: str) -> str:
    """Sanitize string values"""
    if not isinstance(value, str):
        return value
    # Remove potentially dangerous HTML
    cleaned = bleach.clean(value, tags=[], strip=True)
    # Truncate if too long
    if len(cleaned) > MAX_STRING_LENGTH:
        cleaned = cleaned[:MAX_STRING_LENGTH]
    return cleaned

def sanitize_dict(d: Dict[str, Any]) -> Dict[str, Any]:
    """Recursively sanitize dictionary values"""
    sanitized = {}
    for key, value in d.items():
        if isinstance(value, str):
            sanitized[key] = sanitize_string(value)
        elif isinstance(value, dict):
            sanitized[key] = sanitize_dict(value)
        elif isinstance(value, list):
            sanitized[key] = [sanitize_string(item) if isinstance(item, str) else item for item in value]
        else:
            sanitized[key] = value
    return sanitized

def validate_event_envelope(envelope: Dict[str, Any]) -> Dict[str, Any]:
    if not isinstance(envelope, dict):
        raise EnvelopeValidationError("Event must be an object")

    # Check payload size
    import json
    if len(json.dumps(envelope)) > MAX_PAYLOAD_SIZE:
        raise EnvelopeValidationError("Payload too large")

    for field in REQUIRED_FIELDS:
        if field not in envelope:
            raise EnvelopeValidationError(f"Missing required field '{field}'")

    # Validate and sanitize timestamp
    if not isinstance(envelope["timestamp"], str):
        raise EnvelopeValidationError("timestamp must be string (ISO 8601)")
    envelope["timestamp"] = sanitize_string(envelope["timestamp"])

    # Validate and sanitize source
    if not isinstance(envelope["source"], str):
        raise EnvelopeValidationError("source must be string")
    if not SOURCE_PATTERN.match(envelope["source"]):
        raise EnvelopeValidationError("Invalid source format")
    envelope["source"] = sanitize_string(envelope["source"])

    # Validate and sanitize intent
    if not isinstance(envelope["intent"], str):
        raise EnvelopeValidationError("intent must be string")
    if not INTENT_PATTERN.match(envelope["intent"]):
        raise EnvelopeValidationError("Invalid intent format")
    envelope["intent"] = sanitize_string(envelope["intent"])

    # Validate and sanitize payload
    if not isinstance(envelope["payload"], dict):
        raise EnvelopeValidationError("payload must be object")
    envelope["payload"] = sanitize_dict(envelope["payload"])

    # Validate optional fields
    if "auth_scope" in envelope and envelope["auth_scope"] is not None:
        if not isinstance(envelope["auth_scope"], str):
            raise EnvelopeValidationError("auth_scope must be string if provided")
        envelope["auth_scope"] = sanitize_string(envelope["auth_scope"])

    if "safety_context" in envelope and envelope["safety_context"] is not None:
        if not isinstance(envelope["safety_context"], dict):
            raise EnvelopeValidationError("safety_context must be object if provided")
        envelope["safety_context"] = sanitize_dict(envelope["safety_context"])

    # Reject unknown top-level fields
    allowed_fields = set(REQUIRED_FIELDS + ["auth_scope", "safety_context"])
    for k in envelope.keys():
        if k not in allowed_fields:
            raise EnvelopeValidationError(f"Unknown top-level field '{k}'")

    return envelope
```

## Deployment Instructions

### 1. Update docker-compose.yml
```bash
# Replace your current docker-compose.yml with the security version
cp docker-compose.security.yml docker-compose.yml
```

### 2. Build and deploy auth service
```bash
cd unison-auth
docker build -t unison-auth .
docker push your-registry/unison-auth:latest
```

### 3. Update all services with authentication
```bash
# Pull updated common library
pip install -e ./unison-common

# Add authentication dependencies to each service
# Update each service's server.py with auth middleware
```

### 4. Deploy with security features
```bash
docker-compose down
docker-compose up -d
```

### 5. Test authentication
```bash
# Get a token
curl -X POST http://localhost/auth/token \
  -H "Content-Type: application/json" \
  -d '{"username": "admin", "password": "admin123"}'

# Use token to access API
curl -X POST http://localhost/api/event \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"intent": "echo", "payload": {"test": "data"}}'
```

This implementation provides the foundation for enterprise-grade security in Unison. Each component can be further customized based on specific requirements and compliance needs.
