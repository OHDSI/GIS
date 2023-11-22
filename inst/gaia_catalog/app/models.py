import datetime as _dt
import sqlalchemy as _sql

import database as _database

class DataSource(_database.Base):
    __tablename__ = "data_source"
    data_source_uuid = _sql.Column(_sql.Integer, primary_key=True, index=True)
    org_id = _sql.Column(_sql.String, index=True)
    org_set_id = _sql.Column(_sql.String, index=True)
    dataset_name = _sql.Column(_sql.String, index=True)
    dataset_version = _sql.Column(_sql.String, index=True)
    geom_type = _sql.Column(_sql.String, index=True)
    geom_spec = _sql.Column(_sql.String, index=True)
    boundary_type = _sql.Column(_sql.String, index=True)
    has_attributes = _sql.Column(_sql.Integer, index=True)
    download_method = _sql.Column(_sql.String, index=True)
    download_subtype = _sql.Column(_sql.String, index=True)
    download_data_standard = _sql.Column(_sql.String, index=True)
    download_filename = _sql.Column(_sql.String, index=True)
    download_url = _sql.Column(_sql.String, index=True)
    download_auth = _sql.Column(_sql.String, index=True)
    documentation_url = _sql.Column(_sql.String, index=True)