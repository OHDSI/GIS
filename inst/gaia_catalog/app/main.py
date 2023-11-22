from typing import TYPE_CHECKING, List
import fastapi as _fastapi
import uvicorn as _uvicorn
import sqlalchemy.orm as _orm

import schemas as _schemas
import services as _services

if TYPE_CHECKING:
    from sqlalchemy.orm import Session

app = _fastapi.FastAPI()

@app.post("/api/data_source/", response_model=_schemas.DataSource)
async def create_data_source(data_source: _schemas.CreateDataSource, db: _orm.Session = _fastapi.Depends(_services.get_db)):
    return await _services.create_data_source(data_source, db)

