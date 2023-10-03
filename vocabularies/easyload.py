import pandas as pd
from sqlalchemy import create_engine
from configparser import ConfigParser

# Define the file paths for your CSV files
concept_file = "./vocabularies/gis_vocabs_concept_stage_v1.csv"
concept_relationship_file = "./vocabularies/gis_vocabs_concept_relationship_stage_v1.csv"
vocabulary_file = "./vocabularies/gis_vocabs_vocabulary_stage_v1.csv"

# Load CSV files into pandas DataFrames
concept_df = pd.read_csv(concept_file)
concept_relationship_df = pd.read_csv(concept_relationship_file)
vocabulary_df = pd.read_csv(vocabulary_file)

concept_df['concept_id'] = range(2000000001, 2000000001 + len(concept_df))

# Add concept_ids to concept_relationship_df

# Extract related vocabularies from gisdev.concept
concept_relationship_df = concept_relationship_df.drop(columns=['concept_id_1', 'concept_id_2'])

vocabs = concept_relationship_df['vocabulary_id_2'].unique().tolist()

quoted_vocabs = [f"'{v}'" for v in vocabs]

sql_query = f"SELECT concept_code, vocabulary_id, concept_id FROM gisdev.concept WHERE vocabulary_id IN ({', '.join(map(str, quoted_vocabs))})"

# Read the database connection details from the config.txt file
config = ConfigParser()
config.read('./vocabularies/config.txt')

# Extract the connection parameters
db_params = {
    'dbname': config.get('DEFAULT', 'DB_NAME'),
    'user': config.get('DEFAULT', 'DB_USER'),
    'password': config.get('DEFAULT', 'PGPASSWORD'),
    'host': config.get('DEFAULT', 'DB_HOST'),
    'port': config.get('DEFAULT', 'DB_PORT')
}

# Create a SQLAlchemy engine
db_url = f"postgresql://{db_params['user']}:{db_params['password']}@{db_params['host']}:{db_params['port']}/{db_params['dbname']}"
engine = create_engine(db_url)

# Execute the query and fetch the results into a Pandas DataFrame
try:
    base_concept_df = pd.read_sql_query(sql_query, engine)
except Exception as e:
    print(f"Error: Unable to fetch data from the database - {e}")
    exit(1)

# Dispose of the engine to close the database connection
engine.dispose()

# add the new concepts to the base concept dataframe
base_concept_df = pd.concat([concept_df[['concept_code', 'vocabulary_id', 'concept_id']], base_concept_df], ignore_index=True)

concept_relationship_df = concept_relationship_df.merge(
    base_concept_df[['concept_code', 'vocabulary_id', 'concept_id']],
    left_on=['concept_code_1', 'vocabulary_id_1'],
    right_on=['concept_code', 'vocabulary_id'],
    how='left'
)

concept_relationship_df = concept_relationship_df.rename(columns={'concept_id': 'concept_id_1'}).drop(columns=['concept_code', 'vocabulary_id'])

concept_relationship_df = concept_relationship_df.merge(
    base_concept_df[['concept_code', 'vocabulary_id', 'concept_id']],
    left_on=['concept_code_2', 'vocabulary_id_2'],
    right_on=['concept_code', 'vocabulary_id'],
    how='left'
)

concept_relationship_df = concept_relationship_df.rename(columns={'concept_id': 'concept_id_2'}).drop(columns=['concept_code', 'vocabulary_id'])

concept_relationship_df = concept_relationship_df[['concept_id_1', 'concept_id_2'] + [col for col in concept_relationship_df.columns if col not in ['concept_id_1', 'concept_id_2']]]

# Create a DataFrame for the unique domain values
domain_df = pd.DataFrame({
    'domain_id': concept_df['domain_id'].unique(),
    'domain_name': concept_df['domain_id'].unique(),
    'domain_concept_id': range(max(concept_df['concept_id']) + 1, max(concept_df['concept_id']) + 1 + concept_df['domain_id'].nunique())
})

# Create a DataFrame for the unique concept_class values
concept_class_df = pd.DataFrame({
    'concept_class_id': concept_df['concept_class_id'].unique(),
    'concept_class_name': concept_df['concept_class_id'].unique(),
    'concept_class_concept_id': range(max(domain_df['domain_concept_id']) + 1, max(domain_df['domain_concept_id']) + 1 + concept_df['concept_class_id'].nunique())
})

# Filter the vocabulary table to keep only rows where vocabulary_concept_id is NaN
vocabulary_df = vocabulary_df[vocabulary_df['vocabulary_concept_id'].isna()]

# Assign incrementing values to the remaining rows in vocabulary_concept_id
vocabulary_df['vocabulary_concept_id'] = range(max(concept_class_df['concept_class_concept_id']) + 1, max(concept_class_df['concept_class_concept_id']) + 1 + len(vocabulary_df))


# Define the output file paths with stems
output_paths = {
    'concept': './vocabularies/gis_concept_fragment.csv',
    'concept_relationship': './vocabularies/gis_concept_relationship_fragment.csv',
    'vocabulary': './vocabularies/gis_vocabulary_fragment.csv',
    'domain': './vocabularies/gis_domain_fragment.csv',
    'concept_class': './vocabularies/gis_concept_class_fragment.csv'
}

# Write DataFrames to CSV files
concept_df.to_csv(output_paths['concept'], index=False, line_terminator='')
concept_relationship_df.to_csv(output_paths['concept_relationship'], index=False, line_terminator='')
vocabulary_df.to_csv(output_paths['vocabulary'], index=False, line_terminator='')
domain_df.to_csv(output_paths['domain'], index=False, line_terminator='')
concept_class_df.to_csv(output_paths['concept_class'], index=False, line_terminator='')

# Display the paths of the saved CSV files
for table_name, file_path in output_paths.items():
    print(f"{table_name.capitalize()} DataFrame saved as {file_path}")