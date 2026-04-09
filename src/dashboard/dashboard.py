import streamlit as st
import pandas as pd
import numpy as np


df_all = pd.read_csv(r"./output_gender.csv")

st.title("Zwischen-Fragen")


protocols = list(df_all.source_file.unique())
protocols = sorted(set([p[:5] for p in protocols]))
print(protocols)
selected_protocols = st.multiselect("Select protocols", protocols)
df = df_all.loc[df_all.source_file.str[:5].isin(selected_protocols)]


next = st.button("next question", shortcut="n", type="primary")
next = True

if next:
    st.markdown("***")
    accepted = False
    while not accepted:
        frage = df.sample(1)
        print(frage.zwischenfrage_text.item())
        if frage.zwischenfrage_text.item() is not np.nan:
            accepted = True
    print(frage.columns)
    st.markdown(f'**"** {frage.zwischenfrage_text.item()}**"**')
    st.markdown("***")
    st.markdown(f"**{frage.current_gender.item()}** (Speaker)  <-  **{frage.interruptor_gender.item()}** (Interruptor)")
    st.markdown(f"**{frage.current_party.item()}** (Speaker)  <-  **{frage.interruptor_party.item()}** (Interruptor)")
    next = False