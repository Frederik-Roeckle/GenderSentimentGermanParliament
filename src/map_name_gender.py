import pandas as pd

df = pd.read_csv(r"./output.csv")
gender_lookup = pd.read_csv(r"../data/member_gender_lookup.csv")
gender_lookup.drop_duplicates(subset=["full_name"],inplace=True)
gender_lookup = gender_lookup.set_index("full_name")
gender_lookup = gender_lookup.to_dict("index")
print(gender_lookup)


def map_gender_current(row):
    if row.current_name in gender_lookup:
        return gender_lookup[row.current_name]["gender"]
    else:
        return "no lookup"
    

def map_gender_interruptor(row):
    if row.interruptor_name in gender_lookup:
        return gender_lookup[row.interruptor_name]["gender"]
    else:
        return "no lookup"

df["current_gender"] = df.apply(map_gender_current, axis=1)
df["interruptor_gender"] = df.apply(map_gender_interruptor, axis=1)

print(df.head())
print(df.columns)

df.to_csv(r"./output_gender.csv", index=False)