from typing import TYPE_CHECKING
import database as _database
import models as _models
import schemas as _schemas

if TYPE_CHECKING:
    from sqlalchemy.orm import Session

def _add_tables():
    return _database.Base.metadata.create_all(bind=_database.engine)

def get_db():
    db = _database.SessionLocal()
    try:
        yield db
    finally:
        db.close()

async def create_data_source(data_source: _schemas.CreateDataSource, db: "Session") -> _schemas.DataSource:
    db_data_source = _models.DataSource(**data_source.dict())
    db.add(db_data_source)
    db.commit()
    db.refresh(db_data_source)
    return _schemas.DataSource.from_orm(db_data_source)