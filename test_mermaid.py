import base64
import json
import urllib.request
import sys

mermaid_code = """erDiagram
    users {
        bigint id PK
        varchar name
        varchar email
        varchar password
    }
    plants {
        bigint id PK
        bigint user_id FK
        varchar name
        varchar location
    }
    plant_histories {
        bigint id PK
        bigint plant_id FK
        varchar action
    }
    plant_care_schedules {
        bigint id PK
        bigint plant_id FK
        varchar task_type
        datetime next_due_at
    }
    plant_libraries {
        bigint id PK
        varchar name
        varchar type
    }
    pest_disease_guides {
        bigint id PK
        varchar disease_name
        varchar type
    }
    articles {
        bigint id PK
        varchar title
        varchar category
    }

    users ||--o{ plants : "sở hữu"
    plants ||--o{ plant_histories : "có lịch sử"
    plants ||--o{ plant_care_schedules : "có lịch trình"
"""

state = {
    "code": mermaid_code,
    "mermaid": {"theme": "default"}
}
json_state = json.dumps(state)
b64_state = base64.urlsafe_b64encode(json_state.encode('utf-8')).decode('utf-8')
url = f"https://mermaid.ink/img/{b64_state}?type=png"

try:
    print(f"Downloading from {url}")
    req = urllib.request.Request(
        url, 
        data=None, 
        headers={
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        }
    )
    with urllib.request.urlopen(req) as response, open("test_er.png", 'wb') as out_file:
        data = response.read()
        out_file.write(data)
    print("Downloaded successfully.")
except Exception as e:
    print(f"Error: {e}")
