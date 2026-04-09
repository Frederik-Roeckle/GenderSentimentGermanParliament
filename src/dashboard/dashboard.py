import streamlit as st
import pandas as pd
import numpy as np


df = pd.read_csv(r"./output_gender.csv")

st.title("Dashboard")

if st.button("next question", shortcut="N", type="primary"):
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
    
