import sqlalchemy as _sql
import sqlalchemy.ext.declarative as _declarative
import sqlalchemy.orm as _orm

DATABASE_URL = "postgresql://postgres:mysecretpassword@localhost:5436/gaiaDB"

engine = _sql.create_engine(DATABASE_URL, echo=True, future=True)

SessionLocal = _orm.sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = _declarative.declarative_base(metadata=_sql.MetaData(schema="backbone"))

