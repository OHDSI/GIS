import datetime as _dt
import pydantic as _pydantic

class _BaseDataSource(_pydantic.BaseModel):
    data_source_uuid: int
    org_id: str
    org_set_id: str
    dataset_name: str
    dataset_version: str
    geom_type: str
    geom_spec: str
    boundary_type: str
    has_attributes: int
    download_method: str
    download_subtype: str
    download_data_standard: str
    download_filename: str
    download_url: str
    download_auth: str
    documentation_url: str

class DataSource(_BaseDataSource):
    class Config:
        from_attributes = True

class CreateDataSource(_BaseDataSource):
    pass