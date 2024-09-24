# Working with color data

from sqlalchemy import create_engine
import pandas as pd
import matplotlib.pyplot as plt
import psycopg2

df = pd.read_csv('data/bbdataconverted.csv')

# df.plot(x='wavelength', y='Back_AcaBaif', kind='line')


# Initialize the database
engine = create_engine('postgresql+psycopg2://chad:manbird@localhost:5432/color', echo=True)

# Add some things to the dataframe before creating tables
df.columns = [c.lower() for c in df.columns] # PostgreSQL doesn't like capitals or spaces
df['bird_id'] = df['catalog number'].factorize()[0] + 1
df['family'] = 'Icteridae'
df['tax_id'] = df[['family', 'genus', 'species']].apply(lambda x: '.'.join(x), axis=1)
df['tax_id'] = df['tax_id'].factorize()[0] + 1
df.head()

# Taxonomy table
taxo = df[['tax_id', 'family','genus','species']]
taxo = taxo.drop_duplicates()
taxo.set_index('tax_id', inplace=True)
taxo
taxo.to_sql("taxonomy", engine)

# Individuals table
indiv = df[['bird_id', 'catalog number', 'sex']]
indiv = indiv.rename(columns={'catalog number':'catnum'})
indiv = indiv.drop_duplicates()
indiv.set_index('bird_id', inplace=True)
indiv.to_sql("birds", engine)

# Patches table
df['patch_id'] = df['region'].factorize()[0] + 1
patches = df[['region', 'patch_id']].drop_duplicates()
patches.set_index('patch_id', inplace=True)
patches.to_sql("patches", engine)
patches.head()

# Metadata table
df.reset_index(inplace=True)
df.rename(columns={'index':'spec_id'}, inplace=True)
meta = df[['spec_id', 'bird_id', 'tax_id', 'patch_id']]
meta['spectrophotometer'] = 'Avantes'
meta['observer'] = 'M. Eaton'
meta['inc_angle'] = 0
meta['obs_angle'] = 0
meta.set_index('spec_id', inplace=True)
meta.to_sql('metadata', engine)

# Spectra table
numeric_cols = [col for col in df.select_dtypes(include=['number']).columns if any(char.isdigit() for char in col)]
spectra = df[numeric_cols]
spectra.reset_index(inplace=True)
spectra = spectra.rename(columns={'index':'spec_id'})
spectra.set_index('spec_id', inplace=True)
# Reshape the spectra DataFrame to have a column for wavelengths and another for the corresponding values
spectra_long = pd.melt(spectra.reset_index(), id_vars=['spec_id'], var_name='wl', value_name='reflectance')
# Convert the wavelength column to numeric, extracting the numeric part from the column names
spectra_long['wl'] = spectra_long['wl'].str.extract('(\d+)').astype(int)
spectra_long.set_index('spec_id', inplace=True)
spectra_long.head()
len(spectra_long)  # 350500 rows
spectra_long.to_sql('spectra', engine)

# I should probably have a column with wavelength and ID then link to that?
# that way can select wl > 300 and wl < 700 or something like that in a filter

# maybe have it be able to search-
# 'red birds'
# 'birds in the midwest'
# 'birds with a red head'
# etc.

# could also have it show a cartoon bird with the coloration



# df.to_csv('test.csv')
